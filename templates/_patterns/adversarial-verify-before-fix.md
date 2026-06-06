---
type: pattern
purpose: Any engineer or agent orchestrating a multi-bug fix session must dispatch an independent adversarial verifier before authoring any fix -- firing when a batch of 3+ bugs has been diagnosed in a single pass or a cited file:line has not been independently read -- because skipping this step ships fixes for phantom bugs and wrong-layer symptoms that survive production and compound the defect count.
read_when: Before authoring any fix when 3 or more bugs have been diagnosed in a single pass, or when a cited file:line has not been independently verified.
trigger: batch of 3+ bugs diagnosed in one pass; OR a bug that "passed" but symptom persists; OR diagnosis cites a specific file:line not yet independently verified
tags: [debugging, quality-gates, multi-bug, verification, diagnosis]
scope: public
departments: [all]
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Adversarial Verify Before Fix

## Pattern

For any multi-bug or multi-fix workflow, run a diagnose -> adversarially-verify pipeline. An independent verifier agent reads the cited file:line firsthand, runs a live probe, and hunts for a deeper or alternative cause BEFORE any fix is authored.

Default posture: skepticism. Confirm the diagnosis is current, correct, and complete.

## When to use

- Batch-bug sessions (3+ bugs diagnosed in one pass)
- Fixing against a captured log or trace file that may be stale
- A bug that "STATUS: OK" agents reported fixed but the symptom persists
- Any diagnosis citing a specific file:line that has not been independently read

Not needed for obvious, single-file, trivial fixes where the root cause is unambiguous.

## Steps or structure

1. Diagnosis agent reads the symptom and proposes a root cause with a file:line citation.
2. Verifier agent (independent, separate dispatch) runs in parallel or immediately after:
   a. Reads the cited file:line directly -- confirm the code still says what the diagnosis claims.
   b. Runs a live probe (curl, test invocation, or log grep against deployed build) -- confirm the symptom is reproducible.
   c. Actively looks for a deeper cause or an alternative explanation at a different layer.
   d. Checks any captured log file (error log, trace file) against current source -- confirm log strings still exist.
3. Verifier returns one of:
   - CONFIRMED: root cause matches, fix is safe to proceed.
   - OVERTURNED: diagnosis is wrong-target, stale, or phantom -- surface evidence to the team; do not fix.
   - DEEPENED: Layer 1 correct but Layer 2 identified -- expand fix scope before proceeding.
4. Fix is authored ONLY after CONFIRMED or DEEPENED verdict.

## Origin

Adversarial pass on a batch of 7 diagnosed bugs in a field-service application:
- Overturned 2 as non-bugs (a deployed PR had already fixed one; a wrong-bundle trace on another).
- Deepened 1 settings-500 error from "bad timezone value" to "duplicate column in SELECT causing the DB driver to return arrays instead of scalars."
- Caught a defect in a proposed fix PR (in-memory repair with no persistence) before merge.

Cost of one verifier agent is far less than a wrong fix plus re-debug. Diagnosis agents (and human engineers) have hypothesis bias; independent skeptical verification catches the gap.

Related: `_patterns/multi-layer-fix-pattern.md`, `rules/verify-before-claiming.md`, `rules/verify-before-presenting.md`.
