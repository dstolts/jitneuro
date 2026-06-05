---
type: pattern
purpose: Any engineer or agent deploying a multi-stage LLM pipeline must execute a real-LLM end-to-end smoke on a small topic before enabling production traffic -- firing after all unit and stub tests pass -- because stub smoke cannot surface the integration bugs that appear only when a live language model participates: budget-tracker sync failures, judge schema omissions, model-routing cost explosions, and token-limit truncations that each go invisible to mocks but break every production run.
trigger: all unit and stub tests pass on a new or refactored LLM pipeline; OR before enabling production traffic on any new pipeline configuration
read_when: After all unit/stub tests pass on any new or refactored LLM pipeline and before enabling production traffic.
tags: [llm-pipelines, smoke-testing, integration-testing, production-readiness, multi-stage]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
origin: promoted from personal memory (project_content_pipeline_smoke_findings.md) -- Knowledge session 2026-06-01
---

# LLM Pipeline Smoke: Real LLM Required

## Pattern

After all unit/stub tests pass, run one real-LLM end-to-end execution on a small topic (low token spend) before declaring any LLM pipeline production-ready. Stubbed smoke cannot detect the integration failure modes that appear only when a real language model participates in the pipeline.

## When to use

- Any new LLM pipeline (multi-stage persona/judge/orchestrator systems, content engines, evaluation chains)
- After major refactors to orchestration, retry logic, or model routing
- Before enabling production traffic on a new pipeline configuration

Not needed for pipeline components that do not invoke real LLMs (pure data transformation, file I/O, formatting).

## Steps or structure

1. Ensure all unit and stub tests pass. This is a floor, not a ceiling.
2. Select a small, cheap topic that exercises the full pipeline path (~$0.10-0.50 real LLM spend).
3. Run the pipeline end-to-end with real LLM calls. Collect: outputs at each stage, token counts, cost tracking, retry events, judge verdicts.
4. Verify each integration point:
   - Budget/cost tracking: does the tracker persist correctly across stages? Does state sync back?
   - Retry logic: does a retry re-invoke the full upstream stage (not re-run the same input)?
   - Judge schema: do judges return required fields (verdict, failing_dimensions, retry_feedback)?
   - Model routing: are judges running on the intended lower-cost model, not inheriting the persona model?
   - Token limits: do persona stages have adequate max_tokens for long-form output? Are judges truncating?
   - Model ID normalization: does the pricing tracker handle versioned model IDs (claude-haiku-4-5-20251001 vs. claude-haiku-4-5)?
5. Fix any integration bugs found. Re-run the real-LLM smoke after each fix to confirm the fix holds.
6. Declare production-ready only after a clean real-LLM smoke pass.

## Known failure modes (invisible to stubs)

| Failure mode | Why stubs miss it |
|---|---|
| Budget tracker writes to own file but not synced to state.json | Stub returns a mock; sync path never executes |
| Retry re-invokes judge on identical input (no persona re-run) | Stub does not model the execution graph |
| Judge returns fail with empty failing_dimensions | Stub schema pre-validates; real LLM omits optional fields |
| Judges run at persona model cost (10x expected) | Stub uses one mock client for all roles |
| Persona output truncated at 4096 tokens | Stub returns full string regardless of max_tokens |
| Versioned model ID not in pricing dict | Stub uses alias keys; real API returns date-stamped IDs |

## Cost guideline

One real-LLM smoke on a short topic: approximately $0.10-0.50. This is the cheapest insurance against deploying a pipeline that fails on first production run.

## Origin

2026-04-21, content pipeline build. 75 assertions across 4 stubbed smoke suites all passed. First real-LLM end-to-end on "AI moats" topic surfaced 5 integration bugs invisible to stubs, plus 2 more during bug-fix validation (7 total). All caught by one smoke run costing approximately $0.10.

Related: `rules/smoke-real-db-before-done.md`, `rules/smoke-real-browser-before-done.md`, `rules/iterate-until-success.md`.
