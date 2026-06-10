# JitNeuro Installer (PowerShell)
# Usage: .\install.ps1 [-Mode workspace|project|user]
#
# workspace  Install to parent directory's .claude\ (covers all repos under it)
# project    Install to current directory's .claude\ (single repo)
# user       Install to ~\.claude\ (available on entire machine)

param(
    [ValidateSet("workspace", "project", "user")]
    [string]$Mode = "project",
    [switch]$Reconfigure
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Templates = Join-Path $ScriptDir "templates"

if (-not (Test-Path $Templates)) {
    Write-Error "templates\ directory not found at $Templates. Run this script from the jitneuro repo root."
    exit 1
}

# Read version from jitneuro.json
$Version = "unknown"
$ConfigFile = Join-Path $Templates "jitneuro.json"
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    $Version = $config.version
}

$WorkspaceRoot = ""
switch ($Mode) {
    "workspace" {
        $Target = Join-Path (Split-Path -Parent (Get-Location)) ".claude"
        $WorkspaceRoot = Split-Path -Parent (Get-Location)
        Write-Host "Installing JitNeuro v$Version at WORKSPACE level: $Target" -ForegroundColor Cyan
        Write-Host "Commands will be available to all repos under $WorkspaceRoot"
    }
    "project" {
        $Target = Join-Path (Get-Location) ".claude"
        Write-Host "Installing JitNeuro v$Version at PROJECT level: $Target" -ForegroundColor Cyan
        Write-Host "Commands will be available in this repo only."
    }
    "user" {
        $Target = Join-Path $env:USERPROFILE ".claude"
        Write-Host "Installing JitNeuro v$Version at USER level: $Target" -ForegroundColor Cyan
        Write-Host "Commands will be available in all projects on this machine."
    }
}

Write-Host ""

# --- Upgrade detection (US-007) ---
$InstalledConfig = Join-Path $Target "jitneuro.json"
$PrevVersion = ""
if (Test-Path $InstalledConfig) {
    try {
        $prev = Get-Content $InstalledConfig -Raw | ConvertFrom-Json
        $PrevVersion = $prev.version
    } catch { }
}
if ($PrevVersion) {
    if ($PrevVersion -eq $Version) {
        Write-Host "Re-installing JitNeuro v$Version (same version)"
    } else {
        Write-Host "Upgrading JitNeuro: v$PrevVersion -> v$Version"
    }
} elseif ((Test-Path (Join-Path $Target "commands")) -and (Get-ChildItem (Join-Path $Target "commands") -File -ErrorAction SilentlyContinue).Count -gt 0) {
    Write-Host "Upgrading from pre-versioned JitNeuro install"
} else {
    Write-Host "Fresh install"
}
Write-Host ""

# --- Upgrade-safe framework manifest (separates framework files from user files) ---
# Records every FRAMEWORK-owned file (path + sha256). On upgrade we prune framework files
# the new version dropped and back up any framework file the user edited -- and never touch
# a file that is not in the manifest (= the user's own).
$Manifest = Join-Path $Target ".jitneuro-manifest.tsv"
$OldManifest = @{}
if (Test-Path $Manifest) {
    foreach ($line in (Get-Content $Manifest)) {
        if ($line -match '^\s*#') { continue }
        $parts = $line -split "`t", 2
        if ($parts.Count -eq 2) { $OldManifest[$parts[0]] = $parts[1] }
    }
}
$NewManifest = [System.Collections.Generic.List[string]]::new()
function Get-JnSha($p) { if (Test-Path $p) { (Get-FileHash $p -Algorithm SHA256).Hash.ToLower() } else { "" } }
function Add-JnManifest($rel) {
    $f = Join-Path $Target $rel
    if (Test-Path $f) { $NewManifest.Add("$rel`t$(Get-JnSha $f)") }
}

