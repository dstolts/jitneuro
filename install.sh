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

# Read version from jitneuro.json
VERSION="unknown"
if [ -f "$TEMPLATES/jitneuro.json" ]; then
  VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$TEMPLATES/jitneuro.json" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

MODE="${1:-project}"

case "$MODE" in
  workspace)
    TARGET="$(dirname "$(pwd)")/.claude"
    echo "Installing JitNeuro v$VERSION at WORKSPACE level: $TARGET"
    echo "Commands will be available to all repos under $(dirname "$(pwd)")"
    WORKSPACE_ROOT="$(dirname "$(pwd)")"
    ;;
  project)
    TARGET="$(pwd)/.claude"
    echo "Installing JitNeuro v$VERSION at PROJECT level: $TARGET"
    echo "Commands will be available in this repo only."
    WORKSPACE_ROOT=""
    ;;
  user)
    TARGET="$HOME/.claude"
    echo "Installing JitNeuro v$VERSION at USER level: $TARGET"
    echo "Commands will be available in all projects on this machine."
    WORKSPACE_ROOT=""
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

# --- Upgrade detection (US-007) ---
INSTALLED_CONFIG="$TARGET/jitneuro.json"
PREV_VERSION=""
if [ -f "$INSTALLED_CONFIG" ]; then
  PREV_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$INSTALLED_CONFIG" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi
if [ -n "$PREV_VERSION" ]; then
  if [ "$PREV_VERSION" = "$VERSION" ]; then
    echo "Re-installing JitNeuro v$VERSION (same version)"
  else
    echo "Upgrading JitNeuro: v$PREV_VERSION -> v$VERSION"
  fi
elif [ -d "$TARGET/commands" ] && [ -n "$(ls -A "$TARGET/commands/" 2>/dev/null)" ]; then
  echo "Upgrading from pre-versioned JitNeuro install"
else
  echo "Fresh install"
fi
echo ""

# Create directories
mkdir -p "$TARGET/commands"
mkdir -p "$TARGET/bundles"
mkdir -p "$TARGET/engrams"
mkdir -p "$TARGET/session-state"
mkdir -p "$TARGET/session-state/heartbeats"
mkdir -p "$TARGET/rules"
mkdir -p "$TARGET/hooks"
mkdir -p "$TARGET/cognition/decisions"
mkdir -p "$TARGET/scripts"
mkdir -p "$TARGET/dashboard/runs"

# --- Backup existing commands before overwrite (US-002) ---
BACKUP_COUNT=0
BACKUP_DIR="$TARGET/commands/.backup"
for cmd_file in "$TEMPLATES/commands/"*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name="$(basename "$cmd_file")"
  existing="$TARGET/commands/$cmd_name"
  if [ -f "$existing" ]; then
    if ! diff -q "$cmd_file" "$existing" >/dev/null 2>&1; then
      mkdir -p "$BACKUP_DIR"
      cp "$existing" "$BACKUP_DIR/$cmd_name"
      BACKUP_COUNT=$((BACKUP_COUNT + 1))
    fi
  fi
done
if [ "$BACKUP_COUNT" -gt 0 ]; then
  echo "Backed up $BACKUP_COUNT existing commands to commands/.backup/"
fi

# --- Install commands (dynamic scan) ---
echo "Installing commands..."
CMD_COUNT=0
for cmd_file in "$TEMPLATES/commands/"*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name="$(basename "$cmd_file" .md)"
  cp "$cmd_file" "$TARGET/commands/$(basename "$cmd_file")"
  echo "  /$cmd_name"
  CMD_COUNT=$((CMD_COUNT + 1))
done
echo "  ($CMD_COUNT commands installed)"

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

# Install rule templates (respect DISABLED marker)
echo "Installing rule templates..."
RULE_COUNT=0
RULE_SKIP=0
for rule_file in "$TEMPLATES/rules/"*.md; do
  [ -f "$rule_file" ] || continue
  rule_name="$(basename "$rule_file")"
  target_rule="$TARGET/rules/$rule_name"
  if [ -f "$target_rule" ]; then
    if head -1 "$target_rule" | grep -q "(DISABLED)" 2>/dev/null; then
      echo "  SKIP: $rule_name (disabled by user)"
      RULE_SKIP=$((RULE_SKIP + 1))
      continue
    fi
    if ! diff -q "$rule_file" "$target_rule" >/dev/null 2>&1; then
      cp "$rule_file" "$target_rule"
      echo "  UPDATED: $rule_name"
      RULE_COUNT=$((RULE_COUNT + 1))
    fi
  else
    cp "$rule_file" "$target_rule"
    echo "  $rule_name"
    RULE_COUNT=$((RULE_COUNT + 1))
  fi
done
echo "  ($RULE_COUNT rules installed, $RULE_SKIP disabled/skipped)"

