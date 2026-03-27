# Hooks Guide

## Why Hooks Matter

Hooks automate what you'd otherwise forget. They fire on Claude Code lifecycle events -- before compaction, before dangerous git commands, when sessions end. JitNeuro ships 6 hooks that protect your work and enforce governance automatically.

Hooks are the safety net that ensures context is never silently lost. When compaction fires, your session state is preserved. When you accidentally try to push to a protected branch, the hook catches it. They run automatically on Claude Code lifecycle events with no manual intervention required.

## Installed Hooks

### 1. PreCompact Save Prompt

- **Event:** PreCompact
- **Script:** pre-compact-save.sh
- **Timeout:** 10s

Prompts Claude to offer `/save` before context gets compressed. Claude will ask the user if they want to checkpoint their session state before compaction proceeds.

**Configuration** (jitneuro.json -> hooks.preCompactBehavior):

| Value | Behavior |
|-------|----------|
| `block` (default) | Compaction blocked (exit 2). User must respond before compaction can proceed. |
| `warn` | Message injected into context. Claude asks about /save. Compaction proceeds. |

**Why this matters:** Context compaction is the #1 cause of lost work. After compaction, Claude forgets active tasks, loaded bundles, file positions, and next steps. This hook catches it before it happens.

### 2. Session Start -- Write Session ID (Heartbeat)

- **Event:** SessionStart (matcher: `""` -- all session starts)
- **Script:** session-start-write-id.sh
- **Timeout:** 5s

Parses `session_id` from the hook JSON and creates `heartbeats/<session-id>` in the session-state directory. If the heartbeat file already exists (resume or compact), reads the existing JitNeuro session name from it; otherwise writes "none" as the initial content. Echoes `[JitNeuro] session-id: <session-id>` to stdout, which Claude Code injects into the conversation context. This is how Claude knows its own session ID for the rest of the conversation -- including after compaction, when SessionStart fires again with source "compact" and re-injects it.

**Why this matters:** Each Claude Code instance gets its own heartbeat file, enabling per-instance liveness tracking. The dashboard reads heartbeat file mtimes to show which sessions are actively running. Multiple conversations in the same workspace each have independent heartbeat files with no risk of overwriting each other.

### 3. Heartbeat

- **Event:** PostToolUse (matcher: `""` -- all tool calls)
- **Script:** heartbeat.sh
- **Timeout:** 5s

Parses `session_id` from the hook JSON and touches `heartbeats/<session-id>` to update its modification time. No stdout; exit 0.

Cost is minimal -- approximately 10-20ms per invocation (stdin read + grep + touch). Over 50 tool calls that adds up to roughly 500ms total, spread across minutes of active work.

**Why PostToolUse:** It fires during active work after every tool call, includes the session_id in its payload, and catches long autonomous runs (e.g., ralph executing stories) that a UserPromptSubmit hook would miss.

**Why this matters:** The dashboard reads heartbeat file mtimes to determine which sessions are actively running in real time. Without this hook, the dashboard would only know a session existed at startup -- not whether it is still alive and working.

### 4. Post-Compact Context Recovery

- **Event:** SessionStart (matcher: `compact`)
- **Script:** session-start-recovery.sh
- **Timeout:** 10s

After compaction, reads the most recent session state file from `.claude/session-state/` and re-injects it into Claude's context window. Restores awareness of: active task, loaded bundles, modified files, and next steps.

stdout from this hook goes directly into Claude's context -- no user action needed.

**Why this matters:** After compaction, Claude forgets what it was doing. This hook restores the last checkpoint automatically so you can pick up where you left off without manually re-explaining context.

### 5. Branch Protection

- **Event:** PreToolUse (matcher: `Bash`)
- **Script:** branch-protection.sh
- **Timeout:** 5s

Intercepts every Bash command before execution and blocks RED zone git operations:

| Command Pattern | Why Blocked |
|-----------------|-------------|
| `git push ... main/master` | Push to main requires explicit permission (unless repo is in `mainPushAllowed`) |
| `git push --force` | Force push is destructive and irreversible (always blocked, no override) |
| `git branch -D` | Force-deletes a branch without merge check |
| `git reset --hard` | Discards all uncommitted work |