# Patch the installed jitneuro.json "knowledgeRoot" value (preserves file formatting).
function Set-KnowledgeRoot($v) {
    $jf = Join-Path $Target "jitneuro.json"
    if (-not (Test-Path $jf)) { return }
    $raw = Get-Content $jf -Raw
    # JSON-escape backslashes and quotes in the value.
    $jsonVal = ($v -replace '\\', '\\') -replace '"', '\"'
    # Escape any literal $ for the regex replacement string ($$ = literal $ in -replace).
    $repl = '$1"' + ($jsonVal -replace '\$', '$$$$') + '"'
    $raw = [regex]::Replace($raw, '("knowledgeRoot"\s*:\s*)"[^"]*"', $repl)
    Set-Content -Path $jf -Value $raw -Encoding UTF8 -NoNewline
}

# Prompt for the shared knowledge catalog location and persist the choice.
# Resolution at runtime: JITNEURO_KNOWLEDGE_ROOT env -> url-resolver map -> this value
# -> .\.knowledge if present -> unset (standalone). Empty = standalone.
function Configure-KnowledgeRoot {
    $kr = $script:PrevKr
    if ($env:JITNEURO_KNOWLEDGE_ROOT) { $kr = $env:JITNEURO_KNOWLEDGE_ROOT }
    if ($kr -and -not $Reconfigure) {
        Write-Host "Knowledge catalog: $kr (re-run with -Reconfigure to change)"
        Set-KnowledgeRoot $kr
        return
    }
    if (-not [Environment]::UserInteractive -and -not $Reconfigure) {
        Write-Host "Knowledge catalog: standalone (no shared catalog). Set JITNEURO_KNOWLEDGE_ROOT or re-run with -Reconfigure to configure." -ForegroundColor Yellow
        Set-KnowledgeRoot ""
        return
    }
    Write-Host ""
    Write-Host "Where should JitNeuro find your shared knowledge catalog?"
    Write-Host "  1) A separate repo / folder elsewhere (recommended -- most common)"
    Write-Host "  2) In this repo, in a .knowledge\ folder"
    Write-Host "  3) Personal: ~\.claude\.knowledge"
    Write-Host "  4) None -- run standalone (no shared catalog)"
    $choice = Read-Host "Choice [1-4, default 4]"
    switch ($choice) {
        "1" { $kr = Read-Host "Absolute path to the catalog repo/folder" }
        "2" {
            $kr = "./.knowledge"
            $d = Join-Path (Split-Path $Target -Parent) ".knowledge"
            if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        }
        "3" {
            $kr = Join-Path $env:USERPROFILE ".claude\.knowledge"
            if (-not (Test-Path $kr)) { New-Item -ItemType Directory -Path $kr -Force | Out-Null }
        }
        default { $kr = "" }
    }
    Set-KnowledgeRoot $kr
    if ($kr) {
        Write-Host "Knowledge catalog set to: $kr"
        Write-Host "Tip: set JITNEURO_KNOWLEDGE_ROOT=$kr to override per-machine without editing config."
    } else {
        Write-Host "Knowledge catalog: standalone (no shared catalog)."
    }
}

