# Load

Shortcut for `/session load`. Delegates to the session command.

## Instructions

When invoked as `/load <name|#>`:

1. Read `.claude/session-state/.preferences` for `shortcut_scope` setting
   - If `session` (default): execute `/session load <name|#>`
   - If `sessions`: execute `/session load <name|#>` (load always targets current session)
2. Follow all instructions in the `/session load` section of session.md

This is a convenience shortcut. All logic lives in `/session load`.
