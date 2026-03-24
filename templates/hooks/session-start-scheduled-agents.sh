#!/bin/bash
# JitNeuro SessionStart Hook: Scheduled Agents Launcher
# Reads scheduledAgents config from jitneuro.json and injects launch instructions
# into Claude's context. Claude (master) then spawns the timer agents.
#
# stdout goes into Claude's context window as injected context.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$CLAUDE_DIR/jitneuro.json"

# Exit silently if no config
[ ! -f "$CONFIG" ] && exit 0

# Check if scheduledAgents key exists
if ! grep -q '"scheduledAgents"' "$CONFIG" 2>/dev/null; then
  exit 0
fi

# Extract enabled agents using basic text parsing (no jq dependency)
# Look for entries where "enabled": true
AGENTS=""
IN_AGENTS=false
CURRENT_NAME=""
CURRENT_INTERVAL=""
CURRENT_INSTRUCTION=""
CURRENT_PROMPT=""
CURRENT_ENABLED=""
CURRENT_DESC=""
AGENT_COUNT=0

while IFS= read -r line; do
  # Detect scheduledAgents array
  if echo "$line" | grep -q '"scheduledAgents"'; then
    IN_AGENTS=true
    continue
  fi

  # Exit array on closing bracket at same indent level
  if $IN_AGENTS && echo "$line" | grep -qE '^\s*\]'; then
    # Flush last agent
    if [ -n "$CURRENT_NAME" ] && [ "$CURRENT_ENABLED" = "true" ]; then
      AGENT_COUNT=$((AGENT_COUNT + 1))
      AGENTS="${AGENTS}
  - name: ${CURRENT_NAME}, interval: ${CURRENT_INTERVAL}m, instruction: ${CURRENT_INSTRUCTION}"
      if [ -n "$CURRENT_PROMPT" ]; then
        AGENTS="${AGENTS}, prompt: ${CURRENT_PROMPT}"
      fi
    fi
    IN_AGENTS=false
    continue
  fi

  if ! $IN_AGENTS; then
    continue
  fi

  # New agent object
  if echo "$line" | grep -q '{'; then
    # Flush previous agent
    if [ -n "$CURRENT_NAME" ] && [ "$CURRENT_ENABLED" = "true" ]; then
      AGENT_COUNT=$((AGENT_COUNT + 1))
      AGENTS="${AGENTS}
  - name: ${CURRENT_NAME}, interval: ${CURRENT_INTERVAL}m, instruction: ${CURRENT_INSTRUCTION}"
      if [ -n "$CURRENT_PROMPT" ]; then
        AGENTS="${AGENTS}, prompt: ${CURRENT_PROMPT}"
      fi
    fi
    CURRENT_NAME=""
    CURRENT_INTERVAL=""
    CURRENT_INSTRUCTION=""
    CURRENT_PROMPT=""
    CURRENT_ENABLED=""
    CURRENT_DESC=""
    continue
  fi

  # Parse fields
  val=$(echo "$line" | sed 's/.*: *"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/')
  if echo "$line" | grep -q '"name"'; then
    CURRENT_NAME="$val"
  elif echo "$line" | grep -q '"interval"'; then
    CURRENT_INTERVAL="$val"
  elif echo "$line" | grep -q '"instruction"'; then
    CURRENT_INSTRUCTION="$val"
  elif echo "$line" | grep -q '"enabled"'; then
    CURRENT_ENABLED="$val"
  elif echo "$line" | grep -q '"description"'; then
    CURRENT_DESC="$val"
  elif echo "$line" | grep -q '"prompt"'; then
    CURRENT_PROMPT="$val"
  fi

done < "$CONFIG"

# Nothing to launch
if [ "$AGENT_COUNT" -eq 0 ]; then
  exit 0
fi

cat <<EOF
[JitNeuro] Scheduled agents configured (${AGENT_COUNT} enabled):
${AGENTS}

Launch these now using /schedule start <name> for each, or run /schedule to see all.
To auto-launch all enabled agents, run: /schedule start-all
EOF

exit 0
