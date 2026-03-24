# Heartbeat File Write Safety

NEVER use Write or Edit tools on files in `.claude/session-state/heartbeats/`. Always use Bash:

```bash
echo -n "<session-name>" > ".claude/session-state/heartbeats/<session-id>"
```

The PostToolUse heartbeat hook touches these files after every tool call. Write/Edit will fail with "file modified since read" because the hook modifies the file between your Read and your Write. Bash echo is atomic and bypasses this check.

This applies to: `/load`, `/save`, `/session new`, `/session switch`, `/session rename` -- any operation that sets the active session name.
