#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2025-2026 Just In Time AI INC
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

# --- Upgrade-safe framework manifest (separates framework files from user files) ---
# The manifest records every FRAMEWORK-owned file (path + sha256) installed this run.
# On upgrade we prune framework files the new version dropped and back up any framework
# file the user edited -- and we NEVER touch a file that is not in the manifest (= yours).
MANIFEST="$TARGET/.jitneuro-manifest.tsv"
OLD_MANIFEST=""
if [ -f "$MANIFEST" ]; then
  OLD_MANIFEST="$(mktemp 2>/dev/null || echo "$TARGET/.jitneuro-manifest.old.$$")"
  cp "$MANIFEST" "$OLD_MANIFEST"
fi
NEW_MANIFEST="$(mktemp 2>/dev/null || echo "$TARGET/.jitneuro-manifest.new.$$")"
: > "$NEW_MANIFEST"

_jn_sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | cut -d' ' -f1
  else shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; fi
}
# old recorded sha for a relpath (empty if none / fresh install)
_jn_oldsha() { [ -n "$OLD_MANIFEST" ] && awk -F'\t' -v p="$1" '$1==p{print $2; exit}' "$OLD_MANIFEST"; }
# record a framework file (by target-relative path) into the new manifest (set -e safe)
_jn_record() { local rel="$1"; if [ -f "$TARGET/$rel" ]; then printf '%s\t%s\n' "$rel" "$(_jn_sha "$TARGET/$rel")" >> "$NEW_MANIFEST"; fi; }

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

# Routing now lives in jit-knowledge/INDEX.md -- do NOT seed context-manifest.md with routing tables.
# If a stale context-manifest.md exists from a prior install, leave it untouched (do not overwrite or delete).
# Users can remove it by running: jit-knowledge/scripts/cleanup-old-routing.sh
if [ -f "$TARGET/context-manifest.md" ]; then
  echo "NOTE: Legacy context-manifest.md found at $TARGET/context-manifest.md"
  echo "      Routing now lives in jit-knowledge/INDEX.md. Run cleanup-old-routing.sh to retire it."
fi

# Scaffold url-resolver.md in user home .claude (machine-specific, gitignored)
USER_CLAUDE="$HOME/.claude"
URL_RESOLVER="$USER_CLAUDE/url-resolver.md"
if [ ! -f "$URL_RESOLVER" ]; then
  mkdir -p "$USER_CLAUDE"
  cp "$TEMPLATES/url-resolver.md" "$URL_RESOLVER"
  echo "Created ~/.claude/url-resolver.md -- map your repo names to local paths (optional)"
else
  echo "Skipped url-resolver.md (already exists)"
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
      # If the user edited this framework rule since last install, preserve their copy.
      old_sha="$(_jn_oldsha "rules/$rule_name")"
      if [ -n "$old_sha" ] && [ "$old_sha" != "$(_jn_sha "$target_rule")" ]; then
        mkdir -p "$TARGET/.jitneuro-backup/rules"
        cp "$target_rule" "$TARGET/.jitneuro-backup/rules/$rule_name"
        echo "  BACKUP: rules/$rule_name (your edit saved to .jitneuro-backup/rules/)"
      fi
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

# Install horizon templates (strategic-context placeholders).
# Seed ONLY if empty -- never overwrite an adopter's filled-in horizon on re-run.
mkdir -p "$TARGET/horizon"
if [ -z "$(ls -A "$TARGET/horizon/" 2>/dev/null)" ]; then
  cp "$TEMPLATES/horizon/"*.md "$TARGET/horizon/" 2>/dev/null
  HORIZON_N=$(ls -1 "$TARGET/horizon/"*.md 2>/dev/null | wc -l)
  echo "Installing horizon templates..."
  echo "  horizon/ ($HORIZON_N placeholders -- fill in via horizon/POPULATE-HORIZON.md)"
else
  echo "Skipped horizon/ (already has files)"
