---
type: pattern
purpose: Tiered escalation ladder for any role, manager, or CoS triage flow when work is blocked, rejected three times, over authority, or crisis-prone; skipping it lets stalled work, stale Owner decisions, or validator conflicts sit unowned.
read_when: When a task is blocked, has been rejected three or more times, or requires an action outside the current role's authority.
tags: [escalation, blocked-task, cos, crisis-mode, role-authority]
scope: public
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Escalation Paths

**Used by:** All roles. Triggered when a role is blocked, rejected 3 times,
or encounters a decision outside its authority.
**Purpose:** Structured ladder so work never silently stalls.

---

## When to Escalate

Escalate when ANY of these conditions are true:

1. Role is blocked on missing input it cannot self-resolve.
2. Artifact has been rejected 3 times (max iterations per runaway-process-prevention rule).
3. Required action is outside the role's trust-zone (RED zone per `rules/trust-zones.md`).
4. Two validators disagree and neither will yield (conflict).
5. Spend is projected to exceed the role's authority limit (see `_patterns/cxo-budget-overrun-25pct.md`).
6. A public-sentiment failure is detected (route directly to crisis-mode).

---

## Escalation Tiers

| Tier | Triggered by | Routed to | Expected response time |
|------|-------------|-----------|------------------------|
| T1 | Specialist blocked, < 4h wait | Manager | < 1h |
| T2 | Manager blocked OR 3 rejections | CoS | < 2h |
| T3 | CoS blocked OR cross-CxO conflict OR RED-zone action | CEO then Owner | < 4h |
| T-Crisis | Public-sentiment failure OR customer-data breach | CCO + COO + CoS (incident triad) | Immediate |

CoS is the clearinghouse for T2. CoS resolves if within authority; escalates to
CEO or Owner only when genuinely stuck or when the decision is irreversible.

---

## Blocked Issue Protocol

When filing a blocked escalation, the escalating role writes a structured block:

```
ESCALATION
Tier: T2
Blocking role: Content Production Mgr
Blocked on: Brand Voice & Moat Mgr has not returned compliance check after 6h.
Artifact: /content-drafts/post-ai-security-2026-05.md
Last status: L4 review dispatched 2026-05-06 10:00; no response.
Owner action needed: (a) Re-dispatch L4 reviewer, OR (b) authorize skip with CCO note.
Recommended: (a) Re-dispatch -- compliance check is mandatory per brand-voice-pattern.
Next owner: CoS
```

Fields are mandatory. Incomplete escalations are returned to the filer.

---

## Max 3 Retry Loops

Before escalating a blocked task, the role MUST attempt resolution:

- Retry 1: Re-submit with additional context or clarification.
- Retry 2: Re-submit with corrected artifact.
- Retry 3: Final attempt, explicitly flagged "FINAL ATTEMPT."
- After 3: File the escalation. Do not retry again without new direction from the
  escalation recipient.

This follows the same discipline as backoff-before-retry patterns (don't hammer;
wait and report) applied to role-level retries.

---

## CoS Triage Rules

When CoS receives a T2 escalation:

1. Read the blocked issue in full.
2. Check if the block is resolvable by a parallel role (reassign, do not escalate).
3. If not resolvable: add the decision needed to the Owner-attention queue
   (see `_patterns/owner-attention-budget.md`).
4. Log the escalation in `governance/escalation-log.md` with date + tier + resolution.
5. Notify the blocked role within the response-time SLA.

---

## Resolution Without Owner (default)

Most T2 escalations resolve without reaching Owner:

- CoS re-dispatches to a parallel specialist.
- CoS authorizes a scope clarification.
- CoS overrides a non-blocking validation disagreement.

Owner is engaged ONLY when the decision is:
- Irreversible (delete, publish live, external commitment)
- Above CxO budget authority (> 125% of envelope)
- Values-layer or legal-risk decision
- Cross-function conflict where both CxOs escalate to the same T3

---

## Cross-References

- `rules/trust-zones.md` -- RED/YELLOW/GREEN action zones
- `rules/backoff-before-retry.md` -- backoff-before-retry discipline
- `rules/runaway-process-prevention.md` -- 3-iteration hard cap
- `_patterns/validation-gates.md` -- when rejection triggers escalation
- `_patterns/owner-attention-budget.md` -- how Owner time is allocated to escalations
- `_patterns/crisis-mode.md` -- T-Crisis escalation path
