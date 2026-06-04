---
type: pattern
purpose: Defines producer-validator routing for any role that generates a durable artifact (content or code) with a low-cost producer model plus a validation chain; MUST be applied when dispatching an artifact-production task, because without its three-iteration cap and escalate-to-a-stronger-model path, production loops indefinitely, ships unvalidated work, or burns paid-model budget on a task a cheaper model could finish.
read_when: Before dispatching any artifact-production task to a role that generates content or code using a tiered model strategy.
tags: [producer-validator, local-inference, iteration-cap, artifact-routing, escalation]
scope: public
last_evaluated: 2026-06-03
---

# Producer-Validator Pattern

**Used by:** All content and code roles. QA Mgr (monitors iteration counts).
**Purpose:** A low-cost producer model generates durable artifacts; the existing
validation chain validates per artifact type. Iteration cap + escalation path
prevent runaway loops.

> **Local model is text-only.** The local inference model can produce and revise
> CONTENT (drafts, classifications, summaries) and can VALIDATE or PROPOSE changes
> as text. It does NOT author code. Code artifacts are produced by a hosted paid
> model; the local model may only review or suggest edits to code as text.

---

## Core Pattern

```
Task arrives at Specialist
  -> Classify task type (per local-inference-policy.md routing table)
  -> Producer model produces V1 artifact
  -> Submit to validation chain (validation-gates.md)
  -> [Pass] -> artifact complete
  -> [Reject] -> Producer produces V2 with rejection feedback embedded in prompt
  -> [Pass] -> artifact complete
  -> [Reject] -> Producer produces V3 (final attempt, explicitly flagged)
  -> [Pass] -> artifact complete
  -> [Reject] -> Escalate (see escalation path below)
```

Max 3 producer iterations. This is a hard cap per `rules/runaway-process-prevention.md`.
No exceptions. After 3 rejections, the task escalates -- it does not retry with the
same producer.

---

## Artifact Types and Validation Chain Mapping

| Artifact Type | Producer | Validator Chain |
|---------------|----------|-----------------|
| Content draft (internal) | Local model | L1 QA + L4 CCO (brand voice) |
| Content draft (customer-facing) | Local model | L1 QA + L4 CCO + L3 CMO |
| Code (internal tooling) | Sonnet (paid) | L1 QA (tests pass) + L2 Manager |
| Code (customer-facing) | Sonnet (paid) | Full L1-L4 chain |
| Classification/ranking batch | Local model | L1 QA (sample validation, 10%) |
| Strategic artifact (plan, brief) | Sonnet | Skip local model entirely |
| Owner-facing communication | Sonnet | Skip local model entirely |

Code artifacts always use a paid model producer -- the local model is text-only and
cannot author code. Strategic and Owner-facing artifacts also skip the local model:
applying it to these types produces output that consistently requires 3 iterations to
reach quality, and the time cost of iterating exceeds the cost of going Sonnet-first.

---

## Prompt Engineering for Iterations

When the producer is dispatched for V2 or V3, the prompt MUST embed the prior rejection:

```
CONTEXT: This is iteration 2 of 3.
PRIOR REJECTION (L2-Manager): Output missing competitor comparison table (5 rows min).
PRIOR ARTIFACT: [attach V1 or summary of V1 structure]
REQUIRED FIX: Add a 5-row competitor table with columns: Name, Strength, Weakness, Our Differentiator.
PRODUCE: V2 of the artifact with the competitor table added. All prior content preserved.
```

A producer without rejection context will produce a similar artifact to V1. The feedback
must be explicit and the instruction must be positive (what to add) not just negative
(what was wrong).

---

## Escalation Path (Post 3 Iterations)

After 3 failed producer iterations:

1. Manager is notified with the 3 rejection summaries.
2. Manager decides: Sonnet producer for V1 fresh start, OR task scope reduction,
   OR send to Owner queue via CoS (if blocking a delivery).
3. Sonnet produces V1 of the artifact with the same acceptance criteria.
4. Sonnet artifact goes through the same validation chain from the start.
5. If Sonnet V3 also fails: CoS escalates to CxO + Owner as T2. Task is paused.
6. This entire chain is capped at 6 total iterations (3 local + 3 Sonnet) before
   Owner involvement -- consistent with `rules/runaway-process-prevention.md` principle.

---

## Iteration Learning Loop

QA Mgr maintains an iteration log in `governance/producer-iteration-log.md`:

```
2026-05-06 | content-draft | local | iter-1 | L4-CCO | PASS
2026-05-06 | content-draft | local | iter-3 | L2-Manager | FAIL -> escalated to Sonnet
2026-05-06 | content-draft | sonnet | iter-1 | L2-Manager | PASS
```

Fields: date | artifact-type | producer | iteration | rejecting-layer | outcome.

CFO + QA Mgr review the log monthly. Reclassification rule:

- If the local model needs 3 iterations on a given task type more than 40% of the
  time over a calendar month, that task type is reclassified to Sonnet-first in
  `_patterns/local-inference-policy.md`.
- Reclassification proposal goes to CMO (for content types) or CTO (for code types)
  for approval before the local-inference-policy.md update is committed.

---

## Anti-Patterns

- Giving the producer V2/V3 prompts without embedding the prior rejection feedback.
- Letting a task iterate past 3 with the local model before escalating (violates iteration cap).
- Applying the local-model-first pattern to strategic, Owner-facing, or code artifacts.
- Silently falling back to Opus on local-model failure (use Haiku per local-inference-policy.md).
- QA Mgr not logging iteration outcomes (the learning loop requires complete data).

---

## Cross-References

- `rules/runaway-process-prevention.md` -- 3-iteration hard cap + mechanical discipline
- `_patterns/local-inference-policy.md` -- which tasks route to the local model vs a paid model
- `_patterns/validation-gates.md` -- the validator chain producer artifacts pass through
- `_patterns/escalation-paths.md` -- T2 escalation after 6 total iterations fail
- `_patterns/autonomous-execution-with-validators.md` -- producer-validator loop runs 24/7 without Owner
