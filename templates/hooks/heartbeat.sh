#!/usr/bin/env bash
# JitNeuro Heartbeat -- PostToolUse hook
# Touches heartbeats/<session-id> to update liveness mtime.
# Fires on every tool call. Must be MINIMAL.
# No stdout. Exit 0 always.

set +e
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
fi
SID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
[ -z "$SID" ] && exit 0
d="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/session-state/heartbeats"
mkdir -p "$d" 2>/dev/null
touch "$d/$SID" 2>/dev/null
exit 0
