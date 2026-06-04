---
type: skill
name: local-llm-dispatch
description: route task to local LLM, dispatch to local model, run on local inference, use local inference, classify task as local or paid, check if task needs paid LLM
purpose: Routes AI tasks to the local Ollama LLM when the task type is eligible (classification, summarization, pre-filtering, drafting prose, validation, brand-voice-check) and falls back to paid cloud LLM otherwise, reducing API spend. CURRENT LIMITATION (2026-05-14) -- text-only, NO code generation; any code-write/refactor/bugfix/code-review task MUST route PAID until the code-capable local stack ships. Read when an agent or worker needs to decide whether to use local inference or a paid model.
tags: [skill, local-llm, ollama, routing, cost-optimization, text-only, no-code-gen-today, capability-limited]
scope: public
owner_role: engineering-lead
current_limitations:
  - text-only (no code generation; routes code tasks PAID -- see Current Capability section in body)
  - capability boundary auditable: 2026-05-14
  - work-in-progress: code-capable local stack
read_when: Before routing any AI task to a local or paid model to determine which inference tier to use and avoid overspending on tasks a local model can handle.
last_evaluated: 2026-06-03
---

# Local LLM Dispatch

Route AI tasks to a local LLM (via Ollama) when the task type is eligible, falling back to a paid cloud LLM only when required. Reduces API spend to $0 for 70-80% of tasks.

## Operating Principle

- The default question is "why paid?" not "why local." Local requires no justification; paid does.
- Routing is based on task type, not difficulty. Classification, validation, drafting, and summarization go local regardless of content complexity.
- Local LLM produces; paid LLM or human validates. Never ship local output to customers without a validation pass.
- Local failures fall back gracefully: retry once, then escalate to the cheapest paid tier (not the most expensive).
- The routing rules come from `_patterns/local-inference-policy.md`. This skill is the execution layer; the pattern is the policy layer.

## Current Capability (2026-05-14) -- text only, NO code generation

The current local model (via Ollama) reliably returns **text**: classification, summarization, ranking, drafting prose, validation answers, brand-voice checks. It does **NOT** write code.

Therefore until further notice:
- Code-generation tasks (write a function, refactor this, generate a script, fix this bug) -> **PAID** -- never local
- Code-review tasks (review this diff, find issues in this snippet) -> **PAID** -- the model can describe issues but not reliably produce correct fix code
- Mixed tasks that include any code output -> **PAID**

Adding code-generation capability to the local stack is in progress (separate workstream). When the local model gains reliable code output, this section is updated and the routing rules below are amended.

This limitation overrides any older routing guidance that suggested `internal-script` or `code-review-internal` could run local. They cannot today.

## When to Use This Skill

- An agent or worker needs to execute an AI task and should minimize cost
- A task needs to be classified as local-eligible vs paid-required before execution
- A system is integrating local LLM support and needs the canonical routing rules
- Building or extending a worker, scheduled agent, or automation that calls an LLM

## Procedure

1. **Read the task description and any tags/context.**

2. **Apply hard rules first (no LLM call needed):**
   - Tags include `customer-facing`, `publish`, or `external-comms` -> PAID
   - Tags include `architecture`, `design`, or `strategy` -> PAID
   - Tags include `code`, `script`, `refactor`, `bugfix`, or `code-review` -> **PAID** (local cannot write code today; see Current Capability section)
   - Description mentions `owner`, `executive`, `brief for`, `recommendation` -> PAID
   - Description mentions `write code`, `write a script`, `refactor`, `fix this bug`, `generate a function`, `review this diff`, `review this code` -> **PAID** (code output not supported locally today)
   - Description mentions `classify`, `categorize`, `tag` -> LOCAL
   - Description mentions `rank`, `sort`, `order by` -> LOCAL
   - Description mentions `summarize`, `summary`, `digest` -> LOCAL
   - Description mentions `draft`, `first pass` (prose only, not code) -> LOCAL
   - Description mentions `validate`, `check if`, `verify that` (text answer only, not patch) -> LOCAL
   - Description mentions `pre-filter`, `screen`, `triage` -> LOCAL

