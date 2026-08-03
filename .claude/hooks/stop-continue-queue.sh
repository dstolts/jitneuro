#!/bin/bash
# JitNeuro Autonomous-Continuation Stop Hook (stop-continue-queue.sh)
# Event: Stop -- fires when the agent finishes a turn and is about to yield control.
#
# PURPOSE: make autonomous execution MECHANICAL instead of advisory. While
# "autonomous mode" is ON for THIS SESSION and executable tasks remain in the
# session's own queue, this hook BLOCKS the stop (exit 2) and re-injects a
# "continue the queue" directive -- so the session keeps working a backlog
# unattended (AFK) instead of stopping after each task. A soft rule ("keep
# going") cannot enforce this; a hook fires in the harness and cannot be
# rationalized past by the model.
#
# SAFE BY DEFAULT: does NOTHING unless the autonomous-mode flag is set for this
# session. Normal interactive sessions are completely unaffected.
#
# SESSION-SCOPED (v2): the autonomous-mode flag is per-session so arming one
# session never blocks sibling sessions in the same workspace.
#
# Stop-hook exit contract (Claude Code):
#   exit 0            -> allow the stop (normal yield)
#   exit 2 + stderr   -> BLOCK the stop; stderr is fed back as the next directive
#   any other nonzero -> non-blocking error (also allows the stop) => FAIL-OPEN
#
# FLAG LOCATIONS (checked in order, session-scoped preferred):
#   1. <STATE_DIR>/autonomous-mode.<SESSION_ID>.flag  (session-scoped, preferred)
#   2. <STATE_DIR>/autonomous-mode.flag               (legacy workspace-shared,
#      backward-compat; content "on:<session_id>" still honored for old scoping)
#
# ARM (preferred):   echo on > <STATE_DIR>/autonomous-mode.<SESSION_ID>.flag
# ARM (legacy):      echo on > <STATE_DIR>/autonomous-mode.flag
# DISARM (preferred): rm <STATE_DIR>/autonomous-mode.<SESSION_ID>.flag
# DISARM (legacy):    rm <STATE_DIR>/autonomous-mode.flag
#
# QUEUE SOURCE (session's own lane -- no cross-lane contamination):
#   The hook resolves the SESSION's lane (= basename of git toplevel of PROJECT_DIR)
#   and reads that lane's queue, NOT cwd's hub blindly.
#   Resolution order:
#     a. $HUBCENTRAL_ROOT/<lane>/Hub.md     (HubCentral branch-agnostic hub)
#        Default HUBCENTRAL_ROOT = sibling _HubCentral/ of the CODE root.
#     b. <cwd>/.HUB/Hub.md (and variants)  ONLY when cwd repo matches session lane.
#        Cross-lane cwd hubs are BLOCKED -- prevents a jit-knowledge session from
#        reading the content-marketing lane's tasks when its cwd is the shared clone.
#   Counts unchecked "- [ ]" lines under ACTIVE TODO, excluding ones marked
#   blocked/hold/awaiting/needs-owner/red-zone.
#
# DB-READY QUEUE (ticket #3892, parent #3890 "Ready queue is never a parking
# lot"): the Hub.md count above is a hand-maintained MIRROR that drifts. The
# authoritative executable queue is the HubCentral DB Ready queue
# (GET devops/tasks/ready?lane=<lane>&limit=1, server-side scoped to THIS lane,
# excludes claimed/in-progress tickets). WORK = Hub.md REMAINING + DB_READY
# drives BOTH the empty-check (block vs allow) and the runaway/stall counter,
# so a lane whose Hub.md is empty but whose DB has Ready tickets still
# continues, and a persistently non-empty DB still releases after MAX_STALL.
# DB_READY is consulted ONLY when the arming gate has already passed (same
# policy as Hub.md continuation -- see Section 3 of
# WIP-Drafts/DESIGN-3892-stop-hook-db-ready-2026-07-22.md for the full
# rationale); a non-armed interactive stop never pays the DB round-trip.
# FAIL-OPEN: any DB error (no lane, no curl/python3, no current-lane env file,
# missing/expired JWT, HTTP error, timeout, non-JSON body) => DB_READY=0. A DB
# problem can only make the hook FORGET DB work, never invent a block.
#
# WIP-DRAFTS GRADUATION GATE (ticket #4921, Owner directive 2026-07-24):
# lane=jit-knowledge ONLY. Once Hub.md REMAINING + DB_READY == 0 (ticket
# queue genuinely exhausted), scans WIP-Drafts/ (excluding .zArchive/) and
# adds any `wip-ready`/`build-ready` draft to WORK, so the stop stays
# BLOCKED with the graduation instruction (skills/graduate/SKILL.md) until
# every graduation-eligible draft has shipped a PR. Drafts in any other
# status are advisory-only (counted, never block). FAIL-OPEN: no WIP-Drafts
# root, no awk/find, or malformed frontmatter (missing opening/closing
# `---`) => that draft (or the whole scan) is skipped, never blocked on.
# See rules/wip-drafts-graduation-stop-gate.md for the policy summary.
#
# RECURSION GUARD (ticket #4313): before ANY side effect, honor the payload's
# stop_hook_active boolean. Claude Code sets it true when THIS stop is already
# happening inside a stop-hook-driven continuation (a previous exit-2 block
# re-entered us). Blocking again just re-triggers the continuation until Claude
# Code's consecutive-block safety cap force-ends the turn -- the Owner-reported
# "blocked 9 consecutive times -- overriding and ending turn" failure. When
# stop_hook_active is JSON boolean true we return success immediately (exit 0,
# no intercom, no queue scan, no counter, no exit 2), so this hook blocks at
# most ONCE per genuine stop attempt and never fights the harness loop-breaker.
#
# RUNAWAY GUARD: stall counter (per-session) resets on progress (combined WORK
# count drops). After JITNEURO_MAX_CONTINUE (default 50) consecutive
# NO-PROGRESS turns it gives up and allows the stop. Claude Code's own
# consecutive-block cap (CLAUDE_CODE_STOP_HOOK_BLOCK_CAP) is a SECONDARY
# backstop for hooks that ignore stop_hook_active -- it is not the primary fix
# and not a substitute for the recursion guard above.

