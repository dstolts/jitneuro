---
type: pattern
purpose: Narration-to-visual alignment rule for storyboard authors and storyboard/image/frame-sample judge designers; requires each frame to illustrate the words spoken at that moment so videos do not pass with generic, theme-only visuals.
read_when: Before authoring any video storyboard, writing frame concepts, or configuring a storyboard/image/frame-sample judge -- any moment a visual is being matched to narration.
tags: [video-production, narration-alignment, storyboard, visual-concept, llm-judge]
scope: public
community_reviewed: 2026-06-02
name: Visuals-Align-Narration Pattern
status: canonical
owner: org/content
consumers: playbooks/judges/storyboard-judge.md, playbooks/judges/frame-sample-judge.md, playbooks/judges/image-judge.md
last_reviewed: 2026-05-12
last_evaluated: 2026-06-03
---

# Visuals-Align-Narration Pattern

For any video with narration, the visual at each narration beat MUST specifically illustrate the words being spoken AT THAT MOMENT. Thematic relevance is not sufficient. Specifically illustrative is required.

This pattern is enforced by the storyboard judge (concept-level), the image judge (still-level), and the frame-sample judge (composed-video-level). It also governs storyboard authoring before any image generation runs.

---

## The Distinction (concept vs theme)

Theme is what the content is generally about. Concept is what THIS frame SHOWS.

A scanner product walkthrough is a THEME.
"Over-shoulder shot of developer viewing a SaaS dashboard with $29 pricing element visible" is a CONCEPT.

Theme drives the brief; concept drives the visual.

A video where every frame is on-theme but no frame illustrates the specific words being spoken fails this pattern. The audience hears a sentence and sees something unrelated to that sentence -- even if related to the broader topic.

---

## How to Apply

### Storyboard authoring

For each narration beat, write an explicit "Visual concept" tied to the specific words spoken at that beat:

```
Beat 3 (00:18-00:24)
Narration: "Someone just paid twenty-nine dollars for your AI product."
Visual concept: Dark SaaS dashboard at 11pm lighting; cursor hovering over a $29 pricing element; subtle teal accent on the price (#2dd4bf). Camera angle = over-shoulder of a developer at a standing desk. Mood: anticipation just before a turn.
```

Beat-by-beat. No "thematic shot of a developer" placeholders.

### Storyboard judge (concept-level)

The storyboard judge scores each beat: "does this Visual concept specifically illustrate the narration line?" A theme-match-but-not-specific = fail. Cite the failing line + the generic concept and require a rewrite to specific imagery.

Dimension: `concept_match` (0-10):
- 10: Visual concept illustrates the specific words spoken; named subject + named action + named setting
- 8: Visual concept is specific; minor abstraction acceptable
- 6: Visual concept is on-topic but theme-level, not line-level
- 4: Visual concept is generic; could illustrate any line in the script
- 2: Visual concept contradicts the line

### Image judge (still-level)

Image judge rubric includes `concept_match` (0-10) where theme-match-but-not-specific = fail. The judge MUST see both the image AND the narration line being illustrated; it scores whether the image illustrates THAT line, not whether the image is on-theme.

Pass threshold: 7 / 10 with no single-dimension score below 5 (per `_patterns/llm-as-judge.md` "fail if any single score < 5 even if average passes" pattern).

### Frame-sample judge (composed-video-level)

After Stage 4 video composition, frame-sample judge extracts one frame per ~10 seconds (or per beat midpoint) and scores each frame against the narration line spoken at that timestamp. Theme-only frames at narration-specific moments fail.

This catches: storyboard passed concept-match, image judge passed concept-match, but during composition the wrong still was placed against the wrong narration line (timing slip or asset-swap error).

---

## Examples

### Example 1

Narration: "Someone just paid twenty-nine dollars for your AI product."

- BAD: Scanner landing page screenshot (thematic; "AI product" matches "AI product" theme)
- GOOD: Dark SaaS dashboard at night-lighting; cursor over a $29 pricing element; teal accent on the price (specific; the WORDS "twenty-nine dollars" are visible in-frame)

### Example 2

Narration: "In forty-eight hours, a competitor will clone it for nine."

- BAD: Cascade of generic code (thematic; "competitor" + "clone" is about code)
- GOOD: Two browser windows side by side, $29 on one side, $9 teal-highlighted on the other (specific; the two prices the narration names are visible side by side)

### Example 3

Narration: "Our customers report 40% reduction in time-to-resolution."

- BAD: A stopwatch (thematic; reduces-time-themed)
- GOOD: Split before/after dashboard showing average resolution time falling from 4h to 2.4h with a teal arrow (specific; the 40% reduction is visualized as a 4h-to-2.4h change)

---

## Why This Matters (origin)

During a video review, the owner corrected: "better but still a long way to go. we need the graphic to align with what we are saying." The sample played a product walkthrough in the background while the narration described a specific competitive scenario about a different SaaS product. Visuals were thematically relevant (both about AI products) but did not illustrate the specific scenario the voice described.

The approved fix used beat stills that each specifically illustrated their narration line. This became the reference for "specific illustration" vs "thematic illustration."

---

## Anti-Patterns (automatic rewrites)

- "Generic shot of [topic]" as a Visual concept -- not specific
- "Cascade of [theme-keyword]" -- decorative, not illustrative
- "B-roll of [setting]" with no named action or subject tied to the narration line
- Reusing the same Visual concept across multiple beats -- if multiple beats share a concept, the concepts aren't specific enough

---

## Origin

This pattern was previously captured as a per-session feedback note. It was relocated to `_patterns/` so it becomes a portable, versioned, PR-gated artifact consumable by every system that uses the shared knowledge repository as its canonical reference.

---

## Cross-References

- `_patterns/llm-as-judge.md` -- the underlying judge-loop pattern this pattern is instantiated by
- `playbooks/judges/storyboard-judge.md` -- enforces concept-level alignment during storyboard authoring
- `playbooks/judges/image-judge.md` -- enforces concept-level alignment per still
- `playbooks/judges/frame-sample-judge.md` -- enforces composed-video-level alignment via beat-midpoint frame sampling
- `playbooks/content-style-guide.md` -- producer-facing style guidance
