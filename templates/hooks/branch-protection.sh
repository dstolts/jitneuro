#!/bin/bash
# JitNeuro Branch Protection Hook (PreToolUse on Bash)
# Blocks git push to main/master without explicit bypass.
#
# RED zone enforcement: push to main requires the project owner's explicit permission.
# This hook enforces it programmatically so Claude can't accidentally push.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$(dirname "$SCRIPT_DIR")/jitneuro.json"

# Read protected branches from config (default: main, master)
PROTECTED="main|master"
ALLOWED_URLS=""
if [ -f "$CONFIG" ]; then
  # Extract branch names from protectedBranches array
  BRANCHES=$(grep -o '"protectedBranches"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$CONFIG" | grep -o '"[a-zA-Z0-9_-]*"' | tr -d '"' | tr '\n' '|' | sed 's/|$//')
  [ -n "$BRANCHES" ] && PROTECTED="$BRANCHES"
  # Extract mainPushAllowed URLs (repos allowed to push to protected branches)
  ALLOWED_URLS=$(grep -o '"mainPushAllowed"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$CONFIG" | grep -o '"https://[^"]*"' | tr -d '"')
fi

# Check if current repo's remote is in the allowed list
is_repo_allowed() {
  [ -z "$ALLOWED_URLS" ] && return 1
  local REMOTE_URL
  REMOTE_URL=$(git remote get-url origin 2>/dev/null)
  [ -z "$REMOTE_URL" ] && return 1
  echo "$ALLOWED_URLS" | while IFS= read -r url; do
    [ "$url" = "$REMOTE_URL" ] && exit 0
  done
  return $?
}

INPUT=$(cat)

# Extract the command from tool input JSON (no python dependency)
# Try multiple patterns to handle different JSON structures Claude Code may send
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')

# If command contains escaped quotes or multiline, try broader extraction
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)/\1/p' | head -1 | sed 's/"[[:space:]]*,.*//' | sed 's/"[[:space:]]*}//')
fi

# Safety: if we still can't parse the command, block git operations rather than allow-all
if [ -z "$COMMAND" ]; then
  # Check raw input for dangerous patterns as a fallback
  if echo "$INPUT" | grep -qiE "git\s+push.*\b($PROTECTED)(\s|$)"; then
    if ! echo "$INPUT" | grep -qiE 'git\s+push.*--force' && is_repo_allowed; then
      exit 0
    fi
    echo "BLOCKED by JitNeuro branch protection: git push to protected branch detected (fallback parser)." >&2
    echo "Protected branches: $PROTECTED. This requires the project owner's explicit permission." >&2
    exit 2
  fi
  if echo "$INPUT" | grep -qiE 'git\s+push.*--force'; then
    echo "BLOCKED by JitNeuro branch protection: force push detected (fallback parser)." >&2
    exit 2
  fi
  if echo "$INPUT" | grep -qiE 'git\s+reset\s+--hard'; then
    echo "BLOCKED by JitNeuro branch protection: git reset --hard detected (fallback parser)." >&2
    exit 2
  fi
  exit 0
fi

# Check for git push to main or master (with or without origin/upstream)
# Match: git push origin main, git push main, git push --force origin main, etc.
if echo "$COMMAND" | grep -qiE "git\s+push\s+.*\b($PROTECTED)(\s|$)"; then
  # Allow if this repo's remote URL is in mainPushAllowed (force push still blocked below)
  if ! echo "$COMMAND" | grep -qiE 'git\s+push\s+.*--force' && is_repo_allowed; then
    exit 0
  fi
  echo "BLOCKED by JitNeuro branch protection: git push to protected branch is a RED zone action." >&2
  echo "Protected branches: $PROTECTED. This requires the project owner's explicit permission." >&2
  exit 2
fi

# Check for force push to any branch (dangerous)
if echo "$COMMAND" | grep -qiE 'git\s+push\s+.*--force'; then
  echo "BLOCKED by JitNeuro branch protection: force push detected." >&2
  echo "Force push is destructive and requires the project owner's explicit permission." >&2
  exit 2
fi

# Check for git branch -D (force delete branch)
if echo "$COMMAND" | grep -qiE 'git\s+branch\s+-D\s'; then
  echo "BLOCKED by JitNeuro branch protection: force branch delete detected." >&2
  echo "This is destructive and requires the project owner's explicit permission." >&2
  exit 2
fi

# Check for git reset --hard
if echo "$COMMAND" | grep -qiE 'git\s+reset\s+--hard'; then
  echo "BLOCKED by JitNeuro branch protection: git reset --hard detected." >&2
  echo "This discards uncommitted work. Requires the project owner's explicit permission." >&2
  exit 2
fi

# Check for git rebase onto main/master (rewrites history on protected branch)
if echo "$COMMAND" | grep -qiE "git\s+rebase\s+.*($PROTECTED)"; then
  echo "BLOCKED by JitNeuro branch protection: rebase onto protected branch detected." >&2
  echo "Protected branches: $PROTECTED. Requires the project owner's explicit permission." >&2
  exit 2
fi

exit 0
