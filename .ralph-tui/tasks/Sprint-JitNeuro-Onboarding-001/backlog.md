# Sprint-JitNeuro-Onboarding-001 Backlog

**Spec:** .ralph-tui/specs/Sprint-JitNeuro-Onboarding-001.md
**Branch:** sprint-jitneuro-onboarding-001 (stories 1-11), main (stories 0a-0b)
**Commit prefix:** [Ralph] ONB-
**Status:** PENDING APPROVAL
**Holistic Review:** COMPLETE -- all enhancements incorporated

---

## Story Table

| # | Story | Priority | Risk | Est | Deps |
|---|-------|----------|------|-----|------|
| US-PR-001 | GitHub branch protection on main | P0 | Low | 10m | None |
| US-PR-002 | PR template | P1 | Low | 10m | None |
| US-005 | Windows bash detection | P1 | Med | 15m | None |
| US-001 | Auto-configure hooks in settings.local.json | P0 | High | 40m | US-005 |
| US-002 | Backup existing commands before overwrite | P1 | Low | 15m | None |
| US-003 | Post-install workspace repo scan | P0 | Low | 20m | None |
| US-004 | Git sync check (deferred to /onboard) | P2 | Low | 5m | US-003 |
| US-007 | Upgrade detection + version file | P2 | Low | 15m | None |
| US-009 | Smarter /onboard | P1 | Low | 5m | DONE |
| US-010 | Smarter /bundle | P1 | Low | 5m | DONE |
| US-006 | /verify command | P0 | Med | 25m | US-001 |
| US-011 | Split README into README + docs/ | P1 | Low | 20m | None |
| US-012 | PreCompact hook default to block mode | P0 | Low | 10m | None |
| US-008 | Update QUICKSTART, setup-guide, commands-ref | P1 | Low | 20m | All |
| US-HER | Holistic Execution Review | Req | -- | 15m | All |

---

## Cross-Cutting: Shared Data Files

**Rationale (Maintenance review):** Both install scripts duplicate command lists,
version numbers, and hooks config. Extract shared data to single-source files
that both scripts read. This eliminates the #1 maintenance drift risk.

### Create VERSION file at repo root:

**File:** VERSION (NEW)
```
0.2.0
```

Both scripts read from this instead of hardcoding version.

### Dynamic command list:

Instead of hardcoding command names in arrays, both scripts scan
`$TEMPLATES/commands/*.md` and extract basenames. This means adding a new
command to templates/ automatically includes it in install -- no script edits.

### Hooks config shared source:

Hooks event names, matchers, and script filenames are defined in
`templates/hooks/jitneuro-hooks.json`. Both scripts read this to build
the settings.local.json hooks block. The JSON already exists but needs
to be extended with the event-to-script mapping.

**File:** templates/hooks/jitneuro-hooks.json (UPDATE)
```json
{
  "preCompactBehavior": "warn",
  "_options": {
    "warn": "Message injected into context, compaction proceeds.",
    "block": "Compaction blocked (exit 2). User must respond before compaction can proceed."
  },
  "hookEvents": [
    { "event": "PreCompact",  "matcher": "",     "script": "pre-compact-save.sh" },
    { "event": "SessionStart","matcher": "",     "script": "session-start-recovery.sh" },
    { "event": "PreToolUse",  "matcher": "Bash", "script": "branch-protection.sh" },
    { "event": "SessionEnd",  "matcher": "",     "script": "session-end-autosave.sh" }
  ]
}
```

Both install scripts read `hookEvents` array to build settings.local.json.
Adding/removing hooks only requires editing this file -- no script changes.

---

## US-PR-001: Configure GitHub branch protection on main

**Execute on:** main (before branch protection exists)

Use `gh` CLI to configure branch protection on `dstolts/jitneuro`:

```bash
gh api repos/dstolts/jitneuro/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field enforce_admins=false \
  --field required_status_checks=null \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

Note: `enforce_admins=false` is intentional -- Dan (admin) can bypass for
hotfixes. Contributors cannot.

**Pass/Fail:**
- [ ] `gh api repos/dstolts/jitneuro/branches/main/protection` returns protection rules
- [ ] Direct push to main is rejected (test with dummy commit)
- [ ] PR merge to main still works

---

## US-PR-002: Create PR template

**Execute on:** main (before branch protection)
**File:** .github/pull_request_template.md (NEW)

```markdown
## Summary
<!-- 1-3 bullet points describing what this PR does -->

## Test Plan
<!-- How was this tested? -->
- [ ] Tested on bash (Linux/Mac)
- [ ] Tested on PowerShell (Windows)
- [ ] /verify passes after changes

