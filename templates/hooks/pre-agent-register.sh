#!/usr/bin/env bash
# JitNeuro Pre-Agent Register -- PreToolUse hook (matcher: "Agent")
# Directly registers agent as "running" in the dashboard runs directory.
# Also writes agent file path to .agent-tracker/<session-id>-<stamp> so
# PostToolUse(Agent) can find and mark it completed.
# ~20ms: stdin read + grep + mkdir + echo > file

set +e
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
fi

SID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
[ -z "$SID" ] && exit 0

DESC=$(echo "$INPUT" | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
[ -z "$DESC" ] && DESC="agent"

# Parent session name from heartbeat
HB_DIR="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/session-state/heartbeats"
PSESS="none"
[ -f "$HB_DIR/$SID" ] && PSESS=$(cat "$HB_DIR/$SID" 2>/dev/null | tr -d '\n\r')
[ -z "$PSESS" ] && PSESS="none"

# Find or create run directory for this session
DASH_DIR="${JITDASH_DIR:-${CLAUDE_PROJECT_DIR:-$HOME}/.claude/dashboard}"
RUNS="$DASH_DIR/runs"
RUN_DIR=""
if [ -d "$RUNS" ]; then
  for d in "$RUNS"/*/; do
    [ -d "$d" ] || continue
    case "$(basename "$d")" in .archive) continue ;; esac
    [ -f "${d}meta.json" ] || continue
    ms=$(grep -o '"session"[[:space:]]*:[[:space:]]*"[^"]*"' "${d}meta.json" 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"')
    archived=$(grep -o '"archivedAt"' "${d}meta.json" 2>/dev/null)
    if [ "$ms" = "$PSESS" ] && [ -z "$archived" ]; then
      RUN_DIR="$d"
      break
    fi
  done
fi
if [ -z "$RUN_DIR" ]; then
  NOW=$(date -u +"%Y%m%d-%H%M%S" 2>/dev/null || date +"%Y%m%d-%H%M%S")
  NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
  RUN_DIR="$RUNS/${PSESS}--${NOW}/"
  mkdir -p "${RUN_DIR}agents" 2>/dev/null
  echo "{\"session\":\"$PSESS\",\"started\":\"$NOW_ISO\",\"wave\":1}" > "${RUN_DIR}meta.json" 2>/dev/null
else
  mkdir -p "${RUN_DIR}agents" 2>/dev/null
fi

# Register agent directly as "running"
AGENTS_DIR="${RUN_DIR}agents"
mkdir -p "$AGENTS_DIR" 2>/dev/null
SAFE=$(echo "$DESC" | tr ' /:\\' '----' | tr -cd 'a-zA-Z0-9_-' | head -c 60)
[ -z "$SAFE" ] && SAFE="agent"
STAMP=$(date -u +"%s%N" 2>/dev/null || date +"%s")
AGENT_ID="${SAFE}-${STAMP}"
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
AGENT_FILE="$AGENTS_DIR/$AGENT_ID.json"
echo "{\"id\":\"$AGENT_ID\",\"name\":\"$DESC\",\"status\":\"running\",\"sessionId\":\"$SID\",\"started\":\"$NOW_ISO\"}" > "$AGENT_FILE" 2>/dev/null

# Store agent file path so PostToolUse(Agent) can mark it completed
TRACKER="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/session-state/.agent-tracker"
mkdir -p "$TRACKER" 2>/dev/null
echo "$AGENT_FILE" > "$TRACKER/${SID}-${STAMP}" 2>/dev/null

exit 0
