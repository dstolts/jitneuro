#!/usr/bin/env bash
# intercom-agent-poll.sh -- the periodic "am I needed?" tool, run by a scheduled
# agent (~every 20min; see scheduledAgents config). Two jobs:
#   1. FORCE a lane heartbeat  -> time-based keep-alive that also covers PAUSED /
#      idle agents (they use no tools, so the PostToolUse heartbeat never fires).
#   2. Check this lane's INBOX + READY + BLOCKED/STALE work and emit an
#      INSTRUCTION line so master can decide: act now / add-to-todo / do nothing.
#
# Low noise by design: prints "INSTRUCTION: NONE" when nothing is actionable.
# Follows rules/scheduled-agent-interrupts.md (master executes the INSTRUCTION).
#
# ALIAS-AWARE (ticket #4705): a lane's canonical identity can have several
# aliases (e.g. the jit-knowledge lane also receives mail addressed to
# knowledge/kb/hubcentral). Querying only the exact resolved $LANE string
# false-zeros real unread work filed under an alias. When HubCentral's
# lane-canon.sh resolver is available on this machine, this hook unions every
# query across the lane's full alias set and dedupes results by id. If the
# resolver is missing (or errors), it falls back to the prior single-lane
# behavior -- this hook must never fail the calling session either way.
#
# SESSION-IDENTITY-FIRST LANE (ticket #4348, reuses the WS6/Epic #4526
# resolver already shipped for stop-continue-queue.sh and agent-spawn-log.sh):
# lane-resolve.sh below gives a cwd/repo-identity GUESS only -- it has no
# concept of session identity and previously WAS the resolved lane outright.
# That let a stale/ambient SHARED work-items/.env or a bare workspace-root
# cwd hand this hook the WRONG lane (phantom 'code' lane, or a leftover lane
# from whichever HubCentral login ran last on the machine), which then polled
# and could have surfaced ANOTHER lane's inbox -- a cross-lane violation.
# resolve_session_lane() (scripts/session-lane-resolve.sh, sourced from the
# same directory as this hook post-install) looks at SESSION-scoped identity
# sources ONLY (env, this session's own minted env-file, session registry)
# before ever falling back to a path-derived guess, and NEVER reads
# WORK_ITEMS_REFRESH_LANE out of the shared, unscoped work-items/.env.
set -uo pipefail
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# 1. keep-alive (covers paused/idle agents)
"$SELF_DIR/lane-heartbeat.sh" --force >/dev/null 2>&1 || true

# creds (JWT/API only -- NEVER lane identity) from the shared work-items/.env
ENV_FILE="${WORK_ITEMS_ENV_FILE:-$HOME/Code/.sessions/work-items/.env}"
[ -f "$ENV_FILE" ] || ENV_FILE="/Volumes/Code/.sessions/work-items/.env"
get_env(){ grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | sed -e 's/^["'\'']//' -e 's/["'\'']$//'; }
JWT="$(get_env WORK_ITEMS_SKILL_JWT)"
API="$(get_env DASH_API_URL)"; API="${API:-https://dash-api.jitai.co/api}"

# --- resolve LANE: session identity first, cwd-derived repo id as hint/fallback only ---
_CWD_LANE_HINT="$("$SELF_DIR/lane-resolve.sh" "$DIR" 2>/dev/null || true)"
LANE=""
_LANE_RESOLVE_SH="$SELF_DIR/session-lane-resolve.sh"
if [ -f "$_LANE_RESOLVE_SH" ]; then
  # shellcheck disable=SC1090
  . "$_LANE_RESOLVE_SH" 2>/dev/null
fi
if command -v resolve_session_lane >/dev/null 2>&1; then
  LANE="$(resolve_session_lane "$_CWD_LANE_HINT" 2>/dev/null)"
fi
# GUARDED INLINE FALLBACK: resolver missing/failed -- reproduce pre-#4348
# behavior (cwd-derived repo-identity lane from lane-resolve.sh). A missing
# shared resolver script must never break this poll.
[ -z "$LANE" ] && LANE="$_CWD_LANE_HINT"

if [ -z "$JWT" ] || [ -z "$LANE" ]; then
  echo "INSTRUCTION: NONE"; echo "(lane or creds unavailable -- skipped)"; exit 0
fi

# --- resolve the lane's full alias set via HubCentral's canonical resolver ---
# Rejects the phantom workspace-root 'code' lane and other junk. Falls back to
# single-lane behavior (today's behavior) if the resolver is missing/errors.
ALIASES=""
LANE_CANON_SH="${HUBCENTRAL_ROOT:-$HOME/Code/HubCentral}/scripts/lane-canon.sh"
if [ -f "$LANE_CANON_SH" ]; then
  # shellcheck disable=SC1090
  source "$LANE_CANON_SH" 2>/dev/null || true
  if command -v lane_canon >/dev/null 2>&1; then
    CANON="$(lane_canon "$LANE" 2>/dev/null || true)"
    if [ "$CANON" = "__PHANTOM_CODE__" ] || [ -z "$CANON" ]; then
      echo "INSTRUCTION: NONE"; echo "(lane '$LANE' resolves to phantom/junk -- skipped)"; exit 0
    fi
    ALIASES="$(lane_aliases "$LANE" 2>/dev/null || true)"
  fi
fi
[ -n "$ALIASES" ] || ALIASES="$LANE"   # resolver missing/failed -> single-lane fallback