set +e   # never abort; FAIL-OPEN -- a crash must allow the stop, never trap the session

# ---- read hook payload (stdin JSON) ----
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  INPUT=$(cat 2>/dev/null || true)
fi

norm(){ printf '%s' "$1" | sed 's#\\\\#/#g; s#\\#/#g'; }

CWD=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
CWD=$(norm "$CWD")

# Session ID: prefer env var (Claude Code sets CLAUDE_SESSION_ID), fall back to payload
SESSION_ID="${CLAUDE_SESSION_ID:-}"
[ -z "$SESSION_ID" ] && SESSION_ID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

PROJECT_DIR=$(norm "${CLAUDE_PROJECT_DIR:-$CWD}")
STATE_DIR="$PROJECT_DIR/.sessions"
LOG="/tmp/jitneuro-autonomous.log"
MAX_STALL="${JITNEURO_MAX_CONTINUE:-50}"

log(){ echo "[$(date 2>/dev/null)] $*" >> "$LOG" 2>/dev/null; }

# ---- RECURSION GUARD (ticket #4313): honor stop_hook_active, FAIL-OPEN ----
# Runs BEFORE lane resolution, intercom, the flag/counter, the DB round-trip,
# and every exit-2 path. Only a bare JSON boolean  true  bypasses; false /
# absent / malformed / the STRING "true" all FALL THROUGH to normal first-pass
# behavior. Fail-open: a parse problem can only make us forget to bypass (we
# then run the ordinary once-block logic), never invent a bypass, and never
# blocks on its own. See scripts/session-lane-resolve.sh's sibling guard note.
_stop_hook_active_is_true(){
  # $1 = raw payload JSON string.
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$1" | python3 -c 'import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(1)
sys.exit(0 if d.get("stop_hook_active") is True else 1)' >/dev/null 2>&1
    return $?
  fi
  # No python3 -- conservative regex: the value must be a bare boolean  true
  # (token followed by whitespace then , or } or line-end), never the "true" string.
  printf '%s' "$1" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true([[:space:]]*[,}]|[[:space:]]*$)'
}
if _stop_hook_active_is_true "$INPUT"; then
  log "stop_hook_active=true -> recursion guard: allow stop (no side effects) [#4313]"
  exit 0
fi

# ---- resolve the session's lane: SESSION IDENTITY first, cwd/path fallback only ----
# WS6 (Epic #4526): lane = session identity (env / env-file / registry), NEVER
# the shell's cwd. Source the shared resolver; on any failure (missing file,
# older install, function not defined), degrade to the EXACT pre-WS6 behavior
# below -- a guarded inline fallback so a missing session-lane-resolve.sh never
# breaks a stop across the fleet. See scripts/session-lane-resolve.sh for the full
# resolution-order contract.
LANE=""
GIT_TOP=""
_LANE_RESOLVE_SH="${BASH_SOURCE[0]%/*}/session-lane-resolve.sh"
if [ -f "$_LANE_RESOLVE_SH" ]; then
  # shellcheck disable=SC1090
  . "$_LANE_RESOLVE_SH" 2>/dev/null
