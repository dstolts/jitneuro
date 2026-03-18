#!/bin/bash
# JitNeuro SessionStart Post-Clear Hook
# Fires after /clear or new session. Shows all sessions with numbered list so user can
# pick one to reload. Most recent session is the default.
#
# stdout goes into Claude's context window as injected context.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_DIR="$CLAUDE_DIR/session-state"
CURRENT_FILE="$SESSION_DIR/.current"

# Consume stdin with timeout (prevents pipe hangs)
if command -v timeout >/dev/null 2>&1; then
  timeout 2 cat >/dev/null 2>&1 || true
else
  while IFS= read -r -t 2 line; do :; done
fi

# Read last active session name (will be default)
LAST_SESSION=""
if [ -f "$CURRENT_FILE" ]; then
  LAST_SESSION=$(cat "$CURRENT_FILE" 2>/dev/null | tr -d '[:space:]')
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
for f in $(ls -t "$SESSION_DIR"/*.md 2>/dev/null); do
  bn=$(basename "$f" .md)
  [ "$bn" = "_autosave" ] && continue
  [ "$bn" = "README" ] && continue
  NUM=$((NUM + 1))

  # Extract checkpoint date and task
  CHECKPOINT=$(head -5 "$f" 2>/dev/null | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' | head -1)
  TASK=$(sed -n '/^## Current Task/{n;/^$/d;p;q;}' "$f" 2>/dev/null | head -c 60)

  # Mark default
  MARKER=" "
  DEFAULT_TAG=""
  if [ "$bn" = "$LAST_SESSION" ]; then
    MARKER="*"
    DEFAULT_TAG=" (default)"
  fi

  SESSION_LIST="${SESSION_LIST}
  ${MARKER}${NUM}. ${bn}  [${CHECKPOINT:-unknown}]  ${TASK}${DEFAULT_TAG}"
done

cat <<EOF
[JitNeuro] Context was cleared.

Available sessions ($SESSION_COUNT):
$SESSION_LIST

Present this list to the user and ask:
"Pick a session number to reload, or say 'fresh' to start new. Default is the starred (*) session."

When the user responds:
- A number (e.g., "2") -> extract the session name from the list above and run: /load <session-name>
- "yes", "ok", "default", "load", or the default session name -> run: /load ${LAST_SESSION:-<first session>}
- "fresh" or "new" or "start fresh" or "no" -> proceed normally, no session loaded
- A session name directly -> run: /load <name>
EOF

exit 0