# Create directories
$dirs = @("commands", "bundles", "engrams", "session-state", "session-state\heartbeats", "rules", "hooks", "cognition", "cognition\decisions", "scripts", "dashboard\runs", "horizon")
foreach ($dir in $dirs) {
    $path = Join-Path $Target $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# --- Backup existing commands before overwrite (US-002) ---
$BackupCount = 0
$BackupDir = Join-Path $Target "commands\.backup"
$cmdTemplates = Get-ChildItem (Join-Path $Templates "commands") -Filter "*.md" -File -ErrorAction SilentlyContinue
foreach ($cmdFile in $cmdTemplates) {
    $existing = Join-Path $Target "commands\$($cmdFile.Name)"
    if (Test-Path $existing) {
        $srcHash = (Get-FileHash $cmdFile.FullName -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $existing -Algorithm MD5).Hash
        if ($srcHash -ne $dstHash) {
            if (-not (Test-Path $BackupDir)) {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            }
            Copy-Item $existing (Join-Path $BackupDir $cmdFile.Name) -Force
            $BackupCount++
        }
    }
}
if ($BackupCount -gt 0) {
    Write-Host "Backed up $BackupCount existing commands to commands\.backup\"
}

# --- Install commands (dynamic scan) ---
Write-Host "Installing commands..." -ForegroundColor Green
$CmdCount = 0
foreach ($cmdFile in $cmdTemplates) {
    $cmdName = $cmdFile.BaseName
    Copy-Item $cmdFile.FullName (Join-Path $Target "commands\$($cmdFile.Name)") -Force
    Write-Host "  /$cmdName"
    $CmdCount++
}
Write-Host "  ($CmdCount commands installed)"

# Routing lives in your configured knowledge catalog's INDEX.md (when one is configured)
# -- do NOT seed context-manifest.md with routing tables.
# If a stale context-manifest.md exists from a prior install, leave it untouched (do not overwrite or delete).
$staleManifest = Join-Path $Target "context-manifest.md"
if (Test-Path $staleManifest) {
    Write-Host "NOTE: Legacy context-manifest.md found at $staleManifest" -ForegroundColor Yellow
    Write-Host "      Routing now lives in your knowledge catalog's INDEX.md. You may retire context-manifest.md." -ForegroundColor Yellow
}

# Scaffold url-resolver.md in user home .claude (machine-specific, gitignored)
$UserClaude = Join-Path $env:USERPROFILE ".claude"
$UrlResolver = Join-Path $UserClaude "url-resolver.md"
if (-not (Test-Path $UrlResolver)) {
    if (-not (Test-Path $UserClaude)) { New-Item -ItemType Directory -Path $UserClaude -Force | Out-Null }
    Copy-Item (Join-Path $Templates "url-resolver.md") $UrlResolver
    Write-Host "Created ~/.claude/url-resolver.md -- map your repo names to local paths (optional)"
} else {
    Write-Host "Skipped url-resolver.md (already exists)" -ForegroundColor Yellow
}

# Copy example bundle if empty
$bundlesDir = Join-Path $Target "bundles"
if ((Get-ChildItem $bundlesDir -File -ErrorAction SilentlyContinue).Count -eq 0) {
    Copy-Item (Join-Path $Templates "bundles\example.md") (Join-Path $bundlesDir "example.md")
    Write-Host "Created bundles\example.md (template)"
} else {
    Write-Host "Skipped bundles\ (already has files)" -ForegroundColor Yellow
}

# Copy example engram if empty
$engramsDir = Join-Path $Target "engrams"
if ((Get-ChildItem $engramsDir -File -ErrorAction SilentlyContinue).Count -eq 0) {
    Copy-Item (Join-Path $Templates "engrams\example.md") (Join-Path $engramsDir "example.md")
    Copy-Item (Join-Path $Templates "engrams\README.md") (Join-Path $engramsDir "README.md")
    Write-Host "Created engrams\example.md (template)"
} else {
    Write-Host "Skipped engrams\ (already has files)" -ForegroundColor Yellow
}

# Copy session-state README
$ssReadme = Join-Path $Target "session-state\README.md"
if (-not (Test-Path $ssReadme)) {
    Copy-Item (Join-Path $Templates "session-state\README.md") $ssReadme
    Write-Host "Created session-state\README.md"
}

# Install rule templates (respect DISABLED marker) -- parity with install.sh:
# install ALL framework rules, skip user-DISABLED, update only on diff.
Write-Host "Installing rule templates..." -ForegroundColor Green
$rulesDir = Join-Path $Target "rules"
$ruleCount = 0
$ruleSkip = 0
foreach ($ruleFile in (Get-ChildItem (Join-Path $Templates "rules") -Filter *.md -File -ErrorAction SilentlyContinue)) {
    $targetRule = Join-Path $rulesDir $ruleFile.Name
    if (Test-Path $targetRule) {
        $firstLine = Get-Content $targetRule -TotalCount 1 -ErrorAction SilentlyContinue
        if ($firstLine -match '\(DISABLED\)') {
            Write-Host "  SKIP: $($ruleFile.Name) (disabled by user)"
            $ruleSkip++
            continue
        }
        if ((Get-FileHash $ruleFile.FullName).Hash -ne (Get-FileHash $targetRule).Hash) {
            # If the user edited this framework rule since last install, preserve their copy.
            $rel = "rules/$($ruleFile.Name)"
            if ($OldManifest.ContainsKey($rel) -and $OldManifest[$rel] -ne (Get-JnSha $targetRule)) {
                $bdir = Join-Path $Target ".jitneuro-backup\rules"
                if (-not (Test-Path $bdir)) { New-Item -ItemType Directory -Path $bdir -Force | Out-Null }
                Copy-Item $targetRule (Join-Path $bdir $ruleFile.Name) -Force
                Write-Host "  BACKUP: rules/$($ruleFile.Name) (your edit saved to .jitneuro-backup\rules\)"
            }
            Copy-Item $ruleFile.FullName $targetRule -Force
            Write-Host "  UPDATED: $($ruleFile.Name)"
            $ruleCount++
        }
    } else {
        Copy-Item $ruleFile.FullName $targetRule
        Write-Host "  $($ruleFile.Name)"
        $ruleCount++
    }
}
Write-Host "  ($ruleCount rules installed, $ruleSkip disabled/skipped)"

# Install horizon templates (strategic-context placeholders).
# Seed ONLY if empty -- never overwrite an adopter's filled-in horizon on re-run.
$horizonDir = Join-Path $Target "horizon"
if ((Get-ChildItem $horizonDir -File -ErrorAction SilentlyContinue).Count -eq 0) {
    Copy-Item (Join-Path $Templates "horizon\*.md") $horizonDir
    $horizonN = (Get-ChildItem $horizonDir -Filter *.md -File).Count
    Write-Host "Installing horizon templates..." -ForegroundColor Green
    Write-Host "  horizon\ ($horizonN placeholders -- fill in via horizon\POPULATE-HORIZON.md)"
} else {
    Write-Host "Skipped horizon\ (already has files)" -ForegroundColor Yellow
}

# Install cognition layer (Phase 2)
Write-Host "Installing cognition layer..." -ForegroundColor Green
$cogDir = Join-Path $Target "cognition"
$cogDecDir = Join-Path $cogDir "decisions"
foreach ($f in (Get-ChildItem (Join-Path $Templates "cognition") -Filter "*.md" -File -ErrorAction SilentlyContinue)) {
    Copy-Item $f.FullName (Join-Path $cogDir $f.Name) -Force
}
foreach ($f in (Get-ChildItem (Join-Path $Templates "cognition\decisions") -Filter "*.md" -File -ErrorAction SilentlyContinue)) {
    Copy-Item $f.FullName (Join-Path $cogDecDir $f.Name) -Force
}
Write-Host "  cognition\personas.md (16 personas)"
Write-Host "  cognition\friction-detection.md"
Write-Host "  cognition\anti-patterns.md (seed entries)"
$decCount = (Get-ChildItem (Join-Path $Templates "cognition\decisions") -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
Write-Host "  cognition\decisions\ ($decCount models)"
$ownerPersona = Join-Path $cogDir "owner-persona.md"
if (-not (Test-Path $ownerPersona)) {
    Copy-Item (Join-Path $Templates "cognition\owner-persona.example.md") $ownerPersona
    Write-Host "  cognition\owner-persona.md (created from template -- customize this)"
} else {
    Write-Host "  Skipped owner-persona.md (already exists)" -ForegroundColor Yellow
}

# Install scripts
Write-Host "Installing scripts..." -ForegroundColor Green
$scriptsDir = Join-Path $Target "scripts"
foreach ($f in (Get-ChildItem (Join-Path $Templates "scripts") -Filter "*.sh" -File -ErrorAction SilentlyContinue)) {
    Copy-Item $f.FullName (Join-Path $scriptsDir $f.Name) -Force
    Write-Host "  scripts\$($f.Name)"
}

# Install dashboard
Write-Host "Installing dashboard..." -ForegroundColor Green
$dashDir = Join-Path $Target "dashboard"
foreach ($ext in @("*.html", "*.js")) {
    foreach ($f in (Get-ChildItem (Join-Path $Templates "dashboard") -Filter $ext -File -ErrorAction SilentlyContinue)) {
        Copy-Item $f.FullName (Join-Path $dashDir $f.Name) -Force
        Write-Host "  dashboard\$($f.Name)"
    }
}
$dashBinSrc = Join-Path $Templates "dashboard\bin"
if (Test-Path $dashBinSrc) {
    $dashBinDir = Join-Path $dashDir "bin"
    if (-not (Test-Path $dashBinDir)) { New-Item -ItemType Directory -Path $dashBinDir -Force | Out-Null }
    foreach ($f in (Get-ChildItem $dashBinSrc -File -ErrorAction SilentlyContinue)) {
        Copy-Item $f.FullName (Join-Path $dashBinDir $f.Name) -Force
    }
    Write-Host "  dashboard\bin\ (launcher scripts)"
}

# Install hooks
Write-Host "Installing hooks..." -ForegroundColor Green
$hookFiles = Get-ChildItem (Join-Path $Templates "hooks") -Filter "*.sh" -File -ErrorAction SilentlyContinue
$hooksDir = Join-Path $Target "hooks"
foreach ($hook in $hookFiles) {
    Copy-Item $hook.FullName (Join-Path $hooksDir $hook.Name) -Force
    Write-Host "  hooks\$($hook.Name)"
}

# --- Copy jitneuro.json config ---
# Preserve a previously configured knowledge catalog root across re-installs.
$script:PrevKr = ""
$installedJson = Join-Path $Target "jitneuro.json"
if (Test-Path $installedJson) {
    try { $script:PrevKr = (Get-Content $installedJson -Raw | ConvertFrom-Json).knowledgeRoot } catch { }
}
Copy-Item $ConfigFile (Join-Path $Target "jitneuro.json") -Force
Write-Host "Installed jitneuro.json (v$Version)"

# --- Configure shared knowledge catalog location (prompt / preserve / standalone) ---
Configure-KnowledgeRoot

# --- Windows bash detection (US-005) ---
Write-Host ""
Write-Host "Detecting bash..." -ForegroundColor Green
$BashPath = ""
$BashSearchPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "${env:LOCALAPPDATA}\Programs\Git\bin\bash.exe",
    "${env:USERPROFILE}\scoop\shims\bash.exe",
    "C:\tools\git\bin\bash.exe",
    "C:\ProgramData\chocolatey\bin\bash.exe"
)

foreach ($path in $BashSearchPaths) {
    if (Test-Path $path) {
        # Validate it's GNU bash (not a shim)
        try {
            $versionOutput = & $path --version 2>&1 | Select-Object -First 1
            if ($versionOutput -match "GNU bash") {
                $BashPath = $path
                break
            }
        } catch { }
    }
}

# Check WSL
$WslBash = ""
if (-not $BashPath) {
    try {
        $wslCheck = & wsl.exe --list 2>&1
        if ($LASTEXITCODE -eq 0) {
            $WslBash = "wsl"
        }
    } catch { }
}

if ($BashPath) {
    # Convert to forward slashes for hooks config
    $BashPathFwd = $BashPath -replace '\\', '/'
    Write-Host "  Found: $BashPath" -ForegroundColor Green
    Write-Host "  Version: $versionOutput"
} elseif ($WslBash) {
    Write-Host "  WSL detected but NOT supported for hooks." -ForegroundColor Yellow
    Write-Host "  Install Git for Windows for bash: https://git-scm.com/downloads/win" -ForegroundColor Yellow
    $BashPathFwd = "bash"
} else {
    Write-Host "  WARNING: bash not found." -ForegroundColor Yellow
    Write-Host "  Hooks require bash. Install Git for Windows: https://git-scm.com/downloads/win" -ForegroundColor Yellow
    Write-Host "  Commands will work without bash; hooks will not." -ForegroundColor Yellow
    $BashPathFwd = "bash"
}

# --- Auto-configure hooks in settings.local.json (US-001) ---
Write-Host ""
Write-Host "Configuring hooks..." -ForegroundColor Green
$SettingsFile = Join-Path $Target "settings.local.json"
$HooksPathFwd = ($hooksDir -replace '\\', '/')

# ============================================================================
# HOW TO WRITE A HOOK COMMAND -- read before editing the entries below
# ----------------------------------------------------------------------------
# Claude Code runs each hook `command` through its OWN shell. The `command`
# value MUST be a bare script path and nothing else, for example:
#       command = "$HooksPathFwd/heartbeat.sh"
#
# NEVER prefix it with bash, bash.exe, or any shell binary. A prefix makes the
# shell try to run bash as bash's own script argument, so EVERY hook then
# fails at runtime with:
#       bash.exe: bash.exe: cannot execute binary file
#
# When adding or changing a hook below, look at the other hook entries in this
# same block and match their format exactly -- each command is just a path.
# Full rule: rules/claude-code-hook-deployment.md (installed with JitNeuro)
# ============================================================================
# Build hooks config object
$hooksConfig = @{
    hooks = @{
        PreCompact = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/pre-compact-save.sh"; timeout = 10 }
                )
            }
        )
        SessionStart = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/session-start-identity.sh"; timeout = 10 }
                )
            }
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/session-start-write-id.sh"; timeout = 10 }
                )
            }
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/session-start-post-clear.sh"; timeout = 10 }
                )
            }
            @{
                matcher = "compact"
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/session-start-recovery.sh"; timeout = 10 }
                )
            }
        )
        PreToolUse = @(
            @{
                matcher = "Bash"
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/branch-protection.sh"; timeout = 10 }
                )
            }
            @{
                matcher = "Agent"
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/pre-agent-register.sh"; timeout = 5 }
                )
            }
        )
        PostToolUse = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/heartbeat.sh"; timeout = 5 }
                )
            }
            @{
                matcher = "Agent"
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/post-agent-complete.sh"; timeout = 5 }
                )
            }
        )
        SessionEnd = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$HooksPathFwd/session-end-autosave.sh"; timeout = 10 }
                )
            }
        )
    }
}

