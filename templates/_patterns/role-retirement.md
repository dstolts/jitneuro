---
type: pattern
purpose: Any org-management agent or principal conducting a quarterly role review MUST apply this pattern before retiring or restructuring a role -- firing at the quarterly cadence or when a role is flagged as underperforming or redundant -- because skipping the structured sunset criteria and coexistence period causes premature retirement of roles that still carry hidden responsibilities, producing knowledge gaps and unassigned work that silently falls through the system.
read_when: At the quarterly org review cadence, or when any role is flagged as underperforming, redundant, or a zombie with zero task assignments.
tags: [role-retirement, org-management, chro, sunset-criteria, knowledge-transfer]
scope: public
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Role Retirement

**Used by:** CHRO (leads process), CFO (cost data), CCO (scope data), CEO (approves).
**Purpose:** Quarterly review process that identifies roles generating less value
than cost, redundant roles, and scope-violating roles. Structured sunset criteria
prevent both premature retirement and zombie-role accumulation.

---

## Quarterly Review Cadence

| Step | Owner | Timing |
|------|-------|--------|
| CFO pulls cost-per-role report | CFO + ROI Analyst Specialist | Q-end week 1 |
| CCO pulls scope-adherence report | CCO | Q-end week 1 |
| CHRO synthesizes retirement candidates | CHRO | Q-end week 2 |
| CEO reviews candidate list | CEO | Q-end week 2 |
| Retirement decisions + coexistence plan | CEO + CHRO | Q-end week 3 |
| Owner notified (if any RED-zone retirement) | CoS | Q-end week 3 |

---

## Sunset Criteria

A role is a retirement CANDIDATE if ANY of the following are true:

1. **Cost > revenue contribution for 2 consecutive quarters.**
   CFO calculates: (role API cost, Q over Q) vs (revenue attributed to role output,
   using attribution model in `governance/attribution-model.md`).
   Threshold: cost exceeds contribution by more than 20% for 2 Q.

2. **Scope-violation rate > 5% over 2 consecutive quarters.**
   CCO measures: (out-of-domain commits or artifacts / total commits or artifacts).
   A role that cannot stay in scope after 1 quarter of coaching is a retirement candidate.

3. **Functional overlap with a newer or higher-performing role.**
   CHRO identifies overlap when > 60% of a role's task types are also performed by
   another role with equal or better quality scores and lower cost.

4. **Zero tasks assigned for a full quarter.**
   A role that received no task assignments is a zombie role. Retire unless CHRO can
   document a specific planned activation in the next quarter.

---

## Retirement Decision

CEO decides. Criteria for approve vs reject:

- **Approve retirement** if: all sunset criteria are met AND no active in-flight tasks
  depend on the role AND a migration plan exists for the role's ongoing responsibilities.
- **Reject retirement** if: role is in a ramp-up phase (< 2 quarters active), OR
  role has a scheduled activation in next quarter, OR retiring would leave a
  critical responsibility unowned.

Owner approves retirement of any CxO role (RED zone -- irreversible org change).
CEO approves Manager and below.

---

## Coexistence Period

When retirement is approved:

1. Role enters "sunset" status for 1-2 sprints (CHRO sets duration).
2. During sunset: role accepts no new task assignments.
3. Responsible Manager completes or reassigns all in-flight tasks.
4. At sunset end: role is archived in `org/archived-roles/`.
5. Role's knowledge artifacts (knowledge-base files owned by the role) are
   transferred to the inheriting role or marked "unowned" for CCO audit.

---

## Knowledge Ownership Transfer

Before a role is archived, CHRO confirms:

- All knowledge-base artifacts owned by the role have a new `owner:` in frontmatter.
- All active playbooks referencing the role by name are updated.
- The `org/ORG-CHART.md` entry is moved to "Archived" section.

Unowned artifacts after a retirement are flagged by CCO in the quarterly
knowledge audit per `_patterns/knowledge-ownership.md`.

---

## Anti-Patterns

- Retiring a role mid-sprint because it is underperforming (wait for Q boundary).
- Retiring a role without a migration plan for its in-flight work.
- Keeping a zombie role "just in case" (zero-task roles cost real API budget).
- Owner approving Manager-level retirements (CEO authority -- do not escalate upward unnecessarily).

---

## Cross-References

- `_patterns/role-guardrails.md` -- scope-violation rate tracked here; feeds retirement
- `_patterns/knowledge-ownership.md` -- artifact ownership transfer on retirement
- `_patterns/cost-estimate-anchor.md` -- cost-per-role calculated at API rates
- `_patterns/cxo-budget-overrun-25pct.md` -- CxO cost authority; persistent overrun feeds retirement signal
