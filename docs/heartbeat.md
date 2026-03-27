# Heartbeat System

## What It Is

A heartbeat is a file in `.claude/session-state/heartbeats/` named after the Claude session ID. Its content is the JitNeuro session name (e.g., "jitneuro"). Its modification time (mtime) is the last time Claude did anything.

```
.claude/session-state/heartbeats/
  63e31988-4cbe-4223-826d-dcf56d742774    content: "jitneuro"    mtime: 2s ago
  a1b2c3d4-e5f6-7890-abcd-ef1234567890    content: "aifs-ci-fix" mtime: 3m ago
```

## How It Works

Three hooks manage the heartbeat lifecycle:

| Hook | Event | What it does |
|------|-------|-------------|
| session-start-write-id.sh | SessionStart | Creates heartbeat file, injects session ID into Claude's context |
| heartbeat.sh | PostToolUse | Touches the file (updates mtime) on EVERY tool call |
| session-end-autosave.sh | SessionEnd | Reads session name from heartbeat, then removes the file |

## Overhead

The PostToolUse heartbeat hook fires on every single tool call. Measured overhead:

- **Per-call:** ~5ms (bash touch on an existing file)
- **200-tool session:** ~1 second total
- **Async:** Non-blocking. Claude doesn't wait for it.

This is the cheapest hook in the system. A file `touch` is a single filesystem syscall.

## Value

| Consumer | What it reads | What it gets |
|----------|--------------|-------------|
| **Session tracking** | File content | Which JitNeuro session this Claude instance is running |
| **Housekeeper agent** | File mtime | Is master still working? (stale = idle or hung) |
| **Dashboard** | All heartbeat files | Which sessions are active RIGHT NOW, real-time |
| **Multi-instance safety** | File per session-id | Two terminals can't overwrite each other's session |
| **SessionEnd hook** | File content + existence | What to save on exit, then removes file to signal "gone" |
| **/sessions command** | All heartbeat files | Mark active session with `*` in list |

## Why File-Based (Not In-Memory)

Heartbeats must survive context compaction, /clear, and crashes. In-memory state dies with the context window. A file on disk is the simplest durable signal. Any process (hooks, agents, dashboard, other terminals) can read it without access to Claude's conversation.

## Write Safety

**Never use Write or Edit tools on heartbeat files.** The PostToolUse hook touches the file after every tool call. Write/Edit will fail with "file modified since read" because the hook modifies the file between your Read and Write. Always use Bash: `echo -n "<name>" > "heartbeats/<session-id>"`.
