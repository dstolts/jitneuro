---
owner-role: cos
type: pattern
purpose: Continuous-improvement operating pattern for specialists, managers, CxOs, and CoS when establishing or auditing KPI/cadence accountability; skipping it lets observed friction recur without tracked ownership or quarterly closure pressure.
read_when: When establishing or auditing KPI ownership, cadence accountability, or friction-reporting processes for any role.
tags: [continuous-improvement, kaizen, kpi, managers, quarterly]
scope: public
last_evaluated: 2026-06-03
reviewed: 2026-05-06
community_reviewed: 2026-06-02
---

# Continuous Improvement

## Purpose

Process improvement is an ongoing responsibility, not a one-time deliverable.
Every manager and chief carries a process-improvement KPI. The system should get
better, not just do work. Friction that is observed and not reported is friction
that will recur. Improvement proposals that are not tracked are proposals that
will decay.

A healthy organization treats process improvement as an ongoing operational
responsibility. Friction that is observed and not reported is friction that
will recur unchecked.

---

## Per-Role Responsibility

### Specialists (individual contributors, engineers, agents)

- Surface friction through lessons-learned entries in the team's knowledge
  system -- weekly minimum
- Friction includes: slow tools, repeated mistakes, unclear handoffs, validation
  gaps, ambiguous role boundaries, any "I had to figure this out the hard way"
- Specialists do not propose improvements directly; they surface raw friction
  so the managing layer can aggregate and pattern-match

### Managers

- Aggregate friction signals from their function each week
- Propose 1+ improvement per quarter to their CxO in writing (PR or tracked task)
- Track closure rate of their own improvement proposals (target: 70%+)
- KPI: improvements proposed per quarter (target: 1+); closure rate (target: 70%+)

### CxOs (chiefs)

- Review their managed managers' improvement velocity monthly
- Sponsor 1+ cross-function improvement per quarter (improvements that span two
  or more direct reports, or that touch a shared workflow)
- Surface systemic improvement needs to CoS for portfolio tracking
- KPI: cross-function improvements sponsored per quarter (target: 1+);
  function improvement velocity (proposals closed within 90 days, target: 80%+)

### CoS (Chief of Staff)

- Aggregates all CxO improvement proposals into the portfolio backlog
- Delivers a quarterly retro to the principal (owner/board): top 5 systemic
  improvements landed, top 3 in flight, top 3 stale (open > 180 days) with
  escalation recommendation
- Flags stale improvements (> 180 days open) to the responsible CxO; escalates
  to the principal if the CxO has not unblocked within 14 days of flag
- KPI: quarterly retro delivered on schedule; stale count below 3 per quarter

---

## Cadence

| Cadence | Who | Action |
|---|---|---|
| Daily | Specialists | Capture friction in the team knowledge system (lessons-learned) |
| Weekly | Managers | Review function friction; queue improvement proposals |
| Monthly | CxOs | Review managed managers' improvement velocity; propose cross-function items |
| Quarterly | CoS + Principal | Portfolio retro -- top landed, top in flight, top stale |

---

## Improvement Types

Classify every proposed improvement before tracking it. Classification determines
who owns the fix and which artifact is updated.

| Type | Description | Target artifact |
|---|---|---|
| Tooling | Slow command, missing automation, manual repetition | Script, automation config |
| Pattern | Ambiguous role boundaries, validation gaps, escalation friction | `_patterns/*.md` |
| Charter | Role scope drift, missing authority, KPI misalignment | `org/*/*/CHARTER.md` |
| Workflow | Handoff inefficiency, sequential where parallel possible, missing trust-ratchet | `workflows/*.workflow.md` |
| Cost | Per-task cost trending up; model-tier or tooling mismatches | Finance lead + manager review |

---

## Improvement KPIs (per tier)

### Manager tier
- Improvements proposed per quarter: target 1+
- Improvement closure rate: target 70%+ (closed within 90 days of proposal)

### CxO tier
- Cross-function improvements sponsored per quarter: target 1+
- Function improvement velocity: 80%+ of proposals closed within 90 days

### CoS
- Quarterly retro delivered: 4x per year, on schedule
- Stale improvements (open > 180 days) in portfolio: target below 3

---

## Anti-Patterns

- "We have always done it this way" -- defaults are not principles; every default
  is a candidate for improvement
- Improvement-by-meeting -- write the improvement as a PR or tracked task; do not
  discuss it across three conversations and then forget it
- Theatrical retros -- if no items landed since the last retro, the retro is
  reporting a failure; name it and fix the velocity, not the report
- Ownership drift -- every improvement has a named owner role; orphaned improvements
  (no owner, no CxO sponsor) are deleted from the backlog after 180 days, not
  silently kept
- Stacking proposals without closures -- a manager who proposes 8 improvements and
  closes 2 is underperforming; throughput matters more than ideation volume

---

## Cross-References

- `_patterns/role-retirement.md` -- when an improvement retires a role entirely
- `_patterns/knowledge-ownership.md` -- every improvement artifact has an owner
- `_patterns/principal-attention-budget.md` -- improvements needing principal time
  go through CoS triage before escalation
- `governance/PR-CHECKLIST.md` -- all improvements ship via PR; checklisted there
