#!/bin/bash
# JitNeuro SessionEnd Auto-Save Hook
# Writes a minimal recovery breadcrumb when session terminates.
#
# This is NOT a full /save -- it's a safety net that captures the bare minimum
# so the next session knows what was happening if the user forgot to /save.
#
# The file is overwritten each time (it's a "last known state" marker, not a log).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$CLAUDE_DIR/jitneuro.json"
SESSION_DIR="$CLAUDE_DIR/session-state"
AUTOSAVE_FILE="$SESSION_DIR/_autosave.md"

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

cat > "$AUTOSAVE_FILE" <<EOF
# Autosave (Safety Net)
**Session ended:** $TIMESTAMP
**Reason:** ${REASON:-unknown}
**Duration:** $DURATION_STR
**Working directory:** ${CWD:-unknown}
**Session ID:** ${SESSION_ID:-unknown}

## Note
This is an auto-generated breadcrumb from the SessionEnd hook.
It is NOT a full /save checkpoint -- it only records that a session ended.

If the user forgot to /save before exiting, this file confirms a session
was active. Use /load with a named session for full state recovery.

Check for recent named sessions in this directory for proper checkpoints.
EOF

exit 0
