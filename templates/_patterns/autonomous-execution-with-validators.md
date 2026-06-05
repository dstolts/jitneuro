---
type: pattern
purpose: Any orchestrator configuring unattended or night-mode AI operation MUST consult this before enabling autonomous execution -- firing when setting up AFK handoff, spend-control validators, or Owner-escalation thresholds -- because omitting the validator chain means cost runaway, quality collapse, or RED-zone actions proceed without a human checkpoint and are not caught until irreversible damage has occurred.
read_when: Before enabling autonomous or unattended execution, AFK handoff, or night-mode operation for any agent or orchestrator.
tags: [autonomous-execution, night-mode, validators, multi-agent, spend-control]
scope: public
departments: [all]
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Autonomous Execution With Validators

**Used by:** All roles. CoS (monitors). CEO (sets scope boundaries).
**Purpose:** Night-mode pattern. The full validation chain runs 24/7 without Owner.
Owner is engaged only for RED-zone actions and decisions that no agent can resolve.

---

## Foundation

`rules/autonomous-execution.md` establishes the core rule:
as long as tasks exist, agents MUST keep executing. AFK reinforces, not suspends,
autonomy. This pattern extends that rule into the multi-agent validator chain.

---

## Validator Chain as Agents (not Owner)

The 4-layer validation chain from `_patterns/validation-gates.md` is fully
staffed by agents. No human review is required for:

- L1 QA: QA Specialist agent
- L2 Manager: Manager agent for the producing role's function
- L3 CxO: CxO agent (CMO, CTO, CFO, etc.) for the relevant function
- L4 CCO: CCO agent

Agents resolve rejections by filing structured feedback to the producing agent
and re-dispatching. The loop continues per the 3-iteration cap in
`rules/runaway-process-prevention.md`.

---

## When Owner Is Required (RED Zone)

Owner intervention is required ONLY for:

| Trigger | Why Owner | Who notifies Owner |
|---------|-----------|-------------------|
| Push to main (public repo) | RED zone per trust-zones.md | CoS |
| $ spend > CxO 25% authority AND > 125% envelope | Irreversible financial commitment | CFO + CoS |
| T1-Critical public-sentiment incident | Brand/legal risk | CoS (immediate) |
| Cross-function conflict at CEO level | Neither CEO nor CoS can resolve | CEO + CoS |
| New external legal commitment | Binding obligation | CCO + CoS |
| New CxO hire or retirement | Org-structure change | CHRO + CEO |

Everything else -- including all content production, code PRs (non-main), validator
iterations, task routing, budget-within-authority decisions -- resolves agent-to-agent.

---

## Night-Mode Execution Pattern

During extended AFK windows:

1. CoS monitors the task queue and validator return queue.
2. CoS re-dispatches blocked tasks where the block is resolvable without Owner.
3. CoS applies auto-apply defaults per `rules/auto-apply-triage.md`
   for technical decisions.
4. CoS queues Owner-requiring items and presents them as a prioritized batch
   on Owner's return (not one-by-one).
5. Producing agents continue work on unblocked tasks while blocked items wait.

```
[AFK starts]
  CoS: scan task queue for blocked items
  CoS: resolve T2-resolvable blocks
  CoS: accumulate RED-zone items in Owner queue
  Producing agents: continue on GREEN/YELLOW items
  Validators: run on completed artifacts continuously
[Owner returns]
  CoS: "3 items need you: [batch]. Recommended defaults listed. Answer by number."
```

---

## Spend Guard (Night-Mode)

During AFK, CoS enforces a spend rate cap:

- Default: no single agent batch may exceed $50 without CFO pre-authorization.
- CFO pre-authorizes batches up to CxO 25% authority during sprint planning.
- If a batch is projected to exceed $50 and has no pre-authorization, CoS holds
  the batch and queues it for Owner approval.
- This is mechanical cost control, not a capability limit. See
  `rules/cost-estimate-anchor.md` for rate anchoring.

---

## Failure Modes and Recovery

| Failure | Recovery |
|---------|---------|
| Agent produces 3 failed iterations | Escalate to Manager -> CoS per escalation-paths.md |
| Validator agent is unreachable | CoS retries once after 60s; if still down, logs and routes to next available validator |
| CoS agent fails | CEO agent takes CoS duties; Owner notified via queued message |
| All CxO validators fail simultaneously | CEO agent holds all pending artifacts; Owner notified on return |

---

## Cross-References

- `rules/autonomous-execution.md` -- foundational rule this pattern extends
- `rules/runaway-process-prevention.md` -- 3-iteration cap on validator loops
- `rules/auto-apply-triage.md` -- how CoS applies defaults without Owner
- `rules/trust-zones.md` -- RED/YELLOW/GREEN defines what triggers Owner notification
- `_patterns/validation-gates.md` -- the 4-layer chain that runs autonomously
- `_patterns/owner-attention-budget.md` -- Owner queue management on return
- `_patterns/crisis-mode.md` -- T1-Critical overrides night-mode and contacts Owner directly
