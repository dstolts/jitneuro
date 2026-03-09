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

switch ($Mode) {
    "workspace" {
        $Target = Join-Path (Split-Path -Parent (Get-Location)) ".claude"
        Write-Host "Installing JitNeuro at WORKSPACE level: $Target" -ForegroundColor Cyan
        Write-Host "Commands will be available to all repos under $(Split-Path -Parent (Get-Location))"
    }
    "project" {
        $Target = Join-Path (Get-Location) ".claude"
        Write-Host "Installing JitNeuro at PROJECT level: $Target" -ForegroundColor Cyan
        Write-Host "Commands will be available in this repo only."
    }
    "user" {
        $Target = Join-Path $env:USERPROFILE ".claude"
        Write-Host "Installing JitNeuro at USER level: $Target" -ForegroundColor Cyan
        Write-Host "Commands will be available in all projects on this machine."
    }
}

Write-Host ""

# Create directories
$dirs = @("commands", "bundles", "engrams", "session-state", "rules")
foreach ($dir in $dirs) {
    $path = Join-Path $Target $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Copy commands
Write-Host "Installing commands..." -ForegroundColor Green
$commands = @("save", "load", "learn", "sessions", "orchestrate", "conversation-log")
foreach ($cmd in $commands) {
    $src = Join-Path $Templates "commands\$cmd.md"
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $Target "commands\$cmd.md") -Force
        Write-Host "  /$cmd"
    }
}

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
if ((Get-ChildItem $bundlesDir -File).Count -eq 0) {
    Copy-Item (Join-Path $Templates "bundles\example.md") (Join-Path $bundlesDir "example.md")
    Write-Host "Created bundles\example.md (template)"
} else {
    Write-Host "Skipped bundles\ (already has files)" -ForegroundColor Yellow
}

# Copy example engram if empty
$engramsDir = Join-Path $Target "engrams"
if ((Get-ChildItem $engramsDir -File).Count -eq 0) {
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
if ((Get-ChildItem $rulesDir -File).Count -eq 0) {
    Copy-Item (Join-Path $Templates "rules\scoped-rule-example.md") (Join-Path $rulesDir "scoped-rule-example.md")
    Write-Host "Created rules\scoped-rule-example.md (template)"
} else {
    Write-Host "Skipped rules\ (already has files)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "---" -ForegroundColor DarkGray
Write-Host "JitNeuro installed to: $Target" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Slim your CLAUDE.md using templates\CLAUDE-brainstem.md as a guide"
Write-Host "  2. Create bundles for your domains in $Target\bundles\"
Write-Host "  3. Create engrams for your projects in $Target\engrams\"
Write-Host "  4. Update $Target\context-manifest.md with your bundles"
Write-Host "  5. Add routing weights to your MEMORY.md"
Write-Host "  6. Start a new Claude Code session (commands load at session start)"
Write-Host ""
Write-Host "Commands available after restart: /save /load /learn /sessions /orchestrate" -ForegroundColor Cyan
Write-Host ""
Write-Host "Docs: $ScriptDir\docs\setup-guide.md"