# Install cognition layer (Phase 2)
echo "Installing cognition layer..."
for cog_file in "$TEMPLATES/cognition/"*.md; do
  [ -f "$cog_file" ] || continue
  cp "$cog_file" "$TARGET/cognition/$(basename "$cog_file")"
done
for dec_file in "$TEMPLATES/cognition/decisions/"*.md; do
  [ -f "$dec_file" ] || continue
  cp "$dec_file" "$TARGET/cognition/decisions/$(basename "$dec_file")"
done
echo "  cognition/personas.md (16 personas)"
echo "  cognition/friction-detection.md"
echo "  cognition/anti-patterns.md (seed entries)"
echo "  cognition/decisions/ ($(ls -1 "$TEMPLATES/cognition/decisions/"*.md 2>/dev/null | wc -l) models)"
# Create owner-persona from example if it doesn't exist
if [ ! -f "$TARGET/cognition/owner-persona.md" ]; then
  cp "$TEMPLATES/cognition/owner-persona.example.md" "$TARGET/cognition/owner-persona.md"
  echo "  cognition/owner-persona.md (created from template -- customize this)"
else
  echo "  Skipped owner-persona.md (already exists)"
fi

# Install scripts
echo "Installing scripts..."
for script_file in "$TEMPLATES/scripts/"*.sh; do
  [ -f "$script_file" ] || continue
  script_name="$(basename "$script_file")"
  cp "$script_file" "$TARGET/scripts/$script_name"
  echo "  scripts/$script_name"
done

# Install dashboard
echo "Installing dashboard..."
for dash_file in "$TEMPLATES/dashboard/"*.html "$TEMPLATES/dashboard/"*.js; do
  [ -f "$dash_file" ] || continue
  dash_name="$(basename "$dash_file")"
  cp "$dash_file" "$TARGET/dashboard/$dash_name"
  echo "  dashboard/$dash_name"
done
if [ -d "$TEMPLATES/dashboard/bin" ]; then
  mkdir -p "$TARGET/dashboard/bin"
  for bin_file in "$TEMPLATES/dashboard/bin/"*; do
    [ -f "$bin_file" ] || continue
    cp "$bin_file" "$TARGET/dashboard/bin/$(basename "$bin_file")"
  done
  echo "  dashboard/bin/ (launcher scripts)"
fi

# Install hooks
echo "Installing hooks..."
for hook_file in "$TEMPLATES/hooks/"*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name="$(basename "$hook_file")"
  cp "$hook_file" "$TARGET/hooks/$hook_name"
  echo "  hooks/$hook_name"
done

# Set permissions (Linux/Mac only)
if [ "$(uname -s)" != "MINGW"* ] && [ "$(uname -s)" != "MSYS"* ]; then
  chmod 700 "$TARGET/hooks" 2>/dev/null || true
  chmod 500 "$TARGET/hooks/"*.sh 2>/dev/null || true
fi

# --- Copy jitneuro.json config ---
cp "$TEMPLATES/jitneuro.json" "$TARGET/jitneuro.json"
echo "Installed jitneuro.json (v$VERSION)"

# --- Auto-configure hooks in settings.local.json (US-001) ---
echo ""
echo "Configuring hooks..."
SETTINGS_FILE="$TARGET/settings.local.json"
HOOKS_PATH="$TARGET/hooks"

# Build hooks JSON using jitneuro.json hookEvents
# Use forward slashes for all paths (Claude Code expects this)
HOOKS_PATH_FWD=$(echo "$HOOKS_PATH" | sed 's|\\|/|g')

build_hooks_json() {
  cat <<HOOKJSON
{
  "hooks": {
    "PreCompact": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/pre-compact-save.sh\"", "timeout": 10 }] }],
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/session-start-write-id.sh\"", "timeout": 10 }] },
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/session-start-post-clear.sh\"", "timeout": 10 }] },
      { "matcher": "compact", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/session-start-recovery.sh\"", "timeout": 10 }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/branch-protection.sh\"", "timeout": 10 }] },
      { "matcher": "Agent", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/pre-agent-register.sh\"", "timeout": 5 }] }
    ],
    "PostToolUse": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/heartbeat.sh\"", "timeout": 5 }] },
      { "matcher": "Agent", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/post-agent-complete.sh\"", "timeout": 5 }] }
    ],
    "SessionEnd": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash \"${HOOKS_PATH_FWD}/session-end-autosave.sh\"", "timeout": 10 }] }]
  }
}
HOOKJSON
}

