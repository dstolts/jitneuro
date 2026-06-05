---
type: pattern
purpose: Any engineer or agent fixing a settings round-trip, App-API contract, or render-race bug must budget 2-3 fix-deploy-test rounds from the outset -- engaging this pattern at the moment a first fix is authored for these bug classes -- because declaring resolved after a single pass means the next layer remains hidden until it breaks in the deployed environment, not locally, causing a second incident with full re-debug cost.
trigger: first fix authored for a settings round-trip, data-path, SSE render-race, or App-API contract bug; OR a fix PR merged but the failing test still fails against the deployed build
read_when: Before authoring the first fix for a settings round-trip, data-path, render-race, or App-API contract bug.
tags: [debugging, iterative-fixing, deploy-test, critical-path, settings-bugs]
scope: public
departments: [engineering]
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Multi-Layer Fix Pattern

## Pattern

Bug classes with multiple independent failure sites (settings round-trips, App-API contracts, render races) require a fix-deploy-test loop, not a single pass. The first fix surfaces the next layer. Budget for 2-3 rounds and do not declare resolved until the deployed code passes the test against the deployed environment.

## When to use

- Settings round-trip bugs (save -> persist -> read back)
- Data-path bugs spanning multiple layers (state guard -> client storage bootstrap -> UI render)
- SSE and render race bugs
- Any bug where the App-API contract has multiple sites that can independently break the round-trip

Single-pass fix is fine for isolated, single-file logic bugs with no multi-layer contract.

## Steps or structure

1. Before writing a fix: diagnose end-to-end first. Run live probes (for example, PUT then GET against a deployed staging environment). Capture full response shapes. The PR body must cite live probe evidence, not just code inspection.
2. Open and merge the fix PR. Wait for deploy to complete.
3. Re-run the specific failing test against the deployed build. Not a local run. Deployed.
4. If the test still fails: do not declare resolved. The first fix addressed Layer 1; a new layer is now visible.
5. Repeat from step 1 for the new layer. Each round's PR body documents which layer it addresses and what the prior round's probe confirmed.
6. Declare resolved only when the deployed build passes the deployed test.

## Anti-patterns to reject

- Declaring a spec "fixed" because the PR opened with a credible-sounding fix and the agent's local test passed. Local test ran against an older staging build; deployment changes the result.
- Trusting a Round-1 agent's "ROOT CAUSE: X" claim without live probe verification. The agent may have correctly identified Layer 1 while missing Layers 2 and 3.
- Treating round-1 incompleteness as a quality failure of the agent. The multi-round shape is a property of the bug class, not the agent.

## Origin

Observed across multiple E2E test stabilization sessions where four end-to-end specs each required 2-3 fix-deploy-test rounds before passing. Representative cases: a settings round-trip bug took 3 rounds (API field allowlist -> storage promotion -> client-side key mapping); a data-path bug took 2 rounds (null-pointer guard -> client storage bootstrap default). The pattern emerged from treating each round's new failure as a discovery, not a regression.

Related: divergent-triple-agent-rca (escalation path at Round 5+), adversarial-verify-before-fix.
