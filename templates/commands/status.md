# Status

Shortcut that delegates to `/session` or `/sessions` based on user preference.

## Instructions

When invoked as `/status`:

1. Read `.claude/session-state/.preferences` for `shortcut_scope` setting
   - If `session` (default): execute `/session` (current session status)
   - If `sessions`: execute `/sessions` (all sessions list + NEEDS DAN)
2. Follow all instructions in the target command

This is a convenience shortcut. All logic lives in `/session` or `/sessions`.