if (Test-Path $SettingsFile) {
    # Existing settings -- per-event merge: preserve user-added hooks, replace/dedup
    # jitneuro's own (entries whose command path starts with this install's hooks dir).
    try {
        $supportsHashtable = (Get-Command ConvertFrom-Json).Parameters.ContainsKey('AsHashtable')
        if ($supportsHashtable) {
            $existing = Get-Content $SettingsFile -Raw | ConvertFrom-Json -AsHashtable
            if (-not $existing.ContainsKey('hooks') -or $null -eq $existing['hooks']) { $existing['hooks'] = @{} }
            foreach ($evt in $hooksConfig.hooks.Keys) {
                $userEntries = @()
                if ($existing['hooks'].ContainsKey($evt) -and $existing['hooks'][$evt]) {
                    foreach ($entry in @($existing['hooks'][$evt])) {
                        $isJit = $false
                        foreach ($h in @($entry['hooks'])) {
                            if ($h['command'] -and $h['command'].ToString().StartsWith($HooksPathFwd)) { $isJit = $true; break }
                        }
                        if (-not $isJit) { $userEntries += $entry }
                    }
                }
                $existing['hooks'][$evt] = @($userEntries + $hooksConfig.hooks[$evt])
            }
            $tempFile = "$SettingsFile.tmp.$PID"
            $existing | ConvertTo-Json -Depth 12 | Set-Content $tempFile -Encoding UTF8
            Move-Item $tempFile $SettingsFile -Force
            Write-Host "  Merged hooks into settings.local.json (preserved user hooks, deduped jitneuro hooks)"
        } else {
            # Windows PowerShell 5.1 (no -AsHashtable): back up, then replace the hooks block.
            Copy-Item $SettingsFile "$SettingsFile.bak" -Force
            $existing = Get-Content $SettingsFile -Raw | ConvertFrom-Json
            $existing | Add-Member -MemberType NoteProperty -Name "hooks" -Value $hooksConfig.hooks -Force
            $tempFile = "$SettingsFile.tmp.$PID"
            $existing | ConvertTo-Json -Depth 12 | Set-Content $tempFile -Encoding UTF8
            Move-Item $tempFile $SettingsFile -Force
            Write-Host "  Replaced hooks block (PS 5.1 -- backup at settings.local.json.bak; re-add any custom hooks)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  WARNING: Could not parse existing settings.local.json." -ForegroundColor Yellow
        Write-Host "  Existing file left UNTOUCHED to prevent data loss." -ForegroundColor Yellow
        Write-Host "  See $Target\jitneuro.json for hooks configuration reference." -ForegroundColor Yellow
    }
} else {
    # No existing settings -- create hooks-only file (atomic write)
    $tempFile = "$SettingsFile.tmp.$PID"
    $hooksConfig | ConvertTo-Json -Depth 10 | Set-Content $tempFile -Encoding UTF8
    Move-Item $tempFile $SettingsFile -Force
    Write-Host "  Created settings.local.json with hooks config"
}

# --- Post-install workspace repo scan (US-003) ---
if ($Mode -eq "workspace" -and $WorkspaceRoot) {
    Write-Host ""
    Write-Host "Scanning workspace for repos..." -ForegroundColor Green
    Write-Host ""
    Write-Host ("  {0,-20} {1,-10} {2,-10} {3,-10}" -f "REPO", "CLAUDE.md", "BRAINSTEM", "ENGRAM")
    Write-Host ("  {0,-20} {1,-10} {2,-10} {3,-10}" -f "----", "---------", "---------", "------")

    $RepoCount = 0
    $NeedsOnboard = 0
    $repos = Get-ChildItem $WorkspaceRoot -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName ".git")) -and
        $_.Name -ne ".claude" -and
        $_.Name -ne "jitneuro"
    } | Select-Object -First 30

    foreach ($repo in $repos) {
        $displayName = $repo.Name
        if ($displayName.Length -gt 20) {
            $displayName = $displayName.Substring(0, 17) + "..."
        }

        $hasClaude = "--"
        $hasBrainstem = "--"
        $hasEngram = "--"

        if (Test-Path (Join-Path $repo.FullName "CLAUDE.md")) { $hasClaude = "YES" }
        if (Test-Path (Join-Path $repo.FullName ".claude\CLAUDE.md")) { $hasBrainstem = "YES" }
        $engramPath = Join-Path $WorkspaceRoot ".claude\engrams\$($repo.Name)-context.md"
        if (Test-Path $engramPath) { $hasEngram = "YES" }

        if ($hasClaude -eq "--" -or $hasBrainstem -eq "--" -or $hasEngram -eq "--") {
            $NeedsOnboard++
        }

        Write-Host ("  {0,-20} {1,-10} {2,-10} {3,-10}" -f $displayName, $hasClaude, $hasBrainstem, $hasEngram)
        $RepoCount++
    }

    $totalRepos = (Get-ChildItem $WorkspaceRoot -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName ".git")) -and $_.Name -ne ".claude" -and $_.Name -ne "jitneuro"
    }).Count
    if ($totalRepos -gt 30) {
        Write-Host "  ... ($totalRepos repos total, showing first 30)"
    }

    Write-Host ""
    Write-Host "  $RepoCount repos found, $NeedsOnboard need onboarding"
    if ($NeedsOnboard -gt 0) {
        Write-Host "  Run /onboard <repo> to set up context for missing repos"
    }
    # US-004: Git sync tip
    Write-Host "  Tip: /onboard checks if repos are behind their remote"
}

