---
name: root-cause-analysis
type: skill
description: This skill should be used when Owner says "root cause analysis", "why did this happen", "how will you prevent this", "trace this to root cause", or "RCA". Also invoke when a fix has been rejected and deeper investigation is needed. Runs an evidence-first four-phase method (Investigate -> Analyze -> Hypothesize -> Implement) that cuts iteration count from ~10 to 3-4 by gathering all evidence up front before forming any hypothesis. Applies to code bugs, process failures, communication mistakes, and behavioral errors.
purpose: Evidence-first four-phase RCA method for any master agent; MUST be invoked before any fix attempt when Owner signals RCA; skipping means hypothesis-before-evidence loops that triple iteration count and produce wrong rules.
tags: [skill, root-cause-analysis, debugging, evidence-first, four-phase, process, agent-behavior]
scope: public
departments: [all]
read_when: Immediately when Owner signals RCA ("root cause analysis", "why did this happen", "trace this to root cause") -- STOP all work and enter this skill before any fix attempt.
last_evaluated: 2026-06-03
---

# Root Cause Analysis

Stop. Gather evidence. Then trace. Then fix. Never form a hypothesis before
you have the evidence to discriminate it from alternatives.

Applies to code bugs, process failures, communication mistakes, and behavioral
errors -- not just debugging.

## When to Apply

- Owner explicitly says "root cause analysis", "RCA", "why did this happen",
  "how will you prevent this", or "trace this to root cause"
- The phrase is an IMMEDIATE intercept: STOP all current work, enter this
  process without asking for confirmation