fi
if command -v resolve_session_lane >/dev/null 2>&1; then
  _CWD_LANE_HINT=""
  if command -v git >/dev/null 2>&1; then
    _CWD_TOP=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)
    [ -n "$_CWD_TOP" ] && _CWD_LANE_HINT=$(basename "$(norm "$_CWD_TOP")")
  fi
  [ -z "$_CWD_LANE_HINT" ] && _CWD_LANE_HINT=$(basename "$CWD")
  LANE=$(resolve_session_lane "$_CWD_LANE_HINT" 2>>"$LOG")
  log "lane resolved via ${LANE_RESOLVE_SOURCE:-unknown}: $LANE"
fi
if [ -z "$LANE" ]; then
  # GUARDED INLINE FALLBACK: resolver missing/failed -- reproduce pre-WS6
  # behavior exactly (basename of git toplevel of PROJECT_DIR/CWD).
  if command -v git >/dev/null 2>&1; then
    GIT_TOP=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null \
              || git -C "$CWD" rev-parse --show-toplevel 2>/dev/null \
              || true)
    [ -n "$GIT_TOP" ] && GIT_TOP=$(norm "$GIT_TOP") && LANE=$(basename "$GIT_TOP")
  fi
  [ -z "$LANE" ] && LANE=$(basename "$PROJECT_DIR")
  log "lane resolver unavailable -> inline fallback: $LANE"
fi

# ---- resolve HubCentral root (optional; enables branch-agnostic queue/inbox) ----
HUBCENTRAL="${HUBCENTRAL_ROOT:-}"
if [ -z "$HUBCENTRAL" ]; then
  CODE_ROOT=$(dirname "${GIT_TOP:-$PROJECT_DIR}")
  [ -d "$CODE_ROOT/_HubCentral" ] && HUBCENTRAL=$(norm "$CODE_ROOT/_HubCentral")
fi

# ---- hoisted: resolve a CURRENT, exact-lane credential env file ----
# Shared by the pre-stop intercom check (below) AND db_ready_count() (used
# later, after the arming gate). Resolved ONCE. Never use a substring glob:
# e.g. lane "knowledge" must not inherit a newer "scanner-knowledge" JWT.
ENV_FILE=""
SESSIONS_DIR="$HOME/Code/.sessions/work-items/sessions"
env_value(){ sed -n "s/^$2=[\"']\{0,1\}\([^\"']*\)[\"']\{0,1\}$/\\1/p" "$1" 2>/dev/null | head -1; }
env_is_current_lane(){
  [ -f "$1" ] || return 1
  [ "$(env_value "$1" WORK_ITEMS_REFRESH_LANE)" = "$LANE" ] || return 1
  expiry=$(env_value "$1" WORK_ITEMS_TOKEN_EXPIRES_AT)
  [ -z "$expiry" ] && return 1
  python3 - "$expiry" <<'PY' >/dev/null 2>&1
import datetime, sys
try:
    exp = datetime.datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
    if exp.tzinfo is None: exp = exp.replace(tzinfo=datetime.timezone.utc)
    raise SystemExit(0 if exp > datetime.datetime.now(datetime.timezone.utc) else 1)
except Exception:
    raise SystemExit(1)
PY
}
if [ -n "$LANE" ]; then
  if [ -n "${WORK_ITEMS_ENV_FILE:-}" ] && env_is_current_lane "${WORK_ITEMS_ENV_FILE:-}"; then
    ENV_FILE="$WORK_ITEMS_ENV_FILE"
  elif [ -d "$SESSIONS_DIR" ] && command -v python3 >/dev/null 2>&1; then
    while IFS= read -r candidate; do
      if env_is_current_lane "$candidate"; then ENV_FILE="$candidate"; break; fi
    done < <(find "$SESSIONS_DIR" -maxdepth 1 -type f -name 'claude-*.env' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null)
  fi
fi

