# JitNeuro Hooks

Claude Code hooks that fire on specific events during a session.
All hooks are configured in `.claude/settings.local.json` (or `settings.json`).

## Installed Hooks

### 1. PreCompact Save Prompt (pre-compact-save.sh)

**Event:** `PreCompact` | **Matcher:** all | **Timeout:** 10s

Fires before context compaction. Prompts Claude to offer `/save` so session
state is checkpointed before context gets compressed.

**Configuration** (jitneuro-hooks.json):
| Value | Behavior |
|-------|----------|
| `warn` (default) | Message injected into context. Claude asks about /save. Compaction proceeds. |
| `block` | Compaction blocked (exit 2). User must respond before compaction can proceed. |

### 2. Post-Compact Context Recovery (session-start-recovery.sh)

**Event:** `SessionStart` | **Matcher:** `compact` | **Timeout:** 10s

Fires when a session resumes after compaction. Reads the most recent session
state file and re-injects it into Claude's context window. This restores
awareness of: active task, loaded bundles, modified files, next steps.

stdout from this hook goes directly into Claude's context -- no user action needed.

### 3. Branch Protection (branch-protection.sh)

**Event:** `PreToolUse` | **Matcher:** `Bash` | **Timeout:** 5s

Intercepts every Bash command and blocks RED zone git operations:
- `git push ... main/master` -- blocked (requires Dan's permission)
- `git push --force` -- blocked (destructive)
- `git branch -D` -- blocked (force delete)
- `git reset --hard` -- blocked (discards uncommitted work)

Exit code 2 blocks the command and sends the reason back to Claude.
Claude will inform the user and ask for permission before retrying.

### 4. Session End Auto-Save (session-end-autosave.sh)

**Event:** `SessionEnd` | **Matcher:** all | **Timeout:** 10s

Safety net that writes a minimal breadcrumb when a session terminates.
Captures: timestamp, exit reason, duration, working directory.

This is NOT a full /save -- it only records that a session ended and where.
If the user forgot to /save, this file confirms a session was active.
Written to `.claude/session-state/_autosave.md` (overwritten each time).

## Installation

Add to `.claude/settings.local.json`:

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

Replace `/path/to/` with your actual workspace or project path.

## Files

| File | Event | Purpose |
|------|-------|---------|
| pre-compact-save.sh | PreCompact | Prompt /save before compaction |
| session-start-recovery.sh | SessionStart | Re-inject context after compaction |
| branch-protection.sh | PreToolUse (Bash) | Block RED zone git operations |
| session-end-autosave.sh | SessionEnd | Safety net breadcrumb on exit |
| jitneuro-hooks.json | Config | Hook behavior settings |

## Future Hooks (Planned)

**Tier 2 -- Medium Value:**
- Subagent bundle injection (SubagentStart) -- auto-inject domain bundles into subagents
- Quality gate on Stop (agent hook) -- run tsc/tests after Claude finishes
- Audit trail (PostToolUse, async) -- log all tool calls to .logs/

**Tier 3 -- Future:**
- Prompt router (UserPromptSubmit) -- auto-detect bundle needs from prompt keywords
- Config guard (ConfigChange) -- block unauthorized settings changes
- Modified tool input (PreToolUse) -- rewrite tool arguments before execution

See FEATURE-REQUESTS.md for full details (FR-014 through FR-016).
