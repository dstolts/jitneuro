---
type: pattern
purpose: Model-routing policy for roles and orchestrators choosing local inference vs a hosted paid model before classification, drafting, validation, review, or code tasks; skipping it wastes paid-model budget or sends quality-sensitive work to underpowered local inference.
read_when: Before routing any inference task to decide whether local inference or a hosted paid model is appropriate.
tags: [local-inference, model-routing, cost-control, llm-routing]
scope: public
departments: [all]
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Local Inference Tier Policy

**Used by:** All roles that invoke AI inference. Orchestrators making routing decisions. Any role tracking inference cost.
**Purpose:** Default model routing between a local inference model (cost-free, fast) and a hosted paid model
(billed per token, higher quality). Correct routing reduces API spend 40-70% on eligible tasks.

**Manifesto: If the local model can do it acceptably, the local model does it. There is no local-model budget.**

---

## Cost Model -- Local Inference is Zero Marginal Cost

A local model runs on hardware the team already owns and operates. The machine is powered on regardless;
electricity is a sunk cost, not a marginal cost per inference call.

- Local model calls have NO hosted API cost, NO third-party billing, NO quota burn against paid tiers.
- Marginal cost per call = $0.
- Local model calls do NOT count against any monthly API budget envelope.
- There is no "local model budget." Volume is not a concern; quality is the only constraint.
- The only physical limit is the throughput of the inference host hardware.
- If the inference host shows thermal throttling, reduce concurrent sessions. Otherwise no concurrency limit applies.

IMPLICATION: lean aggressively on local inference wherever it can produce acceptable output. The correct
default question is "why use the paid model?" not "why use local?" -- paid model calls require justification;
local inference does not.

---

## Local Inference Host Setup

Host a compatible model (e.g., a mid-size instruction-tuned model in the 7B-30B range) on a local machine
using a self-hosted inference server such as Ollama, llama.cpp server, or vLLM.

Recommended minimum for reliable instruction-following on classification and summarization tasks: a
quantized 26B-class model or a full-weight 7B-class model on hardware with >= 24 GB VRAM or unified memory.

When the inference host is unreachable, apply the fallback procedure in the Resilience section below.

---

## Default Routing

### Use local inference for:

- Classification and ranking (tag a post, score a lead, rank candidates)
- Pre-filtering (screen a batch before expensive processing)
- Embedding and RAG retrieval (vector generation, similarity search)
- Internal summarization (meeting notes, status digests, log analysis)
- Brand-voice drift detection: local model scans published artifacts continuously (no quota concern);
  flagged drift items are escalated to the paid model for adjudication only
- Compliance pre-screen: local model scans public artifacts before reviewer evaluation; reviewer veto applies
  only on flagged items -- local model is the first-pass gate, not a sample gate
- Internal classification, ranking, and summarization: all local; never escalate "for cost" alone
- Content drafts (first-pass only; paid model or human-grade validator confirms)
- Validation scoring (LLM-as-judge on internal artifacts)
- Validation passes over code or content: the local model returns a verdict (pass/fail or score) PLUS
  proposed changes described in text. This is a supported use -- it returns text. A paid model or human
  then applies any code changes; the local model does not author the committed code.
- Code review for non-shipping internal scripts: local model returns review findings as text (cheap first
  pass); escalate to a paid model when findings warrant a fix or the output ships to customers

### Use a hosted paid model for:

- Customer-facing publish-grade copy (blog posts, social, emails, reports)
- Code shipping to customers (any artifact that runs in customer environment)
- Architecture decisions and system design
- Executive briefs and strategic recommendations
- High-stakes communications requiring deep reasoning
- Any artifact where the local model failed 3 iterations (escalation path, see below)

### Never use local inference for:

- Writing or modifying code directly -- local inference is unreliable at code generation. It may PROPOSE
  changes as text (a verdict plus a description of the fix), but a paid model or human authors the
  committed code. Local inference is for tasks that RETURN TEXT, not for authoring code.
- Final publish of any customer-facing content (always validate with a paid model)
- Legal or compliance final decisions
- Direct owner communications

---

## Task-Type Classification (Routing Decision)

Before invoking any AI model, the dispatching role classifies the task:

| Classification | Criteria | Model |
|----------------|----------|-------|
| Internal-mechanical | No customer output, reversible, bulk volume | Local model |
| Internal-judgment | Requires reasoning depth, cross-domain synthesis | Paid model |
| Customer-draft | First pass of customer-facing content | Local model |
| Customer-publish | Final version delivered to customer | Paid model (after local draft + validation) |
| Strategic | Architecture, org decisions, owner-level briefs | Paid model |

When uncertain, default to local model for draft + paid model for validation pass.

---

## Structured Prompt Discipline (Required for Every Local Inference Call)

Every local model invocation requires a STRUCTURED PROMPT written before the call is issued.
Never pass an ad-hoc string to a local model.

Required prompt structure (4 blocks minimum):

```
INPUT:
  <describe the exact input -- snippet, list of N items, file excerpt>

TASK:
  <one sentence: what the model must do>

OUTPUT:
  <exact shape: JSON key names, list format, true/false, N-bullet list>
  Example output: { "category": "billing", "confidence": "high" }

FAILURE-MODE:
  <what to output when uncertain: a sentinel value, empty object, or explicit "UNSURE">
```

Partial prompts (missing OUTPUT or FAILURE-MODE) are not acceptable for local model calls.
Write all four blocks before dispatching. Small-model output quality is highly prompt-sensitive;
structured prompts give the model a clear contract and reduce silent failures.

---

## Resilience and Fallback

When the local inference host is invoked and fails:

1. **Timeout (< 30s):** Retry once with the same structured prompt.
2. **Timeout (>= 30s) or connection refused:** Verify the inference host is running and
   the model is loaded. Retry once after confirming the service is up.
3. **3 consecutive failures:** Stop using local inference for this session. Route all tasks
   to the fastest available paid model tier (equivalent to Haiku / Flash tier). Log the outage:
   ```
   LOCAL_INFERENCE_OUTAGE | <timestamp> | 3 failures | fallback: paid-haiku-tier | session: <id>
   ```
4. Do NOT silently fall back to the most expensive paid model tier on local inference failure --
   that is a budget risk. The cheapest paid tier is the correct fallback, not the most capable.

---

## Tracking Deflection Rate

Track local vs paid model task counts periodically. Metric: "local deflection rate"
-- tasks routed to local inference that would otherwise be paid model calls. Target >= 40% deflection
for internal-mechanical task categories.

If deflection rate drops below 20% for 2 consecutive periods, review routing decisions to identify
task types that are being misclassified and sent to the paid model unnecessarily.

---

## Cross-References

- `_patterns/producer-validator-pattern.md` -- local model as producer; paid model chain as validator
- `_patterns/brand-voice-pattern.md` -- brand-voice drift detection is a local-inference-eligible task