# ---- db_ready_count(): pull-eligible Ready count for THIS lane (fail-open) ----
# Reuses the same hget/count pattern as intercom-agent-poll.sh. Called later,
# after the arming gate, so a non-armed interactive stop never pays this cost.
db_ready_count(){
  # FAIL-OPEN: any failure prints 0 and returns 0. A DB problem can only make
  # this hook FORGET DB work, never invent a block.
  [ -n "$LANE" ] || { echo 0; return 0; }
  command -v curl    >/dev/null 2>&1 || { echo 0; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo 0; return 0; }

  local envf="$1" jwt api body n
  [ -n "$envf" ] && [ -f "$envf" ] || { echo 0; return 0; }   # no current-lane env => fail open
  jwt=$(env_value "$envf" WORK_ITEMS_SKILL_JWT)
  api=$(env_value "$envf" DASH_API_URL); api="${api:-https://dash-api.jitai.co/api}"
  [ -n "$jwt" ] || { echo 0; return 0; }                       # no JWT => fail open

  # -m 5 hard timeout; no retry (a Stop hook must stay fast -- a missed Ready
  # ticket on one stop is recovered on the next stop or the scheduled poll).
  body=$(curl -sS -m 5 -H "Authorization: Bearer $jwt" \
         "$api/devops/tasks/ready?lane=$LANE&limit=1" 2>/dev/null || echo '')
  case "$body" in \{*|\[*) : ;; *) echo 0; return 0 ;; esac      # non-JSON/empty => fail open

  n=$(printf '%s' "$body" | python3 -c '
import sys,json
try: d=json.load(sys.stdin)
except Exception: print(0); sys.exit()
if isinstance(d,list): print(len(d)); sys.exit()
if isinstance(d,dict):
  for k in ("items","data","messages","tasks","candidates","results","rows"):
    v=d.get(k)
    if isinstance(v,list): print(len(v)); sys.exit()
print(0)' 2>/dev/null || echo 0)
  n=$(printf '%s' "$n" | tr -cd '0-9'); echo "${n:-0}"; return 0
}

# ---- WIP-Drafts graduation gate (#4921, Owner directive 2026-07-24) ----
# "for the knowledge lane if you are in afk working tickets or all done and
# before stop, you must also check WIP-Draft and work to get drafts pushed
# into production before the full stop can execute". Consulted ONLY when
# lane=jit-knowledge AND the ticket queue (Hub.md + DB-ready, above) is
# otherwise exhausted -- same cost discipline as the DB-ready round-trip: a
# non-armed interactive stop, a non-jit-knowledge lane, or a lane with real
# ticket work left never pays this scan. A `wip-ready` or `build-ready`
# draft (frontmatter `status:`, `.zArchive/` excluded) is graduation-eligible
# and BLOCKS the stop; every other status is advisory-only (never blocks) --
# per skills/graduate/SKILL.md and rules/wip-drafts-lifecycle.md.
# FAIL-OPEN throughout: a missing WIP-Drafts root, missing awk/find, an
# unreadable file, or malformed frontmatter (no opening/closing `---`) can
# only make this gate FORGET a draft, never invent a block.

# Resolve the jit-knowledge repo root that actually has a WIP-Drafts/ dir.
# Tries the caller-supplied root, PROJECT_DIR, CWD (each either directly or
# via its git toplevel), then the documented default clone path -- mirrors
# the <KnowledgeRoot> resolver in rules/jit-knowledge-load.md so a worktree
# session (whose own checkout also carries a tracked WIP-Drafts/) resolves
# correctly without hard-coding a single path.
_wip_drafts_root(){
  local cand top
  for cand in "${JIT_KNOWLEDGE_ROOT:-}" "$PROJECT_DIR" "$CWD" "$HOME/Code/jit-knowledge"; do
    [ -n "$cand" ] || continue
    if [ -d "$cand/WIP-Drafts" ]; then printf '%s' "$cand"; return 0; fi
    if command -v git >/dev/null 2>&1; then
      top=$(git -C "$cand" rev-parse --show-toplevel 2>/dev/null || true)
      if [ -n "$top" ] && [ -d "$top/WIP-Drafts" ]; then printf '%s' "$top"; return 0; fi
    fi
  done
  return 1
}

# Print a file's frontmatter `status:` value, or "" when the frontmatter is
# absent/malformed (no opening `---` on line 1, or no closing `---` found
# within 250 lines) -- the empty result is the fail-open signal the caller
# treats as "skip, do not count either way". Never errors the caller.
_frontmatter_status(){
  awk '
    NR==1 {
      if ($0 !~ /^---[[:space:]]*$/) { exit }
      ok=1; next
    }
    ok && /^---[[:space:]]*$/ { closed=1; exit }
    ok && /^status:[[:space:]]*/ && st=="" {
      val=$0
      sub(/^status:[[:space:]]*/, "", val)
      sub(/^"/, "", val); sub(/"[[:space:]]*$/, "", val)
      sub(/[[:space:]]*#.*$/, "", val)
      gsub(/[[:space:]]+$/, "", val)
      st=val
    }
    ok && FNR>250 { exit }
    END { if (closed==1) print st; else print "" }
  ' "$1" 2>/dev/null
}

# Scan WIP-Drafts/ (excluding .zArchive/) and set:
#   WIP_OFFENDERS       newline-joined "path (status: X)" for wip-ready/build-ready
#   WIP_OFFENDER_COUNT  count of the above (blocking)
#   WIP_ADVISORY_COUNT  count of every other real-status draft (never blocks)
# Always returns 0 -- callers check the globals, not the return code.
_wip_drafts_scan(){
  WIP_OFFENDERS=""
  WIP_ADVISORY_COUNT=0
  WIP_OFFENDER_COUNT=0
  command -v awk  >/dev/null 2>&1 || { log "wip-drafts scan: no awk -> skip (fail-open)"; return 0; }
  command -v find >/dev/null 2>&1 || { log "wip-drafts scan: no find -> skip (fail-open)"; return 0; }

  local root
  root=$(_wip_drafts_root) || { log "wip-drafts scan: no WIP-Drafts root found -> skip (fail-open)"; return 0; }

  local f status offenders="" advisory=0 ocount=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    status=$(_frontmatter_status "$f")
    case "$status" in
      wip-ready|build-ready)
        offenders="${offenders}${f} (status: ${status})"$'\n'
        ocount=$((ocount+1))
        ;;
      "") : ;;   # no/malformed frontmatter -> fail-open, uncounted either way
      *) advisory=$((advisory+1)) ;;
    esac
  done < <(find "$root/WIP-Drafts" -type f -name '*.md' -not -path '*/.zArchive/*' 2>/dev/null)

  WIP_OFFENDERS="$offenders"
  WIP_ADVISORY_COUNT="$advisory"
  WIP_OFFENDER_COUNT="$ocount"
  return 0
}

