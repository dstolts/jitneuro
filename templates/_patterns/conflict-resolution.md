---
type: pattern
purpose: Any orchestrator or CoS agent resolving a conflict between two roles, validators, or systems MUST consult this before applying a resolution -- firing the moment two agents or functions produce contradictory outputs or decisions -- because applying ad-hoc resolution without a defined authority ladder causes the wrong function's signal to win, invalidates the higher-authority actor's guardrails, and produces decisions that bypass the trust-zone hierarchy.
read_when: When two agents, validators, or systems produce contradictory outputs or decisions that require resolution.
tags: [conflict-resolution, multi-agent, authority, escalation, trust-zones]
scope: public
departments: [all]
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Conflict Resolution

**Used by:** All roles, orchestrator, compliance/IP guardian, cost governor. Resolves conflicting outputs, decisions, and signals between roles.
**Purpose:** When two roles produce conflicting outputs, decisions, or signals, this pattern defines who wins, why, and how to escalate if the winner is uncertain.

---

## Foundation

Trust-zone authority is defined in `rules/trust-zones.md`.
Role-level authority is defined in `_patterns/role-guardrails.md`.
This pattern adds the inter-role conflict resolution layer.

---

## Cross-Axis Conflict Matrix

| Axis | Winner | Why | Escalation if uncertain |
|---|---|---|---|
| Action-zone (GREEN/YELLOW/RED) | Trust zone classification | Universal floor; no role overrides RED unilaterally | `rules/trust-zones.md` |
| Decision-gate (Strategy Mode) | Approval-workflow gate | Strategy Mode suspends all code execution regardless of trust zone | `rules/approval-workflow.md` |
| File-domain (intra-agent-system) | Owning agent's charter | Out-of-domain findings -> [SCOPE-ESCALATION] issue; never inline fix | `rules/agent-scope-guardrail.md` |
| Repo ownership (inter-system) | Disjoint allowlist | Overlap requires pause + surface to owner | `rules/multi-agent-repo-coordination.md` |
| Decision batch (auto-apply) | AI on tech/reversible; Owner on business/security/irreversible | Triage rule; owner vetoes by ID from ledger | `rules/auto-apply-triage.md` |
| Blocker (autonomous execution) | Blocker wins; work halts | RED zone, missing info, or genuinely harmful conflict stops execution | `rules/autonomous-execution.md` |
| Owner correction | Owner wins; course-correct immediately | Highest-severity signal; all other work pauses | `rules/friction-detection.md` |
| RCA active | RCA process wins; all other work frozen | Closes only on owner approval phrase | `rules/root-cause-analysis.md` |
| Rules vs judgment | Hard guardrails win; operating principles yield to judgment | Owner direction beats any operating principle | `rules/judgment-over-compliance.md` |
| Code authority | Agent dispatch system wins; owner direct override beats rule | Master = planning; code dispatch = agent dispatch system | `_patterns/delegation-pattern.md` |
| LLM spend anomaly | Cost governor flags; lead architect reviews at threshold overage | Cannot block agents; advisory only until hard budget stop fires | `_patterns/cost-governance.md` |
| Sprint stall | Orchestrator stall chain | File lock -> configured hours -> lead architect; extended -> owner | `_patterns/escalation-paths.md` |
| Code quality gates | Code reviewer blocks at merge and staging-branch gates | Parallel with security and QA; no overlap between lanes | `_patterns/review-gates.md` |
| Multi-validator PR gate | All gate labels required; any BLOCKING label holds the PR | ci-passed + qa-approved + security-approved + architect-approved + compliance-cleared | Multi-validator PR pipeline pattern |

---

## GAP Resolutions (Not Covered by Existing Rules)

### GAP-01: Content Guardian vs Marketing -- Draft vs Compliance/IP Finding

**When:** A compliance/IP scan returns HIGH or CRITICAL on a content draft that the marketing role has queued for owner approval -- including drafts that already have owner pre-approval.

