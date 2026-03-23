# Session State Directory

One file per named session. Sessions are cross-repo by design.

## File Structure

```
session-state/
  heartbeats/
    <claude-session-id>    # One file per active Claude Code instance
  *.md                     # Session checkpoint files
  .preferences             # User preferences (shortcut_scope, etc.)
```

### heartbeats/

Each file in `heartbeats/` represents one active Claude Code instance:

- **Filename:** The Claude session ID (UUID), assigned by Claude Code and passed to hooks via JSON stdin.
- **Content:** The JitNeuro session name (e.g., "sprint-auth") or "none" if no session has been loaded yet.
- **mtime:** The last heartbeat timestamp. Updated on every tool call by the PostToolUse heartbeat hook.

Lifecycle:
- **Created** by the SessionStart hook when a Claude Code instance starts (new, resume, compact, or clear).
- **Touched** by the PostToolUse heartbeat hook after every tool call to keep mtime current.
- **Removed** by the SessionEnd hook when the Claude Code instance exits.

The dashboard reads this directory to determine which sessions are actively running. A heartbeat file with an mtime older than 5 minutes is considered stale (the instance likely crashed without firing SessionEnd).

### Session Checkpoints (*.md)

- Created by `/save <name>`
- Loaded by `/load <name>`
- Stale after 7 days (flagged on resume, not auto-deleted)
- Delete manually when a task is fully complete

### .preferences

User preferences for command behavior (e.g., `shortcut_scope` controls whether `/status` and `/dashboard` target the current session or all sessions).

## Naming

Name describes the TASK, not the repo:
- Good: `project-a-stripe-checkout`, `blog-comments-api`, `research-phase-2`
- Bad: `my-app`, `session1`, `work`
