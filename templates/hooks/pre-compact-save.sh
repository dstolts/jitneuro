#!/bin/bash
# JitNeuro PreCompact Hook
# Fires before context compaction -- prompts Claude to offer /save
#
# Config: .claude/hooks/jitneuro-hooks.json
# Behavior options: "warn" (default) or "block"
#   warn  = message to Claude, compaction proceeds
#   block = exit 2, compaction blocked until user responds

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOOKS_DIR/jitneuro-hooks.json"

# Read config (default to warn if no config)
BEHAVIOR="warn"
if [ -f "$CONFIG" ]; then
  BEHAVIOR=$(cat "$CONFIG" | grep -o '"preCompactBehavior"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
  [ -z "$BEHAVIOR" ] && BEHAVIOR="warn"
fi

# Read hook input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

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