**Per-repo override:** For local development repos and self-made internal tools where push-to-main is low risk (e.g., Vercel auto-deploys, no team review required), you can add the repo's full upstream URL to `mainPushAllowed` in jitneuro.json. The hook checks `git remote get-url origin` against this list before blocking. Force push is always blocked regardless of this setting.

When a command is blocked, Claude receives the reason via stderr and will inform the user and ask for permission before retrying.

**Why this matters:** Governance rules written in CLAUDE.md are "prose rules" -- Claude follows them most of the time, but can still slip. This hook enforces RED zone protections programmatically. The dangerous command never executes.

### 6. Session End Auto-Save

- **Event:** SessionEnd
- **Script:** session-end-autosave.sh
- **Timeout:** 10s

Safety net for forgotten `/save`. When a session ends, this hook reads the session name from `heartbeats/<session-id>` (before removing the heartbeat file), then checks whether a `/save` was called during the session by comparing the active session file's modification time against the session duration. After the check, the heartbeat file is removed to signal the instance is no longer active.

**If /save was detected:** Writes a minimal "all clear" breadcrumb -- no action needed.

**If /save was NOT detected:** Writes a warning breadcrumb with recovery info:
- The active session name (read from `heartbeats/<session-id>`)
- How long ago the last save was
- The last known task and repos (extracted from the session file)
- A `/load` command to restore the last checkpoint

Written to `.claude/session-state/_autosave.md` (overwritten each time). Excluded from `/sessions` dashboard output.

**Why this matters:** The most common way to lose context is forgetting to `/save` before closing the terminal. This hook detects that gap and tells the next session exactly what to recover. Removing the heartbeat file on exit ensures the dashboard stops showing the session as active.

**Limitations:**
- The SessionEnd event provides only 4 fields: reason, duration, cwd, session_id. It has NO access to conversation context. The hook cannot capture what you were actually working on -- only what the last `/save` recorded.
- Save detection relies on file modification timestamps. If the system clock is wrong or the filesystem doesn't update mtime, detection may be inaccurate.
- If no `/save` was ever called (no session files), the breadcrumb can only report "none" for session name, task, and repos.
- The hook reads the first 15 lines of the session file to extract task/repos. If the session file format changes or those fields are beyond line 15, extraction will miss them.
- On Windows, `stat -c %Y` may not work depending on the bash environment. The hook falls back to `stat -f %m` (BSD/macOS), but if both fail, save detection defaults to "no" (safe fallback -- always warns).

## Heartbeat System

See [heartbeat.md](heartbeat.md) for the full heartbeat reference -- what it is, how it works, overhead (~5ms/call), value to 6 consumers, why file-based, and write safety rules.

## Configuration

### settings.local.json hooks block

Add the following to `.claude/settings.local.json` in your project or workspace root:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/pre-compact-save.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/session-start-write-id.sh\"",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/session-start-recovery.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/branch-protection.sh\"",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/heartbeat.sh\"",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/session-end-autosave.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Replace `/path/to/` with your actual workspace or project path (e.g., `/home/user/workspace/.claude/hooks/`).

### jitneuro.json

Located at `.claude/jitneuro.json`. Central config for JitNeuro version, hook behavior, and settings.

```json
{
  "version": "0.1.3",
  "hooks": {
    "preCompactBehavior": "block",
    "autosave": true,
    "protectedBranches": ["main", "master"],
    "mainPushAllowed": [
      "https://github.com/yourorg/your-repo.git"
    ],
    "hookEvents": [...]
  }
}
```

| Setting | Default | Purpose |
|---------|---------|---------|
| `preCompactBehavior` | `block` | "block" halts compaction until user responds. "warn" lets it proceed. |
| `autosave` | `true` | Write `_autosave.md` breadcrumb on session end. Set false to disable. |
| `protectedBranches` | `["main", "master"]` | Branches that branch-protection hook blocks push to. |
| `mainPushAllowed` | `[]` | Full git remote URLs allowed to push to protected branches without approval. Must match `git remote get-url origin` exactly. Use for local dev repos and self-made internal tools where push-to-main is low risk. Force push is always blocked. |

Hook scripts read this config from `$(dirname "$HOOKS_DIR")/jitneuro.json` (one level up from hooks/).

