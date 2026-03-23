# JitNeuro Agent Dashboard launcher (PowerShell)
# Place in PATH. Usage: jitdash [--port=9847] [--no-open]
$server = Join-Path $env:USERPROFILE '.claude\dashboard\server.js'
$port = if ($env:JITDASH_PORT) { $env:JITDASH_PORT } else { '9847' }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Error 'Node.js not in PATH.'; exit 1 }
if (-not (Test-Path $server)) { Write-Error "$server not found. Run jitneuro install."; exit 1 }
node $server "--port=$port" @args