## Checklist
- [ ] Docs updated (if user-facing changes)
- [ ] No secrets or credentials in diff
- [ ] No breaking changes (or documented below)
- [ ] Commit messages follow convention
```

**Pass/Fail:**
- [ ] File exists at .github/pull_request_template.md
- [ ] Template appears when creating PR on GitHub

---

## US-005: Windows bash detection

**File:** install.ps1 (add function near top, after line 21)

**Holistic enhancements applied:**
- Added Scoop and Chocolatey paths (Architect)
- Added `bash --version` validation to filter shims (Reliability)
- WSL detected but explicitly not supported for hooks (Architect + Security)

```powershell
function Find-Bash {
    $candidates = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "$env:USERPROFILE\scoop\apps\git\current\bin\bash.exe",
        "C:\tools\git\bin\bash.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            # Validate it's real bash, not a shim
            try {
                $ver = & $path --version 2>&1 | Select-Object -First 1
                if ($ver -match "GNU bash") {
                    return $path.Replace('\', '/')
                }
            } catch { }
        }
    }
    # Check system PATH
    $pathBash = Get-Command bash -ErrorAction SilentlyContinue
    if ($pathBash) {
        try {
            $ver = & $pathBash.Source --version 2>&1 | Select-Object -First 1
            if ($ver -match "GNU bash") {
                return $pathBash.Source.Replace('\', '/')
            }
        } catch { }
    }
    # WSL detected but not supported for hooks
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        Write-Host "  WSL detected but not supported for JitNeuro hooks (filesystem path mismatch)." -ForegroundColor Yellow
        Write-Host "  Install Git for Windows for full hook support." -ForegroundColor Yellow
    }
    return $null
}
```

Call after directory creation. Store result in `$BashPath`. If null, warn but continue.

**Pass/Fail:**
- [ ] Git Bash at standard path: returns correct path with forward slashes
- [ ] Git Bash at Scoop/Chocolatey path: found correctly
- [ ] Shim/non-GNU-bash in PATH: filtered out (not returned)
- [ ] WSL only: returns null, prints WSL-not-supported message
- [ ] No bash at all: returns null, install continues
- [ ] `bash --version` validates "GNU bash" in output

---

## US-001: Auto-configure hooks in settings.local.json

**Files:** install.ps1, install.sh

**Holistic enhancements applied:**
- Fixed settings.local.json path for all modes (Architect)
- Atomic write via temp file (Reliability)
- When jq missing: SKIP merge, don't overwrite (Security + Reliability)
- Quote all paths in bash heredoc (Security: path injection)
- PowerShell 5.1 compatibility -- no -AsHashtable (Maintenance)
- Tighten hook permissions to 700/500 (Security)
- Add *.backup to .gitignore (Security)
- Detect file locks before writing (Reliability)

### Settings path resolution (CORRECTED per Architect review):

Claude Code resolves settings.local.json from the .claude/ directory level
or from ~/.claude/. The correct paths are:

```
user:      ~/.claude/settings.local.json
workspace: <workspace-root>/settings.local.json  (same level as .claude/)
project:   <project-root>/settings.local.json    (same level as .claude/)
```

### install.ps1 (replace lines 107-153):

```powershell
# Configure hooks in settings.local.json
$BashPath = Find-Bash

# Tighten hook permissions (owner-only execute)
# Note: Windows ACLs don't use chmod but we restrict inheritance
$hooksAcl = Get-Acl (Join-Path $Target "hooks")
$hooksAcl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$hooksAcl.AddAccessRule($rule)
try { Set-Acl (Join-Path $Target "hooks") $hooksAcl } catch {
    Write-Host "  Could not restrict hooks directory permissions (non-fatal)" -ForegroundColor Yellow
}