3. **For ambiguous tasks, ask the local LLM to self-classify (meta-routing at $0):**
   ```
   System: You are a classifier. Respond with exactly one word from this list:
   classification, ranking, pre-filtering, embedding, summarization,
   brand-voice-check, compliance-screen, validation, internal-script,
   content-draft, code-review-internal, customer-publish, customer-code,
   architecture, strategy, complex-reasoning, external-comms

   User: Task: "<task description>". Which category best describes this task?
   ```
   Categories in the first group are LOCAL (text output only): classification, ranking, pre-filtering, embedding, summarization, brand-voice-check, compliance-screen, validation, content-draft.
   Categories in the second group are **PAID**: internal-script, code-review-internal, customer-publish, customer-code, architecture, strategy, complex-reasoning, external-comms. Note: `internal-script` and `code-review-internal` are PAID today because the local model cannot reliably emit code; they will move to LOCAL when the code-capable local stack ships (see Current Capability section).

4. **Execute on the routed model:**
   - LOCAL: Call Ollama HTTP API at the configured host (default `http://localhost:11434`)
   - PAID: Call the configured paid LLM API (Anthropic, OpenAI, etc.)

5. **Record the routing decision:** Log which model was used, the category, the routing reason, duration, and cost ($0 for local).

## Required Fields / Inputs

- `task_description` -- the task to route and execute (string)
- `OLLAMA_HOST` -- local LLM endpoint (env var, default `http://localhost:11434`)
- `LOCAL_LLM_MODEL` -- model name (env var, e.g. `llama3.1:8b`)

## Local LLM Client Contract

Any implementation of this skill must provide these functions:

| Function | Purpose | Returns |
|----------|---------|---------|
| `generate(prompt, { system, format })` | Send prompt to local LLM | `{ ok, response, model, duration_ms }` or `{ ok: false, error, fallback }` |
| `classify(text, categories)` | Classify text into one of N categories | `{ ok, category, model }` |
| `draft(prompt, { system })` | Generate first-pass content | `{ ok, draft, model, duration_ms }` |
| `validate(prompt, { system })` | Check/verify something | `{ ok, result, model, duration_ms }` |

## Resilience (from local-inference-policy.md)

1. Timeout < 30s: retry once with same prompt
2. Timeout >= 30s or connection refused: check LAN config, retry once
3. 3 consecutive failures: disable local LLM for this session, fall back to cheapest paid tier
4. Never silently fall back to the most expensive paid tier -- that's a budget risk

## Example Usage

```bash
# Shell hook (quick scripts, cron jobs)
~/.local/llm-dispatch.sh "You are a classifier." "Classify this: ..." 

# Node module (worker, automation)
import { classify } from './llm-client.mjs';
const result = await classify('Check if all charters have validation criteria', ['LOCAL', 'PAID']);
```

```javascript
// Router (task classification)
import { route } from './router.mjs';
const { model, reason, category } = await route('Summarize the git log');
// -> { model: 'local', reason: 'Summarization -- local by default', category: 'summarization' }
```

## Reference Implementation

A reference implementation provides:

| File | Purpose |
|------|---------|
| `orchestrator/src/llm-client.mjs` | Local LLM client with retry/fallback |
| `orchestrator/src/router.mjs` | Task classifier applying routing rules |
| `~/.local/llm-dispatch.sh` | Shell hook for quick dispatch |

Consuming systems should copy and adapt these files, or import them directly if the orchestrator is a dependency.

## QA Gates

Reject or revise the routing if any of these are true:

- Customer-facing output was routed to local without a paid validation pass
- Owner-facing brief or recommendation was routed to local
- Architecture or design decision was routed to local
- **Any code-generation, refactor, bugfix, or code-review task was routed to local** (not supported today; see Current Capability)
- Local LLM failure did not trigger fallback (silent failure)
- Cost was not logged for paid tasks

## After This Skill Completes

1. Task result is written back to the task queue (`task_queue` or equivalent)
2. Routing decision + cost logged to the action log
3. Worker stats updated (local_llm_tasks / paid_llm_tasks counters)

## Cross-References

- `_patterns/local-inference-policy.md` -- the policy layer this skill implements
- `_patterns/producer-validator-pattern.md` -- local produces, paid/human validates
