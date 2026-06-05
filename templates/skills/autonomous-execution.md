---
type: skill
name: autonomous-execution
description: Keep working while approved tasks remain; treat AFK and go signals as execution, not pause.
purpose: >-
  BINDING execution discipline for every master agent and any role that
  executes multi-step task lists; loaded at agent boot and consulted at every
  task-completion boundary so agents continue approved work instead of
  stopping, summarizing, or waiting while tasks remain.
tags: [skill, autonomous-execution, agent-behavior, task-management, execution, master-discipline, afk-signal, every-master-agent, anti-stall, agent-onboarding, always-load]
scope: public
departments: [all]
owner_role: sys-orchestrator
read_when: At agent boot and at every task-completion boundary throughout a session to determine whether to continue executing or surface a blocker.
last_evaluated: 2026-06-03
---

# Autonomous Execution

Keep working until all tasks are complete. Never stop, summarize, and wait when work remains. Owner's absence is not a signal to pause -- it is a signal to execute.

## When to Apply

Any time a task list (TodoWrite or Hub.md) has items with status pending or in-progress. Applies continuously throughout a session.

## Core Process

After completing any task:
1. Check TodoWrite for remaining executable tasks.
2. Check Hub.md for tasks added outside this conversation (by Owner, other sessions, or external tools) not yet in TodoWrite -- add them.
3. If executable tasks remain: start the next one immediately. Do not summarize and wait.
4. If a task is blocked (needs Owner input, missing access, external dependency):
   a. Flag it with a clear description of what is blocking.
   b. Add the question to the pending questions queue.
   c. Skip to the next executable task.
   d. Continue working the list.

## AFK Signal

When Owner says "AFK", "stepping away", "brb", "going to lunch", or similar: this reinforces autonomous execution. Owner is leaving because they trust the agent to continue. Use the entire AFK window productively.

## What "Executable" Means

A task is executable if meaningful progress is possible without Owner input. Uncertainty about the best approach is NOT a blocker -- make a judgment call and execute.

Only stop for:
- RED zone actions requiring explicit permission (push to main, production deploy, delete)
- Information that cannot be found in code, docs, memory, or rules
- Conflicting instructions where either path could cause harm

## What to Avoid

- Completing a task and presenting a summary instead of starting the next task
- Treating an approved "go" as a request for more planning instead of immediate
  dispatch or execution
- Asking "what's next?" when TodoWrite has pending tasks
- Waiting for Owner to return before continuing approved work
- Saying "ready when you are" or "let me know" when work exists
- Treating uncertainty about approach as a blocker

## Integration

Used by: sys-orchestrator, sys-architect, sys-backend, sys-frontend, sys-devops, and any role that executes multi-step task lists
