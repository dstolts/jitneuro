# Dashboard

Shortcut that delegates to `/session dashboard` or `/sessions dashboard` based on user preference.

## Instructions

When invoked as `/dashboard`:

1. Read `.claude/session-state/.preferences` for `shortcut_scope` setting
   - If `session` (default): execute `/session dashboard` (current session blockers)
   - If `sessions`: execute `/sessions dashboard` (all sessions aggregate NEEDS DAN)
2. Follow all instructions in the target command

This is a convenience shortcut. All logic lives in `/session dashboard` or `/sessions dashboard`.
