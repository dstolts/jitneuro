---
type: rule
purpose: Require durable task-list, decision-log, and architecture-context files to be updated at phase boundaries rather than deferred to session end, so state survives context resets.
read_when: At each phase or milestone boundary during a session, and before ending or handing off any work in progress.
tags: [documentation, task-list, hub-md, phase-boundary, session-state]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Context and Documentation Updates

## Active Task List (Hub.md or equivalent)

Maintain a durable task list that survives session resets. In-memory task lists are volatile
and will be lost when a session ends or context resets. The durable file is the source of truth.

- Update status as tasks complete -- do not wait until session end
- When adding, completing, or removing a task, update the durable file in the same action
- ACTIVE TODO items should be sequentially numbered; numbers do not repeat while items remain open
- History sections preserve original numbers for cross-reference

## Decision Log

Log all significant decisions with date and reasoning in a decision log file. Include:
- What was decided
- Why (alternatives considered, constraints, owner directive)
- Date

## Architecture Context (Engrams or equivalent)

Update architecture context files at sprint/milestone completion when features are added,
removed, or changed. Exception: update immediately if a change affects architecture or adds
a major integration.

Context files store project-specific facts and confirmed patterns ONLY -- never duplicate
rules or preferences already defined in framework config. Repo config files may intentionally
repeat global rules as a safety net; that duplication is correct and should not be removed.

## Phase-Boundary Update Discipline

At every phase / major-milestone boundary -- sprint completion, multi-stage process advancement,
agent-batch return, council round closure -- update the task list and decision log immediately.
Not at session end.

State changes that wait for session save risk loss on context reset. The task list is the
durable record of current state; if it lags reality by more than one phase boundary, it is stale.

**How to apply:**
- After each stage completion: append phase-boundary update to the task list before responding to the user
- Include: what just shipped, what's next, any state that another session would need to pick up
