---
name: Slide Judge
scores:
  - typography_hierarchy
  - bullet_discipline
  - whitespace
  - one_idea_clarity
  - pyramid_structure
  - brand_consistency
  - data_viz_quality
  - readability_at_preview_size
pass_threshold:
  typography_hierarchy: 8
  bullet_discipline: 8
  whitespace: 8
  brand_consistency: 8
  one_idea_clarity: 7
  pyramid_structure: 7
  data_viz_quality: 7
  readability_at_preview_size: 7
hard_reject_rules:
  - bullet_count_gt_7
  - fonts_3_or_more
  - venture_logo_missing
  - raw_text_on_busy_image
retry_max: 3
model: claude-sonnet-4-6
model_note: "Vision required. Must be Claude Sonnet with vision (claude-sonnet-4-6). Haiku does not support vision in all configurations."
judge_pattern_ref: _patterns/llm-as-judge.md
type: playbook
purpose: MUST be invoked by the content-pipeline orchestrator after slide-producer completes Stage 3 slide PNGs and before compose begins; hard rejects bullet_count_gt_7, 3+ fonts, missing venture logo, and raw text on busy image. Skipping means visually broken, off-brand, or unreadable slides ship as the published visual layer.
read_when: After slide-producer finishes Stage 3 PNGs and before the compose step runs.
tags: [llm-as-judge, vlm, slide-production, content-pipeline, quality-gate]
scope: public
last_evaluated: 2026-06-03
---

# Slide Judge (VLM)

## Purpose

Score each slide PNG produced by slide-producer before it advances to compose (video overlay) or distribution (LinkedIn carousel/deck). This judge uses vision (Claude Sonnet with vision) to examine the actual rendered pixel content of each slide PNG. It catches typography violations, bullet overload, branding gaps, and readability failures before they reach the compose pipeline or Owner's review queue.

## Model note

This judge requires vision capability. Use claude-sonnet-4-6 with vision enabled. Haiku does not support vision in all configurations. Do not substitute a text-only model.

## Input contract per slide

You receive for each slide PNG:
- The .png file path
- The narration line for that beat (exact text from storyboard -- this is the speaker notes / intended spoken content)
- The slide title (as rendered)
- The beat number
- The sprint_id
- The venture name (for brand palette reference; default: jitai.co)

## Scoring rubric (0-10 per dimension)

### A. typography_hierarchy (threshold 8+ -- viral-critical)

Is there a clear visual hierarchy: title > subtitle > body > caption? Are fewer than 3 fonts used?

Score:
- 9-10: Clear visual levels. Title is largest and boldest. Body is smaller, consistent. One heading font + one body font visible. No third font.
- 7-8: Hierarchy is present but one level is slightly ambiguous (e.g., subtitle and body nearly same size).
- 5-6: Hierarchy is unclear. Multiple elements compete for visual attention at the same size/weight.
- 3-4: Two or more fonts that conflict visually, or no clear size hierarchy.
- 0-2: Typography chaos. Three or more fonts detected, or body text larger than title.

Detection note: count distinct font faces visible. If three or more distinct typefaces appear on a single slide, this is a hard reject (3+ fonts), regardless of score.

### B. bullet_discipline (threshold 8+ -- viral-critical)

How many bullets are visible? Are they each 5 words or fewer?

Score:
- 10: Zero bullets (visual slide) or 1-3 bullets each under 5 words.
- 8-9: 4-5 bullets, all under 5 words each.
- 6-7: 5 bullets but one or two are 6-7 words (slightly over).
- 3-5: 6 bullets visible, or any bullet is a full sentence (10+ words).
- 0-2: 7+ bullets visible, or bullets are paragraph-length text blocks.

Hard reject rule: if 7 or more bullets are visible, return verdict "hard_reject_bullets" immediately. Do not score remaining dimensions. State: "Bullet count exceeds 7 -- hard reject. Slide-producer must split this slide into two or replace bullets with a visual."

### C. whitespace (threshold 8+ -- viral-critical)

Does the slide have visual breathing room? Is at least 15% of the slide area empty?

Score:
- 9-10: Generous whitespace. Text and images occupy roughly 70-80% of the slide. Content has room to breathe.
- 7-8: Adequate whitespace. Slide is full but not cramped.
- 5-6: Slightly crowded. Text block fills most of the slide but there is some margin.
- 3-4: Crowded. Text or images touch near the edges. Little visual rest.
- 0-2: No whitespace. Content is edge-to-edge. Visually fatiguing.

### D. one_idea_clarity (threshold 7+)

Does the slide communicate exactly ONE primary idea or insight?

Score:
- 9-10: One clear idea. The title asserts it. All body elements support it. Nothing else competes.
- 7-8: One primary idea, with one minor secondary point that is clearly subordinate.
- 5-6: Two ideas with roughly equal visual weight. Viewer is unsure which is the takeaway.
- 3-4: Multiple competing ideas. Slide would be clearer as two or three separate slides.
- 0-2: No coherent idea. Content is a data dump.

### E. pyramid_structure (threshold 7+)

Does the title make a full-sentence assertion (the McKinsey/Minto headline rule)?

Score:
- 9-10: Title is a complete sentence with a verb that asserts the slide's point. Example: "Three controls block 80% of breaches." Body points support this claim.
- 7-8: Title nearly asserts a point but lacks a verb. Example: "Three key security controls" -- directional but not assertive.
- 5-6: Title is a topic label only. Example: "Security Controls." The viewer must read the body to find the insight.
- 3-4: Title contradicts or is unrelated to the body content.
- 0-2: No title visible, or title is decorative only.

