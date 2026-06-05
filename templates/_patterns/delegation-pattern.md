---
type: pattern
purpose: Any manager-level agent or CoS routing work to specialist agents MUST consult this before dispatching tasks -- firing when decomposing a goal into parallel or sequential subtasks, or when validating a specialist's return -- because skipping it causes tasks to be dispatched without authority boundaries, producing overlapping work, no clear acceptance criteria, and return artifacts that cannot be validated against the original goal.
read_when: Before decomposing a goal into subtasks for specialist agents or validating a specialist's returned artifact.
tags: [delegation, role-chain, task-routing, parallel-execution, managers]
scope: public
departments: [all]
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Delegation Pattern

**Used by:** CoS, all CxO roles, all Manager roles
**Purpose:** How a manager decomposes a goal into routed work for specialists.

---

## Principle

A manager's job is to translate a goal into well-scoped tasks and route each task
to the role best equipped to execute it. Managers do not execute specialist work --
they own the decomposition, routing, hand-off, and validation loop.

Master-level delegation is governed by the framework's master-delegation rule
(`rules/master-delegation.md`). This pattern extends that rule into the org hierarchy.

---

## Role Chain

Each work item flows through a chain from strategic to execution:

```
Owner (sets direction)
  -> CEO (translates to company-level goal)
    -> CxO (translates to function-level objective)
      -> CoS (schedules, routes, tracks)
        -> Manager (scopes + assigns individual tasks)
          -> Specialist (executes bounded task)
            -> Skill (invokes tool / API / model)
```

No level should skip a link. A CxO does not assign tasks directly to Skills.
A Specialist does not accept goal-level directives; they accept task-level scope.

---

## Decomposition Steps (Manager)

1. **Receive objective** from CxO (measurable outcome, deadline, budget envelope).
2. **Break into tasks.** Each task must have:
   - One output artifact (file, score, draft, report, commit)
   - Clear acceptance criteria (how do we know it is done?)
   - Estimated cost/time (anchor to real API rates, not subscription-flat cost)
   - Named owner role
3. **Check routing weights.** Match task topic to specialist role using the
   framework's routing-weights index or the org chart (`org/ORG-CHART.md`).
   Route to the most specific match.
4. **Hand off with full context.** The specialist receives:
   - Task scope (not the full objective)
   - Input artifact paths
   - Output artifact path + format
   - Acceptance criteria
   - Return protocol (see `rules/subagent-communication.md` for the STATUS/FILES/RESULT schema)
5. **Validate return.** Manager checks STATUS + acceptance criteria before marking done.
   If STATUS: BLOCKED, route the blocker per the escalation-paths pattern.
6. **Report up.** Summarize completion to CxO -- STATUS, output path, cost actual vs estimate.

---

## Routing Logic (Role-Chain)

When a task spans multiple domains, the Manager routes to the primary owner and
lists dependencies. The primary owner is responsible for pulling inputs from
secondary roles; the Manager does not split the task into sub-tasks across roles
unless the sub-tasks are independently deliverable.

```
Task: "Publish blog post on AI security"
Primary owner: Content Production Mgr
Dependencies: Brand Voice & Moat Mgr (voice compliance check)
Routing: Content Production Mgr receives full task; pulls brand-voice check inline.
```

---

## Parallel Execution

Default is parallel when work items are independent. Independent means: no shared file conflicts
and no sequential output-input dependency between items.

**Rule:** When a Manager dispatches multiple specialists for independent work, the dispatch is
parallel -- a single message with multiple Agent tool calls fired simultaneously.

Sequential dispatch applies ONLY when:

- (a) Output of agent A is required as input to agent B (hard dependency)
- (b) Two agents would write to the same file (shared file conflict)
- (c) A rate-limit or cost concern justifies serialization (document why when invoked)

**Safe concurrency ceiling:** 10-12 concurrent agents (API rate limit threshold is
approximately 20; do not approach it -- see `rules/context-safety.md`).

**Wave pattern** for large batches:

```
Wave 1: dispatch all agents with no upstream dependencies (parallel)
  -> validate all wave-1 returns
Wave 2: dispatch agents that depend on wave-1 outputs (parallel within wave)
  -> validate all wave-2 returns
...
```

**Concrete examples:**

| Work items | Execution |
|---|---|
| Author 5 independent charter files | Parallel (5 agents, single dispatch) |
| Author a charter, then validate it | Sequential (validation depends on authored output) |
| Run brand-voice scan across 8 posts | Parallel (no inter-post dependency) |
| Generate script, then produce audio | Sequential (audio depends on script) |
| Classify 50 leads from a batch CSV | Parallel agents on slices (no cross-slice dependency) |

**Cross-references:**

- `rules/master-delegation.md` -- what the orchestrator keeps vs delegates (parent rule)
- `rules/context-safety.md` -- concurrency ceiling + batching discipline
- `_patterns/producer-validator-pattern.md` -- validator separation rule

---

## Anti-Patterns

- Manager writes the deliverable instead of assigning it (violates master-delegation rule)
- CxO hands a goal directly to a Specialist, bypassing Manager routing
- Task handed off without acceptance criteria (Specialist cannot know when done)
- Manager waits for Specialist to ask what to do (push, do not pull)
- Routing to a generic role when a specific role exists (e.g., routing SEO work
  to "Content Writer" when "SEO Content Specialist" exists)

---

## Cross-References

- `rules/master-delegation.md` -- what the orchestrator keeps vs delegates
- `rules/subagent-communication.md` -- return protocol for all delegated work
- `rules/cost-estimate-anchor.md` -- how to estimate task cost at API rates
- `_patterns/escalation-paths.md` -- what to do when a specialist is blocked
- `_patterns/validation-gates.md` -- how to validate the returned artifact
