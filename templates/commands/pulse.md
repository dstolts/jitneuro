# Pulse

Shortcut for `/session pulse`. Re-read shared state from disk to sync this session with changes made by other sessions.

## Instructions

When invoked as `/pulse`:

1. Read `.claude/session-state/.preferences` for `shortcut_scope` setting
   - If `session` (default): execute `/session pulse`
   - If `sessions`: execute `/session pulse` (pulse always targets current session)
2. Follow all instructions in the `/session pulse` section of session.md

This is a convenience shortcut. All logic lives in `/session pulse`.
