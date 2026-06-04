---
type: pattern
purpose: Canonical quality-gate judge pattern for authors and pipeline integrators creating or wiring LLM judges; defines rubric scoring, retry-with-critique, and escalation caps so validation does not drift, loop indefinitely, or advance weak artifacts.
read_when: Before authoring or wiring any LLM judge into a quality-gate pipeline to ensure the scoring, retry, and escalation shape follows the canonical pattern.
tags: [llm-judge, quality-gate, retry-loop, rubric, content-quality]
scope: public
name: LLM-as-Judge Pattern
status: canonical
owner: org/architect
consumers: playbooks/judges/*.md, agents/judges/*.md
last_reviewed: 2026-05-12
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# LLM-as-Judge Pattern

Canonical pattern for every quality-gate judge in jitneuro: an LLM scores generated content against a rubric; the stage completes only when the score passes threshold; failures trigger auto-retry with sharpened prompts.

Every judge in `playbooks/judges/` and `agents/judges/` inherits this pattern. Judge-specific rubrics, dimensions, and thresholds live in each judge's own file; the SHAPE of how a judge runs lives here.

---

## Core Loop

1. **Generate** the artifact (content, image, audio, slide, etc.)
2. **Score** -- call the judge with the rubric + the artifact
3. **Branch** on verdict:
   - PASS -> advance to next stage
   - FAIL -> inject judge's critique into the next generation prompt; regenerate (up to `retry_max`, default 3)
   - HARD-BLOCK (where applicable) -> halt the pipeline; surface to the owner
4. **Escalate** after retry cap: surface specific blocker ("judge says palette wrong 3 consecutive times; input needed on whether to proceed with fallback or pause")

---

## Judge Type Catalog

Reference table of judge types with their typical model choice and what each catches. Specific judges in `playbooks/judges/` instantiate these patterns with concrete rubrics.

| Judge type | Typical model | Cost / call (approximate) | Catches |
|---|---|---|---|
| Script / framing judge | Haiku | ~$0.01 | Missing opening elements, voice slips, banned phrases, structure violations |
| Storyboard judge | Haiku | ~$0.02 | Narration-visual misalignment, weak concepts, beat-to-line drift |
| Image judge | Multimodal vision model | ~$0.02-$0.05 / image | Placeholder images, concept mismatch, palette drift, flat backgrounds, literal-text-as-subject |
| Audio judge | Transcription model + text-diff | ~$0.01 | Truncated reads, silent gaps, WPM out of range |
| Frame-sample judge | Vision LLM at each beat midpoint | ~$0.02 / frame | Compose-level visual/narration mismatch |
| Brand-voice judge | Sonnet | ~$0.05-$0.10 | Posture drift, banned phrases, tone-matrix violations |
| Content-quality judge | Haiku (Sonnet escalation on edge cases) | ~$0.01-$0.02 | SEO/AEO/Quality floor, structural / credibility / hygiene binary gates |
| Moat-protection judge | Haiku (Sonnet escalation on ambiguous) | ~$0.02 | Secrets, PII, competitor branding, defensible claims, legal compliance |

Costs are approximate at current provider list prices. Judges should document their own cost ceiling anchored to API-rate pricing (not subscription flat costs).

---

## Rubric Shape (binding for new judges)

A judge's rubric file (in `playbooks/judges/` or `agents/judges/`) MUST contain:

### 1. Frontmatter (YAML)

Required keys:
- `name` -- the judge's identifier
- `title` or `role` -- one-line description
- `scores` -- array of dimension names this judge scores (omit for binary-only judges)
- `pass_threshold` -- map of dimension to threshold value (numeric for scoring judges; binary-pass-criteria for binary judges)
- `retry_max` -- integer (default: 3); the harmonized key name across all judges (NOT `max_retries`)
- `model` -- target model tier (`haiku` / `sonnet` / `opus` / `vision-model-name`)
- `reference` (or `reference_pattern`) -- `_patterns/llm-as-judge.md` (THIS file; canonical pattern)
- Optional: `companion_judge`, `manager` (the charter that invokes the judge), `rubric_source` (a checklist file with detailed per-component formulas)

Threshold conventions:
- 0-10 scale: thresholds typically `7` (acceptable) or `8` (strong); `10` = zero-tolerance / hard-block
- 0-100 scale: typical floor `85` for quality gates
- HARD-BLOCK below threshold: documented explicitly in the dimension rubric

### 2. Purpose section

One paragraph stating: what this judge gates, when it runs in the pipeline, and which companion judges run before/after it.

### 3. How to Call section

Input format + return JSON schema. The schema MUST be deterministic -- every field typed, every enum enumerated. Callers depend on the schema to make pass/fail decisions.

Required return fields:
- `verdict` -- enum: `pass | fail` (or `pass | fail | hard_block` for judges with hard-block dimensions, or `pass | fail | rewrite_from_scratch` for content judges with severity-of-failure trifurcation)
- `scores` -- map of dimension -> integer
- `failing_dimensions` -- array (empty on pass)
- `retry_feedback` -- string (the prompt-injection block for the next regen attempt)
- `escalate` -- boolean
- `escalation_message` -- string (conditional on escalate)

### 4. Dimension rubrics

Per dimension: scoring guide (one paragraph per score band: 10, 8, 6, 4, 2, 0 for 0-10 scales). Cite failing-passage requirements + provide pass-example.

### 5. Retry prompt injection

Template for the feedback block injected into the next regen attempt. Must reference: judge identity, dimension failing, score vs threshold, failing-passage verbatim, required fix, example of pass.

### 6. Escalation triggers

Named triggers (e.g., "same dimension fails on retry 3" -> standard escalation; "voice_match below 6 on first attempt" -> upstream signal). Each trigger has a specific escalation message template.

### 7. Hard rules

Non-negotiables. The model tier choice MUST be justified inline if it deviates from the default for the judge type.

### 8. Cost note

Estimate per call + ceiling at `retry_max` retries. Anchor costs to API-rate pricing, not subscription flat rates, so cost projections remain valid when subscription caps are exhausted.

### 9. Cross-references

Cite this pattern doc (`_patterns/llm-as-judge.md`), the rubric source (e.g., `playbooks/content-grading-checklist.md` for content judges), the manager charter that invokes the judge, sibling / companion judges, and any binding rules.

---

## Image Judge Rubric (canonical example)

The image judge is the reference instantiation for vision-LLM judges. Its rubric pattern:

```
Rate this image 0-10 on:
(a) Concept match -- does image illustrate the narration "{line}"?
(b) Production quality -- cinematic scene or placeholder (solid BG, literal text/numbers, flat shapes)?
(c) Palette compliance -- {documented brand palette}?
(d) No text artifacts -- text belongs as overlay, not baked into image.

Return JSON: { scores: { concept_match, production_quality, palette_compliance, no_text_artifacts }, verdict: pass | fail, reason: "<one paragraph>" }

Pass threshold: 7/10 each, no single score below 5.
```

The "fail if any single score < 5 even if average passes" pattern is generalizable: per-dimension floors prevent a high score on three dimensions from masking a critical failure on the fourth.

---

## Retry Loop Discipline

- Generate output, call judge, if pass advance, if fail inject critique into next regen, regen up to `retry_max` (default 3)
- After `retry_max` fails: do not silently retry; escalate with a specific blocker description

### Budget safety

Per-task cap + 2x-kill rule: a retry loop that burns `retry_max` without reaching pass automatically aborts and surfaces the blocker to the owner. Anchoring estimates to API-rate pricing (not subscription cost) ensures the cap is meaningful when tokens run on metered APIs.

### When NOT to retry

- Hard-block dimensions (trade-secret leaks, secrets, PII): one strike, escalate, no retry. The leak is permanent once published.
- Score below 70 on a 0-100 dimension: rewrite from scratch, do not retry-patch.
- Same dimension fails on retry 3: standard escalation -- owner judgment required.

---

## Model Tier Selection

Choose Haiku for pattern-bearing tasks (count things, check string presence, verify lengths, scan for banned terms). Choose Sonnet for judgment-bearing tasks (voice nuance, posture detection, semantic credibility checks, ambiguous edge cases).

Hybrid pattern: judge runs on Haiku by default; specific named cases escalate to Sonnet (e.g., ambiguous-zone scores, retry-3 failures, non-standard inputs). Document the escalation triggers in the judge's Escalation Triggers section.

---

## When This Pattern Does NOT Apply

- **Mechanical checks** (regex, length, count, file-existence): use a rule-based scanner. Rule-based scans run BEFORE the LLM judge and gate it (the LLM judge runs only after mechanical checks pass).
- **Subjective ranking with no rubric**: not a judge. A judge requires an explicit, citable rubric with deterministic dimension scoring.
- **Owner-only decisions** (pricing, customer copy, business direction): never delegate to an LLM judge. Surface to the owner.

---

## Origin

This pattern was extracted from a per-session memory reference and relocated to `_patterns/` so it becomes a portable, versioned, PR-gated artifact consumable by every system that uses jitneuro as its canonical reference.

---

## Cross-References

- `_patterns/visuals-align-narration.md` -- companion pattern; storyboard / frame-sample / image judges enforce visual-narration alignment per beat
- `_patterns/brand-voice-pattern.md` -- brand-voice inheritance + monthly LLM-as-judge audit
- `playbooks/judges/*.md` -- judge instantiations (each cites this pattern)
- `playbooks/content-grading-checklist.md` -- detailed per-check formulas for content-quality judge
