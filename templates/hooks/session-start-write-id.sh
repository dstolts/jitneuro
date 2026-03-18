#!/bin/bash
# JitNeuro SessionStart -- Write Session ID
# Fires on every SessionStart (new session, resume, after compact, after /clear).
# Writes this conversation's session_id to .session-id so commands can resolve
# "my current" per-session ( .current.d/<id> ) instead of one global .current.
#
# No stdout; exit 0. Does not block.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_DIR="$CLAUDE_DIR/session-state"
SESSION_ID_FILE="$SESSION_DIR/.session-id"
CURRENT_D_DIR="$SESSION_DIR/.current.d"
LOG="/tmp/jitneuro-session-start.log"

# Read hook input with timeout (prevents hanging if stdin pipe stays open)
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  # Fallback: read line by line with bash timeout
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

SESSION_ID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')

echo "[$(date 2>/dev/null)] SessionStart write-id fired. ID=$SESSION_ID" >> "$LOG" 2>/dev/null

# Create session-state and .current.d if needed
mkdir -p "$SESSION_DIR" 2>/dev/null
mkdir -p "$CURRENT_D_DIR" 2>/dev/null

if [ -n "$SESSION_ID" ]; then
  printf '%s' "$SESSION_ID" > "$SESSION_ID_FILE" 2>/dev/null
fi

exit 0