# ---- pre-stop intercom check: applies even when autonomous mode is not armed ----
# This is deliberately separate from queue continuation. An agent that is about
# to yield must not miss an inbound cross-lane request just because its task
# queue is empty or autonomous mode is off.
#
# BASH-FIRST (preferred, cross-platform): shells out to HubCentral's
# intercom-curl.sh (curl + python3, no PowerShell required). pwsh is broken
# on some machines (crashes with a .NET assembly error) which silently
# no-ops the old pwsh-only check under `2>/dev/null` -- bash-first avoids
# that failure mode entirely. The pwsh/intercom-check.ps1 path is kept ONLY
# as a fallback for when intercom-curl.sh itself is not present locally
# (e.g. Windows machines without the bash script).
#
# Use --raw and parse the stable JSON contract ourselves.
if [ -n "$HUBCENTRAL" ] && [ -n "$LANE" ]; then
  INTERCOM_SH="$HUBCENTRAL/scripts/intercom-curl.sh"
  if [ -f "$INTERCOM_SH" ]; then
    ENV_ARGS=()
    [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ] && ENV_ARGS=(--env-file "$ENV_FILE")

    looks_json(){ case "$1" in \{*|\[*) return 0 ;; *) return 1 ;; esac; }

    RAW_JSON=$(bash "$INTERCOM_SH" check --lane "$LANE" --raw "${ENV_ARGS[@]}" 2>/dev/null || true)
    if [ -z "$RAW_JSON" ] || ! looks_json "$RAW_JSON"; then
      # one retry -- intercom reads are known to be occasionally flaky
      RAW_JSON=$(bash "$INTERCOM_SH" check --lane "$LANE" --raw "${ENV_ARGS[@]}" 2>/dev/null || true)
    fi

    if [ -n "$RAW_JSON" ] && looks_json "$RAW_JSON" && command -v python3 >/dev/null 2>&1; then
      ACTIONABLE=$(printf '%s' "$RAW_JSON" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print(0)
    raise SystemExit(0)
if isinstance(data, list):
    items = data
elif isinstance(data, dict) and isinstance(data.get("items"), list):
    items = data["items"]
elif isinstance(data, dict) and data:
    items = [data]
else:
    items = []
print(len(items))
' 2>/dev/null)
      ACTIONABLE=$(printf '%s' "$ACTIONABLE" | tr -cd '0-9')
      ACTIONABLE=${ACTIONABLE:-0}
      if [ "$ACTIONABLE" -gt 0 ]; then
        log "BLOCK: inbound intercom (bash) for lane=$LANE count=$ACTIONABLE"
        echo "INBOUND HUBCENTRAL INTERCOM -- do NOT stop. Lane '$LANE' has $ACTIONABLE unread message(s). Run: bash $INTERCOM_SH read --lane $LANE --raw${ENV_FILE:+ --env-file $ENV_FILE} ; then handle each message, resolve it (bash $INTERCOM_SH resolve --id <id>), and mark it processed before yielding." >&2
        exit 2
      fi
    fi
  elif command -v pwsh >/dev/null 2>&1 || command -v powershell.exe >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
    # FALLBACK: intercom-curl.sh not found locally -- use the legacy
    # PowerShell intercom-check.ps1 path (Windows machines typically).
    CHECK_SCRIPT="$HUBCENTRAL/scripts/intercom-check.ps1"
    if [ -f "$CHECK_SCRIPT" ]; then
      INTERCOM_OUT=""
      if command -v pwsh >/dev/null 2>&1; then
        INTERCOM_OUT=$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$CHECK_SCRIPT" -Repo "$LANE" 2>/dev/null || true)
      elif command -v powershell.exe >/dev/null 2>&1; then
        INTERCOM_OUT=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$CHECK_SCRIPT" -Repo "$LANE" 2>/dev/null || true)
      elif command -v powershell >/dev/null 2>&1; then
        INTERCOM_OUT=$(powershell -NoProfile -ExecutionPolicy Bypass -File "$CHECK_SCRIPT" -Repo "$LANE" 2>/dev/null || true)
      fi
      if printf '%s\n' "$INTERCOM_OUT" | grep -qE '^(ACTION|ACTION NEEDED)'; then
        log "BLOCK: inbound intercom (pwsh fallback) for lane=$LANE"
        echo "INBOUND HUBCENTRAL INTERCOM -- do NOT stop. Lane '$LANE' has pending intercom. Run: powershell -NoProfile -ExecutionPolicy Bypass -File $HUBCENTRAL/scripts/intercom-db.ps1 -Action check -Lane $LANE ; then read the relevant message with -Action read, handle it or mark it blocked, and resolve/mark processed before yielding. Check output: $INTERCOM_OUT" >&2
        exit 2
      fi
    fi
  fi
fi

# ---- resolve flag: session-scoped (preferred) vs legacy shared (backward-compat) ----
SESSION_FLAG=""
LEGACY_FLAG="$STATE_DIR/autonomous-mode.flag"
FLAG=""

if [ -n "$SESSION_ID" ]; then
  SESSION_FLAG="$STATE_DIR/autonomous-mode.$SESSION_ID.flag"
fi

if [ -n "$SESSION_FLAG" ] && [ -f "$SESSION_FLAG" ]; then
  FLAG="$SESSION_FLAG"
  log "using session-scoped flag: $SESSION_FLAG"
elif [ -f "$LEGACY_FLAG" ]; then
  FLAG="$LEGACY_FLAG"
  log "using legacy flag: $LEGACY_FLAG"
fi

# Per-session stall counter (prevents session B from polluting session A's stall count)
if [ -n "$SESSION_ID" ]; then
  COUNTER="$STATE_DIR/.autonomous-stall-count.$SESSION_ID"
else
  COUNTER="$STATE_DIR/.autonomous-stall-count"
fi

# ---- safe-by-default: no active flag => allow stop ----
[ -f "$FLAG" ] || { rm -f "$COUNTER" 2>/dev/null; exit 0; }
FLAG_LINE=$(head -1 "$FLAG" 2>/dev/null | tr -d '\r' | tr -d '[:space:]')
case "$FLAG_LINE" in
  on|ON|on:*|ON:*) : ;;                              # active
  *) rm -f "$COUNTER" 2>/dev/null; exit 0 ;;          # off / blank / unknown => allow stop
