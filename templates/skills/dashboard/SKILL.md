---
type: skill
purpose: Shortcut that delegates to /session dashboard or /sessions dashboard based on shortcut_scope preference.
tags: [dashboard, session-management, shortcut, blockers]
scope: public
status: canonical
graduation_target: skills/dashboard/SKILL.md
read_when: When Owner wants a quick status view of blockers and NEEDS OWNER items at the start of a work block.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /dashboard

Shortcut command. Delegates to session dashboard or sessions dashboard.

## Delegation logic

1. Read `.claude/preferences.json` for `shortcut_scope`
2. If `shortcut_scope == "sessions"`: run `/sessions dashboard`
3. Otherwise (default): run `/session dashboard`

## /session dashboard (default)

Shows blockers and NEEDS OWNER items for the current session:

- Current session name and status
- Open TODO items blocked on Owner input
- Pending questions queue
- In-flight background agents
- Open PRs awaiting Owner merge

## /sessions dashboard

Shows status across all active sessions:
- Numbered list of active sessions
- Each session's last-updated timestamp
- Blocked items count per session
- NEEDS OWNER summary across all sessions

## Use case

Quick status check at the start of a work block. Shows exactly what requires Owner attention before the Owner engages with any session.

## Implementation notes

- The deterministic dashboard renderer is bundled at `scripts/dashboard.sh`
  (usage: `dashboard.sh [session|sessions] [--current <name>]`). Use it for consistent
  output instead of hand-formatting, per the Runners-Over-Tokens principle.
