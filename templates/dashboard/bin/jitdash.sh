#!/usr/bin/env bash
# JitNeuro Agent Dashboard launcher (bash/zsh)
# Place in PATH. Usage: jitdash [--port=9847] [--no-open]
set -e
SERVER="$HOME/.claude/dashboard/server.js"
PORT="${JITDASH_PORT:-9847}"
command -v node >/dev/null 2>&1 || { echo "Error: Node.js not in PATH." >&2; exit 1; }
[ -f "$SERVER" ] || { echo "Error: $SERVER not found. Run jitneuro install." >&2; exit 1; }
exec node "$SERVER" "--port=$PORT" "$@"