### F. brand_consistency (threshold 8+ -- viral-critical)

Is the venture logo present? Do colors match the expected master palette? Does the footer appear?

For jitai.co master palette: primary navy (#1A2B4E), accent teal (#26D0C9), neutral white/grey, warm accent orange (#FF6B35 for highlights).

Score:
- 10: Logo visible (small, top-left or master placeholder). Footer present with venture name. Colors match palette. Fonts match Inter (or Arial fallback).
- 8-9: Logo present. Footer present. One minor color deviation (e.g., slightly different shade of navy).
- 6-7: Logo present but footer missing, or one palette color significantly off.
- 3-5: Logo missing OR footer missing AND palette is off.
- 0-2: No brand elements visible. Could be any deck from any company.

Hard reject rule: if the venture logo is completely absent from the slide, return verdict "hard_reject_brand" immediately. State: "Venture logo not detected. Slide-producer must apply the venture master correctly. Check that --master argument points to the correct .pptx file."

### G. data_viz_quality (threshold 7+ -- applies only if slide contains a chart or graph)

Is there one primary insight highlighted? Is the chart readable? No chartjunk?

If no chart is present on this slide, score this dimension 10 (not applicable) and note "N/A -- no chart on this slide."

Score (when chart present):
- 9-10: One bar, line, or segment is highlighted (bold, accent color, or direct label). Legend is readable at 8pt+. No 3D effects. No gratuitous gridlines.
- 7-8: Insight is discernible but not highlighted. Chart is readable.
- 5-6: Multiple elements compete. No clear primary insight. Legend small but present.
- 3-4: Chartjunk visible (3D, shadow, decorative fills). Insight buried.
- 0-2: Chart is unreadable. Legend missing or too small to parse. 3D effects obscure data.

### H. readability_at_preview_size (threshold 7+)

Is body text readable when the slide is shown at LinkedIn feed thumbnail size (approximately 400px wide) AND at full-screen?

Score:
- 9-10: All text is clearly readable at thumbnail. Title text is large and punchy. No text is smaller than 14pt apparent size.
- 7-8: Title readable at thumbnail. Body text may require slight zoom but is not microscopic.
- 5-6: Title readable but body text is borderline at thumbnail size (appears as texture, not words).
- 3-4: Only the title (or nothing) is readable at thumbnail. Body is invisible at that size.
- 0-2: Even the title is unreadable at thumbnail size.

## Pass/fail determination

Pass: A (typography_hierarchy) >= 8, B (bullet_discipline) >= 8, C (whitespace) >= 8, F (brand_consistency) >= 8, AND D/E/G/H >= 7.

Fail: any dimension below its threshold.

Hard reject (immediate, no retry count consumed):
- bullet_count_gt_7: bullet_discipline score results in hard_reject_bullets verdict
- fonts_3_or_more: three or more distinct fonts detected in typography_hierarchy scoring
- venture_logo_missing: brand_consistency score results in hard_reject_brand verdict
- raw_text_on_busy_image: text is placed directly on a complex photo without a color block overlay (deduct 3 from whitespace and brand_consistency; if either drops below 5, emit hard_reject_text_on_image)

Hard reject does NOT count against the 3-retry maximum. Slide-producer must fix the configuration-level issue first (split the slide, apply the master, reduce fonts), then retry.

## Output format (per slide)

```json
{
  "beat": N,
  "verdict": "pass" | "fail" | "hard_reject_bullets" | "hard_reject_brand" | "hard_reject_text_on_image",
  "scores": {
    "typography_hierarchy": 0,
    "bullet_discipline": 0,
    "whitespace": 0,
    "one_idea_clarity": 0,
    "pyramid_structure": 0,
    "brand_consistency": 0,
    "data_viz_quality": 0,
    "readability_at_preview_size": 0
  },
  "failing_dimensions": ["dimension_name", "..."],
  "feedback": "One paragraph summarizing what needs to change. Cite the specific dimension and the specific visual element that is failing.",
  "retry_guidance": "Concrete fix instructions for slide-producer. Example: 'Reduce body_items from 6 to 4. Current items 3 and 5 can be merged into one. Split item 6 into a new slide with layout title-body.'"
}
```

## Retry behavior

On normal FAIL: inject retry_guidance into slide-producer's next spec revision for the failing slides. The guidance must name the specific slide number, the specific failing dimension, and the exact change to the slide spec entry. Example: "Slide 3 bullet_discipline=5: reduce body_items to max 5 items of max 5 words each. Current spec has 7 items. Remove items 4 and 6 (redundant with items 3 and 5). Rewrite item 2 from 'Ensures comprehensive security monitoring across all endpoints' to 'Monitors all endpoints'."

On hard reject: do NOT generate retry_guidance. Emit the hard reject verdict immediately. Slide-producer must fix the structural issue (master application, slide split, font reduction) before any retry. Hard rejects are escalation events -- surface to master.

Max 3 normal retries per slide. After 3 fails: mark slide BLOCKED with full score history attached.

## Budget

Per-call cost: approximately $0.03-0.05 per slide PNG (Sonnet with vision). Typical sprint 8-12 slides = approximately $0.36-0.60 for judge passes alone. Three retries max per slide = approximately $0.90 upper bound. Within $5 external Stage 3 cap.