For enterprise security considerations, see [enterprise-security.md](enterprise-security.md).

## How Hooks Work

Claude Code hooks are bash scripts that fire on specific lifecycle events. The flow:

1. An event occurs (e.g., compaction starts, a Bash command is about to run).
2. Claude Code checks `settings.local.json` for hooks registered to that event.
3. If a **matcher** is defined, only events matching that pattern trigger the hook. An empty matcher (`""`) matches all events of that type.
4. Claude Code pipes a JSON payload to the hook's stdin with event details (event type, tool input, session info, etc.).
5. The hook script runs and communicates back via exit codes and output:

| Exit Code | Meaning | Output Handling |
|-----------|---------|-----------------|
| 0 (proceed) | Allow the action | stdout is injected into Claude's context window |
| 2 (block) | Block the action | stderr is sent to Claude as feedback |

This means hooks can both inform Claude (exit 0 with stdout) and prevent actions (exit 2 with stderr).

## Adding Custom Hooks

Step-by-step for adding a new hook:

**1. Create a bash script in .claude/hooks/**

```bash
#!/bin/bash
# My custom hook
# Read event data from stdin
INPUT=$(cat)

# Parse fields with grep (no jq dependency)
FIELD=$(echo "$INPUT" | grep -o '"field_name"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

# Your logic here
echo "Message for Claude's context"
exit 0
```

**2. Add the event + matcher + command to settings.local.json**

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "optional-filter",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/path/to/.claude/hooks/my-hook.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Available events: `PreCompact`, `SessionStart`, `SessionEnd`, `PreToolUse`, `PostToolUse`, `SubagentStart`.

**3. Test manually**

```bash
echo '{"event":"PreToolUse","tool_input":{"command":"git status"}}' | bash /path/to/.claude/hooks/my-hook.sh
echo "Exit code: $?"
```

Check that exit codes and output match your expectations before relying on the hook in production.

## Troubleshooting

**Windows path issues:**
Use forward slashes in all hook paths (`C:/workspace/.claude/hooks/`, not `C:\workspace\.claude\hooks\`). Bash must be available in PATH -- Git for Windows includes bash at `C:/Program Files/Git/bin/bash.exe`.

**Script not firing:**
Check the matcher pattern in settings.local.json. An empty string (`""`) matches all events of that type. Run `/hooks` in Claude Code to verify registered hooks. Confirm the script path is correct and the file has execute permissions.

**JSON parsing issues:**
JitNeuro hooks use grep patterns instead of jq to avoid external dependencies. If you need complex JSON parsing, install jq and use `echo "$INPUT" | jq -r '.field'` instead of the grep approach.

**Timeout errors:**
Default timeout is 10 seconds (5s for branch-protection). If a hook needs more time, increase the `timeout` value in settings.local.json. Keep timeouts short -- hooks block Claude's execution while running.

**Hook blocks unexpectedly:**
If branch-protection blocks a push to main that you want to allow, add the repo's full upstream URL to `mainPushAllowed` in jitneuro.json. The URL must match `git remote get-url origin` exactly -- check with `git -C /path/to/repo remote get-url origin`. This is designed for local development repos and self-made internal tools where the owner is the sole committer and push-to-main is low risk. For shared repos or repos with CI gates, keep the RED zone protection and use explicit per-push approval instead.

## Future Hooks (Planned)

**Tier 2 -- Medium Value:**

| Hook | Event | Purpose |
|------|-------|---------|
| Subagent bundle injection | SubagentStart | Auto-inject domain bundles into subagents based on task context |
| Quality gate on Stop | PostToolUse | Run tsc/tests after Claude finishes a task, before declaring done |
| Async audit trail | PostToolUse (async) | Log all tool calls to .logs/ for compliance and debugging |

**Tier 3 -- Future:**

| Hook | Event | Purpose |
|------|-------|---------|
| Prompt router | UserPromptSubmit | Auto-detect bundle needs from prompt keywords and pre-load context |
| Config guard | ConfigChange | Block unauthorized changes to settings or CLAUDE.md files |
| Modified tool input | PreToolUse | Rewrite tool arguments before execution (e.g., inject defaults) |

See FEATURE-REQUESTS.md for full details (FR-014 through FR-016).