fi

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
  # -f so a re-install can overwrite a previously chmod-locked (read-only) hook
  cp -f "$hook_file" "$TARGET/hooks/$hook_name"
  echo "  hooks/$hook_name"
done

# Set permissions (Linux/Mac only). Skip on Windows (MSYS/MinGW/Cygwin): POSIX perms
# do not apply there, and chmod 500 makes hooks read-only, breaking the NEXT install's
# copy. (The old `[ ... != "MINGW"* ]` test never matched -- [ ] does not glob.)
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) : ;;
  *)
    chmod 700 "$TARGET/hooks" 2>/dev/null || true
    chmod 500 "$TARGET/hooks/"*.sh 2>/dev/null || true
    ;;
esac

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

# ============================================================================
# HOW TO WRITE A HOOK COMMAND -- read before editing the entries below
# ----------------------------------------------------------------------------
# Claude Code runs each hook `command` through its OWN shell. The `command`
# value MUST be a bare script path and nothing else, for example:
#       "command": "${HOOKS_PATH_FWD}/heartbeat.sh"
#
# NEVER prefix it with `bash`, `bash.exe`, or any shell binary. A prefix makes
# the shell try to run bash as bash's own script argument, so EVERY hook then
# fails at runtime with:
#       bash.exe: bash.exe: cannot execute binary file
#
# When adding or changing a hook below, look at the other hook entries in this
# same block and match their format exactly -- each `command` is just a path.
# Full rule: jit-knowledge/rules/claude-code-hook-deployment.md
# ============================================================================
build_hooks_json() {
  cat <<HOOKJSON
{
  "hooks": {
    "Stop": [{ "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/stop-continue-queue.sh", "timeout": 10 }] }],
    "PreCompact": [{ "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/pre-compact-save.sh", "timeout": 10 }] }],
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/session-start-identity.sh", "timeout": 10 }] },
      { "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/session-start-write-id.sh", "timeout": 10 }] },
      { "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/session-start-post-clear.sh", "timeout": 10 }] },
      { "matcher": "compact", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/session-start-recovery.sh", "timeout": 10 }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/branch-protection.sh", "timeout": 10 }] },
      { "matcher": "Agent", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/pre-agent-register.sh", "timeout": 5 }] }
    ],
    "PostToolUse": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/heartbeat.sh", "timeout": 5 }] },
      { "matcher": "Agent", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/post-agent-complete.sh", "timeout": 5 }] }
    ],
    "SessionEnd": [{ "matcher": "", "hooks": [{ "type": "command", "command": "${HOOKS_PATH_FWD}/session-end-autosave.sh", "timeout": 10 }] }]
  }
}
HOOKJSON
}