# --- Add *.backup to .gitignore ---
$gitignore = Join-Path (Split-Path $Target -Parent) ".gitignore"
if (Test-Path $gitignore) {
    $content = Get-Content $gitignore -Raw
    if ($content -notmatch '\.backup') {
        Add-Content $gitignore "`n# JitNeuro command backups`n.claude/commands/.backup/"
    }
}

# --- Record framework manifest + prune framework files dropped since last install ---
Write-Host ""
Write-Host "Recording framework manifest..." -ForegroundColor Green
foreach ($t in (Get-ChildItem (Join-Path $Templates "commands") -Filter *.md -File -EA SilentlyContinue)) { Add-JnManifest "commands/$($t.Name)" }
foreach ($t in (Get-ChildItem (Join-Path $Templates "rules") -Filter *.md -File -EA SilentlyContinue)) { Add-JnManifest "rules/$($t.Name)" }
foreach ($t in (Get-ChildItem (Join-Path $Templates "cognition") -Filter *.md -File -EA SilentlyContinue)) {
    if ($t.Name -eq "owner-persona.example.md") { continue }   # owner-persona is user-owned after seeding
    Add-JnManifest "cognition/$($t.Name)"
}
foreach ($t in (Get-ChildItem (Join-Path $Templates "cognition\decisions") -Filter *.md -File -EA SilentlyContinue)) { Add-JnManifest "cognition/decisions/$($t.Name)" }
foreach ($t in (Get-ChildItem (Join-Path $Templates "scripts") -Filter *.sh -File -EA SilentlyContinue)) { Add-JnManifest "scripts/$($t.Name)" }
foreach ($t in (Get-ChildItem (Join-Path $Templates "dashboard") -File -EA SilentlyContinue | Where-Object { $_.Extension -in ".html",".js" })) { Add-JnManifest "dashboard/$($t.Name)" }
if (Test-Path (Join-Path $Templates "dashboard\bin")) {
    foreach ($t in (Get-ChildItem (Join-Path $Templates "dashboard\bin") -File -EA SilentlyContinue)) { Add-JnManifest "dashboard/bin/$($t.Name)" }
}
foreach ($t in (Get-ChildItem (Join-Path $Templates "hooks") -Filter *.sh -File -EA SilentlyContinue)) { Add-JnManifest "hooks/$($t.Name)" }
Add-JnManifest "jitneuro.json"