# hget writes the response body to $1 and the HTTP status code to $1.status.
# A companion .status file lets merge_count distinguish "genuinely zero
# items" from "this alias fetch errored" (expired/wrong-lane JWT, network
# blip, 5xx). Without that distinction, an auth failure silently renders as
# READY_TASKS=0 / BLOCKED_OR_STALE=0 -- indistinguishable from a truly quiet
# lane (ticket #4726: reproduced live with an expired JWT on the default
# credential file, which curl treats as a normal 200-shaped-nothing/401 body
# rather than a fetch failure).
hget(){
  local out="$1" url="$2" code
  code="$(curl -sS -m 10 -o "$out" -w '%{http_code}' -H "Authorization: Bearer $JWT" "$API/$url" 2>/dev/null || true)"
  printf '%s' "${code:-000}" > "$out.status"
}

TMPDIR_POLL="$(mktemp -d "${TMPDIR:-/tmp}/intercom-poll.XXXXXX" 2>/dev/null || true)"
if [ -z "$TMPDIR_POLL" ] || [ ! -d "$TMPDIR_POLL" ]; then
  echo "INSTRUCTION: NONE"; echo "(tmp dir unavailable -- skipped)"; exit 0
fi
trap 'rm -rf "$TMPDIR_POLL"' EXIT

# Query every alias for inbox/ready/blocked-or-stale, one response file each.
# Inbox is fetched WITHOUT a server-side status filter: the API's status query
# param does an exact SQL match (status = @status), which silently drops any
# message row whose status is null/None -- a real false-zero source, not a
# hypothetical. We fetch by laneTo only (bounded, recency-ordered) and decide
# "unread" ourselves from the ACTUAL status field per message (see
# merge_count below), mirroring intercom-curl's real intent (unread = not yet
# processed) rather than a brittle string == 'unread' filter.
inbox_files=(); ready_files=(); cand_files=()
n=0
for alias in $ALIASES; do
  n=$((n+1))
  f="$TMPDIR_POLL/inbox_$n.json"
  hget "$f" "devops/messages?laneTo=$alias&limit=100"
  inbox_files+=("$f")
  f="$TMPDIR_POLL/ready_$n.json"
  hget "$f" "devops/tasks/ready?lane=$alias&limit=50"
  ready_files+=("$f")
  f="$TMPDIR_POLL/cand_$n.json"
  hget "$f" "devops/loop/candidates?lane=$alias&pickupTtlSec=900&heartbeatTtlSec=900&limit=25"
  cand_files+=("$f")
done

# Union + dedupe-by-id count across every alias file for one query type.
#   mode=any    -> count every distinct item (ready tasks, blocked/stale candidates)
#   mode=unread -> count distinct items whose status is NOT the terminal
#                  'processed' state (covers status == 'unread' AND status
#                  null/None/missing -- both are unread; only 'processed' is closed)
# Response shape: the API returns either a top-level JSON array (the current
# devops/tasks/ready and devops/loop/candidates shape) or an object carrying
# the list under items/data/messages/tasks/candidates/results/rows -- both are
# handled. Prints "<count> <error_count>": error_count is how many of the
# input files failed (non-2xx status, or unparseable body) -- a non-zero
# error_count means the printed count is a floor, not a verified total.
merge_count(){
  local mode="$1"; shift
  python3 - "$mode" "$@" <<'PY' 2>/dev/null || echo "0 0"
import sys, json, os
mode = sys.argv[1]
paths = sys.argv[2:]
seen = set()
count = 0
errors = 0
for path in paths:
    status = None
    status_path = path + ".status"
    if os.path.exists(status_path):
        try:
            with open(status_path) as sf:
                status = sf.read().strip()
        except Exception:
            status = None
    if status is not None and not status.startswith("2"):
        errors += 1
        continue
    try:
        with open(path) as fh:
            d = json.load(fh)
    except Exception:
        errors += 1
        continue
    items = None
    if isinstance(d, list):
        items = d
    elif isinstance(d, dict):
        for k in ("items", "data", "messages", "tasks", "candidates", "results", "rows"):
            v = d.get(k)
            if isinstance(v, list):
                items = v
                break
    if items is None:
        continue
    for it in items:
        if mode == "unread" and isinstance(it, dict):
            status_field = it.get("status")
            if isinstance(status_field, str) and status_field.strip().lower() == "processed":
                continue  # only a terminal/closed status excludes a message
        key = None
        if isinstance(it, dict):
            key = it.get("id") or it.get("messageId") or it.get("message_id") or it.get("taskId") or it.get("task_id")
        key = str(key) if key is not None else json.dumps(it, sort_keys=True, default=str)
        if key in seen:
            continue
        seen.add(key)
        count += 1
print(f"{count} {errors}")
PY
}

read -r nin nin_err <<<"$(merge_count unread "${inbox_files[@]}")"
read -r nready nready_err <<<"$(merge_count any "${ready_files[@]}")"
read -r ncand ncand_err <<<"$(merge_count any "${cand_files[@]}")"

echo "LANE: $LANE"
echo "INBOX_UNREAD: ${nin:-0}"
echo "READY_TASKS: ${nready:-0}"
echo "BLOCKED_OR_STALE: ${ncand:-0}"
total_err=$(( ${nin_err:-0} + ${nready_err:-0} + ${ncand_err:-0} ))
if [ "$total_err" -gt 0 ]; then
  echo "WARN: $total_err of $((n * 3)) alias fetch(es) failed (network/auth) -- counts above are a floor, not verified; refresh the lane JWT if this persists"
fi
if [ "${nin:-0}" -gt 0 ] || [ "${ncand:-0}" -gt 0 ]; then
  echo "INSTRUCTION: ASK_USER lane '$LANE' has ${nin:-0} unread intercom message(s) and ${ncand:-0} blocked/stale item(s) -- review now"
elif [ "${nready:-0}" -gt 0 ]; then
  echo "INSTRUCTION: RESUME_TASKS ${nready:-0} ready task(s) for lane '$LANE' -- add to todo and work when free"
else
  echo "INSTRUCTION: NONE"
fi
exit 0
