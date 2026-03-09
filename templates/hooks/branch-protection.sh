#!/bin/bash
# JitNeuro Branch Protection Hook (PreToolUse on Bash)
# Blocks git push to main/master without explicit bypass.
#
# RED zone enforcement: push to main requires the project owner's explicit permission.
# This hook enforces it programmatically so Claude can't accidentally push.

INPUT=$(cat)

# Extract the command from tool input
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')

# Also handle escaped quotes in JSON
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Check for git push to main or master (with or without origin/upstream)
# Match: git push origin main, git push main, git push --force origin main, etc.
if echo "$COMMAND" | grep -qiE 'git\s+push\s+.*\b(main|master)\b'; then
  echo "BLOCKED by JitNeuro branch protection: git push to main/master is a RED zone action." >&2
  echo "This requires the project owner's explicit permission. Ask before retrying." >&2
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
if echo "$COMMAND" | grep -qiE 'git\s+rebase\s+.*(main|master)'; then
  echo "BLOCKED by JitNeuro branch protection: rebase onto main/master detected." >&2
  echo "Rebasing rewrites history on a protected branch. Requires the project owner's explicit permission." >&2
  exit 2
fi

exit 0