# Prune framework files present at last install but no longer shipped (sha-guarded).
$newPaths = @{}
foreach ($e in $NewManifest) { $newPaths[($e -split "`t",2)[0]] = $true }
$pruned = 0
foreach ($rel in $OldManifest.Keys) {
    if ($newPaths.ContainsKey($rel)) { continue }
    $f = Join-Path $Target $rel
    if (Test-Path $f) {
        if ((Get-JnSha $f) -eq $OldManifest[$rel]) {
            Remove-Item $f -Force; Write-Host "  REMOVED (dropped by framework): $rel"; $pruned++
        } else {
            Write-Host "  KEPT (you edited a now-removed framework file): $rel"
        }
    }
}
if ($pruned -gt 0) { Write-Host "  ($pruned stale framework file(s) removed)" }

# Write the manifest (sorted, version-stamped). Files NOT listed here = yours; never touched.
$sorted = $NewManifest | Sort-Object
$out = @("# jitneuro-manifest v$Version") + $sorted
Set-Content -Path $Manifest -Value $out -Encoding ascii   # ASCII: no BOM, cross-tool safe
Write-Host "  .jitneuro-manifest.tsv ($($NewManifest.Count) framework files tracked)"

# --- Summary ---
Write-Host ""
Write-Host "---" -ForegroundColor DarkGray
Write-Host "JitNeuro v$Version installed to: $Target" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. CLOSE AND REOPEN Claude Code (commands load at session start)" -ForegroundColor Yellow
Write-Host "  2. Run /verify to confirm everything is working"
Write-Host "  3. Populate your horizon: tell Claude 'populate my horizon files' (or open"
Write-Host "     $Target\horizon\POPULATE-HORIZON.md) to capture your vision, goals, and profile"
Write-Host "  4. Run /onboard <repo> to set up context for your repos"
Write-Host "  5. Create bundles for your domains in $Target\bundles\"
Write-Host "  6. (optional) Edit ~/.claude/url-resolver.md to map your repo names to local paths"
Write-Host ""
Write-Host "*** You MUST restart Claude Code for slash commands to take effect. ***" -ForegroundColor Red
Write-Host ""
Write-Host "Docs: $ScriptDir\docs\setup-guide.md"
