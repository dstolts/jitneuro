---
name: Image Judge
scores:
  - beat_alignment
  - no_text_artifacts
  - no_pil_placeholder
  - palette_consistency
  - platform_safety
pass_threshold:
  beat_alignment: 8
  no_pil_placeholder: 10
  default: 7
retry_max: 3
model: sonnet-vision
judge_pattern_ref: _patterns/llm-as-judge.md
type: playbook
purpose: MUST be invoked by the content-pipeline orchestrator after image-producer completes Stage 3 still images; PIL placeholder is a hard reject, beat alignment and platform safety are required. Skipping means placeholder images or off-beat visuals advance to compose and ship in the final video.
read_when: After image-producer returns Stage 3 still images and before compose-producer begins Stage 4 assembly.
tags: [llm-as-judge, vlm, image-generation, content-pipeline, quality-gate]
scope: public
last_evaluated: 2026-06-03
---

# Image Judge (VLM)

## Purpose

Score each Stage 3 still image produced by image-generator before it advances to compose. This judge uses vision (VLM -- Claude Sonnet with vision) to examine the actual pixel content of each .png file. It catches PIL placeholder fallbacks, concept mismatches, text artifacts, and palette drift before they enter the compose pipeline. PIL placeholder detection is a hard-reject that escalates to Owner and dispatches /learn.

## Model note

This judge requires vision capability (Claude Sonnet with vision, NOT Haiku). Haiku does not support vision in all configurations. Use sonnet with vision for all image evaluations.

## Input contract per beat

You receive for each beat image:
- The .png file path
- The narration line for that beat (exact text from storyboard)
- The visual_description from the storyboard beat
- The beat number
- The sprint_id

## Scoring rubric (0-10 per dimension)

### a. beat_alignment (threshold 8+)
Does the image specifically illustrate the narration line for this beat, not just the overall topic?

Specificity test (from `_patterns/visuals-align-narration.md`):
- 9-10: Image shows the specific subject + action + visual element that the narration describes. Example: narration "Someone just paid twenty-nine dollars for your AI product" -- image shows a checkout/pricing UI with a $29 figure prominently visible.
- 7-8: Image shows the correct scenario but misses one specific detail.
- 5-6: Image is thematically on-topic but does not illustrate the specific narration words (a generic SaaS dashboard when the narration describes a specific pricing comparison).
- 3-4: Image is related to the broader topic but not to this beat.
- 0-2: Image is completely unrelated to the narration.

For each beat, state: "Narration: [excerpt]. Image shows: [your description of what is in the image]. Alignment verdict: [specific/thematic/unrelated]."

### b. no_text_artifacts
Does the image contain garbled, unreadable, or nonsensical text baked into the scene?

Score:
- 10: No text in image at all (correct -- text comes from FFmpeg overlay in Stage 4).
- 8-9: Intentional, readable text (e.g., a UI screenshot showing a price "29.00") that supports the narration.
- 4-6: Partial text visible, some characters garbled.
- 0-3: AI hallucinated text (random characters, fake words, nonsense strings baked into signs/screens/labels).

Note: Nano Banana 2 can hallucinate fake UI text. If you see a UI screenshot element with unreadable or nonsensical characters, flag it. The prompt instructed "no text artifacts" -- if present, it is a model failure.

### c. no_pil_placeholder (threshold 10 -- hard reject)
Is this image a PIL-generated placeholder?

PIL placeholder pattern (from reference_nano_banana_2_api.md): a solid single-color background (often gray, white, or black) with a single short text element rendered in a sans-serif font (e.g., the number "5", a word like "beat", or a short phrase). No photographic content, no depth, no scene.

Detection heuristic:
- If image is a flat solid-color fill with no photographic depth: POTENTIAL PIL. Check for text element.
- If image contains a single text string on a flat background with no other visual content: DEFINITIVE PIL PLACEHOLDER.
- Score 10 = no PIL detected (correct image). Score 0 = PIL placeholder confirmed.

Hard reject rule: If no_pil_placeholder score is 0 (PIL detected), return verdict: "hard_reject_pil" immediately. Do not score remaining dimensions. This is an escalation event:
1. Return STATUS: BLOCKED to master with: "PIL placeholder detected on beat {N}. Nano Banana 2 model regression -- image-generator fell back to PIL. Dispatch /learn."
2. Image-generator must not retry with the same broken configuration -- it must first verify that the model ID is gemini-2.5-flash-image (not imagen-*).

### d. palette_consistency
Does the image use the expected color palette?
Expected: deep navy #0a1628 background tones + teal #2dd4bf accent elements, cinematic depth, professional lighting.

Score:
- 9-10: Palette matches closely. Deep dark backgrounds, teal or cool accent tones.
- 7-8: Palette is close but one element is off (e.g., warm orange accent instead of teal).
- 5-6: Palette is inconsistent but image is not jarring.
- 3-4: Palette is wrong (bright white backgrounds, garish colors, no cinematic quality).
- 0-2: Flat, bright, zero cinematic quality.

Note: palette is a style consistency concern for the assembled video. A single off-palette image creates a jarring cut. Flag palette failures even at 7+ so compose-producer can apply color grading.

### e. platform_safety
Is the image safe for all target platforms (LinkedIn, YouTube, X, Thinkers360)?

Check for:
- Copyright-bait: recognizable logos, faces of real named individuals (not the avatar), branded product screenshots that could create IP issues. Deduct 3 per instance.
- Inappropriate content: not applicable for this content type, but score 10 if no concerns.
- Stock-photo feel (generic, could be anyone's content): deduct 1 (reduces viral quality, noted but not blocking).

## Pass/fail determination

Pass: beat_alignment >= 8, no_pil_placeholder = 10, AND all other dimensions >= 7.
Fail: any dimension below threshold.
Hard reject (PIL): verdict is "hard_reject_pil" regardless of other scores. Does not count as a normal retry -- requires image-generator to fix its model configuration first.

## Output format (per beat)

{
  "beat": N,
  "verdict": "pass" or "fail" or "hard_reject_pil",
  "scores": {
    "beat_alignment": X,
    "no_text_artifacts": X,
    "no_pil_placeholder": X,
    "palette_consistency": X,
    "platform_safety": X
  },
  "beat_alignment_detail": "Narration: '...'. Image shows: '...'. Alignment: specific/thematic/unrelated.",
  "text_artifact_detail": "None detected" or "Garbled text in lower-right UI element",
  "retry_guidance": "Sharpen prompt with: [specific visual suggestion tied to narration words]"
}

## Retry behavior

On normal FAIL: inject retry_guidance into the image-generator's next prompt. The guidance must name the specific narration line and what scene change would improve alignment. Example: "Beat 4 narration is 'Your competitor launched a nine-dollar clone in 48 hours.' Retry with: 'Side-by-side product landing pages on two browser tabs, left tab shows $29 price in large text with established brand color, right tab shows $9 in bright red teal -- direct pricing comparison view, developer POV, deep navy background.'"

On hard_reject_pil: do NOT generate retry guidance. Return the escalation immediately. Image-generator must fix model configuration before any retry.

Max 3 normal retries per beat. After 3 fails: mark beat BLOCKED with full score history.

## Budget

Per-call cost: approximately $0.02-0.05 per image (Sonnet with vision). Typical sprint 8-12 beats = approximately $0.24-0.60 for judge passes alone. Three retries max per beat on average 2 fails = approximately $0.50 additional. Total judge budget: approximately $1.00 within the $5 external cap.
