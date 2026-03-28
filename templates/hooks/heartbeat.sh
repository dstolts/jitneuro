#!/usr/bin/env bash
# JitNeuro Heartbeat -- PostToolUse hook
# Touches heartbeats/<session-id> to update liveness mtime.
# Fires on every tool call. Must be MINIMAL.
# No stdout. Exit 0 always.

set +e

# Fast path: use env var set by SessionStart (zero parsing)
SID="$CLAUDE_SESSION_ID"

# Fallback: parse JSON from stdin (first session before env var is set)
if [ -z "$SID" ]; then
  INPUT=""
  if command -v timeout >/dev/null 2>&1; then
    INPUT=$(timeout 2 cat 2>/dev/null || true)
  else
    while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
  fi
  # Bash parameter expansion instead of grep/sed pipeline
  tmp="${INPUT#*\"session_id\"}"
  tmp="${tmp#*\"}"
  SID="${tmp%%\"*}"
  # Validate: session IDs are UUID-like, reject garbage
  case "$SID" in *[!a-f0-9-]*) SID="" ;; esac
fi

[ -z "$SID" ] && exit 0
d="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/session-state/heartbeats"
mkdir -p "$d" 2>/dev/null
touch "$d/$SID" 2>/dev/null
exit 0
