---
type: pattern
purpose: Kill-switch triggers and rollback procedures for autonomous AI work -- cost runaway, quality collapse, priority drift, and external incidents; read when implementing autonomous agent oversight or responding to a K1-K4 trigger event.
read_when: When implementing autonomous agent oversight for a project, or when a K1-K4 kill-switch event fires and rollback procedures must be executed.
tags: [kill-switch, rollback, autonomous-ai, cost-runaway, demotion-cascade]
scope: public
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Rollback Guardrails + Kill-Switch Procedures

**Status:** DRAFT
**Paired docs:** your project's budget-envelope doc (cost caps), decision-routing doc (Trust-Earning Ratchet), and risk-register (cost runaway entry)

> This doc covers the STOP/REVERT half of autonomous agent oversight. Budget caps live in your budget-envelope doc; demotion logic lives in your decision-routing doc. This doc operationalizes both.

---

## 1. Kill-Switch Triggers (auto-pause autonomous work)

All four fire automatically. No owner action needed to trigger; owner action required to resume.

| Trigger | Threshold | What fires |
|---------|-----------|-----------|
| **K1 Cost runaway** | > 2x your configured daily average spend in one calendar day | Pause ALL background agents; alert the owner via your configured notification channels |
| **K2 Quality collapse** | 3 consecutive brief/recommendation cycles rejected by the owner | Halt brief-driven autonomous task execution; owner hand-curates the task list until resolved |
| **K3 Priority drift** | Wrong-priority rate > 20% over any rolling 7-day window | Revert to last owner-approved priority weights; demote vision-scoring capability one tier |
| **K4 External incident** | Security incident / compliance trigger / customer fire (manual signal by owner) | Freeze all autonomous work; surface active agent list; await owner direction |

**K1 cross-reference:** your budget-envelope doc defines the exact dollar threshold and alert path. This doc defines what happens to agent state when K1 fires.

**Resume path for all triggers:** The owner sends an explicit "resume" signal in the designated channel (morning brief, direct session message, or equivalent). Kill triggers are not time-expiring -- they stay active until the owner clears them.

---

## 2. Rollback Procedures (when things go wrong)

### 2a. Priority Drift (K3 fires)

1. Read the last owner-approved priority weights from your project's strategy/config document (the weights the owner last confirmed in a review cycle).
2. Restore those weights as the active operating set; discard any AI-proposed adjustments since the last confirmation.
3. Demote the vision-scoring capability one tier (T1->T2 or T2->T3) per your decision-routing doc.
4. Surface in the next review brief: "Priority drift detected. Priority weights reverted to [date] owner-confirmed set. Vision-scoring demoted [from tier -> to tier]."
5. Do NOT auto-re-promote until the owner explicitly confirms the reverted weights are correct.

### 2b. Budget Runaway (K1 fires)

1. Freeze: pause all background agent dispatches immediately.
2. Log: write the kill event to your token log with timestamp, session ID, and total spend at trigger point.
3. RCA: surface a brief root-cause prompt in the next review cycle -- "K1 fired at $X. Root cause: [1 line]. Action: [1 line]."
4. Ratchet back: next period's autonomous cap drops to the prior tier (your budget-envelope doc one-strike rule).
5. Resume: the owner explicitly clears in the next brief; cap stays at the demoted tier for the remainder of that period.

### 2c. Quality Collapse (K2 fires)

1. Halt: stop all brief-driven autonomous task execution.
2. Owner hand-curates the task list: the AI surfaces the current task list and asks the owner to re-prioritize directly.
3. RCA: identify what the 3 rejected recommendations had in common; propose a rule fix.
4. Do NOT resume brief-driven execution until the RCA is owner-closed using your project's root-cause-analysis process.
5. Informational briefs (status, spend, task list) continue during quality RCA -- information delivery is never suspended.

### 2d. Demotion Cascade (systemic signal)

If 3 or more capabilities are demoted within the same 7-day window:

1. **Full autonomy regime reset:** all capabilities currently above T3 revert to T3 immediately.
2. The Trust Ledger resets consecutive-success counters to zero for all affected capabilities.
3. The next brief surfaces: "Demotion cascade -- [N] capabilities demoted in 7 days. Full reset to T3 baseline."
4. The re-promotion clock starts fresh; no capability can be promoted until the RCA on the most material failure is owner-closed.
5. T1 standing capabilities (discovery and planning) are EXEMPT from cascade reset -- their blast radius is near-zero and they are needed to manage the recovery.

---

## 3. Auto-Demotion Logic (operationalizing the 1-strike rule)

**What counts as a "material failure"** (concrete examples per capability class):

