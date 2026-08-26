#!/usr/bin/env bash
# lane-heartbeat.sh [--force] -- send a THROTTLED HubCentral presence heartbeat
# for the current repo's STABLE lane, carrying a dynamic FOCUS string
# ("<lane> @ <branch> [- note]").
#
# Throttle: if a heartbeat was sent < LANE_HEARTBEAT_THROTTLE_SECS ago (default
# 600s = 10min) this is a no-op -- UNLESS --force is passed (used on session
# start). This keeps an actively-working lane fresh without spamming the API on
# every tool call. Time-based keep-alive for PAUSED/idle agents comes from the
# scheduled poll (intercom-agent-poll.sh), which calls this with --force.
#
# Fail-safe: any missing cred / tool / network error -> silent exit 0. Never
# blocks a hook.

FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1
THROTTLE_SECS="${LANE_HEARTBEAT_THROTTLE_SECS:-600}"
DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/Code/.sessions"
STAMP="$STATE_DIR/.lane-heartbeat-stamp"

# --- throttle ---------------------------------------------------------------
if [ "$FORCE" = "0" ] && [ -f "$STAMP" ]; then
  now="$(date +%s)"; last="$(cat "$STAMP" 2>/dev/null || echo 0)"
  [ $((now - last)) -lt "$THROTTLE_SECS" ] && exit 0
fi

# --- creds (plain curl + skill JWT; no node dependency) ---------------------
ENV_FILE="${WORK_ITEMS_ENV_FILE:-$HOME/Code/.sessions/work-items/.env}"
[ -f "$ENV_FILE" ] || ENV_FILE="/Volumes/Code/.sessions/work-items/.env"
[ -f "$ENV_FILE" ] || exit 0
get_env() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | sed -e 's/^["'\'']//' -e 's/["'\'']$//'; }
JWT="$(get_env WORK_ITEMS_SKILL_JWT)"
API="$(get_env DASH_API_URL)"; API="${API:-https://dash-api.jitai.co/api}"
[ -n "$JWT" ] || exit 0

# --- stable lane + dynamic focus --------------------------------------------
LANE="$("$SELF_DIR/lane-resolve.sh" "$DIR" 2>/dev/null || true)"
[ -n "$LANE" ] || exit 0
BRANCH="$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
FOCUS="$LANE"
[ -n "$BRANCH" ] && FOCUS="$LANE @ $BRANCH"
FOCUS_FILE="$STATE_DIR/lane-focus"
if [ -f "$FOCUS_FILE" ]; then
  NOTE="$(head -1 "$FOCUS_FILE" 2>/dev/null | tr -d '"' | cut -c1-100)"
  [ -n "$NOTE" ] && FOCUS="$FOCUS - $NOTE"
fi

HOST="$(hostname -s 2>/dev/null || echo mac)"
VENDOR="${CLAUDE_AGENT_VENDOR:-claude}"
SESSION_ID="${VENDOR}:${LANE}:${HOST}"
BODY="$(printf '{"sessionId":"%s","vendor":"%s","role":"agent","lane":"%s","lanePinned":"%s","machine":"%s","status":"alive","focus":"%s"}' \
  "$SESSION_ID" "$VENDOR" "$LANE" "$LANE" "$HOST" "$FOCUS")"

curl -sS -m 8 -X POST "$API/devops/agents/heartbeat" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d "$BODY" >/dev/null 2>&1 || true

mkdir -p "$STATE_DIR" 2>/dev/null || true
date +%s > "$STAMP" 2>/dev/null || true
exit 0
