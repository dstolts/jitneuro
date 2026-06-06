---
type: skill
purpose: Shortcut for /session pulse that re-reads shared state from other active sessions; skipping means stale task state when multiple sessions are running concurrently.
read_when: After returning from an AFK break or when another session or external tool has made changes that need to be reflected in the current session.
tags: [pulse, session-management, shortcut, shared-state, multi-session]
scope: public
departments: [all]
status: canonical
graduation_target: skills/pulse/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /pulse

Shortcut for `/session pulse`. Delegates to session.md.

## Behavior

Delegates entirely to `/session pulse`. See `/session` SKILL.md for the full pulse procedure.

## Quick reference

Pulse re-reads shared state that may have been updated by other active sessions:
- Hub.md (task state)
- Shared session-state files
- Any pending messages from other sessions

## When to use

- Returning from an AFK break
- After another session or tool has made changes
- Before a status report to ensure current data
- Periodically during long sessions to stay in sync

## See also

`/session` for full session lifecycle documentation.