**Resolution:**
- Compliance/IP guardian wins. The veto holds regardless of owner pre-approval state.
- Content is HELD (not posted) until the finding is resolved.
- Owner pre-approval does NOT override the compliance veto on IP/moat findings.
- Re-fix path: compliance guardian writes structured feedback (specific finding, line, recommended change). The content author applies the fix. Compliance guardian re-reviews.
- Maximum 3 retry cycles. If still failing after 3 retries, escalate to owner via the T2 URGENT escalation path with: finding detail, content value rationale, and structured feedback.
- Owner makes final call on unblock or kill.

**Basis:** External communication rules (trade secrets hard block); compliance HIGH/CRITICAL blocks merge per the compliance role charter.

---

### GAP-02: Budget Governor Hard Stop -- Budget Breach Becomes Blocking Input

**When:** The cost governor signals 100% budget breach.

**Resolution:**
- The 100% signal is a BLOCKING input to the orchestrator (not advisory).
- New issue assignments refused immediately. No new dispatches.
- Active dispatches: complete current task then halt. Do not abandon mid-task.
- Re-enable only on: (a) owner explicit approval to continue, OR (b) new period rollover resetting the budget envelope.
- At 80% threshold: cost governor issues soft alert to owner. No halt; advisory only.
- At 100%: hard stop as above. Orchestrator enforces; no agent bypasses on "critical path" grounds.
- If a high-priority work item is blocked by the hard stop: surface it to owner as a T2 URGENT escalation with cost context so owner can make an informed unblock decision.

**Basis:** Agent dispatch cost-control rules (dispatch discipline); cost governor role charter (threshold definitions).

---

### GAP-03: Lead Architect vs Security Role -- Parallel Findings Conflict on Same PR

**When:** Lead architect assesses a finding as "acceptable risk" but the security role flags the same finding as BLOCKING on the same PR.

**Resolution:**
- Security wins. A security BLOCKING finding holds the PR regardless of the architect's risk assessment.
- Lead architect cannot override a security-approved label requirement.
- The PR remains held until the security role removes the blocking label.
- If lead architect formally disagrees: architect files a documented escalation to the compliance/IP guardian (security has dotted-line to compliance per charter).
- Compliance guardian and lead architect conduct joint review. Compliance guardian has final say within the compliance domain.
- If compliance and lead architect cannot resolve: escalate to owner via T2 URGENT with both positions documented.
- Owner makes final call. Decision is logged in `governance/override-log.md` with rationale.

**Basis:** `rules/agent-scope-guardrail.md` (domain separation); `rules/trust-zones.md` (security findings are not a judgment call at agent level); multi-validator gate pattern.

---

## General Principles

- Compliance/IP guardian wins on legal, IP, and exposure risks. Authority is asymmetric and veto-capable across all output types.
- Cost governor wins on budget breach. At the hard-stop threshold, the signal is mechanical and blocking -- not advisory.
- Lead architect wins on technical correctness within GREEN-zone scope. Cannot override security or compliance blocking findings.
- Marketing role wins on brand voice and public-facing tone, within the compliance veto envelope. Brand decisions below compliance radar are the marketing role's call.
- Orchestrator arbitrates non-domain conflicts -- scheduling, routing, priority sequencing. Escalates to owner via T2 URGENT if unresolved after one arbitration attempt.
- Any conflict not resolved by this matrix escalates to the owner via the T2 URGENT path with both sides' positions documented before the owner sees it.

---

## Cross-References

- `rules/trust-zones.md` -- RED/YELLOW/GREEN action tiers
- `rules/agent-scope-guardrail.md` -- write-domain per agent type
- `rules/judgment-over-compliance.md` -- hard guardrails vs operating principles
- `_patterns/role-guardrails.md` -- role-level authority and blast radius
- `_patterns/escalation-paths.md` -- when and how to escalate beyond this matrix
- `governance/override-log.md` -- where owner unblocks and escalation resolutions are recorded
