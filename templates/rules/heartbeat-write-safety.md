---
type: rule
purpose: Prevent Write/Edit tool race conditions on heartbeat files by requiring Bash echo instead -- any session operation that sets the active session name will silently corrupt the heartbeat if Write/Edit is used.
read_when: Before any session operation that writes to heartbeat files (/load, /save, session new, session switch, session rename) -- Write/Edit causes a race with the PostToolUse hook and corrupts session state.
tags: [heartbeat, session-management, hooks, race-condition, tools]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# Heartbeat File Write Safety

NEVER use Write or Edit tools on files in `.sessions/heartbeats/`. Always use Bash:

```bash
echo -n "<session-name>" > ".sessions/heartbeats/<session-id>"
```

The PostToolUse heartbeat hook touches these files after every tool call. Write/Edit will fail with "file modified since read" because the hook modifies the file between your Read and your Write. Bash echo is atomic and bypasses this check.

This applies to: `/load`, `/save`, `/session new`, `/session switch`, `/session rename` -- any operation that sets the active session name.
