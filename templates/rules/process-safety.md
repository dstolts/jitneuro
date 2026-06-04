---
type: rule
purpose: Prohibit spawning processes, running tests, or triggering hooks that could crash the IDE, close terminals, or kill other agent sessions.
tags: [process-safety, ide, terminal, session-protection, spawn]
scope: public
read_when: Before running any command that launches a new process, spawns a secondary agent CLI, or triggers a hook from within a running session.
last_evaluated: 2026-06-03
---
# Process Safety

Never spawn processes, run tests, or trigger hooks that could crash the IDE, close terminals, or kill other agent sessions.

## Why

Spawning new processes from within a session is unpredictable -- new windows may open, existing sessions may be killed, and the user loses all unsaved work across all terminals.

## How to apply

Before running any command that launches a new process (code CLI, wt, secondary agent CLI), consider whether it could affect other open windows or terminal sessions. If uncertain, ask the user first.

Never attempt to programmatically close/reopen the IDE or spawn new agent instances from within a running session.
