#!/bin/bash
# JitNeuro SessionStart — Write Session ID
# Fires on every SessionStart (new session, resume, after compact, after /clear).
# Writes this conversation's session_id to .session-id so commands can resolve
# "my current" per-session ( .current.d/<id> ) instead of one global .current.
#
# No stdout; exit 0. Does not block.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_DIR="$CLAUDE_DIR/session-state"
SESSION_ID_FILE="$SESSION_DIR/.session-id"
CURRENT_D_DIR="$SESSION_DIR/.current.d"

# Read hook input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')

# Create session-state and .current.d if needed
mkdir -p "$SESSION_DIR"
mkdir -p "$CURRENT_D_DIR"

if [ -n "$SESSION_ID" ]; then
  printf '%s' "$SESSION_ID" > "$SESSION_ID_FILE"
fi

exit 0
