# Save

Shortcut for `/session save`. Delegates to the session command.

## Instructions

When invoked as `/save <name>`:

1. Read `.claude/session-state/.preferences` for `shortcut_scope` setting
   - If `session` (default): execute `/session save <name>`
   - If `sessions`: execute `/session save <name>` (save always targets current session)
2. Follow all instructions in the `/session save` section of session.md

This is a convenience shortcut. All logic lives in `/session save`.