esac

# legacy session scoping: "on:<session_id>" in the legacy flag applies only to
# that session -- honored for backward-compat with pre-v2 armed sessions
if [ "$FLAG" = "$LEGACY_FLAG" ]; then
  FLAG_SESSION="${FLAG_LINE#*:}"
  if [ "$FLAG_SESSION" != "$FLAG_LINE" ] && [ -n "$FLAG_SESSION" ] && [ -n "$SESSION_ID" ] && [ "$FLAG_SESSION" != "$SESSION_ID" ]; then
    log "legacy flag scoped to $FLAG_SESSION; current session $SESSION_ID -> allow stop"
    exit 0
  fi
fi

log "session=$SESSION_ID lane=$LANE"

# ---- locate the queue -- SESSION's own lane ONLY (no cross-lane contamination) ----
HUB=""

# Priority 1: HubCentral lane hub -- branch-agnostic, immune to worktree churn
if [ -n "$HUBCENTRAL" ] && [ -n "$LANE" ]; then
  HC_HUB="$HUBCENTRAL/$LANE/Hub.md"
  if [ -f "$HC_HUB" ]; then
    HUB="$HC_HUB"
    log "queue: HubCentral hub $HUB"
  fi
fi

# Priority 2: cwd .HUB/Hub.md -- ONLY when cwd repo matches session lane
# This prevents a session whose cwd is a shared clone (e.g. jit-knowledge main)
# from reading a DIFFERENT lane's hub tasks.
if [ -z "$HUB" ]; then
  CWD_GIT_TOP=""
  CWD_LANE=""
  if command -v git >/dev/null 2>&1; then
    CWD_GIT_TOP=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)
    [ -n "$CWD_GIT_TOP" ] && CWD_GIT_TOP=$(norm "$CWD_GIT_TOP") && CWD_LANE=$(basename "$CWD_GIT_TOP")
  fi
  [ -z "$CWD_LANE" ] && CWD_LANE=$(basename "$CWD")

  if [ "$CWD_LANE" = "$LANE" ] || [ -z "$LANE" ]; then
    for cand in "$CWD/.HUB/Hub.md" "$CWD/.hub/hub.md" "$PROJECT_DIR/.HUB/Hub.md" "$PROJECT_DIR/.hub/hub.md"; do
      if [ -f "$cand" ]; then
        HUB="$cand"
        log "queue: cwd hub $HUB (lane match: $LANE)"
        break
      fi
    done
  else
    log "cwd lane ($CWD_LANE) != session lane ($LANE) -> skip cwd hub (cross-lane contamination blocked)"
  fi
