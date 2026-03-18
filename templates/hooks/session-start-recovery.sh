#!/bin/bash
# JitNeuro SessionStart Recovery Hook
# Fires after compaction to re-inject critical context into Claude's window.
#
# Reads the most recent session state file and outputs it as context.
# stdout from this hook goes directly into Claude's context window.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
SESSION_DIR="$(dirname "$SCRIPT_DIR")/session-state"
LOG="/tmp/jitneuro-session-recovery.log"

# Consume stdin (required even if unused, prevents pipe errors)
if command -v timeout >/dev/null 2>&1; then
  timeout 2 cat >/dev/null 2>&1 || true
else
  while IFS= read -r -t 2 line; do :; done
fi

# Find the most recently modified session state file
if [ ! -d "$SESSION_DIR" ]; then
  echo "[$(date 2>/dev/null)] Recovery: no session-state dir" >> "$LOG" 2>/dev/null
  exit 0
fi

LATEST=$(ls -t "$SESSION_DIR"/*.md 2>/dev/null | grep -v '_autosave.md' | head -1)
if [ -z "$LATEST" ]; then
  echo "[$(date 2>/dev/null)] Recovery: no session files found" >> "$LOG" 2>/dev/null
  exit 0
fi

SESSION_NAME=$(basename "$LATEST" .md)
echo "[$(date 2>/dev/null)] Recovery: restoring $SESSION_NAME from $LATEST" >> "$LOG" 2>/dev/null

CONTENT=$(cat "$LATEST" 2>/dev/null || echo "(could not read session file)")

cat <<EOF
[JitNeuro] Context was compacted. Restoring session context from last checkpoint.

Session: $SESSION_NAME
Source: $LATEST

--- BEGIN SESSION STATE ---
$CONTENT
--- END SESSION STATE ---

IMPORTANT: Context was just compacted. The session state above is your last checkpoint.
Review it to understand what you were working on. If it seems stale, ask the user
if they want to continue from this state or start fresh.
EOF

exit 0
