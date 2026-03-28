#!/bin/bash
# JitNeuro SessionStart -- Write Session ID + Context Injection
# Fires on every SessionStart (new session, resume, after compact, after /clear).
# Creates heartbeats/<session-id> with session name (or "none" for new sessions).
# Echoes session-id to stdout so it gets injected into Claude's context window.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_DIR="$CLAUDE_DIR/session-state"
HEARTBEATS_DIR="$SESSION_DIR/heartbeats"
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

# Create session-state and heartbeats dir if needed
mkdir -p "$HEARTBEATS_DIR" 2>/dev/null

if [ -n "$SESSION_ID" ]; then
  # Resume/compact: preserve existing session name. New: set to "none".
  if [ -f "$HEARTBEATS_DIR/$SESSION_ID" ]; then
    SESSION_NAME=$(cat "$HEARTBEATS_DIR/$SESSION_ID" 2>/dev/null)
  else
    SESSION_NAME="none"
  fi
  printf '%s' "$SESSION_NAME" > "$HEARTBEATS_DIR/$SESSION_ID" 2>/dev/null

  echo "[JitNeuro] session-id: $SESSION_ID"

  # Export session ID as env var for downstream hooks (heartbeat, etc.)
  # CLAUDE_ENV_FILE is only available to SessionStart hooks
  if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo "export CLAUDE_SESSION_ID=$SESSION_ID" >> "$CLAUDE_ENV_FILE" 2>/dev/null
  fi
fi

exit 0