if [ -f "$SETTINGS_FILE" ]; then
  # Existing settings -- try to merge with jq
  if command -v jq >/dev/null 2>&1; then
    HOOKS_JSON=$(build_hooks_json)
    TEMP_FILE="$SETTINGS_FILE.tmp.$$"
    jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOKS_JSON") > "$TEMP_FILE" 2>/dev/null
    if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
      mv "$TEMP_FILE" "$SETTINGS_FILE"
      echo "  Merged hooks into existing settings.local.json"
    else
      rm -f "$TEMP_FILE"
      echo "  WARNING: jq merge failed. Existing settings.local.json left UNTOUCHED."
      echo "  You must manually add hooks config. See $TARGET/jitneuro.json for reference."
    fi
  else
    echo "  WARNING: jq not found and settings.local.json already exists."
    echo "  Existing file left UNTOUCHED to prevent data loss."
    echo "  Install jq and re-run, or manually add hooks config."
    echo "  See $TARGET/jitneuro.json for the hooks configuration."
  fi
else
  # No existing settings -- create hooks-only file (atomic write)
  TEMP_FILE="$SETTINGS_FILE.tmp.$$"
  build_hooks_json > "$TEMP_FILE"
  mv "$TEMP_FILE" "$SETTINGS_FILE"
  echo "  Created settings.local.json with hooks config"
fi

# --- Post-install workspace repo scan (US-003) ---
if [ "$MODE" = "workspace" ] && [ -n "$WORKSPACE_ROOT" ]; then
  echo ""
  echo "Scanning workspace for repos..."
  echo ""
  printf "  %-20s %-10s %-10s %-10s\n" "REPO" "CLAUDE.md" "BRAINSTEM" "ENGRAM"
  printf "  %-20s %-10s %-10s %-10s\n" "----" "---------" "---------" "------"
  REPO_COUNT=0
  NEEDS_ONBOARD=0
  for dir in "$WORKSPACE_ROOT"/*/; do
    [ -d "$dir/.git" ] || continue
    repo_name="$(basename "$dir")"
    # Skip .claude and jitneuro directories
    [ "$repo_name" = ".claude" ] && continue
    [ "$repo_name" = "jitneuro" ] && continue

    # Truncate long names
    display_name="$repo_name"
    if [ ${#display_name} -gt 20 ]; then
      display_name="${display_name:0:17}..."
    fi

    has_claude="--"
    has_brainstem="--"
    has_engram="--"

    [ -f "$dir/CLAUDE.md" ] && has_claude="YES"
    [ -f "$dir/.claude/CLAUDE.md" ] && has_brainstem="YES"
    [ -f "$WORKSPACE_ROOT/.claude/engrams/${repo_name}-context.md" ] && has_engram="YES"

    if [ "$has_claude" = "--" ] || [ "$has_brainstem" = "--" ] || [ "$has_engram" = "--" ]; then
      NEEDS_ONBOARD=$((NEEDS_ONBOARD + 1))
    fi

    printf "  %-20s %-10s %-10s %-10s\n" "$display_name" "$has_claude" "$has_brainstem" "$has_engram"
    REPO_COUNT=$((REPO_COUNT + 1))

    # Cap at 30 repos
    if [ "$REPO_COUNT" -ge 30 ]; then
      echo "  ... ($REPO_COUNT+ repos, showing first 30)"
      break
    fi
  done
  echo ""
  echo "  $REPO_COUNT repos found, $NEEDS_ONBOARD need onboarding"
  if [ "$NEEDS_ONBOARD" -gt 0 ]; then
    echo "  Run /onboard <repo> to set up context for missing repos"
  fi
  # US-004: Git sync tip
  echo "  Tip: /onboard checks if repos are behind their remote"
fi

# --- Add *.backup to .gitignore ---
GITIGNORE="$TARGET/../.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q '\.backup' "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# JitNeuro command backups" >> "$GITIGNORE"
    echo ".claude/commands/.backup/" >> "$GITIGNORE"
  fi
fi

# --- Leave onboard marker for SessionStart hook ---
if [ "$MODE" = "workspace" ] && [ -n "$WORKSPACE_ROOT" ]; then
  MARKER="$TARGET/.needs-onboard"
  echo "installed=$(date -u +%Y-%m-%dT%H:%M:%S)" > "$MARKER"
  echo "mode=$MODE" >> "$MARKER"
  echo "workspace=$WORKSPACE_ROOT" >> "$MARKER"
  echo ""
  echo "  On next Claude Code session start, you will be prompted to scan"
  echo "  and onboard all repos in the workspace automatically."
fi

# --- Summary ---
echo ""
echo "---"
echo "JitNeuro v$VERSION installed to: $TARGET"
echo ""
echo "Next steps:"
echo "  1. CLOSE AND REOPEN Claude Code (commands load at session start)"
echo "  2. Claude will prompt to onboard all repos in the workspace"
echo "  3. Run /verify to confirm everything is working"
echo "  4. Create bundles for your domains in $TARGET/bundles/"
echo ""
echo "*** You MUST restart Claude Code for slash commands to take effect. ***"
echo ""
echo "Docs: $SCRIPT_DIR/docs/setup-guide.md"