| Capability Class | Material Failure |
|-----------------|-----------------|
| Cost / spend decisions | Dispatches an agent that exceeds the per-task cap without pre-approval |
| Brief delivery | A review brief contains factually wrong data (wrong spend figure, wrong task status) |
| Priority adjustments | Moves a priority weight outside the approved threshold band without surfacing it |
| Content publish | Publishes content scoring below the project's minimum quality threshold |
| Task list sync | Marks a task complete when it is not; loses a pending task |
| Agent dispatch | Dispatches a code agent in violation of the project's dispatch policy |
| Priority ordering | Recommends lower-priority work when a higher-priority item is clearly unblocked |

**What is NOT a material failure:**
- The owner redirects or refines during normal iteration.
- A background agent returns BLOCKED (an unexecuted task is not a failure).
- A scheduled agent fails to spawn due to missing config.

**Grace window (self-correction):**
If the AI self-detects a failure AND self-corrects AND flags the correction in the same response, before the owner notices: the event is logged as a "caught failure" in the Trust Ledger but does NOT count as a demotion-triggering strike. Evidence of self-detection must be explicit ("I caught X, corrected to Y"). Silent corrections still count as strikes.

**3-strike -> mandatory RCA:**
- 3 material failures within the promotion window (configure per your decision-routing doc, e.g. 30 days for T3->T2; 45 days for T2->T1) = capability resets to T3.
- RCA is required before the re-promotion clock starts.
- The owner explicitly closes the RCA before the consecutive-success count restarts.

---

## 4. Owner Override Procedures

### Force-stop any agent / capability / entire scheduled run

```
"Stop [agent name / all agents / tonight's run]"
```

AI immediately: (1) sends interrupt to named agent(s), (2) logs the stop event with timestamp, (3) surfaces the active task list so nothing is lost, (4) confirms stopped in the next response. No background work resumes without an explicit "resume."

### Override a specific demotion

```
"Override capability [name / ID] to [T1/T2/T3] until [date or event]"
```

AI logs the override with expiry in the Trust Ledger. At expiry the capability reverts to its earned tier (not a T3 reset unless the owner specifies). The override does not reset the failure counter or the success clock.

### Override a kill-switch

```
"Resume [all agents / K1 / K3 / specific capability]"
```

Clears the named kill trigger. AI confirms clear and logs it. If K1 was the trigger, the next period's cap stays at the demoted tier per the budget ratchet -- resume does not reverse the ratchet.

### Override a demotion cascade

```
"Restore [capability name / all capabilities] to [tier]"
```

Restores named capabilities to the specified tier. AI logs the manual restoration as an owner override event (does not count as an earned promotion; the success clock continues from wherever it was).

---

## 5. Monitoring (what surfaces these triggers in real time)

**Review briefs (standing sections):**
- "Kill-switch status: [ACTIVE / CLEAR]" -- one line; if ACTIVE, name the trigger and the date it fired.
- "Demotion events since last brief: [N]" -- if N > 0, list capability names and failure descriptions.
- "Trust Ledger: T1=[N] T2=[M] T3=[P] | Movement: [+X up, -Y down] this week."
- "Budget: $X spent today / $[daily cap] daily cap | $Y period-to-date / $[cap] period cap."

**Active-work briefs (standing sections):**
- "Active rollbacks: [none / list]" -- any K2/K3 rollback currently in effect.
- "Next run blocked by: [none / kill-switch / pending owner question]."

**Dashboard / notification banner (real-time, highest priority):**
- K1 fires -> high-priority alert: "KILL SWITCH ACTIVE -- cost runaway. All background agents paused. Check next brief."
- K4 fires -> elevated alert: "External incident mode -- autonomous work frozen."

---

## 6. Open Questions (calibrate for your project)

- **OQ1.** Wrong-priority rate (K3): how is "wrong" measured in your system? Owner rejection of a recommendation counts, but AI self-generated plans with no owner feedback are harder to score. Confirm your measurement method before enabling K3.
- **OQ2.** K2 quality collapse -- does "3 consecutive rejections" reset if the owner approves an intervening recommendation, or does any rejection within N days count? Recommended default: resets on approval (consecutive is the right framing).
- **OQ3.** Demotion cascade exempt list: should any capability above T1 standing be explicitly immune to cascade reset? For example, brief delivery capability -- if brief delivery is demoted during a cascade, the owner loses the visibility mechanism needed to manage the cascade.

---

## Related Docs (configure for your project)

- your `budget-envelope.md` -- cost caps, 2x kill math, period ratchet
- your `decision-routing.md` -- tier definitions, promotion/demotion thresholds, Trust Ledger schema
- your `risk-register.md` -- cost runaway entry, gate-skip entry, memory exhaustion entry
- your `operating-rhythm.md` -- review brief cadence where kill-switch status surfaces
- your `personal-constitution.md` or equivalent -- trust-earning ratchet principle, discovery+planning T1 standing
