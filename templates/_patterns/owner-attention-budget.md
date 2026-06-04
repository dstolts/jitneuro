---
type: pattern
purpose: Any CoS agent or function-lead routing a request to the principal MUST verify the attention budget before dispatching -- firing every time a question, review, or approval is about to be surfaced to the owner -- because skipping the budget check causes individual function-leads to fragment principal time with unbatched requests, depleting the weekly cap and leaving higher-priority decisions without an owner review slot.
read_when: Before surfacing any question, review request, or approval to the principal; enforced by CoS on every function-lead escalation.
tags: [attention-budget, cos, escalation-batching, time-budget, function-routing]
scope: public
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Principal Attention Budget

**Used by:** Chief of Staff (enforces), all function leads (consume budget).
**Purpose:** Weekly principal-time cap per function. CoS blocks function-lead requests that
exceed the budget without a filed justification.

---

## Why This Exists

The principal's time is the scarcest resource. Without a budget, each function lead independently
believes its escalation is the most urgent. The aggregate is decision overload.
CoS holds the budget and acts as gatekeeper -- not to block good decisions, but
to batch and prioritize so the principal's 30-second reviews happen, not 30-minute ones.

Recommended presentation format: recommended option first, enough context to answer
in 2 seconds without follow-up.

---

## Default Weekly Budgets

These are proposals. The principal adjusts by editing this file or telling CoS.

| Function | Default principal-minutes/week | Notes |
|----------|-------------------------------|-------|
| CoS (all routing) | 20 min | CoS batches all other function requests; this is the one weekly sync |
| Marketing | 30 min | Content approvals, campaign direction |
| Finance | 15 min | Budget overrun approvals, vendor contracts |
| Technology | 20 min | Architecture decisions, new external APIs |
| Compliance | 10 min | Policy exceptions, legal exposure flags |
| Operations | 15 min | Process changes, incident postmortems |
| Strategy | 25 min | Quarterly priority reframes, new venture decisions |
| People | 10 min | Role retirements, new role proposals |

Total default: ~145 min/week. CoS collapses overlapping requests to keep actual
principal time closer to 60-90 min/week through batching.

---

## Budget Enforcement

CoS tracks consumed minutes in `governance/principal-attention-log.md`.
Format per entry:
```
YYYY-MM-DD | Marketing | Topic: <brief label> | Minutes: 5 | Outcome: approved
```

When a function lead submits a request that would exceed the weekly budget:

1. CoS holds the request in queue.
2. CoS notifies the function lead: "Budget consumed for this week. Request queued for
   next cycle or file an urgency justification."
3. Urgency justification format:
   - What is the cost of waiting 7 days? (concrete: lost revenue, legal risk, etc.)
   - Who else is blocked until the principal decides?
   - What is the recommended default if the principal does not decide?
4. CoS elevates justified urgencies only. CoS resolves the rest with the
   recommended default and logs it.

---

## Batching Rules

CoS MUST batch when possible:

- Consolidate same-function requests into one principal touchpoint (not one message per decision).
- Auto-apply technical defaults where the correct answer is unambiguous; escalate only genuine judgment calls.
- Format principal-facing batches as: recommended option first, 2-second read, numbered
  choices only when choice is genuinely required.

---

## Overflow Handling

If the principal's weekly budget is exhausted and unresolved items are accumulating:

1. CoS applies recommended defaults to all auto-applicable items (log each).
2. CoS carries unresolved judgment calls to the next weekly touchpoint.
3. CoS surfaces the backlog at the start of the next principal interaction:
   "Carried from last week: [N items]. Here are the [K] that still need judgment."

---

## Cross-References

- `rules/auto-apply-triage.md` -- auto-apply vs escalate decision logic
- `_patterns/escalation-paths.md` -- T2/T3 escalation feeds into this budget
- `_patterns/autonomous-execution-with-validators.md` -- how agents resolve without consuming principal budget
