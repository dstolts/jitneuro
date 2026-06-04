---
type: pattern
purpose: Defines an OPT-IN CxO self-approval authority for budget overruns (disabled by default; owner decides) and the forced renegotiation trigger at sustained 110%; read when a CxO function is over budget or when configuring CFO oversight touchpoints.
read_when: When a CxO function is projected to exceed its budget envelope or when configuring CFO budget-governance touchpoints.
tags: [budget, cxo-authority, cost-control, cfo, spend-governance]
scope: public
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# CxO Budget Overrun: 25% Authority

**Used by:** All CxO roles, CFO (tracks), CoS (enforces).
**Purpose:** When explicitly enabled, CxOs may self-approve up to 25% over their
function's budget envelope, subject to 4 conditions. Above 125% always requires the
owner. Sustained overrun triggers forced renegotiation.

## Configuration Flag: CxO Self-Approval (default: OFF)

```
cxo_self_approval_enabled: false   # default
```

**Default (flag OFF):** there is NO self-approval override. EVERY overrun above 100%
of envelope routes to the owner for an explicit decision before spend. CxOs cannot
authorize their own overrun at any percentage. This is the safe default -- the owner
retains the spend decision.

**Opt-in (flag ON):** the 100-125% self-approval band below activates. A team that
trusts its CxO functions with bounded autonomy can enable it deliberately.

The 25% self-approval band and the 110% renegotiation threshold are illustrative
defaults. When the flag is ON, teams should still tune these to their risk tolerance
(e.g., a tighter 10% band for high-spend functions, or a lower 105% renegotiation
trigger for predictable workloads).

---

## Authority Levels

Default behavior (flag OFF) is in the **Owner-decides** column. The CxO self-approval
column applies ONLY when `cxo_self_approval_enabled: true`.

| Spend vs Budget Envelope | Default (flag OFF) | If self-approval enabled (flag ON) |
|--------------------------|--------------------|------------------------------------|
| <= 100% | CxO -- within envelope | CxO -- within envelope |
| 100-125% | **Owner decides** (CoS queues for owner approval before spend) | CxO self-approval, must meet all 4 criteria below |
| > 125% | Owner decides | Owner decides (CoS queues for owner approval) |
| 110%+ sustained >= 2 months | CFO + CHRO forced renegotiation (see below) | CFO + CHRO forced renegotiation (see below) |

---

## 4 Criteria for CxO Self-Approval (100-125%)

> Applies only when `cxo_self_approval_enabled: true`. With the flag OFF (default),
> a CxO cannot self-approve any overrun -- it routes to the owner regardless.

ALL four must be true for a CxO to approve their own overrun:

**(a) Specific work item identified.**
The overrun is tied to a named task or sprint, not a general "we ran over."
Example: "Overrun on Sprint 14 content batch -- 12 deliverables instead of planned 10."

**(b) ROI rationale documented.**
The additional spend has a projected return. CFO-format: "Extra spend of X% generates
projected return of Y within N days." Speculative or unmeasurable rationale does not qualify.

**(c) Reported to CFO + CoS within 24 hours.**
CFO and CoS are notified by the CxO with the work item + ROI rationale + actual
spend vs envelope. Not after the fact -- within the same day the overrun is
authorized.

**(d) Logged in `governance/budget-overruns.log`.**
Entry format:
```
<date> | <role> | <work-item> | Envelope: <configured-amount> | Actual: <actual-amount> | +<pct>% |
  ROI: <rationale> | CFO notified: <time> UTC
```

If any criterion is missing, the overrun requires owner approval retroactively.
CFO flags missing criteria in the weekly budget report.

---

## Forced Renegotiation (Sustained 110%+)

If a function sustains >= 110% of its envelope for 2 consecutive months:

1. CFO flags the pattern in the monthly budget report.
2. CHRO schedules a renegotiation session (CxO + CFO + CoS).
3. Renegotiation outputs one of:
   - **Envelope increase:** justified by demonstrated ROI; owner approves.
   - **Scope reduction:** remove task categories until spend fits envelope.
   - **Efficiency mandate:** same scope, lower cost via model-tier change or process optimization.
4. Renegotiation decision logged in `governance/budget-renegotiations.log`.
5. New envelope effective next month.

A CxO who sustains 110%+ for 3 consecutive months without renegotiating is flagged
for CHRO review (signals scope or capability mismatch, input to role-retirement review).

---

## CFO Oversight Touchpoints

CFO reviews budget actuals weekly:

- Generates `governance/budget-weekly-YYYY-WNN.md` with per-role actuals vs envelope.
- Flags any single spend event above the configured anomaly threshold that is not tied to an approved work item.
- Flags any CxO self-approval that is missing one or more of the 4 criteria.
- Routes flags to CoS for resolution within 48 hours.

---

## Model-Tier Cost Control

CxO budget envelopes should be calculated using API-rate pricing (actual marginal
cost per call), not flat subscription cost. This ensures budget decisions reflect
real marginal spend, which matters when subscription caps are exhausted or when
moving to production-scale usage.

Switching from a higher-capability model tier to a lighter tier for eligible tasks
(research, classification, pre-filtering) can reduce a function's spend by 40-60%
without scope reduction.

CFO tracks model-tier mix per role. If a CxO is running all tasks at
higher-capability tiers when a lighter tier is sufficient, the CFO recommends a
model-tier change as the first efficiency option before scope reduction.

---

## Cross-References

- `_patterns/role-guardrails.md` -- CxO authority table; budget overrun authority sits here
- `_patterns/role-retirement.md` -- persistent 110%+ feeds retirement signal
