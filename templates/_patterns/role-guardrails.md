---
type: pattern
purpose: BINDING for every org role agent before taking any GREEN/YELLOW/RED-zone action or before touching a file or resource outside its assigned task scope -- because an agent that does not consult this table before acting will execute RED-zone work without escalation, modify artifacts outside its write domain, or override higher-level decisions unilaterally, each of which bypasses governance and creates unrecoverable blast-radius in proportion to the role level.
read_when: Before any org role agent takes a GREEN/YELLOW/RED-zone action or touches a resource outside its assigned task scope.
tags: [role-authority, trust-zones, write-domain, blast-radius, scope-guardrail]
scope: public
last_evaluated: 2026-06-03
---

# Role Guardrails

**Used by:** All roles. Authority limits, blast-radius, override rules.
**Purpose:** Map each org level to the trust-zone actions it may take unilaterally.

---

## Foundation

Trust zones (RED / YELLOW / GREEN) are defined in `rules/trust-zones.md`.
This pattern adds the role-axis layer: which roles may take which zone actions,
and what the escalation path is when authority is exceeded.

---

## Authority Table by Role Level

| Role Level | GREEN (execute freely) | YELLOW (execute + report) | RED (stop + escalate) |
|------------|------------------------|---------------------------|-----------------------|
| CEO | All org-internal decisions, strategy docs, vendor selection | New infra commitments, new CxO hire, budget reallocations > 50K | Push to main on public-facing repos, external legal commitments, Owner equity decisions |
| CxO | Function-level decisions, hire/retire managers, function budget within envelope | New vendors for function, function scope changes, overrun up to 25% | Hire/retire CxO peers, cross-function policy, budgets over 125%, public crisis comms |
| CoS | Scheduling, routing, re-assignment, T2 escalation resolution | Cross-function coordination decisions, Owner-queue additions | Any action the CoS is not certain is within authority -- default to escalate |
| Manager | Task assignment, Specialist feedback, sprint scope | New tooling for team, task scope changes, retry-3 decisions | Hire/retire Specialists, new external API keys, schema changes |
| Specialist | Execute assigned task, produce artifact, file block | Request additional inputs, propose scope clarification | Modify artifacts outside their assigned scope, access Owner-level secrets |
| Skill | Invoke tool / API / model per assigned parameters | Log unexpected behavior, flag anomaly | Modify own config, self-assign new tasks, access unassigned data |

---

## Blast Radius Per Level

| Role Level | Max blast radius (what breaks if wrong) |
|------------|------------------------------------------|
| CEO | Company strategy misdirection; recoverable in 1-2 sprints |
| CxO | Function output degraded; recoverable in 1 sprint |
| CoS | Scheduling disorder; recoverable in hours |
| Manager | Sprint scope drift; recoverable same sprint |
| Specialist | Single artifact wrong; recoverable in task retry |
| Skill | Single tool call fails; recoverable instantly |

---

## Override Rules

A higher level may override a lower level's decision IF:
1. The override is logged in `governance/override-log.md` with rationale.
2. The overriding role is within its own authority for the action.
3. The overridden role is notified (not silently corrected).

A lower level MUST NOT override a higher level. Instead, file an escalation per
`_patterns/escalation-paths.md`.

---

## Write-Domain Discipline

Every role has a write domain -- files it may commit changes to.
Roles may READ any file. Roles may NOT commit changes outside their domain.

If a role finds an issue outside its domain: create a [SCOPE-ESCALATION] issue,
document the finding, continue own work. Do NOT fix it inline.

Full write-domain table: `rules/agent-scope-guardrail.md`.

---

## Scope-Violation Consequences

Scope violation rate is tracked per role. CCO reviews quarterly:
- 0-5%: within tolerance
- 5-10%: Manager notified, coaching issued
- > 10%: role enters probation (all artifacts L3-reviewed for 1 sprint)
- > 5% sustained over 2 quarters: factor in role-retirement review per `_patterns/role-retirement.md`

---

## Cross-References

- `rules/trust-zones.md` -- RED/YELLOW/GREEN action definition
- `rules/agent-scope-guardrail.md` -- write-domain per agent type
- `_patterns/escalation-paths.md` -- what to do when authority is exceeded
- `_patterns/role-retirement.md` -- sustained scope violations factor into retirement
- `_patterns/cxo-budget-overrun-25pct.md` -- CxO budget authority detail
