#!/usr/bin/env bash
# intercom-watch-curl.sh -- Standalone watcher that polls the HubCentral intercom
# API for ACTION-class directed messages and writes a signal file.
#
# PURPOSE: decouple the network/API call from the PreToolUse hot path. This script
# runs on a schedule (launchd or cron, ~60s interval) so that intercom-inject.sh
# (the PreToolUse hook) can check a local signal file with ZERO network latency
# instead of making a live curl call on every debounce window.
#
# SIGNAL FILE LOCATION:
#   ~/.sessions/intercom-signal/<lane>.json
#
# SIGNAL FILE SCHEMA (atomic write via tmp+mv):
#   {"unread":N,"urgent":N,"latest_id":"<id>","latest_summary":"<text>","ts":"<ISO8601>"}
#   When there are zero unread ACTION-class messages:
#   {"unread":0,"ts":"<ISO8601>"}
#
# LANE RESOLUTION:
#   1. $INTERCOM_WATCH_LANE env var (explicit override)
#   2. lane-canon.sh / lane_aliases from $HUBCENTRAL/scripts/lane-canon.sh
#   3. lane-resolve.sh from the same directory as this script
#
# CREDENTIALS: same env-file resolution as intercom-inject.sh.
#   ENV_FILE: $WORK_ITEMS_ENV_FILE or $HOME/Code/.sessions/work-items/.env
#   JWT: WORK_ITEMS_SKILL_JWT from the env file
#   API: DASH_API_URL from the env file (default: https://dash-api.jitai.co/api)
#
# FILTER: ACTION, DIRECTIVE, REQUEST message types only (not STATUS noise).
#
# FAIL OPEN: any error (missing lane, missing creds, network error, parse error)
# writes a zero-unread signal file (or leaves the existing one intact) and exits 0.
# This script must never block the scheduler or the Claude agent session.
#
# USAGE:
#   bash intercom-watch-curl.sh [--lane <lane>] [--dir <cwd>]
#   Scheduled: run every 60s via launchd / cron.
#
# INSTALL:
#   Copied to ~/.claude/hooks/ by scripts/install.sh (the templates/claude-hooks/
#   glob picks it up automatically). Register in launchd or a cron job:
#     bash ~/.claude/hooks/intercom-watch-curl.sh
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
HUBCENTRAL="${HUBCENTRAL_ROOT:-$HOME/Code/HubCentral}"
SIGNAL_DIR="${INTERCOM_SIGNAL_DIR:-$HOME/.sessions/intercom-signal}"
WATCH_TIMEOUT="${INTERCOM_WATCH_TIMEOUT:-8}"

# ---- parse args ----------------------------------------------------------------
LANE_OVERRIDE=""
DIR_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lane) LANE_OVERRIDE="${2:-}"; shift 2 ;;
    --dir)  DIR_OVERRIDE="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
DIR="${DIR_OVERRIDE:-${CLAUDE_PROJECT_DIR:-$PWD}}"

# ---- helper: write zero-unread signal (best-effort, fail open) -----------------
_write_zero() {
  local lane="$1"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")"
  local tmp
  tmp="$(mktemp "$SIGNAL_DIR/.tmp_${lane}_XXXXXX" 2>/dev/null)" || return 0
  printf '{"unread":0,"ts":"%s"}\n' "$ts" >"$tmp" 2>/dev/null || { rm -f "$tmp"; return 0; }
  mv "$tmp" "$SIGNAL_DIR/${lane}.json" 2>/dev/null || rm -f "$tmp"
}

# ---- 1. resolve canonical lane -------------------------------------------------
LANE="${INTERCOM_WATCH_LANE:-${LANE_OVERRIDE:-}}"
if [ -z "$LANE" ]; then
  [ -x "$SELF_DIR/lane-resolve.sh" ] || exit 0
  LANE_RAW="$("$SELF_DIR/lane-resolve.sh" "$DIR" 2>/dev/null || true)"
  [ -n "$LANE_RAW" ] || exit 0

  if [ -f "$HUBCENTRAL/scripts/lane-canon.sh" ]; then
    # shellcheck source=/dev/null
    . "$HUBCENTRAL/scripts/lane-canon.sh" 2>/dev/null || true
  fi
  if command -v lane_canon >/dev/null 2>&1; then
    LANE="$(lane_canon "$LANE_RAW" 2>/dev/null || true)"
  else
    LANE="$LANE_RAW"
  fi
  [ -n "$LANE" ] || exit 0
  [ "$LANE" != "__PHANTOM_CODE__" ] || exit 0
fi

# ---- ensure signal dir exists --------------------------------------------------
mkdir -p "$SIGNAL_DIR" 2>/dev/null || exit 0

# ---- 2. credentials ------------------------------------------------------------
ENV_FILE="${WORK_ITEMS_ENV_FILE:-$HOME/Code/.sessions/work-items/.env}"
[ -f "$ENV_FILE" ] || ENV_FILE="/Volumes/Code/.sessions/work-items/.env"
get_env() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | sed -e 's/^["'\'']//' -e 's/["'\'']$//'; }
JWT="$(get_env WORK_ITEMS_SKILL_JWT)"
API="$(get_env DASH_API_URL)"; API="${API:-https://dash-api.jitai.co/api}"
if [ -z "$JWT" ]; then
  _write_zero "$LANE"
  exit 0
