#!/bin/bash
# JitNeuro SessionEnd Auto-Save Hook
# Safety net for forgotten /save. Detects whether a /save happened during
# the session and writes a useful breadcrumb if not.
#
# The file is overwritten each time (it's a "last known state" marker, not a log).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$CLAUDE_DIR/jitneuro.json"
SESSION_DIR="$CLAUDE_DIR/session-state"
AUTOSAVE_FILE="$SESSION_DIR/_autosave.md"
CURRENT_FILE="$SESSION_DIR/.current"

# Check if autosave is disabled in config
if [ -f "$CONFIG" ]; then
  AUTOSAVE=$(grep -o '"autosave"[[:space:]]*:[[:space:]]*[a-z]*' "$CONFIG" | head -1 | grep -o '[a-z]*$')
  if [ "$AUTOSAVE" = "false" ]; then
    exit 0
  fi
fi

# Read hook input
INPUT=$(cat)
REASON=$(echo "$INPUT" | grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
DURATION=$(echo "$INPUT" | grep -o '"session_duration_seconds"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
CWD=$(echo "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

# Calculate duration in human-readable format
if [ -n "$DURATION" ] && [ "$DURATION" -gt 0 ] 2>/dev/null; then
  HOURS=$((DURATION / 3600))
  MINUTES=$(((DURATION % 3600) / 60))
  if [ "$HOURS" -gt 0 ]; then
    DURATION_STR="${HOURS}h ${MINUTES}m"
  else
    DURATION_STR="${MINUTES}m"
  fi
else
  DURATION_STR="unknown"
fi

# Create session-state dir if needed
mkdir -p "$SESSION_DIR"

# Get current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")

# Detect active session name from .current
CURRENT_SESSION=""
if [ -f "$CURRENT_FILE" ]; then
  CURRENT_SESSION=$(cat "$CURRENT_FILE" | tr -d '[:space:]')
fi

# Check if the active session file was updated during this session
# (i.e., did a /save happen recently?)
SAVE_DETECTED="no"
LAST_SAVE_AGE=""
SESSION_TASK=""
SESSION_REPOS=""
if [ -n "$CURRENT_SESSION" ] && [ -f "$SESSION_DIR/$CURRENT_SESSION.md" ]; then
  # Get session file modification time vs now (seconds)
  if command -v stat >/dev/null 2>&1; then
    FILE_MOD=$(stat -c %Y "$SESSION_DIR/$CURRENT_SESSION.md" 2>/dev/null || stat -f %m "$SESSION_DIR/$CURRENT_SESSION.md" 2>/dev/null)
    NOW=$(date +%s 2>/dev/null)
    if [ -n "$FILE_MOD" ] && [ -n "$NOW" ] && [ -n "$DURATION" ]; then
      AGE=$((NOW - FILE_MOD))
      # If session file was modified within the session duration, a /save happened
      if [ "$AGE" -le "$DURATION" ] 2>/dev/null; then
        SAVE_DETECTED="yes"
      fi
      # Human-readable age
      AGE_MIN=$((AGE / 60))
      if [ "$AGE_MIN" -lt 60 ]; then
        LAST_SAVE_AGE="${AGE_MIN}m ago"
      else
        AGE_HR=$((AGE_MIN / 60))
        LAST_SAVE_AGE="${AGE_HR}h ago"
      fi
    fi
  fi
  # Extract task and repos from session file (first 15 lines)
  SESSION_TASK=$(head -15 "$SESSION_DIR/$CURRENT_SESSION.md" 2>/dev/null | grep -A1 "^## Current Task" | tail -1 | sed 's/^[[:space:]]*//')
  SESSION_REPOS=$(head -15 "$SESSION_DIR/$CURRENT_SESSION.md" 2>/dev/null | grep -A5 "^## Repos Involved" | grep "^-" | sed 's/^- //' | sed 's/ --.*//' | tr '\n' ', ' | sed 's/,$//')
fi

# If save was detected during this session, write minimal breadcrumb
if [ "$SAVE_DETECTED" = "yes" ]; then
  cat > "$AUTOSAVE_FILE" <<EOF
# Autosave (Safety Net)
**Session ended:** $TIMESTAMP
**Duration:** $DURATION_STR
**Save detected:** yes (session: $CURRENT_SESSION)
**Status:** No action needed -- /save was called during this session.
EOF
  exit 0
fi

# No save detected -- write a useful warning breadcrumb
cat > "$AUTOSAVE_FILE" <<EOF
# Autosave (Safety Net) -- NO SAVE DETECTED
**Session ended:** $TIMESTAMP
**Reason:** ${REASON:-unknown}
**Duration:** $DURATION_STR
**Working directory:** ${CWD:-unknown}
**Session ID:** ${SESSION_ID:-unknown}

## WARNING: No /save detected this session
The user may have forgotten to save before exiting.

**Last active session:** ${CURRENT_SESSION:-none}
**Last save age:** ${LAST_SAVE_AGE:-unknown}
**Last known task:** ${SESSION_TASK:-unknown}
**Last known repos:** ${SESSION_REPOS:-unknown}

## Recovery
Run \`/load ${CURRENT_SESSION:-<name>}\` to restore the last checkpoint.
That checkpoint may be stale -- review and update it with current work.
EOF

exit 0
