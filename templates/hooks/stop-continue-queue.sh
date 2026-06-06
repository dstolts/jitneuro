#!/bin/bash
# JitNeuro Autonomous-Continuation Stop Hook (stop-continue-queue.sh)
# Event: Stop -- fires when the agent finishes a turn and is about to yield control.
#
# PURPOSE: make autonomous execution MECHANICAL instead of advisory. While
# "autonomous mode" is ON and executable tasks remain in the active Hub.md
# queue, this hook BLOCKS the stop (exit 2) and re-injects a "continue the
# queue" directive -- so the session keeps working a backlog unattended (AFK)
# instead of stopping after each task. A soft rule ("keep going") cannot enforce
# this; a hook fires in the harness and cannot be rationalized past by the model.
#
# SAFE BY DEFAULT: does NOTHING unless the autonomous-mode flag is set. Normal
# interactive sessions are completely unaffected.
#
# Stop-hook exit contract (Claude Code):
#   exit 0            -> allow the stop (normal yield)
#   exit 2 + stderr   -> BLOCK the stop; stderr is fed back to the model as the next directive
#   any other nonzero -> non-blocking error (also allows the stop)  => we FAIL-OPEN
#
# Enable :  echo on  > <project>/.claude/session-state/autonomous-mode.flag
#           (optionally scope to one session: echo "on:<session_id>" > ...flag)
#           -- or use the /afk slash command.
# Disable:  rm <project>/.claude/session-state/autonomous-mode.flag   (or: echo off > it)
#
# Queue source: the first existing of  <cwd>/.HUB/Hub.md , <cwd>/.hub/hub.md ,
# <project>/.HUB/Hub.md , <project>/.hub/hub.md  -- counts unchecked "- [ ]" lines,
# excluding ones marked blocked/hold/awaiting/needs owner/red-zone/owner-gated.
#
# Runaway guard: a stall counter that RESETS on progress (remaining count drops).
# After JITNEURO_MAX_CONTINUE (default 50) consecutive NO-PROGRESS turns it gives
# up and allows the stop. Claude Code's own consecutive-block cap is a secondary
# backstop; raise it via CLAUDE_CODE_STOP_HOOK_BLOCK_CAP for long unattended runs.

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

SESSION_ID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

PROJECT_DIR=$(norm "${CLAUDE_PROJECT_DIR:-$CWD}")
STATE_DIR="$PROJECT_DIR/.claude/session-state"
FLAG="$STATE_DIR/autonomous-mode.flag"
COUNTER="$STATE_DIR/.autonomous-stall-count"
LOG="/tmp/jitneuro-autonomous.log"
MAX_STALL="${JITNEURO_MAX_CONTINUE:-50}"

log(){ echo "[$(date 2>/dev/null)] $*" >> "$LOG" 2>/dev/null; }

# ---- safe-by-default: no active flag => allow stop ----
[ -f "$FLAG" ] || { rm -f "$COUNTER" 2>/dev/null; exit 0; }
FLAG_LINE=$(head -1 "$FLAG" 2>/dev/null | tr -d '\r' | tr -d '[:space:]')
case "$FLAG_LINE" in
  on|ON|on:*|ON:*) : ;;                              # active
  *) rm -f "$COUNTER" 2>/dev/null; exit 0 ;;          # off / blank / unknown => allow stop
esac

# optional session scoping: "on:<session_id>" applies only to that session
FLAG_SESSION="${FLAG_LINE#*:}"
if [ "$FLAG_SESSION" != "$FLAG_LINE" ] && [ -n "$FLAG_SESSION" ] && [ -n "$SESSION_ID" ] && [ "$FLAG_SESSION" != "$SESSION_ID" ]; then
  log "flag scoped to $FLAG_SESSION; current session $SESSION_ID -> allow stop"
  exit 0
fi

# ---- locate the queue (Hub.md ACTIVE TODO) ----
HUB=""
for cand in "$CWD/.HUB/Hub.md" "$CWD/.hub/hub.md" "$PROJECT_DIR/.HUB/Hub.md" "$PROJECT_DIR/.hub/hub.md"; do
  [ -f "$cand" ] && { HUB="$cand"; break; }
done
[ -n "$HUB" ] || { log "no Hub.md under $CWD / $PROJECT_DIR -> allow stop"; rm -f "$COUNTER" 2>/dev/null; exit 0; }

# count executable unchecked tasks: "- [ ]" / "* [ ]" lines, excluding blocked/hold/awaiting
REMAINING=$(grep -E '^[[:space:]]*[-*][[:space:]]*\[[[:space:]]\]' "$HUB" 2>/dev/null \
            | grep -ivE '(blocked|on hold|[^a-z]hold|awaiting|needs owner|red.?zone|waiting on|owner-gated)' \
            | grep -c . 2>/dev/null)
REMAINING=$(printf '%s' "$REMAINING" | tr -cd '0-9'); REMAINING=${REMAINING:-0}

# queue empty => work done => allow stop
if [ "$REMAINING" -le 0 ]; then
  log "queue empty in $HUB -> allow stop (done)"
  rm -f "$COUNTER" 2>/dev/null
  exit 0
fi

# ---- runaway guard: stall counter (resets on progress) ----
PREV_COUNT=0; PREV_REM=999999
if [ -f "$COUNTER" ]; then
  PREV_COUNT=$(sed -n '1p' "$COUNTER" 2>/dev/null | tr -cd '0-9')
  PREV_REM=$(sed -n '2p' "$COUNTER" 2>/dev/null | tr -cd '0-9')
  PREV_COUNT=${PREV_COUNT:-0}; PREV_REM=${PREV_REM:-999999}
fi
if [ "$REMAINING" -lt "$PREV_REM" ]; then
  COUNT=0                       # progress since last turn -> reset stall counter
else
  COUNT=$((PREV_COUNT + 1))     # no progress this turn
fi

if [ "$COUNT" -gt "$MAX_STALL" ]; then
  log "stall cap hit ($COUNT > $MAX_STALL) on $HUB -> allow stop"
  echo "AUTONOMOUS MODE: no queue progress for $MAX_STALL turns ($REMAINING task(s) still open in $HUB). Stopping to avoid a runaway loop. Review the stuck task, then re-arm with: echo on > $FLAG" >&2
  rm -f "$COUNTER" 2>/dev/null
  exit 0
fi

printf '%s\n%s\n' "$COUNT" "$REMAINING" > "$COUNTER" 2>/dev/null

# ---- block the stop; inject the continue directive ----
log "BLOCK: $REMAINING open in $HUB (stall $COUNT/$MAX_STALL) session=$SESSION_ID"
echo "AUTONOMOUS MODE ON -- do NOT stop. $REMAINING executable task(s) remain in the queue ($HUB '## ACTIVE TODO'). Pick the next unblocked task, mark it in_progress, do the work end-to-end, update Hub.md (check it off, or mark it blocked/awaiting-owner with the reason), then continue to the next task. If EVERY remaining task is genuinely blocked on the owner or a RED-zone approval, mark them so in Hub.md and run: rm $FLAG  (to release autonomous mode). (continuation; stall $COUNT/$MAX_STALL)" >&2
exit 2
