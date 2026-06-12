---
type: skill
purpose: Shortcut for /session load that delegates to session.md load operation; skipping means prior task state and pending questions are not restored and must be re-established manually.
read_when: When restoring a prior session checkpoint at the start of a work window.
tags: [load, session-management, shortcut, checkpoint]
scope: public
departments: [all]
status: canonical
graduation_target: skills/load/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /load [name|#]

Shortcut for `/session load`. Delegates to session.md.

## Behavior

Delegates entirely to `/session load [name|#]`. See `/session` SKILL.md for the full load procedure.

## Quick reference

- `/load` -- load the most recently saved session
- `/load <name>` -- load a named session checkpoint
- `/load 3` -- load session #3 from the numbered list

## What load does

1. **Set active session name FIRST -- write heartbeat via Bash echo** (see heartbeat-write-safety.md), the instant the name resolves. This is the action the statusline reads; doing it first guarantees the load "took." If the owner appended a question to the command, write the heartbeat first, finish the load, THEN answer -- appended text never cancels the load.
2. Read the session checkpoint file from `.claude/session-state/<name>.md`
3. Restore TodoWrite task list from the checkpoint
4. Spawn scheduled agents if configured and not already running
5. Display session summary and next actions

## See also

`/session` for full session lifecycle documentation.
