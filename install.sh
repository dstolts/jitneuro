#!/usr/bin/env bash
# JitNeuro Installer
# Usage: ./install.sh [workspace|project|user]
#
# workspace  Install to parent directory's .claude/ (covers all repos under it)
# project    Install to current directory's .claude/ (single repo)
# user       Install to ~/.claude/ (available on entire machine)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

if [ ! -d "$TEMPLATES" ]; then
  echo "ERROR: templates/ directory not found at $TEMPLATES"
  echo "Run this script from the jitneuro repo root."
  exit 1
fi

MODE="${1:-project}"

case "$MODE" in
  workspace)
    # Assumes you run this from a repo directory; parent is the shared workspace root
    TARGET="$(dirname "$(pwd)")/.claude"
    echo "Installing JitNeuro at WORKSPACE level: $TARGET"
    echo "Commands will be available to all repos under $(dirname "$(pwd)")"
    ;;
  project)
    TARGET="$(pwd)/.claude"
    echo "Installing JitNeuro at PROJECT level: $TARGET"
    echo "Commands will be available in this repo only."
    ;;
  user)
    TARGET="$HOME/.claude"
    echo "Installing JitNeuro at USER level: $TARGET"
    echo "Commands will be available in all projects on this machine."
    ;;
  *)
    echo "Usage: ./install.sh [workspace|project|user]"
    echo ""
    echo "  workspace  Parent directory .claude/ (all repos underneath)"
    echo "  project    Current directory .claude/ (single repo, default)"
    echo "  user       ~/.claude/ (global, all projects)"
    exit 1
    ;;
esac

echo ""

# Create directories
mkdir -p "$TARGET/commands"
mkdir -p "$TARGET/bundles"
mkdir -p "$TARGET/engrams"
mkdir -p "$TARGET/session-state"
mkdir -p "$TARGET/rules"
mkdir -p "$TARGET/hooks"

# Copy commands (slash commands)
echo "Installing commands..."
for cmd in save load learn sessions orchestrate conversation-log health enterprise status dashboard gitstatus diff audit bundle onboard; do
  if [ -f "$TEMPLATES/commands/$cmd.md" ]; then
    cp "$TEMPLATES/commands/$cmd.md" "$TARGET/commands/$cmd.md"
    echo "  /$cmd"
  fi
done

# Copy templates (don't overwrite existing)
if [ ! -f "$TARGET/context-manifest.md" ]; then
  cp "$TEMPLATES/context-manifest.md" "$TARGET/context-manifest.md"
  echo "Created context-manifest.md"
else
  echo "Skipped context-manifest.md (already exists)"
fi

# Copy example bundle if bundles dir is empty
if [ -z "$(ls -A "$TARGET/bundles/" 2>/dev/null)" ]; then
  cp "$TEMPLATES/bundles/example.md" "$TARGET/bundles/example.md"
  echo "Created bundles/example.md (template)"
else
  echo "Skipped bundles/ (already has files)"
fi

# Copy example engram if engrams dir is empty
if [ -z "$(ls -A "$TARGET/engrams/" 2>/dev/null)" ]; then
  cp "$TEMPLATES/engrams/example.md" "$TARGET/engrams/example.md"
  cp "$TEMPLATES/engrams/README.md" "$TARGET/engrams/README.md"
  echo "Created engrams/example.md (template)"
else
  echo "Skipped engrams/ (already has files)"
fi

# Copy session-state README
if [ ! -f "$TARGET/session-state/README.md" ]; then
  cp "$TEMPLATES/session-state/README.md" "$TARGET/session-state/README.md"
  echo "Created session-state/README.md"
fi

# Copy scoped rule example if rules dir is empty
if [ -z "$(ls -A "$TARGET/rules/" 2>/dev/null)" ]; then
  cp "$TEMPLATES/rules/scoped-rule-example.md" "$TARGET/rules/scoped-rule-example.md"
  echo "Created rules/scoped-rule-example.md (template)"
else
  echo "Skipped rules/ (already has files)"
fi

# Copy hooks
echo "Installing hooks..."
for hook in pre-compact-save.sh session-start-recovery.sh branch-protection.sh session-end-autosave.sh jitneuro-hooks.json; do
  if [ -f "$TEMPLATES/hooks/$hook" ]; then
    cp "$TEMPLATES/hooks/$hook" "$TARGET/hooks/$hook"
    echo "  hooks/$hook"
  fi
done
chmod +x "$TARGET/hooks/"*.sh 2>/dev/null

# Show brainstem template hint
echo ""
echo "---"
echo "JitNeuro installed to: $TARGET"
echo ""
echo "Next steps:"
echo "  1. Slim your CLAUDE.md using templates/CLAUDE-brainstem.md as a guide"
echo "  2. Create bundles for your domains in $TARGET/bundles/"
echo "  3. Create engrams for your projects in $TARGET/engrams/"
echo "  4. Update $TARGET/context-manifest.md with your bundles"
echo "  5. Add routing weights to your MEMORY.md"
echo "  6. CLOSE AND REOPEN Claude Code (commands are only discovered at session start)"
echo ""
echo "*** You MUST restart Claude Code for slash commands to take effect. ***"
echo ""
echo "Commands available after restart: /save /load /learn /sessions /orchestrate"
echo "New commands: /health /enterprise /status /dashboard /gitstatus /diff /audit /bundle /onboard"
echo ""
echo "IMPORTANT: Hooks were installed to $TARGET/hooks/ but you must"
echo "manually configure them in your settings.local.json file."
echo ""
echo "Add the following to your ~/.claude/settings.local.json (or merge"
echo "with existing hooks config):"
echo ""
echo '  "hooks": {'
echo '    "PreCompact": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash '"$TARGET"'/hooks/pre-compact-save.sh" }] }],'
echo '    "SessionStart": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash '"$TARGET"'/hooks/session-start-recovery.sh" }] }],'
echo '    "PrePush": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash '"$TARGET"'/hooks/branch-protection.sh" }] }],'
echo '    "SessionEnd": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash '"$TARGET"'/hooks/session-end-autosave.sh" }] }]'
echo '  }'
echo ""
echo "See $TARGET/hooks/jitneuro-hooks.json for the full hooks configuration."
echo ""
echo "Docs: $SCRIPT_DIR/docs/setup-guide.md"