- A fix was applied and Owner rejected it ("wrong", "all wrong", "that's not
  it") -- ask "Want me to trigger RCA?" and wait for confirmation before
  entering
- Do NOT auto-enter RCA from a failed fix alone -- ask first

## Core Governance Wrapper

1. **STOP.** Do not fix anything yet. Do not continue prior work. RCA is the
   only active task.
2. **Run the four-phase method** (see below).
3. **CONFIRM** -- State the root cause in one sentence. Present it to Owner.
   Wait for confirmation before proposing a solution.
4. **PROPOSE** -- Offer the solution. Do NOT implement it yet.
5. **CLOSE** -- Ask: "Ready to accept, save and close RCA? (yes/no)". RCA
   closes ONLY when Owner uses an explicit closure phrase (see below). No
   interpretation, no assumed equivalents.
6. **IMPLEMENT** -- Only after Owner explicitly closes: apply the fix. Write
   the rca artifact. Display `** RCA saved **` when complete.

Never update rules, memory, or resume other work while RCA is open. Premature
fixes with wrong root causes create wrong rules.

## Closure Phrases (Owner must use one)

Accepted (case-insensitive): "yes", "approved", "accepted", "rca approved",
"sign off", "signed off", "close it", "lgtm". Minor phrasing variations of
these count -- intent is the signal, not exact string match. If ambiguous,
re-ask with the strict closure prompt.

## Four-Phase Method

### Phase 1 -- Investigate (evidence before hypothesis)

Do not form any hypothesis yet. Gather all available evidence first.

1. **Reproduce the failure reliably.** Find the simplest input/state that
   triggers it consistently. A failure that cannot be reproduced cannot be
   root-caused. If it cannot be reproduced: state that as a finding and
   escalate to Owner before continuing.
2. **Gather all evidence up front.** In one pass, collect:
   - Error messages, stack traces, log output
   - The full code path from entry point to failure
   - Recent commits/changes (git log, diff) that touched the affected area
   - System state at the time of failure (env vars, config, DB state)
   - For behavioral failures: re-read the EXACT exchange -- do not rely on
     memory
   - For code bugs: check server logs first; run real API tests (curl against
     live/uat endpoints); never mock to validate
3. **Trace data flow backward.** Find where the failure ORIGINATES, not just
   where it APPEARS. These are often different locations.

### Phase 2 -- Analyze Patterns (differential reasoning)

4. **Build a differential map.** Compare working state vs broken state.
   What MUST differ for the failure to occur? Include:
   - Code changes between last-working and current
   - Config or environment differences
   - Dependency version changes
   - State differences (data, session, cache)
   Identify the structural constraint: "the bug REQUIRES X to be true".

### Phase 3 -- Hypothesize and Test (bisection)

5. **Generate 2-3 ranked hypotheses** from the differential map. Rank by
   (likelihood x cheapness-to-test). Do not test the most likely first --
   test the most DISCRIMINATING first (the test that eliminates the most
   alternative hypotheses with one result).
6. **Predict before testing.** For each hypothesis, state what you expect to
   observe IF the hypothesis is true AND if it is false. A result that
   contradicts the prediction is where the root cause hides.
7. **Run the most discriminating test.** Record:
   ```
   Hypothesis N: [description]
     Test: [single variable changed -- the discriminating test]
     Prediction if true: [what you expect]
     Actual result: [what happened]
     Verdict: Confirmed | Disproven | Inconclusive
   ```
   **Capture failed hypotheses.** They are load-bearing context -- without
   them, future sessions re-attempt the same dead ends. Record them in the
   rca artifact regardless of outcome. (Anthropic research: persistent failure
   context is critical; failed approaches must be captured.)
8. **Stop condition.** If three consecutive hypotheses all fail, STOP and
   escalate to Owner before continuing. The problem may not be in the
   investigated layer.

### Phase 4 -- Synthesize Causality (causal structure)

Produce a causal structure, not a single linear chain:

- **Trigger:** the specific change or condition that initiated the failure
- **Root cause:** why the trigger was able to cause harm (missing guardrail,
  wrong assumption, design gap)
- **Detection gap:** what should have caught this earlier and did not
- **Symptom:** what the user/Owner observed (separate from root cause)

Separate "what caused it" from "what should have caught it". These require
different fixes: one fixes the system, one adds detection.

## Output Artifact

After confirming the root cause with Owner, write a structured `rca_*.md`
artifact to the relevant repo's `.HUB/` or `docs/reviews/` folder:

```markdown
---
type: rca
date: YYYY-MM-DD
classification: rule-candidate | persona | engram | jit-knowledge-candidate | none
---

# RCA: [short title]

## Trigger
[specific change or condition]

## Root Cause
[why the trigger caused harm]

## Detection Gap
[what should have caught this earlier]

## Symptom
[what was observed]

## Evidence Gathered
[log snippets, diffs, state observations from Phase 1-2]

## Hypotheses Tested
[all hypotheses with Verdict; include FAILED ones]

## Fix Applied
[what was changed]

## Prevention
[rule, guardrail, or skill that would prevent recurrence]

## Failed Approaches / Dead Ends
[what was tried and ruled out, with reasoning -- future sessions must not
re-attempt these dead ends]
```

The `classification` field drives next-action routing:
- `rule-candidate` -- propose a new or amended rule in `~/.claude/rules/`
- `persona` -- amend the master-orchestrator persona or a specialist charter
- `engram` -- update the repo's `.jitneuro/engrams/context.md`
- `jit-knowledge-candidate` -- flag for WS6 cross-repo rollup promotion
- `none` -- fix only, no structural artifact needed

## Domain Shortcuts

**For code bugs:** check server logs first; run real API tests (curl against
live/uat endpoints); never mock to validate; confirm the target branch before
writing code.

**For behavioral and communication failures:** re-read the exact exchange (do
not rely on memory); identify the rule that should have prevented this and why
it did not fire.

## What to Avoid

- Forming a hypothesis before completing Phase 1 evidence gathering
- Testing a confirm-one-guess test instead of the most discriminating test
- Patching the symptom instead of the root cause
- Discarding failed hypotheses -- they are evidence, not noise
- Closing RCA before Owner uses an explicit closure phrase
- Running RCA in parallel with another task
- Updating rules, memory, or code while RCA is open

## Integration

Used by: sys-architect, sys-backend, sys-security, sys-qa, sys-code-reviewer,
sys-sre, security-developer, master-orchestrator.

Canonical home: `jit-knowledge/skills/root-cause-analysis.md`. The
user-global rule at `~/.claude/rules/root-cause-analysis.md` is a thin wrapper
that points here; the authoritative method lives in this skill.
