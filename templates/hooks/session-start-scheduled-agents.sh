#!/bin/bash
# JitNeuro SessionStart Hook: Scheduled Agents Launcher
# Reads scheduledAgents config from both personal (.claude/jitneuro.json)
# and team (.jitneuro/jitneuro.json) configs. Merges results.
# Personal overrides team (same name = personal wins).
#
# stdout goes into Claude's context window as injected context.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
PERSONAL_CONFIG="$CLAUDE_DIR/jitneuro.json"

# Find repo root for team config
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
TEAM_CONFIG=""
if [ -n "$REPO_ROOT" ] && [ -f "$REPO_ROOT/.jitneuro/jitneuro.json" ]; then
  TEAM_CONFIG="$REPO_ROOT/.jitneuro/jitneuro.json"
fi

# Exit silently if no config at either level
[ ! -f "$PERSONAL_CONFIG" ] && [ -z "$TEAM_CONFIG" ] && exit 0

# Function to extract agents from a config file
# Appends to AGENTS string and increments AGENT_COUNT
# Args: $1 = config file path, $2 = source label ("personal" or "team")
parse_config() {
  local CONFIG="$1"
  local SOURCE="$2"

  [ ! -f "$CONFIG" ] && return
  grep -q '"scheduledAgents"' "$CONFIG" 2>/dev/null || return

  local IN_AGENTS=false
  local CURRENT_NAME=""
  local CURRENT_INTERVAL=""
  local CURRENT_INSTRUCTION=""
  local CURRENT_PROMPT=""
  local CURRENT_ENABLED=""

  flush_agent() {
    if [ -n "$CURRENT_NAME" ] && [ "$CURRENT_ENABLED" = "true" ]; then
      # Check if personal override exists (personal wins over team)
      if [ "$SOURCE" = "team" ] && echo "$PERSONAL_NAMES" | grep -qw "$CURRENT_NAME"; then
        return
      fi
      AGENT_COUNT=$((AGENT_COUNT + 1))
      AGENTS="${AGENTS}
  - name: ${CURRENT_NAME} (${SOURCE}), interval: ${CURRENT_INTERVAL}m, instruction: ${CURRENT_INSTRUCTION}"
      if [ -n "$CURRENT_PROMPT" ]; then
        AGENTS="${AGENTS}, prompt: ${CURRENT_PROMPT}"
      fi
    fi
  }

  while IFS= read -r line; do
    if echo "$line" | grep -q '"scheduledAgents"'; then
      IN_AGENTS=true
      continue
    fi

    if $IN_AGENTS && echo "$line" | grep -qE '^\s*\]'; then
      flush_agent
      IN_AGENTS=false
      continue
    fi

    ! $IN_AGENTS && continue

    if echo "$line" | grep -q '{'; then
      flush_agent
      CURRENT_NAME=""
      CURRENT_INTERVAL=""
      CURRENT_INSTRUCTION=""
      CURRENT_PROMPT=""
      CURRENT_ENABLED=""
      continue
    fi

    val=$(echo "$line" | sed 's/.*: *"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/')
    if echo "$line" | grep -q '"name"'; then
      CURRENT_NAME="$val"
    elif echo "$line" | grep -q '"interval"'; then
      CURRENT_INTERVAL="$val"
    elif echo "$line" | grep -q '"instruction"'; then
      CURRENT_INSTRUCTION="$val"
    elif echo "$line" | grep -q '"enabled"'; then
      CURRENT_ENABLED="$val"
    elif echo "$line" | grep -q '"prompt"'; then
      CURRENT_PROMPT="$val"
    fi
  done < "$CONFIG"
}

AGENTS=""
AGENT_COUNT=0

# Collect personal agent names first (for override detection)
PERSONAL_NAMES=""
if [ -f "$PERSONAL_CONFIG" ]; then
  PERSONAL_NAMES=$(grep '"name"' "$PERSONAL_CONFIG" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# Parse team config first, then personal (personal overrides team by name)
parse_config "$TEAM_CONFIG" "team"
parse_config "$PERSONAL_CONFIG" "personal"

# Nothing to launch
if [ "$AGENT_COUNT" -eq 0 ]; then
  exit 0
fi

SOURCES=""
[ -f "$PERSONAL_CONFIG" ] && SOURCES="personal"
[ -n "$TEAM_CONFIG" ] && SOURCES="${SOURCES:+$SOURCES + }team"

cat <<EOF
[JitNeuro] Scheduled agents configured (${AGENT_COUNT} enabled, sources: ${SOURCES}):
${AGENTS}

Launch these now using /schedule start <name> for each, or run /schedule to see all.
To auto-launch all enabled agents, run: /schedule start-all
EOF

exit 0
