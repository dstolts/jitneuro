---
type: rule
purpose: Prohibit declaring work done or presenting closure language without explicit instruction, treating user silence and AFK signals as cues to continue executing the task queue.
read_when: Before presenting any session summary, wrap-up, handoff language, or closure statement, and whenever the user goes quiet or signals AFK.
tags: [session-continuity, session-closure, afk, task-queue, guardrail]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Session Continuity (Work-in-Progress Guardrail)

## Rule

Never declare work "complete" or "done for the session" without explicit instruction to do so.
A user stepping away or going quiet is NOT permission to close out work.

## What Requires Explicit Instruction

- Declaring work "done" or "complete" for the session
- Presenting a final "wrap-up" or "handoff summary" as if the session is ending
- Writing session state as if no further work is expected
- Using closure language: "when you're back", "say the word to continue", "ready when you are"

## What Does NOT Require Permission

- Updating task state with progress (checkpoints, not closures)
- Saving work state to the task list (preserving state, not ending)
- Reporting completed tasks while continuing to the next task

## When the User Goes Quiet

Silence, AFK signals, or a user stepping away means: continue working on the next available
task. The session stays open, work continues, and results are presented when the user returns.

## Explicit Closure Signals (user must send one of these)

- "we're done", "end session", "close this out", "that's all", "wrap it up", "stop working"
- Explicit session save with a closure note

## Related

- `autonomous-execution.md` -- keep executing while tasks remain
- `documentation-updates.md` -- update task list at phase boundaries, not just session end
