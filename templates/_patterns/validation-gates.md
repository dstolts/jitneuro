---
type: pattern
purpose: BINDING for every role agent routing a durable artifact (code, content, schema, config) for approval or designing a new pipeline gate -- because an artifact that skips any of the 4 layers (QA correctness, Manager scope-fit, CxO strategic alignment, CCO compliance/brand-safety) reaches Owner or production with a domain-specific blind spot that single-validator review cannot catch; parallel-capable layers that run in isolation produce faster gates without sacrificing coverage.
read_when: Before routing any durable artifact for approval or designing a new pipeline gate -- apply the 4-layer validation chain every time.
tags: [validation, quality-gate, artifact-approval, rejection-protocol, parallel-validation]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---

# Validation Gates

**Used by:** All roles that produce or consume artifacts.
**Purpose:** 4-layer validation chain that every durable artifact passes through
before reaching Owner or being published.

---

## Why 4 Layers

Single-validator approval misses domain-specific blind spots. A QA agent verifies
correctness; a Manager verifies scope fit; a CxO verifies strategic alignment;
a CCO verifies compliance and brand safety. Each layer catches a different failure
class. Layers run in parallel where possible to avoid serial latency.

---

## Layer Definitions

| Layer | Role | Criteria | Blocking? |
|-------|------|----------|-----------|
| L1 QA | QA Specialist (or QA Mgr) | Correctness, completeness, no broken links, tests pass | Yes |
| L2 Manager | Manager of the producing role | Scope fit, acceptance criteria met, no regressions | Yes |
| L3 CxO | Relevant chief (CMO for content, CTO for code, etc.) | Strategic alignment, budget actual vs estimate within 25% | Yes |
| L4 CCO | Chief Compliance Officer | Brand voice, legal, moat protection, trust-zone compliance | Yes |

Any layer can return REJECTED with a structured reason. The artifact goes back to
the Specialist, not to a higher layer. Layers do not override each other.

---

## Parallel Validation Pattern

For artifacts where L1-L4 are independent (e.g., a published blog post):

```
Specialist produces artifact
  -> L1 QA + L4 CCO run in parallel (fast: correctness + compliance)
  -> Both must pass before L2 Manager runs
  -> L2 Manager passes before L3 CxO runs
  -> L3 CxO clears -> artifact is APPROVED
```

For code artifacts (per the PR pipeline pattern):

```
ci-passed -> qa-approved -> security-approved -> architect-approved -> cco-cleared
```

These labels map to L1/L1/L3-security-axis/L3-arch-axis/L4 respectively.

---

## Rejection Protocol

When any layer rejects:

1. Return STATUS: BLOCKED with layer ID, rejection reason, and required fix.
2. Specialist receives the rejection -- not the Manager (Manager is notified).
3. Specialist produces V2 and re-submits to the SAME layer that rejected.
4. Max 3 iterations per `rules/runaway-process-prevention.md`.
5. At iteration 3 with no pass: escalate per `_patterns/escalation-paths.md`.

Rejection format:
```
LAYER: L2-Manager
STATUS: REJECTED
REASON: Output does not match acceptance criteria: missing competitor table.
REQUIRED: Add competitor comparison table with 5 rows min.
ITERATION: 2 of 3
```

---

## Expedited Path

For time-sensitive artifacts (incident comms, hotfix deploys):

- L1 + L4 are mandatory -- never skipped.
- L2 + L3 may run concurrently with publish if CCO clears and incident Commander
  authorizes. Post-publish review happens within 2 hours.
- Expedited path is logged and flagged to CoS for audit.

---

## Cross-References

- `rules/runaway-process-prevention.md` -- 3-iteration max + mechanical caps
- `rules/subagent-communication.md` -- STATUS protocol used by each layer
- `rules/agent-scope-guardrail.md` -- validators check scope adherence
- `_patterns/escalation-paths.md` -- what happens after 3 failed iterations
- `_patterns/crisis-mode.md` -- expedited path in incident scenarios