fi
command -v curl >/dev/null 2>&1 || { _write_zero "$LANE"; exit 0; }

# ---- 3. build alias set --------------------------------------------------------
ALIASES="$LANE"
if command -v lane_aliases >/dev/null 2>&1; then
  _aliases="$(lane_aliases "$LANE" 2>/dev/null || true)"
  [ -n "$_aliases" ] && ALIASES="$_aliases"
fi

# ---- 4. fetch ACTION-class unread messages across all aliases ------------------
TMP_DIR="$(mktemp -d 2>/dev/null)" || { _write_zero "$LANE"; exit 0; }
trap 'rm -rf "$TMP_DIR"' EXIT

total_unread=0
total_urgent=0
latest_id=""
latest_summary=""
seen_ids=""

for alias in $ALIASES; do
  resp_file="$TMP_DIR/resp_${alias}.json"
  http_code="$(curl -sS -m "$WATCH_TIMEOUT" \
    -o "$resp_file" -w '%{http_code}' \
    -H "Authorization: Bearer $JWT" \
    "$API/devops/messages?laneTo=$alias&status=unread&limit=50" 2>/dev/null || echo "000")"

  # skip non-2xx responses
  case "$http_code" in 2*) ;; *) continue ;; esac
  [ -f "$resp_file" ] || continue

  # parse with awk/grep to avoid python3 dependency
  # Extract ids and types using line-oriented json parsing (API returns compact or
  # pretty-printed JSON). We use a simple state-machine approach via awk.
  # Expected response: array of message objects with fields: id, type, priority, body/message
  # We extract one object at a time by splitting on "}," or "}" patterns.

  # Use python3 only if available (fail-open to zero if not)
  if command -v python3 >/dev/null 2>&1; then
    result="$(python3 - "$resp_file" <<'PY' 2>/dev/null || true
import sys, json, re

try:
    with open(sys.argv[1]) as f:
        raw = f.read().strip()
    d = json.loads(raw)
except Exception:
    sys.exit(0)

if isinstance(d, list):
    items = d
elif isinstance(d, dict):
    items = None
    for k in ("items", "data", "messages", "results", "rows"):
        v = d.get(k)
        if isinstance(v, list):
            items = v
            break
    if items is None:
        items = []
else:
    items = []

for m in items:
    if not isinstance(m, dict):
        continue
    mid = str(m.get("id") or "")
    mtype = str(m.get("type") or "").upper()
    mpri = str(m.get("priority") or "normal").lower()
    mstatus = str(m.get("status") or "unread").lower()
    if mstatus == "processed":
        continue
    if mtype not in ("ACTION", "DIRECTIVE", "REQUEST"):
        continue
    body = m.get("body") or m.get("message") or ""
    body = re.sub(r"\s+", " ", str(body)).strip()[:120]
    is_urgent = "1" if mpri in ("urgent", "high", "critical") else "0"
    print(f"{mid}\t{is_urgent}\t{body}")
PY
)"
    if [ -n "$result" ]; then
      while IFS="$(printf '\t')" read -r mid is_urgent body; do
        [ -n "$mid" ] || continue
        # deduplicate by id across aliases
        case " $seen_ids " in *" $mid "*) continue ;; esac
        seen_ids="$seen_ids $mid"
        total_unread=$(( total_unread + 1 ))
        [ "$is_urgent" = "1" ] && total_urgent=$(( total_urgent + 1 ))
        if [ -z "$latest_id" ]; then
          latest_id="$mid"
          latest_summary="$body"
        fi
      done <<EOF
$result
EOF
    fi
  fi
  # If python3 not available, we leave counts at zero from this alias;
  # the signal file will reflect zero and the hook will be a no-op.
done

# ---- 5. write signal file (atomic tmp+mv) -------------------------------------
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")"
tmp_sig="$(mktemp "$SIGNAL_DIR/.tmp_${LANE}_XXXXXX" 2>/dev/null)" || exit 0

# Escape for JSON (basic: escape backslashes and double-quotes, remove newlines)
_json_str() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n\r'
}

if [ "$total_unread" -gt 0 ]; then
  lid="$(_json_str "$latest_id")"
  lsum="$(_json_str "$latest_summary")"
  printf '{"unread":%d,"urgent":%d,"latest_id":"%s","latest_summary":"%s","ts":"%s"}\n' \
    "$total_unread" "$total_urgent" "$lid" "$lsum" "$ts" >"$tmp_sig" 2>/dev/null || { rm -f "$tmp_sig"; exit 0; }
else
  printf '{"unread":0,"ts":"%s"}\n' "$ts" >"$tmp_sig" 2>/dev/null || { rm -f "$tmp_sig"; exit 0; }
fi

mv "$tmp_sig" "$SIGNAL_DIR/${LANE}.json" 2>/dev/null || rm -f "$tmp_sig"
exit 0