if (-not $BashPath) {
    Write-Host ""
    Write-Host "WARNING: bash not found. Hooks require bash (Git for Windows recommended)." -ForegroundColor Yellow
    Write-Host "  Slash commands work without bash. Hooks will not." -ForegroundColor Yellow
    Write-Host "  Install Git for Windows: https://git-scm.com/download/win" -ForegroundColor Yellow
} else {
    Write-Host "Found bash: $BashPath" -ForegroundColor Green
    $HooksDir = $Target.Replace('\', '/')

    # Determine settings.local.json location
    switch ($Mode) {
        "user"      { $SettingsPath = Join-Path $env:USERPROFILE ".claude\settings.local.json" }
        "workspace" { $SettingsPath = Join-Path (Split-Path -Parent (Get-Location)) "settings.local.json" }
        "project"   { $SettingsPath = Join-Path (Get-Location) "settings.local.json" }
    }

    # Build hooks config from jitneuro-hooks.json
    $hooksJsonSrc = Join-Path $Target "hooks\jitneuro-hooks.json"
    $hooksDef = Get-Content $hooksJsonSrc -Raw | ConvertFrom-Json

    # Build settings object (PS 5.1 compatible -- no -AsHashtable)
    $hooksBlock = @{}
    foreach ($h in $hooksDef.hookEvents) {
        $cmd = "`"$BashPath`" `"$HooksDir/hooks/$($h.script)`""
        $hooksBlock[$h.event] = @(
            [PSCustomObject]@{
                matcher = $h.matcher
                hooks = @([PSCustomObject]@{ type = "command"; command = $cmd })
            }
        )
    }
    $newConfig = [PSCustomObject]@{ hooks = $hooksBlock }

    # Write or merge settings.local.json
    if (Test-Path $SettingsPath) {
        Copy-Item $SettingsPath "$SettingsPath.backup" -Force
        Write-Host "Backed up existing settings to $SettingsPath.backup" -ForegroundColor Yellow
        try {
            $existing = Get-Content $SettingsPath -Raw | ConvertFrom-Json
            # Add/replace hooks property
            if ($existing.PSObject.Properties['hooks']) {
                $existing.PSObject.Properties.Remove('hooks')
            }
            $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $hooksBlock

            # Atomic write: temp file then rename
            $tempPath = "$SettingsPath.tmp"
            $existing | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempPath -Encoding utf8 -Force
            Move-Item $tempPath $SettingsPath -Force
            Write-Host "Merged hooks config into existing settings" -ForegroundColor Green
        } catch {
            Write-Host "WARNING: Could not parse existing settings.local.json." -ForegroundColor Yellow
            Write-Host "Backup saved at $SettingsPath.backup" -ForegroundColor Yellow
            Write-Host "Writing new settings file with hooks config." -ForegroundColor Yellow
            $tempPath = "$SettingsPath.tmp"
            $newConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempPath -Encoding utf8 -Force
            Move-Item $tempPath $SettingsPath -Force
        }
    } else {
        $tempPath = "$SettingsPath.tmp"
        $newConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempPath -Encoding utf8 -Force
        Move-Item $tempPath $SettingsPath -Force
        Write-Host "Created settings.local.json with hooks config" -ForegroundColor Green
    }
}
```

### install.sh (replace lines 107-151):

```bash
# Tighten hook permissions (owner-only)
chmod 700 "$TARGET/hooks" 2>/dev/null
chmod 500 "$TARGET/hooks/"*.sh 2>/dev/null

# Configure hooks in settings.local.json
BASH_PATH="$(command -v bash 2>/dev/null || true)"
if [ -z "$BASH_PATH" ] || [ ! -x "$BASH_PATH" ]; then
  BASH_PATH="/bin/bash"
fi

# Verify it's GNU bash
if ! "$BASH_PATH" --version 2>/dev/null | grep -q "GNU bash"; then
  echo "WARNING: bash not found or not GNU bash. Hooks may not work."
  echo "  Slash commands work without bash. Hooks will not."
  BASH_PATH=""
fi

if [ -n "$BASH_PATH" ]; then
  echo "Found bash: $BASH_PATH"

  # Determine settings.local.json location
  case "$MODE" in
    user)      SETTINGS_PATH="$HOME/.claude/settings.local.json" ;;
    workspace) SETTINGS_PATH="$(dirname "$(pwd)")/settings.local.json" ;;
    project)   SETTINGS_PATH="$(pwd)/settings.local.json" ;;
  esac

  HOOKS_DIR="$TARGET"

  # Build hooks JSON from jitneuro-hooks.json (quote all paths for spaces)
  # Read hook events from shared config
  if command -v jq &>/dev/null; then
    HOOKS_JSON=$(jq -n \
      --arg bash "$BASH_PATH" \
      --arg dir "$HOOKS_DIR" \
      --slurpfile cfg "$TARGET/hooks/jitneuro-hooks.json" \
      '{hooks: (reduce ($cfg[0].hookEvents[]) as $h ({};
        .[$h.event] = [{
          matcher: $h.matcher,
          hooks: [{ type: "command", command: ("\($bash) \($dir)/hooks/\($h.script)") }]
        }]))}')

    if [ -f "$SETTINGS_PATH" ]; then
      cp "$SETTINGS_PATH" "$SETTINGS_PATH.backup"
      echo "Backed up existing settings to $SETTINGS_PATH.backup"
      # Merge: replace hooks key in existing config
      MERGED=$(jq --argjson hooks "$(echo "$HOOKS_JSON" | jq '.hooks')" \
        '. + {hooks: $hooks}' "$SETTINGS_PATH.backup") || {
        echo "WARNING: Could not parse existing settings.local.json."
        echo "Backup saved. Writing new settings file."
        MERGED="$HOOKS_JSON"
      }
      # Atomic write: temp file then rename
      echo "$MERGED" > "$SETTINGS_PATH.tmp"
      mv "$SETTINGS_PATH.tmp" "$SETTINGS_PATH"
      echo "Merged hooks config into existing settings"
    else
      echo "$HOOKS_JSON" > "$SETTINGS_PATH.tmp"
      mv "$SETTINGS_PATH.tmp" "$SETTINGS_PATH"
      echo "Created settings.local.json with hooks config"
    fi
  else
    # No jq: SKIP merge, do NOT overwrite existing config (Security review)
    if [ -f "$SETTINGS_PATH" ]; then
      echo ""
      echo "WARNING: jq not found. Cannot safely merge hooks into existing settings.local.json."
      echo "  Install jq (https://jqlang.github.io/jq/) and re-run install, OR"
      echo "  manually add hooks config. See templates/hooks/jitneuro-hooks.json for reference."
      echo "  Your existing settings are UNTOUCHED."
    else
      # No existing file -- safe to write hooks-only config without jq
      # Build JSON manually (all paths quoted for spaces/special chars)
      cat > "$SETTINGS_PATH.tmp" <<ENDJSON
{
  "hooks": {
    "PreCompact": [{ "matcher": "", "hooks": [{ "type": "command", "command": "$BASH_PATH $HOOKS_DIR/hooks/pre-compact-save.sh" }] }],
    "SessionStart": [{ "matcher": "", "hooks": [{ "type": "command", "command": "$BASH_PATH $HOOKS_DIR/hooks/session-start-recovery.sh" }] }],
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "$BASH_PATH $HOOKS_DIR/hooks/branch-protection.sh" }] }],
    "SessionEnd": [{ "matcher": "", "hooks": [{ "type": "command", "command": "$BASH_PATH $HOOKS_DIR/hooks/session-end-autosave.sh" }] }]
  }
}
ENDJSON
      mv "$SETTINGS_PATH.tmp" "$SETTINGS_PATH"
      echo "Created settings.local.json with hooks config"
    fi
  fi
