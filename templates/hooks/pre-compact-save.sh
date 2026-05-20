#!/bin/bash
# JitNeuro PreCompact Hook
# Fires before context compaction -- prompts Claude to offer /save
#
# Config: .claude/jitneuro.json (hooks.preCompactBehavior)
# Behavior options: "warn" or "block" (default)
#   warn  = message to Claude, compaction proceeds
#   block = exit 2, compaction blocked until user responds
#
# BUG FIX (WS5): stateless block on every compaction is harmful -- it prevents
# compaction even when a recent /save already checkpointed the session.
# Fix: /save (and /session save) writes a save-timestamp marker file.
# This hook reads the marker and exits 0 (allows compaction silently)
# when the last save is fresh (within FRESH_THRESHOLD_SECONDS).
# Otherwise behaves as configured (block or warn).

set +e  # never abort on errors

HOOKS_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CONFIG="$(dirname "$HOOKS_DIR")/jitneuro.json"
SESSION_DIR="$(dirname "$HOOKS_DIR")/session-state"
SAVE_MARKER="$SESSION_DIR/.last-save-timestamp"
LOG="/tmp/jitneuro-precompact.log"

# Threshold: if last save is within this many seconds, allow compaction silently
FRESH_THRESHOLD_SECONDS=600  # 10 minutes

# Read config (default to block if no config -- fail secure)
BEHAVIOR="block"
if [ -f "$CONFIG" ]; then
  BEHAVIOR=$(grep -o '"preCompactBehavior"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  [ -z "$BEHAVIOR" ] && BEHAVIOR="block"
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

# WS5 FIX: check save-timestamp marker for freshness
if [ -f "$SAVE_MARKER" ]; then
  SAVED_AT=$(cat "$SAVE_MARKER" 2>/dev/null | tr -d '[:space:]')
  NOW=$(date +%s 2>/dev/null)
  if [ -n "$SAVED_AT" ] && [ -n "$NOW" ] && [ "$SAVED_AT" -gt 0 ] 2>/dev/null; then
    AGE=$((NOW - SAVED_AT))
    if [ "$AGE" -le "$FRESH_THRESHOLD_SECONDS" ] 2>/dev/null; then
      echo "[$(date 2>/dev/null)] PreCompact: save is fresh (${AGE}s ago, threshold ${FRESH_THRESHOLD_SECONDS}s). Allowing compaction." >> "$LOG" 2>/dev/null
      exit 0  # allow compaction silently -- save already happened
    fi
    echo "[$(date 2>/dev/null)] PreCompact: save is stale (${AGE}s ago). Applying behavior=$BEHAVIOR." >> "$LOG" 2>/dev/null
  fi
fi

# Build the message
MSG="[JitNeuro] Context compaction triggered (source: ${SOURCE:-auto}). Run /save to checkpoint your session before context is compressed."

if [ "$BEHAVIOR" = "block" ]; then
  echo "$MSG" >&2
  echo "Compaction blocked by JitNeuro hook. Ask the user: save session with /save, then compact?" >&2
  exit 2
else
  # Warn mode: output goes to Claude as injected context
  echo "$MSG"
  echo "IMPORTANT: Before proceeding, ask the user if they want to run /save to checkpoint the current session state. If they say yes, run /save first, then allow compaction to proceed."
  exit 0
fi
