#!/bin/bash
# JitNeuro PreCompact Hook
# Fires before context compaction -- prompts Claude to offer /save
#
# Config: .claude/jitneuro.json (hooks.preCompactBehavior)
# Behavior options: "warn" or "block" (default)
#   warn  = message to Claude, compaction proceeds
#   block = exit 2, compaction blocked until user responds

set +e  # never abort on errors

HOOKS_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CONFIG="$(dirname "$HOOKS_DIR")/jitneuro.json"
LOG="/tmp/jitneuro-precompact.log"

# Read config (default to block if no config -- fail secure)
BEHAVIOR="block"
if [ -f "$CONFIG" ]; then
  BEHAVIOR=$(grep -o '"preCompactBehavior"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  [ -z "$BEHAVIOR" ] && BEHAVIOR="block"
fi

# Read hook input from stdin with timeout
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

echo "[$(date 2>/dev/null)] PreCompact hook fired. Behavior=$BEHAVIOR" >> "$LOG" 2>/dev/null
echo "[$(date 2>/dev/null)] Input: $INPUT" >> "$LOG" 2>/dev/null

SOURCE=$(echo "$INPUT" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"')

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
