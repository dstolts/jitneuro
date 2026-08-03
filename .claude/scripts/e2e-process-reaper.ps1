#Requires -Version 5.1
<#
.SYNOPSIS
  Windows counterpart to templates/scripts/e2e-process-reaper.sh (ticket
  #2695) -- finds and kills the FULL process tree of orphaned
  Playwright/Cypress/Puppeteer test-runner or headless-browser processes.

.DESCRIPTION
  Root cause this closes: rules/e2e-test-safety.md item 4 ("No orphans") was
  advisory only. On Windows, Owner observed CPU pegged at 100% after a hung
  e2e run, cleared only when VS Code's "Delete Terminal" action killed the
  process tree -- a strong signal the cause was orphaned chromium/node
  children outliving the aborted run. This script guarantees that reap with
  `taskkill /F /T` (force, tree) instead of relying on a terminal UI action.

.PARAMETER PreTest
  Reap before starting a new e2e batch (clears leftovers from a prior
  aborted/killed run that never ran PostTest, e.g. a session crash).

.PARAMETER PostTest
  Reap immediately after a run (pass or fail) to guarantee zero orphans
  remain -- the acceptance bar for ticket #2695.

.PARAMETER ListOnly
  Report matches without killing (verification / dry-run).

.PARAMETER KillTree
  Test/scoped hook: taskkill /F /T a specific PID's tree without the
  classify scan, so unit tests can target a known fake process.

.PARAMETER Classify
  Test mode: echo yes/no for one command-line string, no process scan.

.EXAMPLE
  pwsh -File templates/scripts/e2e-process-reaper.ps1 -PreTest
  pwsh -File templates/scripts/e2e-process-reaper.ps1 -PostTest
  pwsh -File templates/scripts/e2e-process-reaper.ps1 -ListOnly
#>
param(
    [switch]$PreTest,
    [switch]$PostTest,
    [switch]$ListOnly,
    [int]$KillTree = 0,
    [string]$Classify = $null
)

$ErrorActionPreference = 'Continue'

function Test-E2EOrphanCommandLine {
    param([string]$CommandLine)
    if ([string]::IsNullOrEmpty($CommandLine)) { return $false }
    $c = $CommandLine

    # Playwright CLI/worker/browser-server processes.
    if ($c -match 'node_modules[\\/]\.bin[\\/]playwright') { return $true }
    if ($c -match 'node_modules[\\/]playwright(-core)?[\\/]') { return $true }
    if ($c -match 'ms-playwright') { return $true }
    if ($c -match 'playwright.*(worker|run-server|test-server)') { return $true }

    # Cypress runner + bundled Electron/Chromium.
    if ($c -match 'node_modules[\\/]\.bin[\\/]cypress') { return $true }
    if ($c -match 'node_modules[\\/]cypress[\\/]') { return $true }
    if ($c -match '\.cache[\\/][Cc]ypress' -or $c -match 'AppData.*Cypress') { return $true }

    # Puppeteer's cached headless Chromium.
    if ($c -match 'puppeteer.*\.local-chromium') { return $true }

    # Headless Chromium invoked with automation flags AND a test-tool hint --
    # narrow on purpose so an unrelated user Chrome window is never matched.
    if ($c -match '(chrome|chromium)(\.exe)?' -and
        ($c -match '--headless' -or $c -match '--remote-debugging-port' -or $c -match '--enable-automation')) {
        if ($c -match 'ms-playwright|playwright|cypress|puppeteer') { return $true }
    }
    return $false
}

if ($PSBoundParameters.ContainsKey('Classify')) {
    if (Test-E2EOrphanCommandLine -CommandLine $Classify) { Write-Output 'yes' } else { Write-Output 'no' }
    exit 0
}

function Get-ProcessTree {
    param([int]$RootPid)
    # Win32_Process gives ProcessId/ParentProcessId/CommandLine -- CIM is the
    # modern (non-deprecated) equivalent of Get-WmiObject, available on
    # PowerShell 5.1+ without extra modules.
    $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $byParent = @{}
    foreach ($p in $all) {
        $key = [string]$p.ParentProcessId
        if (-not $byParent.ContainsKey($key)) { $byParent[$key] = New-Object System.Collections.Generic.List[object] }
        $byParent[$key].Add($p)
    }
    $result = [System.Collections.Generic.List[int]]::new()
    $frontier = [System.Collections.Generic.Queue[int]]::new()
    $frontier.Enqueue($RootPid)
    while ($frontier.Count -gt 0) {
        $processId = $frontier.Dequeue()
        $result.Add($processId)
        $key = [string]$processId
        if ($byParent.ContainsKey($key)) {
            foreach ($child in $byParent[$key]) { $frontier.Enqueue([int]$child.ProcessId) }
        }
    }
    return ,$result
}

function Invoke-TreeKill {
    param([int]$RootPid)
    # taskkill /F /T kills the process and its FULL descendant tree in one
    # call -- this is the literal acceptance-criteria mechanism for ticket
    # #2695 ("Windows taskkill /F /T"). We still walk + verify the tree via
    # CIM afterward so a survivor is caught, not assumed away.
    Write-Output "e2e-process-reaper: taskkill /F /T on pid $RootPid"
    & taskkill /F /T /PID $RootPid 2>$null | Out-Null
    Start-Sleep -Seconds 1
    $survivors = @()
    $tree = Get-ProcessTree -RootPid $RootPid
    foreach ($processId in $tree) {
        if (Get-Process -Id $processId -ErrorAction SilentlyContinue) { $survivors += $processId }
    }
    if ($survivors.Count -gt 0) {
        Write-Warning "e2e-process-reaper: $($survivors.Count) process(es) survived taskkill /F /T: $($survivors -join ',')"
        foreach ($processId in $survivors) {
            & taskkill /F /PID $processId 2>$null | Out-Null
        }
        Start-Sleep -Milliseconds 500
        $stillAlive = @($survivors | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
        if ($stillAlive.Count -gt 0) {
            Write-Warning "e2e-process-reaper: WARNING -- $($stillAlive.Count) process(es) still alive after retry: $($stillAlive -join ',')"
            return $false
        }
    }
    Write-Output 'e2e-process-reaper: verified clean -- 0 orphans remain.'
    return $true
}

if ($KillTree -gt 0) {
    $ok = Invoke-TreeKill -RootPid $KillTree
    exit ($(if ($ok) { 0 } else { 1 }))
}

if (-not ($PreTest -or $PostTest -or $ListOnly)) {
    Write-Error 'Usage: e2e-process-reaper.ps1 -PreTest | -PostTest | -ListOnly | -KillTree <pid> | -Classify "<cmdline>"'
    exit 64
}

$all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
$matches = @()
foreach ($p in $all) {
    if ($p.ProcessId -eq $PID) { continue }  # never match this script's own process
    if (Test-E2EOrphanCommandLine -CommandLine $p.CommandLine) { $matches += $p }
}

if ($matches.Count -eq 0) {
    Write-Output 'e2e-process-reaper: no matching processes found.'
    exit 0
}

Write-Output "e2e-process-reaper: found $($matches.Count) matching root process(es):"
foreach ($m in $matches) {
    Write-Output "  pid=$($m.ProcessId)  $($m.CommandLine)"
}

if ($ListOnly) { exit 0 }

$allOk = $true
foreach ($m in $matches) {
    if (-not (Invoke-TreeKill -RootPid $m.ProcessId)) { $allOk = $false }
}
exit ($(if ($allOk) { 0 } else { 1 }))
