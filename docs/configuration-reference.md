# Configuration Reference

Single source of truth for all JitNeuro configuration files, settings, and environment variables.

---

## Configuration Files Overview

| File | Location | Purpose | Committed to Git? |
|------|----------|---------|-------------------|
| `jitneuro.json` | `.claude/jitneuro.json` | JitNeuro version, hook behavior, scheduled agents, branch protection | Yes (no secrets) |
| `settings.local.json` | `.claude/settings.local.json` or project root | Claude Code hooks wiring (which scripts fire on which events) | Yes (no secrets) |
| `settings.json` | `~/.claude/settings.json` | Claude Code user settings (permissions, effort level) | No (user-level) |
| `toggles.json` | `.claude/toggles.json` | Feature toggles (engrams, divergent thinking) | Yes (no secrets) |
| `.preferences` | `.claude/session-state/.preferences` | Session UI preferences (shortcut scope) | Yes |

---

## jitneuro.json

Central JitNeuro configuration. Located at `.claude/jitneuro.json`. Hook scripts read this at runtime.

### Full Schema

```json
{
  "version": "0.4.0",
  "scheduledAgents": [...],
  "hooks": {
    "preCompactBehavior": "block",
    "autosave": true,
    "protectedBranches": ["main", "master"],
    "mainPushAllowed": [],
    "hookEvents": [...]
  }
}
```

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | JitNeuro version (semver). Used by /verify and /health to detect stale installs. |
| `scheduledAgents` | array | No | Timer agents that periodically interrupt master with housekeeping instructions. See [Scheduled Agents](#scheduled-agents). |
| `hooks` | object | Yes | Hook behavior configuration. See [Hooks Configuration](#hooks-configuration). |

### Hooks Configuration

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `preCompactBehavior` | `"block"` or `"warn"` | `"block"` | **block:** Compaction halted (exit 2). User must respond before compaction proceeds. Prevents context loss. **warn:** Message injected into context, compaction proceeds. Claude asks user about /save. |
| `autosave` | boolean | `true` | Write `_autosave.md` breadcrumb on session end. Set false to disable. |
| `protectedBranches` | string[] | `["main", "master"]` | Branch names that branch-protection hook blocks push to. |
| `mainPushAllowed` | string[] | `[]` | Full git remote URLs allowed to push to protected branches without asking. Must match `git remote get-url origin` exactly. Force push is always blocked regardless of this list. |
| `hookEvents` | array | (see below) | Hook script definitions. The install script populates these. |

### hookEvents Array

Each entry maps a Claude Code lifecycle event to a bash script:

```json
{
  "event": "PreToolUse",
  "matcher": "Bash",
  "script": "branch-protection.sh",
  "timeout": 10
}
```

| Field | Type | Description |
|-------|------|-------------|
| `event` | string | Claude Code event: `PreCompact`, `SessionStart`, `PreToolUse`, `PostToolUse`, `SessionEnd` |
| `matcher` | string | Filter pattern. Empty string (`""`) matches all events of that type. `"Bash"` matches only Bash tool calls. `"compact"` matches compaction-triggered session starts. |
| `script` | string | Script filename in `.claude/hooks/`. The hook runner resolves the full path. |
| `timeout` | number | Max seconds before the hook is killed. Keep short (5-10s) to avoid blocking Claude Code. |

**Default hooks shipped with JitNeuro:**

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| PreCompact | (all) | `pre-compact-save.sh` | Block or warn before context compaction |
| SessionStart | (all) | `session-start-write-id.sh` | Write Claude session ID to heartbeat file |
| SessionStart | (all) | `session-start-post-clear.sh` | Present session picker after /clear |
| SessionStart | compact | `session-start-recovery.sh` | Auto-recover session after compaction |
| SessionStart | (all) | `session-start-scheduled-agents.sh` | Present scheduled agent config for launch |
| PreToolUse | Bash | `branch-protection.sh` | Block push to protected branches |
| PreToolUse | Agent | `pre-agent-register.sh` | Register agent dispatch for tracking |
| PostToolUse | (all) | `heartbeat.sh` | Update session heartbeat timestamp |
| PostToolUse | Agent | `post-agent-complete.sh` | Track agent completion |
| SessionEnd | (all) | `session-end-autosave.sh` | Auto-save session state on exit |

### Scheduled Agents

Timer agents that run on an interval, interrupt master with an instruction, and get re-spawned.

```json
{
  "name": "autosave",
  "interval": 30,
  "enabled": true,
  "instruction": "/save",
  "prompt": "(optional -- evaluation prompt for smart agents)",
  "description": "Auto-save session state every 30 minutes"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique identifier. Used by `/schedule start/stop <name>`. |
| `interval` | number | Yes | Minutes between executions. |
| `enabled` | boolean | Yes | Whether the agent is available for launch. `/schedule stop` sets this to false. |
| `instruction` | string | Yes | What master executes when the agent returns. Can be a slash command (`/save`), a keyword (`UPDATE_HUB`, `NONE`), or `ASK_USER <message>`. |
| `prompt` | string | No | For smart agents: an evaluation prompt the agent runs before returning. If the agent determines no action is needed, it returns `INSTRUCTION: NONE`. If omitted, the agent simply sleeps and returns the instruction. |
| `description` | string | No | Human-readable description shown by `/schedule list`. |

**Default agents:**

| Name | Interval | Instruction | Purpose |
|------|----------|-------------|---------|
| `autosave` | 30m | `/save` | Checkpoint session state periodically |
| `hub-sync` | 10m | `UPDATE_HUB` | Keep TodoWrite and Hub.md in sync |

---

## settings.local.json

Claude Code's hook wiring. This tells Claude Code WHICH scripts to run on WHICH events. Located at `.claude/settings.local.json` (project or workspace level).

**This file is generated by the install script.** Manual editing is rarely needed. If you do edit it, the structure must match Claude Code's expected format exactly.

### Structure

```json
{
  "permissions": {
    "allow": [...]
  },
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<pattern>",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/script-name.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Event Types

| Event | When It Fires | Common Use |
|-------|--------------|------------|
| `PreCompact` | Before context compaction starts | Save session state before context is compressed |
| `SessionStart` | When a new session begins or after /clear | Recover session, present picker, inject context |
| `PreToolUse` | Before Claude executes any tool | Branch protection, command validation |
| `PostToolUse` | After Claude executes any tool | Heartbeat updates, agent tracking |
| `SessionEnd` | When the session is ending | Auto-save breadcrumb |

### Matcher Patterns

| Matcher | Matches | Example Use |
|---------|---------|-------------|
| `""` (empty) | All events of that type | Heartbeat on every tool use |
| `"Bash"` | Only Bash tool calls | Branch protection (only relevant for git push) |
| `"Agent"` | Only Agent tool calls | Track agent dispatch/completion |
| `"compact"` | Only compaction-triggered starts | Auto-recover session after compaction |

### Permission Entries

The `permissions.allow` array grants auto-approval for tool calls:

```json
"Bash(git *)"        // All git commands
"Read(D:/Code/**)"   // Read any file under D:\Code
"Write(D:/Code/**)"  // Write any file under D:\Code
"WebFetch(*)"        // Fetch any URL
```

Pattern: `ToolName(glob pattern)`. The `*` and `**` globs work as expected.

---

## settings.json (User Level)

Claude Code's user-level settings. Located at `~/.claude/settings.json`. Not project-specific -- applies to ALL projects.

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Read(D:/Code/**)",
      "Write(D:/Code/**)",
      "WebFetch(*)"
    ]
  },
  "effortLevel": "high",
  "skipDangerousModePermissionPrompt": true
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `permissions.allow` | string[] | `[]` | Tool call patterns auto-approved without prompting. |
| `effortLevel` | `"low"`, `"medium"`, `"high"` | `"medium"` | Controls reasoning depth. Higher = more thorough but slower. |
| `skipDangerousModePermissionPrompt` | boolean | `false` | Skip the confirmation prompt when enabling dangerous mode. |

### Precedence: settings.json vs settings.local.json

Both can define permissions and hooks. When both exist:
- **Permissions:** Merged. Both lists combine (union).
- **Hooks:** Merged. Both lists of hooks fire for matching events.
- **Settings.json** is user-global (all projects). **Settings.local.json** is project/workspace-specific.
- Neither overrides the other -- they add together.

---

## toggles.json

Feature toggles for JitNeuro. Located at `.claude/toggles.json`. Supports workspace and repo-level hierarchy.

```json
{
  "engrams": {
    "owner-identity": true
  },
  "divergent": "auto"
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `engrams.<name>` | boolean | `true` | Enable/disable specific engrams by name (filename without `-context.md`). |
| `divergent` | `"auto"`, `"always"`, `"never"` | `"auto"` | Divergent thinking mode. See `/divergent` command. |

### Hierarchy

Repo-level overrides workspace-level:

```
Workspace: <workspace>/.claude/toggles.json    (default for all repos)
Repo:      <repo>/.claude/toggles.json         (override for this repo only)
```

Resolution order:
1. Check `<repo>/.claude/toggles.json`
2. If not found: check `<workspace>/.claude/toggles.json`
3. If not found: use defaults

Manage with `/divergent` command (for divergent mode) or edit directly (for engram toggles).

---

## .preferences

Session UI preferences. Located at `.claude/session-state/.preferences`.

```
shortcut_scope: session
```

| Field | Values | Default | Description |
|-------|--------|---------|-------------|
| `shortcut_scope` | `session`, `sessions` | `session` | Where `/status` and `/dashboard` shortcuts route. `session` = current session. `sessions` = all sessions. `/save`, `/load`, `/pulse` always target current session. |

---

## Environment Variables

JitNeuro does not use environment variables. All configuration is file-based (jitneuro.json, toggles.json, settings.local.json). This is intentional -- file-based config is auditable, versionable, and visible to Claude Code without shell access.

---

## Multi-Level Configuration

JitNeuro and Claude Code both support configuration at multiple levels. Understanding precedence prevents "it works on my machine" surprises.

### Claude Code Levels

| Level | Location | Scope | Committed? |
|-------|----------|-------|------------|
| User | `~/.claude/settings.json` | All projects on this machine | No |
| Project | `<repo>/.claude/settings.local.json` | This repo only | Yes |
| Workspace | `<workspace>/.claude/settings.local.json` | Repos launched from workspace root | Yes |

**Commands** resolve from two locations (most specific wins):
1. `<git-root>/.claude/commands/` (project level)
2. `~/.claude/commands/` (user level)

There is no parent-directory traversal. Workspace-level commands only work when Claude Code is launched from the workspace root directly.

### JitNeuro Levels

| Config | Workspace | Repo | Resolution |
|--------|-----------|------|------------|
| `jitneuro.json` | One per workspace | Future (not yet) | Single level today |
| `toggles.json` | `.claude/toggles.json` | `<repo>/.claude/toggles.json` | Repo wins if present |
| `CLAUDE.md` | Workspace `.claude/CLAUDE.md` | Repo `.claude/CLAUDE.md` | Both load; repo-specific rules add to workspace rules |
| `rules/` | Workspace `.claude/rules/` | Repo `.claude/rules/` | Both load; Claude Code merges all levels |

### Gotcha: Stale Commands at Another Level

The #1 install issue. If you installed commands at BOTH user level and workspace level, upgrading only one leaves the other stale. Claude Code loads the most-specific level, so a stale project-level command overrides an updated user-level command.

**Fix:** Pick ONE level (user recommended) and remove commands from other levels. Or upgrade all levels together.

---

## Quick Reference: Common Customizations

| I want to... | Edit this file | Field/section |
|--------------|---------------|---------------|
| Allow a new tool without prompting | `~/.claude/settings.json` | `permissions.allow` |
| Change which branches are protected | `.claude/jitneuro.json` | `hooks.protectedBranches` |
| Allow push to main for a repo | `.claude/jitneuro.json` | `hooks.mainPushAllowed` |
| Change compaction behavior | `.claude/jitneuro.json` | `hooks.preCompactBehavior` |
| Disable auto-save on exit | `.claude/jitneuro.json` | `hooks.autosave` |
| Add a scheduled agent | `.claude/jitneuro.json` | `scheduledAgents` array |
| Change divergent thinking mode | `.claude/toggles.json` | `divergent` (or use `/divergent`) |
| Disable an engram | `.claude/toggles.json` | `engrams.<name>: false` |
| Add a custom hook | `.claude/settings.local.json` | `hooks.<EventName>` array |
| Change shortcut routing | `.claude/session-state/.preferences` | `shortcut_scope` |

---

## Related Docs

- [Setup Guide](setup-guide.md) -- Installation and post-install configuration
- [Hooks Guide](hooks-guide.md) -- How hooks work, adding custom hooks, lifecycle details
- [Enterprise Security](enterprise-security.md) -- Trust model, securing hooks for teams
- [Customization Guide](customization-guide.md) -- Customizing personas, rules, and cognitive identity
