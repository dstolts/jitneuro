#!/bin/bash
# JitNeuro SessionStart Post-Clear Hook
# Fires after /clear or new session. Shows all sessions with numbered list so user can
# pick one to reload. Most recent checkpoint is the default.
#
# stdout goes into Claude's context window as injected context.
# Uses heartbeats/ directory for active session detection (not .current).

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_DIR="$CLAUDE_DIR/session-state"
HEARTBEAT_DIR="$SESSION_DIR/heartbeats"

# Parse session_id from stdin JSON
SESSION_ID=""
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null) || true
else
  while IFS= read -r -t 2 chunk; do INPUT="${INPUT}${chunk}"; done
fi
if [ -n "$INPUT" ]; then
  SESSION_ID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
fi

# Determine last active session:
# 1. Check own heartbeat (resume/compact case)
# 2. Fall back to most recently modified .md file
LAST_SESSION=""
if [ -n "$SESSION_ID" ] && [ -f "$HEARTBEAT_DIR/$SESSION_ID" ]; then
  LAST_SESSION=$(cat "$HEARTBEAT_DIR/$SESSION_ID" 2>/dev/null | tr -d '[:space:]')
  [ "$LAST_SESSION" = "none" ] && LAST_SESSION=""
fi

# Count available sessions (exclude _autosave, README, dotfiles)
SESSION_COUNT=0
for f in "$SESSION_DIR"/*.md; do
  [ ! -f "$f" ] && continue
  bn=$(basename "$f" .md)
  [ "$bn" = "_autosave" ] && continue
  [ "$bn" = "README" ] && continue
  SESSION_COUNT=$((SESSION_COUNT + 1))
done

# If no sessions exist, nothing to offer
if [ "$SESSION_COUNT" -eq 0 ]; then
  exit 0
fi

# Build numbered session list (sorted by modification time, newest first)
SESSION_LIST=""
NUM=0
FIRST_SESSION=""
for f in $(ls -t "$SESSION_DIR"/*.md 2>/dev/null); do
  bn=$(basename "$f" .md)
  [ "$bn" = "_autosave" ] && continue
  [ "$bn" = "README" ] && continue
  NUM=$((NUM + 1))

  # Track first (most recent) session for fallback default
  if [ -z "$FIRST_SESSION" ]; then
    FIRST_SESSION="$bn"
  fi

  # Extract checkpoint date and task
  CHECKPOINT=$(head -5 "$f" 2>/dev/null | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' | head -1)
  TASK=$(sed -n '/^## Current Task/{n;/^$/d;p;q;}' "$f" 2>/dev/null | head -c 60)

  # Mark default (heartbeat match or first in list)
  MARKER=" "
  DEFAULT_TAG=""
  if [ -n "$LAST_SESSION" ] && [ "$bn" = "$LAST_SESSION" ]; then
    MARKER="*"
    DEFAULT_TAG=" (default)"
  elif [ -z "$LAST_SESSION" ] && [ "$bn" = "$FIRST_SESSION" ]; then
    MARKER="*"
    DEFAULT_TAG=" (default)"
  fi

  SESSION_LIST="${SESSION_LIST}
   ${MARKER}${NUM}. ${bn}  [${CHECKPOINT:-unknown}]  ${TASK}${DEFAULT_TAG}"
done

# Use heartbeat session or first session as default for prompt
DEFAULT="${LAST_SESSION:-$FIRST_SESSION}"

RELOAD_LINE=""
if [ -n "$LAST_SESSION" ]; then
  RELOAD_LINE="
You were working on session: ${LAST_SESSION}
To reload it: /load ${LAST_SESSION}
"
fi

cat <<EOF
[JitNeuro] Context was cleared.
${RELOAD_LINE}
Available sessions ($SESSION_COUNT):
$SESSION_LIST

Present this list to the user and ask:
"Pick a session number to reload, or say 'fresh' to start new. Default is the starred (*) session."

When the user responds:
- A number (e.g., "2") -> extract the session name from the list above and run: /load <session-name>
- "yes", "ok", "default", "load", or the default session name -> run: /load ${DEFAULT}
- "fresh" or "new" or "start fresh" or "no" -> proceed normally, no session loaded
- A session name directly -> run: /load <name>
EOF

exit 0
