---
type: pattern
purpose: MUST be consulted by the CCO, COO, and CoS triad within 30 minutes of any T1/T2 incident detection (bad content live, customer complaint, legal threat, brand-safety violation) -- because skipping this playbook means each responder improvises independently, Owner is burdened with decisions the triad is chartered to resolve, and T1 incidents without a structured commander model escalate into brand damage before a coherent response is mounted.
read_when: Within 30 minutes of detecting any T1 or T2 incident (bad content live, customer complaint, legal threat, or brand-safety violation).
tags: [crisis-mode, incident-response, cco, escalation, brand-safety]
scope: public
last_evaluated: 2026-06-03
---

# Crisis Mode

**Used by:** CCO (lead), COO, CoS (incident triad). All public-facing roles.
**Purpose:** Structured response to public-sentiment failures, customer complaints,
and bad content live in market. Minimizes Owner decision load during incidents.

---

## Incident Types

| Type | Example | Severity |
|------|---------|----------|
| T1-Critical | Customer data leaked, legal threat received, fraudulent content live | Immediate -- halt related operations |
| T1-High | Viral negative post about company, influencer complaint, brand-safety violation live | < 1h response |
| T2-Medium | Customer support failure visible publicly, incorrect published claim | < 4h response |
| T3-Low | Minor factual error in post, formatting/voice violation | Next business cycle |

T1 escalations bypass the normal Owner attention budget and engage Owner directly.
T2 and T3 are resolved by the incident triad without Owner unless they escalate.

---

## Incident Commander Triad

- **CCO** -- compliance + public-sentiment lead. Owns the response decision.
- **COO** -- operations lead. Owns takedown execution and process fix.
- **CoS** -- coordination. Owns Owner communication and timeline tracking.

Triad forms within 30 minutes of T1 detection. Each member acts in parallel:

```
CCO: Assess severity -> decide on takedown vs correction vs no-action
COO: Identify operational impact -> execute takedown if authorized by CCO
CoS: Notify Owner (T1 only) -> open escalation log -> track resolution
```

---

## Playbook

### 1. Detect

Sources: social listening (Brand Voice & Moat Mgr), customer support queue,
internal QA flag, Owner direct report.

Any role that detects a potential T1 incident STOPS normal work and files an
incident report to the triad immediately:

```
INCIDENT REPORT
Severity: T1-High (proposed)
Source: Twitter/X @handle
Content: [screenshot or quote]
Live URL: [if applicable]
First seen: 2026-05-06 14:32 UTC
Filed by: Brand Voice & Moat Mgr
```

### 2. Assess Severity

CCO reads the incident report within 15 minutes. Reclassifies if needed.
Severity criteria:
- Is customer data involved? -> T1-Critical
- Is the content live and spreading? -> T1-High at minimum
- Is there a legal claim attached? -> T1-Critical, legal counsel notification

### 3. Takedown Decision

CCO has authority to authorize takedown of owned content (GREEN zone for CCO).
Takedown of third-party content requires legal involvement (escalate to CEO + Owner).

COO executes takedown within 15 minutes of CCO authorization:
- Remove content from all owned channels
- Invalidate CDN cache where applicable
- Log the takedown in `governance/incident-log.md`

### 4. Comms Response

CCO authors the response statement (not Brand Voice & Moat Mgr -- CCO owns crisis comms).
Format: one direct acknowledgment, what we did, what we are doing. No embellishment.
Response goes through expedited L1 + L4 (L2/L3 concurrent with publish for T1-High).

Owner approves public comms for T1-Critical. CCO owns T1-High and below.

### 5. Root Cause

After resolution, COO + CCO file a root-cause analysis per
`rules/root-cause-analysis.md` within 48 hours.
RCA goes to CEO for review. Process fix is tracked in `governance/rca-log.md`.

### 6. Postmortem

CoS schedules a postmortem within 1 week. Attendees: incident triad + relevant Manager.
Output: process change proposal. CEO approves changes to the content or compliance pipeline.

---

## Night-Mode Behavior

During AFK windows, the incident triad operates autonomously:

- T3: Brand Voice & Moat Mgr corrects + re-validates without waking Owner.
- T2: Triad resolves with CCO authority; Owner briefed on return.
- T1-High: COO executes takedown; CoS queues Owner notification as highest-priority item.
- T1-Critical: CoS attempts Owner contact via all configured channels. If no response
  within 30 minutes, COO executes defensive takedown of all related content.

---

## Cross-References

- `rules/root-cause-analysis.md` -- RCA process used in step 5
- `rules/autonomous-execution.md` -- night-mode autonomy reinforces self-resolution
- `_patterns/escalation-paths.md` -- T-Crisis tier routes directly to incident triad
- `_patterns/validation-gates.md` -- expedited gate path during T1 incidents
- `_patterns/owner-attention-budget.md` -- T1-Critical bypasses normal budget; T2 does not
