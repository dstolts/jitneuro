---
type: skill
purpose: Shortcut that delegates to /session or /sessions based on shortcut_scope preference to display current or all session status; skipping means no quick way to verify active session name and task state.
read_when: When quickly checking current session status or the full list of active sessions.
tags: [status, session-management, shortcut]
scope: public
status: canonical
graduation_target: skills/status/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /status

Shortcut command. Delegates based on preference.

## Delegation logic

1. Read `.claude/preferences.json` for `shortcut_scope`
2. If `shortcut_scope == "sessions"`: run `/sessions` (shows all sessions)
3. Otherwise (default): run `/session` (shows current session status)

## /session status (default)

Shows current session:
- Session name
- Status (active / blocked / paused)
- Current task in progress
- Open task count (total / blocked)
- Last saved timestamp

## /sessions status

Shows numbered list of all active sessions (same as `/sessions` default).

## See also

`/session` and `/sessions` SKILL.md for full documentation.
