#!/bin/bash
# JitNeuro SessionStart Recovery Hook
# Fires after compaction to re-inject critical context into Claude's window.
#
# Reads the most recent session state file and outputs it as context.
# stdout from this hook goes directly into Claude's context window.

SESSION_DIR="D:/Code/.claude/session-state"

# Find the most recently modified session state file
if [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

LATEST=$(ls -t "$SESSION_DIR"/*.md 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
  exit 0
fi

SESSION_NAME=$(basename "$LATEST" .md)
CHECKPOINT_DATE=$(stat -c %Y "$LATEST" 2>/dev/null || stat -f %m "$LATEST" 2>/dev/null)

cat <<EOF
[JitNeuro] Context was compacted. Restoring session context from last checkpoint.

Session: $SESSION_NAME
Source: $LATEST

--- BEGIN SESSION STATE ---
$(cat "$LATEST")
--- END SESSION STATE ---

IMPORTANT: Context was just compacted. The session state above is your last checkpoint.
Review it to understand what you were working on. If it seems stale, ask the user
if they want to continue from this state or start fresh.
EOF

exit 0
