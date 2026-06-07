#!/bin/bash
# JitNeuro PreCompact Hook
# Fires before context compaction.
#
# A PreCompact hook MUST NOT block auto-compaction. When Claude Code
# auto-triggers compaction the context window is full and compaction MUST
# proceed -- returning exit 2 there wedges the session permanently. Therefore:
#   - source=auto   -> always warn-only (exit 0); compaction proceeds
#   - source=manual -> may pause (exit 2) only when preCompactBehavior=block
#
# Config: .claude/jitneuro.json (hooks.preCompactBehavior): "warn" | "block"
#   Default is "warn" -- a non-destructive operation must never wedge a session
#   by default. /save can run at any time, including after compaction.
#
# A fresh save (within FRESH_THRESHOLD_SECONDS) suppresses the message entirely.

set +e  # never abort on errors

HOOKS_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CONFIG="$(dirname "$HOOKS_DIR")/jitneuro.json"
SESSION_DIR="$(dirname "$HOOKS_DIR")/session-state"
SAVE_MARKER="$SESSION_DIR/.last-save-timestamp"
LOG="/tmp/jitneuro-precompact.log"

# If the last save is within this many seconds, allow compaction silently.
FRESH_THRESHOLD_SECONDS=600  # 10 minutes

# Read config (default to warn -- never wedge a session by default)
BEHAVIOR="warn"
if [ -f "$CONFIG" ]; then
  BEHAVIOR=$(grep -o '"preCompactBehavior"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  [ -z "$BEHAVIOR" ] && BEHAVIOR="warn"
fi

# Read hook input from stdin with timeout
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

echo "[$(date 2>/dev/null)] PreCompact hook fired. Behavior=$BEHAVIOR" >> "$LOG" 2>/dev/null
echo "[$(date 2>/dev/null)] Input: $INPUT" >> "$LOG" 2>/dev/null

SOURCE=$(echo "$INPUT" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"')

# Fresh-save check: if a /save happened recently, allow compaction silently.
if [ -f "$SAVE_MARKER" ]; then
  SAVED_AT=$(cat "$SAVE_MARKER" 2>/dev/null | tr -d '[:space:]')
  NOW=$(date +%s 2>/dev/null)
  if [ -n "$SAVED_AT" ] && [ -n "$NOW" ] && [ "$SAVED_AT" -gt 0 ] 2>/dev/null; then
    AGE=$((NOW - SAVED_AT))
    if [ "$AGE" -le "$FRESH_THRESHOLD_SECONDS" ] 2>/dev/null; then
      echo "[$(date 2>/dev/null)] PreCompact: save is fresh (${AGE}s ago). Allowing compaction silently." >> "$LOG" 2>/dev/null
      echo "[JitNeuro] POST-COMPACT: in your next turn, run /load first to restore session state and re-read context before continuing work."
      exit 0
    fi
  fi
fi

MSG="[JitNeuro] Context compaction triggered (source: ${SOURCE:-auto}). Run /save to checkpoint your session before context is compressed."

# CRITICAL: never block auto-compaction -- exit 2 there wedges the session.
# Only an explicit manual /compact may be paused, and only when configured.
if [ "$BEHAVIOR" = "block" ] && [ "$SOURCE" = "manual" ]; then
  # Make the pause stand out. Claude Code renders this stderr inline with its
  # own "Compaction blocked by PreCompact hook" wrapper, so a leading blank line
  # plus a banner separates the action message from the surrounding output.
  echo "" >&2
  echo "================================================================" >&2
  echo "  ACTION NEEDED -- MANUAL COMPACTION PAUSED" >&2
  echo "================================================================" >&2
  echo "$MSG" >&2
  echo "" >&2
  echo "  Run /save to checkpoint this session, then re-run /compact." >&2
  echo "================================================================" >&2
  echo "" >&2
  exit 2
fi

# Warn (default, and always for auto-compaction): compaction proceeds.
echo "$MSG"
echo "Compaction is proceeding. Run /save afterward if the session was not recently checkpointed."
echo "[JitNeuro] POST-COMPACT: in your next turn, run /load first to restore session state and re-read context before continuing work."
exit 0
