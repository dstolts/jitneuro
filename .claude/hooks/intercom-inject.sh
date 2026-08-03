#!/usr/bin/env bash
# intercom-inject.sh -- PUSH counterpart to intercom-agent-poll.sh (PULL).
#
# ARCHITECTURE (ticket #5309 -- signal-file decoupling):
#   The previous implementation made live curl + python3 API calls on every
#   debounce window, adding up to 8s of network latency to the tool-call path.
#   This refactored version reads a LOCAL SIGNAL FILE written by the standalone
#   watcher (templates/claude-hooks/intercom-watch-curl.sh, run on a schedule
#   via launchd/cron) and emits the intercom notification with ZERO network I/O.
#
#   Signal file: ~/.sessions/intercom-signal/<lane>.json
#   Written by: intercom-watch-curl.sh (network-bound, runs off the hot path)
#   Read by:    this hook (pure bash, sub-millisecond)
#
#   If the watcher has never run (no signal file), this hook is a silent no-op.
#   If the watcher wrote zero-unread, this hook is a silent no-op.
#   Only when unread>0 AND the signal file is newer than the per-session
#   last-seen timestamp does this hook emit the notification block.
#
# DEBOUNCE: per-session timestamp under
#   ~/.sessions/intercom-signal/.last-seen-<session_id>
#   Gates repeat injections to at most one per ${INJECT_MIN_INTERVAL:-45}s.
#
# FAIL OPEN: any error (missing lane, missing signal file, parse error) -> exit 0.
# A hook bug must never block a tool call.
#
# See templates/claude-hooks/intercom-watch-curl.sh for the watcher that
# populates the signal files this hook consumes.
# See templates/claude-hooks/intercom-agent-poll.sh for the cadence fallback.
# See rules/scheduled-agent-interrupts.md for the "execute the instruction
# immediately" contract this hook's injected block falls under.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HUBCENTRAL="${HUBCENTRAL_ROOT:-$HOME/Code/HubCentral}"
SIGNAL_DIR="${INTERCOM_SIGNAL_DIR:-$HOME/.sessions/intercom-signal}"

# ---- 1. resolve canonical lane (fail-open: any miss -> silent exit 0) ----------
[ -x "$SELF_DIR/lane-resolve.sh" ] || exit 0
LANE_RAW="$("$SELF_DIR/lane-resolve.sh" "$DIR" 2>/dev/null || true)"
[ -n "$LANE_RAW" ] || exit 0

[ -f "$HUBCENTRAL/scripts/lane-canon.sh" ] || exit 0
# shellcheck source=/dev/null
. "$HUBCENTRAL/scripts/lane-canon.sh" 2>/dev/null || exit 0
command -v lane_canon >/dev/null 2>&1 || exit 0

LANE="$(lane_canon "$LANE_RAW" 2>/dev/null || true)"
[ -n "$LANE" ] || exit 0
[ "$LANE" != "__PHANTOM_CODE__" ] || exit 0

# ---- 2. debounce ---------------------------------------------------------------
STATE_DIR="$SIGNAL_DIR"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_FILE="$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9_.-' '_')"
STAMP_FILE="$STATE_DIR/.last-seen-${SESSION_FILE}"
MIN_INTERVAL="${INJECT_MIN_INTERVAL:-45}"

now="$(date +%s 2>/dev/null || echo 0)"
if [ -f "$STAMP_FILE" ]; then
  last="$(cat "$STAMP_FILE" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  elapsed=$(( now - last ))
  if [ "$elapsed" -lt "$MIN_INTERVAL" ]; then
    exit 0
  fi
fi
# Update stamp NOW so even a failed/no-op run still advances the debounce window
echo "$now" > "$STAMP_FILE" 2>/dev/null || true

# ---- 3. read signal file -------------------------------------------------------
SIG_FILE="$SIGNAL_DIR/${LANE}.json"
[ -f "$SIG_FILE" ] || exit 0

# Read unread count (pure bash grep/sed -- no python3, no curl)
sig_content="$(cat "$SIG_FILE" 2>/dev/null || true)"
[ -n "$sig_content" ] || exit 0

# Extract "unread": N  (handles both 0 and positive integers)
unread="$(printf '%s' "$sig_content" | grep -oE '"unread"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$' || true)"
unread="${unread:-0}"
case "$unread" in ''|*[!0-9]*) unread=0 ;; esac
[ "$unread" -gt 0 ] || exit 0

# ---- 4. extract summary fields from signal file --------------------------------
urgent="$(printf '%s' "$sig_content" | grep -oE '"urgent"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$' || true)"
urgent="${urgent:-0}"
case "$urgent" in ''|*[!0-9]*) urgent=0 ;; esac

latest_id="$(printf '%s' "$sig_content" | grep -oE '"latest_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"latest_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)"
latest_summary="$(printf '%s' "$sig_content" | grep -oE '"latest_summary"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"latest_summary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)"

sig_ts="$(printf '%s' "$sig_content" | grep -oE '"ts"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"ts"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)"
sig_ts="${sig_ts:-unknown}"

# ---- 5. emit injection block ---------------------------------------------------
if [ "$urgent" -gt 0 ]; then
  echo "===== INTERCOM: $LANE -- $unread unread ($urgent urgent) [as of $sig_ts] ====="
else
  echo "===== INTERCOM: $LANE -- $unread unread [as of $sig_ts] ====="
fi
if [ -n "$latest_id" ]; then
  echo "  latest id=$latest_id: $latest_summary"
fi
echo "  Run intercom-check or check the signal file to read full messages."
echo "===== END INTERCOM -- act on these before continuing prior work ====="

exit 0
