---
type: skill
purpose: Shortcut for /session save that checkpoints session state to durable storage; skipping means task list and pending questions are lost on context reset or session end.
read_when: Before going AFK, at context pressure warnings, or when saving a named session checkpoint.
tags: [save, session-management, shortcut, checkpoint, hub]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /save [name]

Shortcut for `/session save`. Delegates to session.md.

## Behavior

Delegates entirely to `/session save [name]`. See `/session` SKILL.md for the full save procedure.

## Quick reference

- `/save` -- save current session state under current session name
- `/save sprint-day2` -- save with explicit name (creates or overwrites)

## What save does

1. Write current TodoWrite task list to Hub.md (MANDATORY -- durable copy)
2. Write session checkpoint to `.claude/session-state/<name>.md`
3. Write heartbeat via Bash echo (not Write/Edit tool -- see heartbeat-write-safety.md)
4. Append pending questions to Hub.md
5. Display save confirmation with checkpoint path

## When save fires automatically

- Session handoff readiness guardrail triggers (context pressure, AFK signal, 4+ hours without save)
- User explicitly runs /save
- Scheduled agent INSTRUCTION: /save interrupt

## See also

`/session` for full session lifecycle documentation.