if [ -f "$SETTINGS_FILE" ]; then
  # Existing settings -- try to merge with jq
  if command -v jq >/dev/null 2>&1; then
    HOOKS_JSON=$(build_hooks_json)
    TEMP_FILE="$SETTINGS_FILE.tmp.$$"
    # Per-event merge: preserve user-added hooks, replace/dedup jitneuro's own
    # (entries whose command path starts with this install's hooks dir). Other
    # top-level settings keys are preserved via the base object merge.
    jq -s --arg hp "$HOOKS_PATH_FWD" '
      (.[0]) as $cur | (.[1]) as $new |
      ($cur * $new) |
      .hooks = (
        reduce ($new.hooks | keys_unsorted[]) as $e
          ( ($cur.hooks // {}) ;
            .[$e] = ( ( ($cur.hooks[$e] // [])
                        | map(select( any(.hooks[]?; .command | startswith($hp)) | not )) )
                      + $new.hooks[$e] )
          )
      )
    ' "$SETTINGS_FILE" <(echo "$HOOKS_JSON") > "$TEMP_FILE" 2>/dev/null
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

# --- Record framework manifest + prune framework files dropped since last install ---
echo ""
echo "Recording framework manifest..."
for t in "$TEMPLATES/commands/"*.md;   do [ -f "$t" ] || continue; _jn_record "commands/$(basename "$t")"; done
for t in "$TEMPLATES/rules/"*.md;      do [ -f "$t" ] || continue; _jn_record "rules/$(basename "$t")"; done
for t in "$TEMPLATES/cognition/"*.md;  do
  [ -f "$t" ] || continue
  b="$(basename "$t")"
  [ "$b" = "owner-persona.example.md" ] && continue   # owner-persona is user-owned after seeding
  _jn_record "cognition/$b"
done
for t in "$TEMPLATES/cognition/decisions/"*.md; do [ -f "$t" ] || continue; _jn_record "cognition/decisions/$(basename "$t")"; done
for t in "$TEMPLATES/scripts/"*.sh;    do [ -f "$t" ] || continue; _jn_record "scripts/$(basename "$t")"; done
for t in "$TEMPLATES/dashboard/"*.html "$TEMPLATES/dashboard/"*.js; do [ -f "$t" ] || continue; _jn_record "dashboard/$(basename "$t")"; done
if [ -d "$TEMPLATES/dashboard/bin" ]; then
  for t in "$TEMPLATES/dashboard/bin/"*; do [ -f "$t" ] || continue; _jn_record "dashboard/bin/$(basename "$t")"; done
fi
for t in "$TEMPLATES/hooks/"*.sh;      do [ -f "$t" ] || continue; _jn_record "hooks/$(basename "$t")"; done
_jn_record "jitneuro.json"

# Prune framework files present at last install but no longer shipped (sha-guarded).
if [ -n "$OLD_MANIFEST" ]; then
  PRUNED=0
  while IFS=$'\t' read -r rel oldsha; do
    [ -n "$rel" ] || continue
    case "$rel" in \#*) continue;; esac
    if ! awk -F'\t' -v p="$rel" '$1==p{f=1} END{exit !f}' "$NEW_MANIFEST"; then
      f="$TARGET/$rel"
      if [ -f "$f" ]; then
        if [ "$(_jn_sha "$f")" = "$oldsha" ]; then
          rm -f "$f"; echo "  REMOVED (dropped by framework): $rel"; PRUNED=$((PRUNED+1))
        else
          echo "  KEPT (you edited a now-removed framework file): $rel"
        fi
      fi
    fi
  done < "$OLD_MANIFEST"
  [ "$PRUNED" -gt 0 ] && echo "  ($PRUNED stale framework file(s) removed)"
fi

# Write the manifest (sorted, version-stamped). Files NOT listed here = yours; never touched.
{ echo "# jitneuro-manifest v$VERSION"; LC_ALL=C sort "$NEW_MANIFEST"; } > "$MANIFEST"
MF_COUNT=$(grep -cv '^#' "$MANIFEST" 2>/dev/null || echo 0)
rm -f "$NEW_MANIFEST" "$OLD_MANIFEST" 2>/dev/null || true
echo "  .jitneuro-manifest.tsv ($MF_COUNT framework files tracked)"

# --- Summary ---
echo ""
echo "---"
echo "JitNeuro v$VERSION installed to: $TARGET"
echo ""
echo "Next steps:"
echo "  1. CLOSE AND REOPEN Claude Code (commands load at session start)"
echo "  2. Run /verify to confirm everything is working"
echo "  3. Populate your horizon: tell Claude \"populate my horizon files\" (or open"
echo "     $TARGET/horizon/POPULATE-HORIZON.md) to capture your vision, goals, and profile"
echo "  4. Run /onboard <repo> to set up context for your repos"
echo "  5. Create bundles for your domains in $TARGET/bundles/"
echo "  6. (optional) Edit ~/.claude/url-resolver.md to map your repo names to local paths"
echo ""
echo "*** You MUST restart Claude Code for slash commands to take effect. ***"
echo ""
echo "Docs: $SCRIPT_DIR/docs/setup-guide.md"
