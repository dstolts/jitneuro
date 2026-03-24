#!/usr/bin/env bash
# JitNeuro Post-Agent Complete -- PostToolUse hook (matcher: "Agent")
# Finds the most recent running agent tracker for this session and marks it completed.
# ~15ms: stdin read + grep + find tracker + sed

set +e
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
fi

SID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
[ -z "$SID" ] && exit 0

TRACKER="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/session-state/.agent-tracker"
[ -d "$TRACKER" ] || exit 0

# Find the oldest tracker file for this session (FIFO for sequential agents)
CRUMB=$(ls -1 "$TRACKER" 2>/dev/null | grep "^${SID}-" | sort | head -1)
[ -z "$CRUMB" ] && exit 0
[ -f "$TRACKER/$CRUMB" ] || exit 0

AGENT_FILE=$(cat "$TRACKER/$CRUMB" 2>/dev/null | tr -d '\n\r')
rm -f "$TRACKER/$CRUMB" 2>/dev/null

if [ -n "$AGENT_FILE" ] && [ -f "$AGENT_FILE" ]; then
  NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
  sed -i "s/\"status\":\"running\"/\"status\":\"completed\"/" "$AGENT_FILE" 2>/dev/null
  # Append finished timestamp before closing brace
  sed -i "s/}$/,\"finished\":\"$NOW_ISO\"}/" "$AGENT_FILE" 2>/dev/null
fi

exit 0