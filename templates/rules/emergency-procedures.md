---
type: rule
purpose: Define the recovery sequence (save state, list files and line numbers, reload from checkpoint) for context-limit emergencies so work can resume without loss.
read_when: When approaching context limits mid-task, or when a session needs to hand off in-progress work to a fresh context.
tags: [emergency, context-limits, recovery, checkpoint, session-state]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Emergency Procedures (Context Limits)

When approaching context limits mid-task:

A. Save work state to the active task list (Hub.md or equivalent) and any in-progress files
B. List exact files and line numbers for continuation
C. After reset: re-read the project config (CLAUDE.md or equivalent), load previous state
   from the task list, and continue from the last checkpoint

## Why

Context resets without saved state mean re-doing work already done. The task list and
explicit file references are the recovery mechanism. Without them, the next session
starts from zero.
