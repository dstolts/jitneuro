@echo off
REM JitNeuro Agent Dashboard launcher (Windows CMD)
REM Place in PATH. Usage: jitdash [--port=9847] [--no-open]
set "SERVER=%USERPROFILE%\.claude\dashboard\server.js"
set "PORT=9847"
if defined JITDASH_PORT set "PORT=%JITDASH_PORT%"
where node >nul 2>&1 || (echo Error: Node.js not in PATH. & exit /b 1)
if not exist "%SERVER%" (echo Error: %SERVER% not found. Run jitneuro install. & exit /b 1)
node "%SERVER%" --port=%PORT% %*
