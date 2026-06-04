---
type: pattern
purpose: Any agent orchestrator or pipeline designer assembling a multi-judge gate on a human-facing content artifact must add a novice-viewer judge before the gate fires -- triggering whenever a gate is being configured for video, blog, social, or email content, or after an Owner rejection of a technically-passed artifact -- because omitting this hat means a unanimous technical PASS can advance genuinely unengaging content to production, wasting the full downstream production cost.
trigger: configuring or auditing a multi-judge content gate; OR Owner rejects an artifact that passed all technical judges; OR adding a new content type to an existing pipeline
read_when: Before configuring or modifying a multi-judge quality gate on any human-facing content artifact (video, blog, social, email).
tags: [content-review, quality-gates, councils, novice-viewer, creative-production]
scope: public
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_validation_council_needs_novice_viewer_hat.md) -- Knowledge session 2026-06-01
---

# Content Validation Council -- Novice-Viewer Hat

## Pattern

For any multi-judge gate on content destined for human viewers (video, blog, social, email, storyboard), add one judge whose ONLY lens is "would a real human think this is great or crap, and why -- ignoring whether it passes the technical standard." Calibrate the hat against concrete exemplars the Owner has designated as good vs. bad. The novice-viewer verdict (GREAT / OK / CRAP per unit) is a first-class gate output; any CRAP fails the gate regardless of technical PASS.

## When to use

- Pre-auth or pre-ship gate on any content artifact viewed by humans
- When adding a new content type to an existing pipeline (gate may not yet have this hat)
- After an Owner rejection of a technically-PASSed artifact -- this hat was missing

Not needed for purely internal artifacts (schemas, configs, runbooks) with no human aesthetic dimension.

## Steps or structure

1. Identify reference exemplars: content Owner has designated as good (model of quality) and bad (model of crap). Without exemplars the hat returns generic feedback.
2. Add a novice-viewer / content-quality-auditor judge to the standing council. Role description: calibrated to 10K+ hours of relevant consumption experience; evaluates engagement, authenticity, whether the artifact earns its place.
3. Judge outputs a per-unit rating: GREAT, OK, or CRAP with a one-line reason.
4. Gate logic: if any unit is rated CRAP, gate fails. Do not accept a PASS from the technical judges as override.
5. When CRAP units are identified, fix at the unit level AND audit whether the production standard has a structural gap (see validate-the-standard-not-just-the-verdict pattern).

## Hat calibration notes

The hat must be calibrated to the specific domain:
- Video storyboard: would a viewer keep watching past this panel?
- Blog post: would a reader scroll past the first paragraph?
- Social content: would someone pause and engage, or scroll past?
- Email: does it read as a response from a person, or a marketing blast?

Generic "quality" without domain calibration produces generic, unhelpful feedback.

## Origin

2026-04-30, SEO-Content-Launch session. 6 specialist hats covered technical criteria (panel count, transition schema, MOAT coverage, runtime gate, CTA accessibility). None covered "is this content engaging." Unanimous PASS. Owner rejected on first browser open: "Looks like text-based PowerPoint slides," "we need to start over, this sucks." Subsequent Opus content-quality auditor calibrated to Owner exemplars returned 0 of 34 panels GREAT, 24/34 CRAP.

Related: validate-the-standard-not-just-the-verdict, research-before-iterate-on-weak-signal, `rules/judgment-over-compliance.md`.
