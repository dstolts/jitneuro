---
type: pattern
name: qa-iteration-loop
status: canonical
purpose: Standardize the orchestrated QA-dev iteration loop. A QA agent validates ACTUAL behavior (running app, deployed surface, generated artifact) against AUTHORITATIVE expected sources (user stories, API contract, UX mockups). On non-compliance, QA reports discrete issues; master-orchestrator triggers developer agents to fix; QA reruns; repeat until 100% compliance. Replaces ad-hoc "test it manually then ship" with a deterministic, bounded loop that converges on full compliance.
read_when: Before declaring any UI feature, API endpoint, or generated artifact done -- configure the QA-dev iteration loop and run it to 100% compliance.
tags: [qa, iteration-loop, master-orchestrator, dev-agent, user-stories, api-contract, mockups, compliance-gate, recursive-improvement, definition-of-done]
scope: public
departments: [engineering]
origin_date: 2026-05-28
origin_event: Owner directive 2026-05-28 -- "qa agent loops validating actual against user stories and mockups completed loops through 100% confidence... this should be a standard QA process to iterate; report issues, master agent triggers developers to fix, and continue iterating until 100% compliance with user stories, contract and mockups." Captured into Knowledge session (item #15) and drafted same turn.
related:
  - rules/definition-of-done.md (compliance with stories + contract + mockups IS DoD for UI features)
  - rules/iterate-until-success.md (iterate until fully green, not partial)
  - rules/verify-before-presenting.md (QA pass before Owner sees the result)
  - rules/subagent-communication.md (STATUS/TOKENS/FILES_CHANGED return shape)
  - _patterns/producer-validator-pattern.md (sibling: producer creates, validator gates)
  - _patterns/llm-as-judge.md (sibling: judge with rubric, not vibes)
  - rules/testing-critical-path.md (test the critical path, not the happy path)
last_evaluated: 2026-06-03
---

# QA Iteration Loop

## Rule

For any feature that ships behavior consumers see (UI surface, API endpoint,
generated artifact), the path to "done" is a BOUNDED ITERATION LOOP between
QA and DEV agents, orchestrated by master, terminating only at 100%
compliance against the three authoritative sources:

1. **User stories** -- the WHAT (behaviors a customer expects)
2. **API contract** -- the HOW (request/response shapes, auth, error codes)
3. **UX mockups** -- the LOOK (layout, copy, interactions, states)

"Looks fine to me" is not the gate. "QA agent says zero findings against all
three sources" is the gate.

## The Loop

```text
+-----------------+       +-----------+       +---------------+
|  Master         |       |  QA       |       |  Dev          |
|  Orchestrator   |       |  Agent    |       |  Agent(s)     |
+--------+--------+       +-----+-----+       +-------+-------+
         |                      |                     |
         |  1. Build / deploy   |                     |
         | -------------------->|                     |
         |                      |                     |
         |  2. Validate actual  |                     |
         |  vs stories + contract                     |
         |  + mockups           |                     |
         |   <------------------|                     |
         |                      |                     |
         |  3. If findings >0:  |                     |
         |     dispatch fix     |                     |
         | --------------------------------+--------->|
         |                      |          |          |
         |  4. Fix returns OK   |          |          |
         |   <----------------------------------------|
         |                      |          |          |
         |  5. Goto step 1                            |
         |  (until findings = 0)                      |
         |                                            |
         |  6. Done -- 100% compliance                |
```

## Inputs the master gives QA on every iteration

QA cannot validate against sources it has not been told to use. Every QA
dispatch MUST include explicit pointers to:

- **User stories** -- path to the spec file (e.g. `dash/docs/design/SPEC-gtd-app-api-contract.md`)
  or backlog row IDs (`<repo>/todo/backlog.md` row references)
- **API contract** -- path to `docs/design/API-CONTRACT.md` (or equivalent)
- **UX mockups** -- path to the HTML mockup OR the Lovable / Figma asset
  reference. If mockups are missing, master MUST surface that as a blocker
  BEFORE dispatching QA. Skipping the visual contract guarantees drift.
- **Actual to validate** -- URL of the running surface, path to the
  artifact, or repo location of the generated output
- **Acceptance criteria** -- the exact things QA must check; usually
  `definition-of-done` items + the user story's acceptance criteria

## QA agent return contract (per `subagent-communication.md`)

```text
STATUS: OK            <- means 100% compliance, NOT just "I ran"
TOKENS: in=X out=Y model=<model>
FILES_CHANGED: (none -- QA does not mutate code)
SUMMARY_DOC: path-to-QA-report-this-iteration.md
RESULT:
  Findings: <count> (0 means done)
  By severity: <CRITICAL/HIGH/MEDIUM/LOW counts>
  By source: <user-story / api-contract / ux-mockup counts>
  Top 5 findings: <one line each, with source + acceptance-criterion ref>
```

If findings > 0:

```text
STATUS: PARTIAL       <- iteration must continue
FINDINGS_PATH: <path to detailed findings file>
NEXT_ITERATION: required
```

## Master's dispatch logic

```text
loop:
    qa = dispatch(QA-agent, inputs)
    if qa.status == OK and qa.findings == 0:
        feature is DONE; mark task complete; update Hub.md
        break
    if qa.findings > 0:
        for finding in qa.findings:
            classify finding (story-gap / contract-mismatch / mockup-deviation)
            dispatch(dev-agent, finding, fix-scope)
        wait for all dev fixes to return OK
        rebuild / redeploy if needed
        continue loop
    if loop_count > MAX_ITERATIONS:
        surface to Owner as blocked-iteration; do not infinite-loop
```

## Termination conditions

- **Convergent (the goal):** QA returns 0 findings. Feature shipped.
- **Stuck loop:** same findings persist after N iterations (default N=5).
  Surface to Owner with full finding history; do NOT keep dispatching the
  same fix to the same agent infinitely.
- **Source ambiguity:** QA finds the actual matches one source but
  contradicts another (e.g. mockup says X, contract says Y). QA returns
  `STATUS: BLOCKED` with the conflict; master surfaces to Owner for
  authoritative decision; loop pauses.
- **Owner stops the loop:** Owner can interject "ship as-is" at any point;
  loop terminates with status = `partial-shipped` + open-finding list
  for follow-up.

## What this pattern does NOT replace

- Manual Owner review for taste / brand voice / strategic copy decisions
  (LLM-as-judge style for those; not in scope of QA-iteration-loop)
- Production smoke tests against real customer data (separate; runs
  AFTER this loop terminates)
- Security review (separate; sys-security gate)

## What this pattern DOES replace

- "Tested locally -- looks good" without artifact (zero compliance signal)
- Ad-hoc dev-then-ship without an independent QA pass
- Endless single-agent iteration where dev validates own work (self-grading)

## Anti-patterns to reject

- **Skipping mockups when mockups exist:** mockups are part of the gate,
  not optional. If Owner doesn't have a mockup for a UI change, master
  surfaces that BEFORE dispatching QA. (Sibling rule:
  `ux-designer-before-lovable.md`.)
- **QA validates against the spec it just helped write:** QA must validate
  against the authoritative source, not its own scratchpad.
- **Master fixes findings directly instead of dispatching dev agents:**
  master is orchestrator, not implementer. (Sibling rule:
  `interactive-master-orchestrator.md`.)
- **Declaring done at 80% compliance:** the rule is 100%. Findings below
  100% mean iterate, not ship.
- **Same fix dispatched repeatedly to same agent without changing the
  prompt:** if a fix isn't sticking, the prompt is wrong; change inputs
  (more context, different agent, clearer scope) before re-dispatching.

## Tooling expectations

For this pattern to run cleanly, the consuming repo needs:

- An automatable build + deploy path so master can rebuild between
  iterations (no Owner-in-loop for deploy)
- Mockups committed alongside specs (HTML, screenshots, Figma exports)
- A QA agent with the rubric encoded in its prompt (severity bands,
  finding format, source mapping)
- A dev agent or pool with write access to the affected source files

## Honors

- `rules/definition-of-done.md` -- DoD = compliance with stories + contract
  + mockups + customer-validated. This pattern implements the first three.
- `rules/iterate-until-success.md` -- bounded iteration to full green,
  not partial-pass-then-ship.
- `rules/verify-before-presenting.md` -- master does NOT present a feature
  to Owner until QA returns 0 findings (or surfaces a blocker).
- `rules/subagent-communication.md` -- QA and dev agents follow the
  STATUS / TOKENS / FILES_CHANGED return contract.

## Open questions for graduation

- How does the loop handle FLAKY findings (e.g. QA reports a finding on
  iteration 3 that wasn't on iteration 1)? Lean: master keeps history
  across iterations; any net-new finding restarts the iteration counter
  for that finding.
- Should QA agent be paid-model (Sonnet+) or local-Tier-L (the local model)? Lean:
  Sonnet+ for production-bound features (judgment matters). Tier-L OK
  for early-iteration smoke during development.
- Should mockups be a hard input (refuse-to-dispatch if missing) or a
  soft input (warn + continue)? Lean: hard for UI features, soft for
  pure API or pure generated-artifact features.
- How do we wire this to `dash`'s GTD critical-path tests + critical-paths
  runner pattern already in jitai-www? Lean: reuse the
  `CRITICAL-PATHS.md` inventory pattern -- each story becomes an entry
  in the per-repo inventory.

## Promotion checklist

- [ ] Live-trial on a real feature: pick the next <your-app> surface
      that has stories + contract + mockup; run the loop end-to-end
- [ ] Refine the QA agent prompt template based on trial findings
- [ ] Decide max-iterations default (lean: 5; surface to Owner at 3)
- [ ] Status -> `wip-ready` after trial done; then `/graduate` to
      `<knowledge-root>/_patterns/qa-iteration-loop.md`
