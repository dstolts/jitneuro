# Load

Shortcut for `/session load`. Delegates to the session command.

## Instructions

When invoked as `/load <name|#>`:

0. **FIRST, UNCONDITIONALLY -- write the heartbeat.** Before reading preferences, before answering any question, before anything else: resolve the session name from the argument and write it to the heartbeat (Bash echo, never Write/Edit -- see `heartbeat-write-safety`):
   ```bash
   echo -n "<name>" > ".sessions/heartbeats/<session-id>"
   ```
   This is the single action the statusline reads to resolve the active session. Skip it and the statusline shows `?`/none and the session is effectively not loaded.
   **CRITICAL -- appended-text trap:** If the owner appends a question or extra prose to the command (e.g. `/load <name> <some question>`), that does NOT cancel the load. Write the heartbeat FIRST, run the full load flow, THEN address the appended text. Appended text is an additional request, never a replacement for the load procedure.
1. Read `.sessions/.preferences` for `shortcut_scope` setting
   - If `session` (default): execute `/session load <name|#>`
   - If `sessions`: execute `/session load <name|#>` (load always targets current session)
2. Follow all instructions in the `/session load` section of session.md

This is a convenience shortcut. All logic lives in `/session load`.
