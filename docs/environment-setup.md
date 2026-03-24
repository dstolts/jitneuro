# Environment Setup

The dashboard server needs `JITDASH_DIR` and `JITDASH_SESSIONS` env vars to find the right directories. The easiest way to configure them:

```
> "Set up the JITDASH_DIR and JITDASH_SESSIONS environment variables permanently
   for my workspace at [path]. Make them survive reboots."
```

Claude Code will detect your OS, set the variables at the right scope, and verify they work.

## Required Variables

| Variable | Purpose | Default | Example |
|----------|---------|---------|---------|
| JITDASH_DIR | Dashboard data directory (runs, HTML) | ~/.claude/dashboard | <workspace>\.claude\dashboard |
| JITDASH_SESSIONS | Session state directory (heartbeats, checkpoints) | ~/.claude/session-state | <workspace>\.claude\session-state |
| JITDASH_PORT | Dashboard server port | 9847 | 9847 |

## When to Set

- If your workspace `.claude/` is NOT under your home directory (e.g., `C:\Projects\.claude\` instead of `~/.claude/`)
- Multi-workspace setups where dashboard should point to a specific workspace

## Platform-Specific Commands (Reference)

## Windows

### Permanent (survives reboot)

PowerShell (run as your user, not admin):

```powershell
[Environment]::SetEnvironmentVariable('JITDASH_DIR','<workspace>\.claude\dashboard','User')
[Environment]::SetEnvironmentVariable('JITDASH_SESSIONS','<workspace>\.claude\session-state','User')
```

### Verify

```powershell
[Environment]::GetEnvironmentVariable('JITDASH_DIR','User')
[Environment]::GetEnvironmentVariable('JITDASH_SESSIONS','User')
```

Note: New terminal windows pick up the change immediately. Running terminals need restart.

## macOS / Linux

### Permanent (bash)

Add to `~/.bashrc` or `~/.bash_profile`:

```bash
export JITDASH_DIR="$HOME/.claude/dashboard"
export JITDASH_SESSIONS="$HOME/.claude/session-state"
```

Then: `source ~/.bashrc`

### Permanent (zsh)

Add to `~/.zshrc`:

```bash
export JITDASH_DIR="$HOME/.claude/dashboard"
export JITDASH_SESSIONS="$HOME/.claude/session-state"
```

Then: `source ~/.zshrc`

### Permanent (fish)

```fish
set -Ux JITDASH_DIR $HOME/.claude/dashboard
set -Ux JITDASH_SESSIONS $HOME/.claude/session-state
```

## Verify (all platforms)

Start the dashboard and check the config in the API response:

```bash
node ~/.claude/dashboard/server.js --no-open &
curl -s http://localhost:9847/api/status | jq '.config'
```

Should show your custom paths, not the defaults.

## Notes

- The install script (install.sh / install.ps1) does NOT set these automatically -- they depend on your workspace layout
- If JITDASH_DIR is not set, the dashboard defaults to ~/.claude/dashboard
- The server also accepts --dir and --sessions flags as command-line overrides