fi

# count executable unchecked tasks within the FIRST "## ACTIVE TODO" section ONLY
# (scoping avoids counting stale checkboxes scattered through a sprawling Hub.md)
# NOTE: HUB may be empty here (no Hub.md found for this lane) -- that is fine,
# REMAINING just stays 0 and the DB-ready count (below) still applies.
REMAINING=0
if [ -n "$HUB" ]; then
  SECTION=$(awk '
    f && /^##[[:space:]]/ {f=0; done=1}
    /^##[[:space:]]+ACTIVE TODO/ {if(!done && !f){f=1; next}}
    f {print}
  ' "$HUB" 2>/dev/null)
  REMAINING=$(printf '%s\n' "$SECTION" \
              | grep -E '^[[:space:]]*[-*][[:space:]]*\[[[:space:]]\]' 2>/dev/null \
              | grep -ivE '(blocked|on hold|[^a-z]hold|awaiting|needs owner|red.?zone|waiting on|owner-gated|backlog)' \
              | grep -c . 2>/dev/null)
  REMAINING=$(printf '%s' "$REMAINING" | tr -cd '0-9'); REMAINING=${REMAINING:-0}
else
  log "no Hub.md queue found for lane $LANE (session=$SESSION_ID) -- checking DB-ready queue"
fi

# ---- DB-ready queue (#3892): authoritative Ready count for this lane, fail-open ----
DB_READY=$(db_ready_count "$ENV_FILE")
DB_READY=$(printf '%s' "$DB_READY" | tr -cd '0-9'); DB_READY=${DB_READY:-0}
log "REMAINING(hub)=$REMAINING DB_READY=$DB_READY lane=$LANE"
WORK=$((REMAINING + DB_READY))

# ---- WIP-Drafts graduation gate (#4921): only consulted once the ticket
# queue is otherwise exhausted, and only for the jit-knowledge lane -- never
# pays the filesystem scan on an armed non-knowledge lane or while real
# ticket work remains.
WIP_OFFENDERS=""
WIP_ADVISORY_COUNT=0
WIP_OFFENDER_COUNT=0
if [ "$LANE" = "jit-knowledge" ] && [ "$WORK" -le 0 ]; then
  _wip_drafts_scan
  log "wip-drafts scan: offenders=$WIP_OFFENDER_COUNT advisory=$WIP_ADVISORY_COUNT lane=$LANE"
fi
WORK=$((WORK + WIP_OFFENDER_COUNT))

# no work anywhere (Hub.md, DB, AND WIP-Drafts all empty/clear) => done => allow stop
if [ "$WORK" -le 0 ]; then
  log "no work in Hub.md, DB-ready, or WIP-Drafts for lane $LANE (wip_advisory=$WIP_ADVISORY_COUNT) -> allow stop (done)"
  rm -f "$COUNTER" 2>/dev/null
  exit 0
fi

# ---- runaway guard: per-session stall counter (resets on progress; combined WORK) ----
PREV_COUNT=0; PREV_WORK=999999
if [ -f "$COUNTER" ]; then
  PREV_COUNT=$(sed -n '1p' "$COUNTER" 2>/dev/null | tr -cd '0-9')
  PREV_WORK=$(sed -n '2p' "$COUNTER" 2>/dev/null | tr -cd '0-9')
  PREV_COUNT=${PREV_COUNT:-0}; PREV_WORK=${PREV_WORK:-999999}
fi
if [ "$WORK" -lt "$PREV_WORK" ]; then
  COUNT=0                       # progress since last turn -> reset stall counter
else
  COUNT=$((PREV_COUNT + 1))     # no progress this turn
fi

if [ "$COUNT" -gt "$MAX_STALL" ]; then
  log "stall cap hit ($COUNT > $MAX_STALL) lane=$LANE session=$SESSION_ID (hub=$REMAINING db=$DB_READY wip=$WIP_OFFENDER_COUNT) -> allow stop"
  echo "AUTONOMOUS MODE: no queue progress for $MAX_STALL turns ($REMAINING task(s) in Hub.md${HUB:+ ($HUB)}, $DB_READY DB-ready task(s), $WIP_OFFENDER_COUNT WIP-Drafts graduation offender(s) for lane '$LANE'). Stopping to avoid a runaway loop. Review the stuck item, then re-arm with: echo on > $FLAG" >&2
  rm -f "$COUNTER" 2>/dev/null
  exit 0
fi

printf '%s\n%s\n' "$COUNT" "$WORK" > "$COUNTER" 2>/dev/null

# ---- block the stop; inject the continue directive ----
log "BLOCK: hub=$REMAINING db=$DB_READY wip=$WIP_OFFENDER_COUNT (stall $COUNT/$MAX_STALL) session=$SESSION_ID lane=$LANE"
SRC_MSG=""
if [ "$REMAINING" -gt 0 ] && [ "$DB_READY" -gt 0 ]; then
  SRC_MSG="$REMAINING executable task(s) remain in Hub.md ($HUB '## ACTIVE TODO') AND $DB_READY DB-ready task(s) are pull-eligible for lane '$LANE'. Work the Hub.md item, OR pull the next Ready ticket: bash \$HOME/Code/HubCentral/scripts/devops-task-curl.sh ready --lane $LANE --env-file $ENV_FILE"
elif [ "$DB_READY" -gt 0 ]; then
  SRC_MSG="Hub.md is empty but $DB_READY DB-ready task(s) are pull-eligible for lane '$LANE' (the authoritative queue). Pull the next Ready ticket: bash \$HOME/Code/HubCentral/scripts/devops-task-curl.sh ready --lane $LANE --env-file $ENV_FILE ; claim it, work it end-to-end, and update its state."
elif [ "$REMAINING" -gt 0 ]; then
  SRC_MSG="$REMAINING executable task(s) remain in the queue ($HUB '## ACTIVE TODO')."
fi

if [ -n "$SRC_MSG" ]; then
  echo "AUTONOMOUS MODE ON -- do NOT stop. $SRC_MSG Pick the next unblocked task, mark it in_progress, do the work end-to-end, update its tracker (Hub.md checkbox or DevOps task state), then continue to the next task. If EVERY remaining task is genuinely blocked on Owner or a RED-zone approval, mark them so and run: rm $FLAG  (to release autonomous mode for this session). (continuation; stall $COUNT/$MAX_STALL; session=$SESSION_ID)" >&2
elif [ "$WIP_OFFENDER_COUNT" -gt 0 ]; then
  # WIP-Drafts graduation gate (#4921): ticket queue was already exhausted
  # (REMAINING=0, DB_READY=0) when this branch is reachable -- see the
  # WORK computation above -- so this is a dedicated directive, not a
  # ticket-queue tail appended to an unrelated message.
  WIP_ADVISORY_MSG=""
  if [ "$WIP_ADVISORY_COUNT" -gt 0 ]; then
    WIP_ADVISORY_MSG=" $WIP_ADVISORY_COUNT other WIP-Drafts file(s) are in a non-blocking status (draft/suggestion/etc.) -- ticket or archive them if stale."
  fi
  echo "AUTONOMOUS MODE ON -- do NOT stop. Ticket queue for lane '$LANE' is exhausted, but $WIP_OFFENDER_COUNT WIP-Drafts file(s) are graduation-eligible (frontmatter status wip-ready or build-ready) and have not shipped to canonical:
$WIP_OFFENDERS
Graduate each via the /graduate procedure (skills/graduate/SKILL.md): resolve the file, confirm gates 1-5, then run scripts/graduate-orchestrate.sh <path> --apply --yes (or the /graduate slash command) to open the graduation PR.$WIP_ADVISORY_MSG Once every wip-ready/build-ready draft has a graduation PR open, the stop is allowed. If a draft is genuinely blocked (topic conflict, needs Owner sign-off), record that in the graduation PR or hub/questions.md and move to the next offender rather than stopping. (continuation; stall $COUNT/$MAX_STALL; session=$SESSION_ID)" >&2
else
  # Unreachable in practice (WORK>0 implies REMAINING>0, DB_READY>0, or
  # WIP_OFFENDER_COUNT>0) -- but fail-open rather than block with no directive.
  log "WARN: block path reached with no SRC_MSG and no WIP offenders (hub=$REMAINING db=$DB_READY wip=$WIP_OFFENDER_COUNT) -> allow stop"
  rm -f "$COUNTER" 2>/dev/null
  exit 0
fi
exit 2
