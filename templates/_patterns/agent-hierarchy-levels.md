---
type: pattern
purpose: MUST be consulted by any architect or agent designer choosing a background-work execution model before dispatching agents -- firing whenever a new agent, pipeline stage, or async workflow is being designed -- because selecting the wrong level (e.g., fire-and-forget when the caller needs results, or Level 6-7 enforcement when Level 2 suffices) produces either silent failures with no recovery path or unnecessary orchestration complexity that blocks composition with meta-orchestrators.
read_when: Before designing a new agent, pipeline stage, or async workflow, to select the correct background-work execution level.
tags: [agent-hierarchy, async-patterns]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
---

# Background Agents vs Fire-and-Forget

How agent orchestration systems handle background work across seven levels of sophistication -- from traditional async patterns to AI-driven autonomous task generation.

---

## Fire-and-Forget: The Baseline

Fire-and-forget is the standard async pattern in Node.js, Go, and most event-driven systems. Run a task, ignore the result, log errors, never block the caller.

This is the right tool for deterministic background work: audit logging, cache warming, analytics pings, webhook dispatches. The caller does not need the result. If the task fails, a log entry is sufficient.

**Characteristics:**
- One function, no tracking, no retry
- Caller continues immediately -- zero coupling to the background work
- Failure is acceptable and invisible to the caller
- No structured result, no completion notification

**Appropriate for:** Tasks where the answer is always "fire it and move on." The caller never needs to know what happened.

---

## The Problem: Fire-and-Forget in AI Workflows

In traditional async code, the background task is deterministic. "Write this row to the audit table" either works or it does not. The caller never needs the result because the result is always the same.

AI agent tasks are fundamentally different. The agent reasons, discovers, and sometimes hits ambiguity. A fire-and-forget agent that discovers something unexpected has no way to report it back.

---

## Seven-Level Hierarchy

This pattern starts with fire-and-forget (Level 1) and builds upward, adding capability at each level. Each level adds a feature the previous level cannot provide.

Levels 1-5 are background patterns. Levels 6-7 are enforcement and task generation.

**Key principle:** Choose the lowest level that solves your problem. Levels 6-7 add complexity; don't use them for work that Levels 1-3 handle fine.

(Full seven-level descriptions are in the source document. Stages include: Fire-and-Forget, Fire-and-Notify, Fire-and-React, Fire-and-Continue, Fire-and-Orchestrate, Watcher Enforcers, and Task-Driven Agents.)

---

## Scheduled Agents Extend Further

Background agents (Levels 1-7) are one-shot by default. Scheduled agents add recurrence, priority, and lifecycle management on top of the same foundation.

Four scheduled agent types build on the background agent hierarchy:

| Type | Context | Purpose |
|------|---------|---------|
| timer | Internal (live session) | Periodic housekeeping: auto-save, Hub sync |
| enforcer | Internal (live session) | Discipline enforcement: task completion, rule compliance |
| cron | External (launches session) | Nightly audit, batch scoring, content pipeline |
| batch | External (launches session) | One-time bulk operations with agent pool management |

---

## Why Structured Returns Matter

The core difference between fire-and-forget and a sophisticated agent hierarchy is the structured return. Fire-and-forget discards results. Each level above adds what the previous level cannot: completion notification, status codes, continuation context, orchestration, enforcement, task generation.

This is load-bearing for AI workflows. Fire-and-forget works for deterministic tasks. AI agents need richer feedback to be useful.
