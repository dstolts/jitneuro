# JitNeuro Installer (PowerShell)
# Usage: .\install.ps1 [-Mode workspace|project|user]
#
# workspace  Install to parent directory's .claude\ (covers all repos under it)
# project    Install to current directory's .claude\ (single repo)
# user       Install to ~\.claude\ (available on entire machine)

param(
    [ValidateSet("workspace", "project", "user")]
    [string]$Mode = "project"
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

# Create directories
$dirs = @("commands", "bundles", "engrams", "session-state", "session-state\heartbeats", "rules", "hooks", "cognition", "cognition\decisions", "scripts", "dashboard\runs")
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

# Copy context-manifest (don't overwrite)
$manifest = Join-Path $Target "context-manifest.md"
if (-not (Test-Path $manifest)) {
    Copy-Item (Join-Path $Templates "context-manifest.md") $manifest
    Write-Host "Created context-manifest.md"
} else {
    Write-Host "Skipped context-manifest.md (already exists)" -ForegroundColor Yellow
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

# Copy scoped rule example if empty
$rulesDir = Join-Path $Target "rules"
if ((Get-ChildItem $rulesDir -File -ErrorAction SilentlyContinue).Count -eq 0) {
    Copy-Item (Join-Path $Templates "rules\scoped-rule-example.md") (Join-Path $rulesDir "scoped-rule-example.md")
    Write-Host "Created rules\scoped-rule-example.md (template)"
} else {
    Write-Host "Skipped rules\ (already has files)" -ForegroundColor Yellow
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
Copy-Item $ConfigFile (Join-Path $Target "jitneuro.json") -Force
Write-Host "Installed jitneuro.json (v$Version)"

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

# Build hooks config object
$hooksConfig = @{
    hooks = @{
        PreCompact = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/pre-compact-save.sh`""; timeout = 10 }
                )
            }
        )
        SessionStart = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/session-start-write-id.sh`""; timeout = 10 }
                )
            }
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/session-start-post-clear.sh`""; timeout = 10 }
                )
            }
            @{
                matcher = "compact"
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/session-start-recovery.sh`""; timeout = 10 }
                )
            }
        )
        PreToolUse = @(
            @{
                matcher = "Bash"
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/branch-protection.sh`""; timeout = 10 }
                )
            }
            @{
                matcher = "Agent"
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/pre-agent-register.sh`""; timeout = 5 }
                )
            }
        )
        PostToolUse = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/heartbeat.sh`""; timeout = 5 }
                )
            }
            @{
                matcher = "Agent"
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/post-agent-complete.sh`""; timeout = 5 }
                )
            }
        )
        SessionEnd = @(
            @{
                matcher = ""
                hooks = @(
                    @{ type = "command"; command = "$BashPathFwd `"$HooksPathFwd/session-end-autosave.sh`""; timeout = 10 }
                )
            }
        )
    }
}

if (Test-Path $SettingsFile) {
    # Existing settings -- merge hooks into it
    try {
        $existing = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        # Add or replace hooks property
        if ($existing.PSObject.Properties['hooks']) {
            Write-Host "  Replacing existing hooks config in settings.local.json"
        } else {
            Write-Host "  Adding hooks config to existing settings.local.json"
        }
        $existing | Add-Member -MemberType NoteProperty -Name "hooks" -Value $hooksConfig.hooks -Force
        $tempFile = "$SettingsFile.tmp.$PID"
        $existing | ConvertTo-Json -Depth 10 | Set-Content $tempFile -Encoding UTF8
        Move-Item $tempFile $SettingsFile -Force
        Write-Host "  Merged hooks into settings.local.json"
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

# --- Leave onboard marker for SessionStart hook ---
if ($Mode -eq "workspace" -and $WorkspaceRoot) {
    $markerPath = Join-Path $Target ".needs-onboard"
    Set-Content -Path $markerPath -Value "installed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`nmode=$Mode`nworkspace=$WorkspaceRoot"
    Write-Host ""
    Write-Host "  On next Claude Code session start, you will be prompted to scan" -ForegroundColor Cyan
    Write-Host "  and onboard all repos in the workspace automatically." -ForegroundColor Cyan
}

# --- Summary ---
Write-Host ""
Write-Host "---" -ForegroundColor DarkGray
Write-Host "JitNeuro v$Version installed to: $Target" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. CLOSE AND REOPEN Claude Code (commands load at session start)" -ForegroundColor Yellow
Write-Host "  2. Claude will prompt to onboard all repos in the workspace"
Write-Host "  3. Run /verify to confirm everything is working"
Write-Host "  4. Create bundles for your domains in $Target\bundles\"
Write-Host ""
Write-Host "*** You MUST restart Claude Code for slash commands to take effect. ***" -ForegroundColor Red
Write-Host ""
Write-Host "Docs: $ScriptDir\docs\setup-guide.md"