fi
```

### Also: Add *.backup to .gitignore

**File:** .gitignore (append)
```
*.backup
```

**Pass/Fail:**
- [ ] Fresh install: settings.local.json created with correct hooks
- [ ] Existing settings: hooks merged, other config preserved, backup created
- [ ] Invalid JSON: backup saved, new file written, warning shown
- [ ] No bash (Windows): warning printed, install completes, commands work
- [ ] No jq + existing settings: SKIP merge, warn, existing file untouched
- [ ] No jq + no existing settings: create hooks-only file
- [ ] All paths quoted in generated JSON (handles spaces in paths)
- [ ] Hook scripts chmod 500, hooks dir chmod 700 (Linux/Mac)
- [ ] Atomic write: temp file then mv (no partial writes)
- [ ] PowerShell 5.1 compatible (no -AsHashtable)
- [ ] Hooks config built from jitneuro-hooks.json (single source of truth)
- [ ] *.backup added to .gitignore
- [ ] After install + restart: all 4 hooks fire correctly

---

## US-002: Backup existing commands before overwrite

**Files:** install.ps1 (lines 53-61), install.sh (lines 60-66)

**Holistic enhancement:** Spec said "timestamped or versioned" but implementation
was flat overwrite. Decision: keep flat `.backup/` (most recent only). Git
handles history. Updated spec to match. Added dynamic command list scan.

### install.ps1 (replace lines 53-61):

```powershell
# Copy commands (backup existing if different, dynamic list from templates)
Write-Host "Installing commands..." -ForegroundColor Green
$backedUp = 0
$cmdFiles = Get-ChildItem (Join-Path $Templates "commands") -Filter "*.md" -File
foreach ($cmdFile in $cmdFiles) {
    $cmd = $cmdFile.BaseName
    $src = $cmdFile.FullName
    $dst = Join-Path $Target "commands\$($cmdFile.Name)"
    if ((Test-Path $dst) -and ((Get-FileHash $src).Hash -ne (Get-FileHash $dst).Hash)) {
        $backupDir = Join-Path $Target "commands\.backup"
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        Copy-Item $dst (Join-Path $backupDir $cmdFile.Name) -Force
        $backedUp++
    }
    Copy-Item $src $dst -Force
    Write-Host "  /$cmd"
}
if ($backedUp -gt 0) {
    Write-Host "  Backed up $backedUp modified commands to commands\.backup\" -ForegroundColor Yellow
}
```

### install.sh (replace lines 60-66):

```bash
# Copy commands (backup existing if different, dynamic list from templates)
echo "Installing commands..."
BACKED_UP=0
for src in "$TEMPLATES"/commands/*.md; do
  [ ! -f "$src" ] && continue
  cmd="$(basename "$src" .md)"
  dst="$TARGET/commands/$(basename "$src")"
  if [ -f "$dst" ] && ! diff -q "$src" "$dst" &>/dev/null; then
    mkdir -p "$TARGET/commands/.backup"
    cp "$dst" "$TARGET/commands/.backup/$(basename "$src")"
    BACKED_UP=$((BACKED_UP + 1))
  fi
  cp "$src" "$dst"
  echo "  /$cmd"
done
if [ "$BACKED_UP" -gt 0 ]; then
  echo "  Backed up $BACKED_UP modified commands to commands/.backup/"
fi
```

**Pass/Fail:**
- [ ] Fresh install: no backup directory created
- [ ] Re-install with unchanged commands: no backup
- [ ] Re-install with user-modified commands: modified files backed up to .backup/
- [ ] Command list is dynamic (no hardcoded array -- scans templates/commands/)
- [ ] Adding new command to templates/ auto-includes it in install
- [ ] Output reports count of backed-up commands

---

## US-003: Post-install workspace repo scan

**Files:** install.ps1, install.sh (add after summary section)

Only runs in workspace mode. Read-only scan -- no git operations.

**Holistic note (Security):** Repo names appear in terminal output and could
be visible in screen-sharing. This is acceptable for a dev tool. Document
in setup-guide.md that scan output shows repo names.

### install.ps1 (add before final "Docs:" line):

```powershell
# Workspace repo scan (workspace mode only)
if ($Mode -eq "workspace") {
    Write-Host ""
    Write-Host "Scanning workspace for repos..." -ForegroundColor Cyan
    $workspaceRoot = Split-Path -Parent (Get-Location)
    $repos = Get-ChildItem $workspaceRoot -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName ".git")) -and
        $_.Name -ne ".claude" -and
        $_.Name -ne "jitneuro"
    }

    if ($repos.Count -gt 0) {
        Write-Host ""
        Write-Host "  Repo                CLAUDE.md  Brainstem  Engram" -ForegroundColor White
        Write-Host "  ----                ---------  ---------  ------" -ForegroundColor DarkGray
        $shown = 0
        foreach ($repo in $repos) {
            if ($shown -ge 30) {
                Write-Host "  ... and $($repos.Count - 30) more repos" -ForegroundColor DarkGray
                break
            }
            $hasClaude = if (Test-Path (Join-Path $repo.FullName "CLAUDE.md")) { "Yes" } else { " - " }
            $hasBrainstem = if (Test-Path (Join-Path $repo.FullName ".claude\CLAUDE.md")) { "Yes" } else { " - " }
            $hasEngram = if (Test-Path (Join-Path $Target "engrams\$($repo.Name)-context.md")) { "Yes" } else { " - " }
            $name = $repo.Name
            if ($name.Length -gt 20) { $name = $name.Substring(0, 17) + "..." }
            $name = $name.PadRight(20)
            Write-Host "  $name $($hasClaude.PadRight(11))$($hasBrainstem.PadRight(11))$hasEngram"
            $shown++
        }
        $missing = $repos | Where-Object {
            -not (Test-Path (Join-Path $_.FullName "CLAUDE.md")) -or
            -not (Test-Path (Join-Path $_.FullName ".claude\CLAUDE.md")) -or
            -not (Test-Path (Join-Path $Target "engrams\$($_.Name)-context.md"))
        }
        if ($missing.Count -gt 0) {
            Write-Host ""
            Write-Host "  Repos needing onboarding: $($missing.Count)" -ForegroundColor Yellow
            Write-Host "  After restarting Claude Code, run: /onboard <repo-path>" -ForegroundColor Yellow
            Write-Host "  Or if context exists on remote: git pull in each repo" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "  All repos have JitNeuro context." -ForegroundColor Green
        }
    }
}
```

### install.sh (add before final "Docs:" line):

```bash
# Workspace repo scan (workspace mode only)
if [ "$MODE" = "workspace" ]; then
  echo ""
  echo "Scanning workspace for repos..."
  WORKSPACE_ROOT="$(dirname "$(pwd)")"
  MISSING_COUNT=0
  SHOWN=0
  TOTAL=0

  printf "\n  %-20s %-11s %-11s %s\n" "Repo" "CLAUDE.md" "Brainstem" "Engram"
  printf "  %-20s %-11s %-11s %s\n" "----" "---------" "---------" "------"

  for dir in "$WORKSPACE_ROOT"/*/; do
    [ ! -d "$dir" ] && continue
    repo_name="$(basename "$dir")"
    [ "$repo_name" = ".claude" ] && continue
    [ "$repo_name" = "jitneuro" ] && continue
    [ ! -d "$dir/.git" ] && continue

    TOTAL=$((TOTAL + 1))
    if [ "$SHOWN" -ge 30 ]; then
      continue  # count but don't print
    fi

    has_claude=" - "
    has_brainstem=" - "
    has_engram=" - "
    needs_work=0

    [ -f "$dir/CLAUDE.md" ] && has_claude="Yes" || needs_work=1
    [ -f "$dir/.claude/CLAUDE.md" ] && has_brainstem="Yes" || needs_work=1
    [ -f "$TARGET/engrams/${repo_name}-context.md" ] && has_engram="Yes" || needs_work=1

    # Truncate long repo names
    display_name="$repo_name"
    if [ ${#display_name} -gt 20 ]; then
      display_name="$(echo "$display_name" | cut -c1-17)..."
    fi

    printf "  %-20s %-11s %-11s %s\n" "$display_name" "$has_claude" "$has_brainstem" "$has_engram"
    SHOWN=$((SHOWN + 1))
    [ "$needs_work" -gt 0 ] && MISSING_COUNT=$((MISSING_COUNT + needs_work))
  done

  if [ "$TOTAL" -gt 30 ]; then
    echo "  ... and $((TOTAL - 30)) more repos"
  fi

  if [ "$MISSING_COUNT" -gt 0 ]; then
    echo ""
    echo "  Repos needing onboarding: $MISSING_COUNT"
    echo "  After restarting Claude Code, run: /onboard <repo-path>"
    echo "  Or if context exists on remote: git pull in each repo"
  elif [ "$TOTAL" -gt 0 ]; then
    echo ""
    echo "  All repos have JitNeuro context."
  fi
fi
```

**Pass/Fail:**
- [ ] Workspace mode: lists all git repos with status table
- [ ] Skips .claude/ and jitneuro directories
- [ ] Non-workspace modes: scan does not run
- [ ] Repos with full context show "Yes" in all columns
- [ ] Repos missing context show " - " and count reported
- [ ] Long repo names truncated (>20 chars)
- [ ] Large workspaces capped at 30 repos displayed ("and N more")
- [ ] Output suggests /onboard or git pull

---

## US-004: Git sync check (SIMPLIFIED -- deferred to /onboard)

**Holistic review decision:** All 4 reviewers flagged `git fetch --dry-run` at
install time as problematic:
- Unreliable (dry-run gives false negatives after recent fetch)
- Triggers auth prompts / SSH passphrase (blocks install)
- `timeout` not on macOS by default
- PowerShell `Start-Job` adds 1-2s overhead per repo
- Credential leakage risk in error output

**Decision:** Remove git fetch from install scripts. The `/onboard` command
(US-009, already updated) handles git sync checking in Claude Code's interactive
context where auth issues can be addressed naturally. Install just shows the
file-based status table (US-003). The /onboard instructions already include:

> Is the repo behind its remote? (git fetch --dry-run -- if CLAUDE.md exists
> on remote but not locally, suggest pulling first.)

This is the right layer for network operations -- interactive, not scripted.

**Install script change:** Add a single line after the repo scan table:

```
Tip: /onboard checks if repos are behind their remote and suggests git pull.
```

**Pass/Fail:**
- [ ] No git fetch in install scripts
- [ ] Tip line printed after repo scan table
- [ ] /onboard handles git sync interactively (verified in US-009)

---

## US-007: Upgrade detection + version file

**Files:** install.ps1, install.sh, VERSION (NEW)

**Holistic enhancements:**
- Single VERSION file at repo root (Maintenance: single source of truth)
- Both scripts read from VERSION file instead of hardcoding
- Write .jitneuro-version LAST (Reliability: signals complete install)
- Detect pre-versioned installs (Reliability: commands exist but no version file)

### Create VERSION file:

**File:** VERSION (NEW)
```
0.2.0
```

### install.sh (add after templates check, before directories):

```bash
# Read version from file
if [ -f "$SCRIPT_DIR/VERSION" ]; then
  JITNEURO_VERSION=$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')
else
  JITNEURO_VERSION="unknown"
fi

VERSION_FILE="$TARGET/.jitneuro-version"
if [ -f "$VERSION_FILE" ]; then
  PREV_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
  if [ "$PREV_VERSION" = "$JITNEURO_VERSION" ]; then
    echo "JitNeuro $JITNEURO_VERSION already installed. Refreshing commands and hooks."
  else
    echo "Upgrading JitNeuro: $PREV_VERSION -> $JITNEURO_VERSION"
  fi
elif [ -d "$TARGET/commands" ] && [ "$(ls "$TARGET/commands/"*.md 2>/dev/null | wc -l)" -gt 5 ]; then
  echo "Upgrading JitNeuro: pre-versioned -> $JITNEURO_VERSION"
else
  echo "Installing JitNeuro $JITNEURO_VERSION"
fi
```

### install.ps1 equivalent:

```powershell
# Read version from file
$VersionFile = Join-Path $ScriptDir "VERSION"
if (Test-Path $VersionFile) {
    $JitNeuroVersion = (Get-Content $VersionFile -Raw).Trim()
} else {
    $JitNeuroVersion = "unknown"
}

$InstalledVersionFile = Join-Path $Target ".jitneuro-version"
if (Test-Path $InstalledVersionFile) {
    $PrevVersion = (Get-Content $InstalledVersionFile -Raw).Trim()
    if ($PrevVersion -eq $JitNeuroVersion) {
        Write-Host "JitNeuro $JitNeuroVersion already installed. Refreshing commands and hooks."
    } else {
        Write-Host "Upgrading JitNeuro: $PrevVersion -> $JitNeuroVersion"
    }
} elseif ((Test-Path (Join-Path $Target "commands")) -and
          (Get-ChildItem (Join-Path $Target "commands") -Filter "*.md" -File).Count -gt 5) {
    Write-Host "Upgrading JitNeuro: pre-versioned -> $JitNeuroVersion"
} else {
    Write-Host "Installing JitNeuro $JitNeuroVersion"
}
```

### Write version LAST (end of both scripts, after all other steps):

```bash
# Write version file LAST (signals complete install)
echo "$JITNEURO_VERSION" > "$VERSION_FILE"
```

```powershell
# Write version file LAST (signals complete install)
$JitNeuroVersion | Set-Content $InstalledVersionFile -Encoding UTF8
```

**Pass/Fail:**
- [ ] VERSION file exists at repo root
- [ ] Both scripts read from VERSION file (not hardcoded)
- [ ] Fresh install: "Installing JitNeuro 0.2.0"
- [ ] Re-install same version: "already installed. Refreshing..."
- [ ] Upgrade: "Upgrading: 0.1.1 -> 0.2.0"
- [ ] Pre-versioned upgrade: "Upgrading: pre-versioned -> 0.2.0"
- [ ] .jitneuro-version written LAST (after all other steps)
- [ ] Interrupted install: no version file = incomplete (detectable by /verify)

---

## US-009: Smarter /onboard (DONE)

templates/commands/onboard.md already updated with:
- No-args workspace scan with status table
- Stale detection + refresh offer
- Git fetch check for remote context (replaces US-004 at install time)
- Bundle creation prompt after onboarding

**Pass/Fail:**
- [ ] Review updated onboard.md -- instructions are clear and complete
- [ ] No broken references to other commands or files

---

## US-010: Smarter /bundle (DONE)

templates/commands/bundle.md already updated with:
- Missing bundle -> offer to create from repo/domain analysis
- No-args -> list with manifest health check
- Refresh and split via natural language
- Auto-update manifest after writes

**Pass/Fail:**
- [ ] Review updated bundle.md -- instructions are clear and complete
- [ ] No broken references to other commands or files

---

## US-006: Post-install verification command (/verify)

**File:** templates/commands/verify.md (NEW)

**Holistic enhancements:**
- Dynamic command count from templates dir, not hardcoded "16+" (Maintenance)
- Validate hook event names match known Claude Code events (Architect)
- Validate bash path in hook commands actually exists (Architect + Reliability)
- Use relative paths in output where possible (Security)
- Add disclaimer: verifies config, not runtime behavior (Reliability)
- Check .jitneuro-version for incomplete install (Reliability)

Create templates/commands/verify.md:

```markdown
# Verify

Check your JitNeuro setup and report what's working, what's missing,
and exactly what to do next.

## When to Use
- Immediately after install to confirm everything worked
- After onboarding repos to verify context is complete
- When something feels broken (commands not loading, hooks not firing)
- On a new machine after cloning and installing

## Instructions

When invoked as `/verify`:

### Run all checks in parallel where possible:

**1. Install Completeness** (GREEN/RED)
- Check `.claude/.jitneuro-version` exists
- RED if missing (install may be incomplete or interrupted -- re-run installer)
- If exists, report version number

**2. Commands** (GREEN/YELLOW)
- Glob `.claude/commands/*.md` and count
- Compare to expected: the jitneuro repo has N command templates in
  `templates/commands/`. If installed count is significantly lower, YELLOW.
- GREEN if count matches or exceeds expected

**3. Hooks (files)** (GREEN/RED)
- Check `.claude/hooks/` for .sh files and jitneuro-hooks.json
- RED if hooks directory missing or empty
- GREEN if 4 scripts + config present

**4. Hooks (config)** (GREEN/YELLOW/RED)
- Search for settings.local.json in these locations (check all):
  - `./settings.local.json` (project level)
  - `../settings.local.json` (workspace level)
  - `~/.claude/settings.local.json` (user level)
- RED if no settings file found with "hooks" key
- If found, parse and validate:
  - Check hook event names are valid Claude Code events
    (PreCompact, SessionStart, PreToolUse, PostToolUse, SessionEnd, SubagentStart, SubagentEnd)
  - Check that each hook command references a script that EXISTS on disk
  - YELLOW if some hooks missing or script paths broken
  - GREEN if all 4 hooks registered with valid script paths

**5. Bundles** (GREEN/YELLOW)
- Glob `.claude/bundles/*.md`
- YELLOW if only example.md (no real bundles yet -- run /bundle <name>)
- GREEN if at least 1 non-example bundle
- WARN on any bundle over 80 lines

**6. Engrams** (GREEN/YELLOW)
- Glob `.claude/engrams/*.md`
- YELLOW if only example.md/README.md (no real engrams)
- GREEN if at least 1 project engram

**7. Context Manifest** (GREEN/YELLOW/RED)
- Check `.claude/context-manifest.md` exists
- RED if missing
- If exists: check that listed bundles actually exist as files
- YELLOW if manifest references bundles that don't exist, or bundles exist with no manifest entry

**8. Current Repo** (GREEN/YELLOW)
- Check `./CLAUDE.md` exists
- Check `./.claude/CLAUDE.md` brainstem exists
- YELLOW if either missing (suggest /onboard)

**9. MEMORY.md** (GREEN/YELLOW)
- Check auto-memory MEMORY.md exists
- YELLOW if missing or has no routing weights

### Present results:

Use relative paths in output (not full absolute paths).

```
JitNeuro v0.2.0 -- Setup Verification
| Component         | Status | Detail                           |
|-------------------|--------|----------------------------------|
| Install           | GREEN  | v0.2.0 complete                  |
| Commands          | GREEN  | 16 installed                     |
| Hooks (files)     | GREEN  | 4 scripts + config               |
| Hooks (config)    | RED    | No settings.local.json found     |
| Bundles           | YELLOW | Only example.md (run /bundle)    |
| Engrams           | GREEN  | 3 project engrams                |
| Manifest          | GREEN  | 5 bundles listed, all exist      |
| Current repo      | YELLOW | No CLAUDE.md (run /onboard)      |
| MEMORY.md         | GREEN  | Routing weights present          |

Next steps:
1. [First RED item with specific fix]
2. [First YELLOW item with specific fix]
```

### If everything is GREEN:
```
JitNeuro v0.2.0 verified. All systems operational.
Tip: Run /save to test hooks are firing.
```

## Important
- This is READ-ONLY. Never modifies any files.
- Check ACTUAL files, not assumptions about what install created.
- Check ALL settings.local.json locations if install mode is unknown.
- This verifies CONFIGURATION, not runtime behavior. Suggest running
  /save to functionally test that hooks fire.
- Use relative paths in output to avoid leaking filesystem structure.
```

**Pass/Fail:**
- [ ] File created at templates/commands/verify.md
- [ ] verify included in install (dynamic scan picks it up automatically)
- [ ] Checks all 9 components listed above
- [ ] RED/YELLOW/GREEN status with specific fix instructions
- [ ] Validates hook event names against known Claude Code events
- [ ] Validates hook script paths exist on disk
- [ ] Checks .jitneuro-version for install completeness
- [ ] Uses relative paths in output (no full system paths)
- [ ] Suggests /save to functionally test hooks
- [ ] Read-only (no file modifications)

---

## US-011: Split README.md into README + docs/

**Files:** README.md (REWRITE), docs/concepts.md (NEW), docs/architecture.md (NEW)

README.md is 439 lines -- too long for a GitHub landing page. Most visitors
scan the first screen and bounce. Split into a ~200-line overview with links
to deep dives in docs/.

### What stays in README.md (~200 lines):

- Problem / Solution (lines 1-32) -- KEEP as-is (first impression)
- Architecture diagram (lines 34-52) -- KEEP as-is (visual anchor)
- How It Works: Context Cycle (lines 70-96) -- KEEP, trim to ~15 lines
- Automated / Subagents (lines 98-108) -- KEEP (key differentiator)
- File Structure (lines 134-177) -- KEEP, trim tree example slightly
- Quick Start (lines 179-210) -- KEEP as-is
- What's Included (lines 212-220) -- KEEP as-is
- Key Concepts -- REPLACE 140 lines with 6-line summary + link:

```markdown
## Key Concepts

- **[Context Bundles](docs/concepts.md#context-bundles)** -- modular knowledge loaded on-demand (50-80 lines each)
- **[Engrams](docs/concepts.md#engrams)** -- per-project deep context, strengthened by /learn
- **[Routing Weights](docs/concepts.md#routing-weights)** -- learned bundle co-activation patterns
- **[Compact Instructions](docs/concepts.md#compact-instructions)** -- control what auto-compaction preserves
- **[Rule of Lowest Context](docs/concepts.md#rule-of-lowest-context)** -- store context at the lowest level possible

See [Concepts Guide](docs/concepts.md) for detailed explanations, examples, and context budget analysis.
```

- Roadmap (lines 395-420) -- KEEP, trim slightly
- Disclaimer / License / Author (lines 422-439) -- KEEP as-is

### What moves to docs/concepts.md (NEW):

All Key Concepts subsections with full detail:
- Context Bundles (full explanation)
- Engrams (full explanation, bundles vs engrams comparison)
- Routing Weights (with code example)
- Conversation Logging (full spec, toggle commands, file format)
- Compact Instructions (with example)
- Rule of Lowest Context (with layered test coverage example)
- Context Budget section (tables, size limits)

Add anchor IDs for deep linking from README:
```markdown
## Context Bundles
## Engrams
## Routing Weights
## Conversation Logging
## Compact Instructions
## Rule of Lowest Context
## Context Budget
```

### What moves to docs/architecture.md (NEW):

- Neural Network Mapping table (lines 54-69)
- Claude Code Primitives Used table (lines 364-378)
- Lineage / evolution table (lines 380-393)

### Template for docs/concepts.md:

```markdown
# JitNeuro Concepts

Detailed explanations of JitNeuro's core concepts. For a quick overview,
see the [README](../README.md#key-concepts).

## Context Bundles
[full content from README lines 224-231]

## Engrams
[full content from README lines 233-247]

## Routing Weights
[full content from README lines 249-255]

## Conversation Logging
[full content from README lines 257-263 + lines 110-132]

## Compact Instructions
[full content from README lines 265-275]

## Rule of Lowest Context
[full content from README lines 277-318]

## Context Budget
[full content from README lines 320-361]
```

### Template for docs/architecture.md:

```markdown
# JitNeuro Architecture

Technical details on how JitNeuro maps to neural network concepts and
uses Claude Code primitives. For the high-level view, see the
[README](../README.md#architecture).

## Neural Network Mapping
[table from README lines 54-69]

## Claude Code Primitives Used
[table from README lines 364-378]

## Evolution
[table from README lines 380-393]
```

### Execution:

1. Create docs/concepts.md with full content from README sections
2. Create docs/architecture.md with tables from README
3. Rewrite README.md: keep overview sections, replace deep dives with links
4. Verify all internal links work (relative paths)
5. Verify no content lost (all moved, none deleted)

**Pass/Fail:**
- [ ] README.md under 220 lines
- [ ] docs/concepts.md exists with all 7 concept sections
- [ ] docs/architecture.md exists with neural mapping, primitives, lineage
- [ ] Key Concepts in README is 6-line summary with working links
- [ ] No content deleted (all moved to docs/)
- [ ] All relative links work (../README.md, docs/concepts.md#anchor)
- [ ] Quick Start, Architecture diagram, Roadmap remain in README
- [ ] docs/concepts.md has anchor IDs matching README links

---

## US-012: PreCompact hook default to block mode

**Files:** templates/hooks/jitneuro-hooks.json, docs/hooks-guide.md, templates/commands/verify.md

**Problem:** PreCompact hook in "warn" mode (exit 0) injects a message asking
Claude to offer /save before compaction. But Claude can ignore the injected
message under context pressure -- which is exactly when it matters most. Result:
silent context loss with no checkpoint. This happened in production (session 5->6
of jitneuro-launch).

**Fix:** Change default to "block" mode (exit 2). Block mode halts compaction
entirely until the user responds. Users who prefer warn mode can switch back
in jitneuro-hooks.json.

### templates/hooks/jitneuro-hooks.json (ALREADY DONE):

```json
{
  "preCompactBehavior": "block",
  "_options": {
    "warn": "Message injected into context, compaction proceeds. Claude asks user about /save.",
    "block": "Compaction blocked (exit 2). User must respond before compaction can proceed."
  },
  "_doc": "Config for JitNeuro hooks. Edit behavior values to change how hooks respond."
}
```

### docs/hooks-guide.md (UPDATE):

Add a section explaining block vs warn:

```markdown
### PreCompact Behavior Modes

The PreCompact hook has two modes, configured in `.claude/hooks/jitneuro-hooks.json`:

**block (default, recommended):** Compaction is halted (exit 2). Claude cannot
proceed until you decide whether to /save. This prevents silent context loss
but means you must respond before work continues.

**warn:** A message is injected into Claude's context asking it to offer /save.
Compaction proceeds immediately. Claude *should* ask you about saving, but may
not under heavy context pressure -- which is exactly when saves matter most.

To switch modes, edit `preCompactBehavior` in `.claude/hooks/jitneuro-hooks.json`.
```

### templates/commands/verify.md (UPDATE):

Add to hooks config check: if preCompactBehavior is "warn", show YELLOW with
note: "PreCompact set to warn mode -- block mode recommended to prevent silent
context loss."

**Pass/Fail:**
- [ ] templates/hooks/jitneuro-hooks.json default is "block"
- [ ] docs/hooks-guide.md documents both modes with tradeoffs
- [ ] /verify warns (YELLOW) if preCompactBehavior is "warn"
- [ ] Fresh install gets block mode
- [ ] Existing users: re-install overwrites jitneuro-hooks.json (install scripts copy templates)

---

## US-008: Update QUICKSTART.md and setup-guide.md

**Files:** QUICKSTART.md, docs/setup-guide.md, docs/commands-reference.md

### QUICKSTART.md changes:

Replace current content with streamlined 4-step flow:
1. Clone jitneuro
2. Run install (pick mode)
3. Restart Claude Code
4. Run /verify

Remove manual hooks config step (now automated).
Remove the 5-step "Next steps" list (replaced by /verify guidance).

### docs/setup-guide.md changes:

Add scenario sections matching the spec:
- Fresh install (no existing repos)
- Multi-machine setup (repos exist but behind)
- Existing repos without JitNeuro context
- Upgrading from previous version
- Windows-specific notes:
  - Hooks require GNU bash (Git for Windows recommended)
  - WSL bash not supported for hooks (filesystem path mismatch)
  - PowerShell 5.1+ required for installer
- Note: repo scan output shows repo names (visible in terminal)
- Troubleshooting FAQ:
  - "Commands not loading" -> restart Claude Code
  - "Hooks not firing" -> run /verify, check settings.local.json
  - "bash not found" (Windows) -> install Git for Windows
  - "/onboard says repo is stale" -> git pull or accept refresh
  - "jq not found" -> install jq for settings merge, or manually configure
  - "Install interrupted" -> re-run installer (idempotent)
### docs/commands-reference.md changes:

Update entries for all commands modified in this sprint:
- /bundle: add create, refresh, split, manifest sync capabilities
- /onboard: add no-args scan, refresh, git-aware, bundle prompt
- /verify: NEW command entry

**Pass/Fail:**
- [ ] QUICKSTART is 4 steps max (clone, install, restart, verify)
- [ ] No reference to manual hooks config
- [ ] Setup guide covers all 4 onboarding scenarios
- [ ] Windows section with bash + PowerShell notes
- [ ] Troubleshooting FAQ with 6+ common issues
- [ ] Note about repo names visible in scan output
- [ ] commands-reference.md updated for /bundle, /onboard, /verify

---

## US-HER: Holistic Execution Review

Post-execution validation from 4 personas.

**Pass/Fail:**
- [ ] All story ACs validated
- [ ] No dead code introduced
- [ ] No spec deviations flagged
- [ ] Install tested: fresh install on bash
- [ ] Install tested: fresh install on PowerShell
- [ ] Install tested: re-install (upgrade path)
- [ ] Install tested: interrupted install leaves no version file
- [ ] /verify tested: missing components detected correctly
- [ ] /verify tested: broken hook paths flagged
- [ ] /onboard tested: no-args scan works
- [ ] /bundle tested: missing bundle creation flow works
- [ ] Hooks config built from jitneuro-hooks.json (single source of truth)
- [ ] Command list dynamic (no hardcoded arrays in install scripts)
- [ ] Version read from VERSION file (single source of truth)
- [ ] All docs updated: setup-guide, commands-reference, QUICKSTART

---

## Execution Order

1. US-PR-001 + US-PR-002 (on main, before protection)
2. Create branch: sprint-jitneuro-onboarding-001
3. Cross-cutting: Create VERSION file, update jitneuro-hooks.json
4. US-005 (Windows bash detection -- needed by US-001)
5. US-001 (auto-configure hooks -- biggest impact)
6. US-002 (command backup with dynamic list -- safety)
7. US-003 (workspace repo scan)
8. US-004 (add tip line to scan output -- trivial)
9. US-007 (version tracking -- reads VERSION file)
10. US-009 + US-010 (commit already-updated command files)
11. US-006 (create /verify command)
12. US-011 (split README into README + docs/ -- can run parallel with US-006)
13. US-012 (PreCompact hook default to block mode -- can run parallel)
14. US-008 (update ALL docs last -- reflects final state)
15. US-HER (holistic review)
16. PR to main

## Pass Criteria
- All P0 stories complete (US-001, US-003, US-006)
- Install scripts work on both bash and PowerShell
- /verify reports accurate status on fresh and existing installs
- No manual hooks config step required
- No hardcoded command lists or version numbers in install scripts
- Hooks config derived from jitneuro-hooks.json
- All docs reflect final state (setup-guide, commands-reference, QUICKSTART)
- Atomic writes on all JSON file operations
