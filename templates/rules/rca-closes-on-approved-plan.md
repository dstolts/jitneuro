---
type: rule
purpose: BINDING for every master/orchestrator agent closing an RCA -- when the solution is substantial (multi-week, 3+ files, 2+ repos, or introduces a named process), a standalone plan document MUST be drafted and Owner-approved before the RCA is closed; closing on inline bullets means the plan is unstable, evolves after closure, and loses its approval gate, letting unreviewed implementation details reach production.
trigger: any agent about to close or declare closure on an RCA whose proposed solution spans multiple components, repos, or weeks of effort
tags: [rca, root-cause-analysis, planning, approval, documentation]
scope: public
read_when: Before closing or declaring closure on any RCA whose solution touches multiple components, repos, or weeks of effort.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_rca_closes_on_approved_plan.md) -- Knowledge session 2026-06-01
---

# RCA Closes on an Approved Plan Document

## Rule

When an RCA solution is substantial, write and get Owner approval on a standalone
PLAN document before closing the RCA. The RCA closure then references the approved
plan. Do not close the RCA on an inline bullet list of proposed steps.

### What counts as substantial (any one of these)

- Multi-week effort
- 3 or more new files or components
- Touches 2 or more repos
- Introduces a named process, pipeline, or framework

### Closure sequence for substantial solutions

1. Draft the plan at a stable path (e.g., `horizon/plan-{name}.md` or `docs/plan-{name}.md`).
2. Present plan to Owner for approval.
3. Iterate until Owner approves.
4. Close the RCA -- closure text references the plan doc path as the solution.
5. RCA artifact has a "Solution reference: see plan-{name}.md" pointer, not a step list.

### Small-fix RCAs

For 1-2 line rule updates, single config changes, or known-bug workarounds: close
with inline solution. No plan doc needed.

### Owner override

If Owner asks to close the RCA inline ("just capture it, no plan doc needed"), do
that. Owner direction wins.

## Why

An inline "proposed solution" in an RCA memory file becomes stale the moment the
plan is refined. A pointer to a living plan doc stays correct as the plan evolves.
The plan doc also gets its own approval gate, which keeps RCA closure clean: one
decision, one artifact, one approval.

Owner 2026-04-21: "Closing the RCA only opens the discussion on the new plan. I think
we should build the plan first, so the RCA can reference the new approved plan."

## What violates this rule

- Closing a substantial RCA on a bullet list of proposed steps without a plan doc.
- Writing a plan doc after RCA closure (plan must be approved BEFORE closure).
- Using "plan written, owner will review later" as a proxy for plan approval.

## Origin

2026-04-21: RCA on "content pipeline starts too late." I offered to close RCA on an
inline proposed solution. Owner correction: build the plan first, close RCA pointing
to the approved plan. Plan written in a dedicated plan doc,
approved, RCA closed referencing it.
