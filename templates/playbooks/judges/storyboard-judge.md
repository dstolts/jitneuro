---
name: Storyboard Judge
scores:
  - beat_count_appropriate
  - beat_completeness
  - framing_anchoring
  - opening_structure
  - visual_specificity
  - no_jump_cuts
pass_threshold:
  default: 7
  visual_specificity: 8
retry_max: 3
model: haiku
judge_pattern_ref: _patterns/llm-as-judge.md
type: playbook
purpose: MUST be invoked by the content-pipeline orchestrator after storyboard-writer completes Stage 2 and before audio, image, or avatar production begins; visual specificity has an elevated threshold (8+). Skipping means vague or jump-cut-prone storyboards drive all downstream production assets, with no way to catch the structural flaw until everything is already rendered.
read_when: After storyboard-writer finishes Stage 2 outline and before any audio, image, or avatar production is dispatched.
tags: [llm-as-judge, storyboard, visual-specificity, content-pipeline, quality-gate]
scope: public
last_evaluated: 2026-06-03
---

# Storyboard Judge

## Purpose

Score the Stage 2 outline.md deliverable before it advances to Stage 3 generation. A storyboard that passes this judge is ready to drive image-generator, voice-producer, and avatar-producer. A storyboard that fails here prevents wasted Stage 3 spend on misaligned beats.

## Input contract

You receive:
- The outline.md file (judge-passed from Stage 2 content-writer output)
- The approved framing.md (Stage 1 deliverable -- contains framework name, element labels, opening structure sentences)
- The format string: video-short / video-long / written / carousel

## Scoring rubric (0-10 per dimension)

### a. beat_count_appropriate
Does the beat count fit the format?
- video-short: 6-9 beats = 10. Outside range by 1 = 7. Outside by 2+ = 3.
- video-long: 12-20 beats = 10. Outside range by 1 = 7. Outside by 2+ = 3.
- written: sections must be present and match the outline template structure = score based on structure completeness.
- carousel: 6-8 slides = 10. Outside by 1 = 7. Outside by 2+ = 3.

### b. beat_completeness
Does every beat contain all required fields?
Required fields for video beats: beat_number, duration_sec, narration, visual_description, element_label_reference, transition_to_next.
Required fields for written sections: section_number, section_title, section_purpose, element_label_reference.
Score: 10 if 100% of beats have all fields. Deduct 1 point per beat missing one or more required fields. Score of 5 = half the beats are incomplete.

### c. framing_anchoring
Does each beat's element_label_reference map to a real element label from framing.md?
Count beats with valid element_label_reference (matching a label in framing.md) vs total beats.
10 = all beats anchored. 7 = 80%+ anchored. 5 = 60%+ anchored. Below 5 = less than 60%.
Also: is the framework name present or implicit in the storyboard structure? If the framework name from framing.md is absent from all beats, deduct 2.

### d. opening_structure
Does beat 1 (or the first written section) implement Hook + Promise + Audience + Payoff?
Score the ACTUAL narration text against these four elements:
- Hook present (stop-scroll opener that creates curiosity or stakes): +2.5
- Promise explicit (what the viewer/reader will get): +2.5
- Audience named or strongly implied (who this is for): +2.5
- Payoff signaled (what changes after they consume this): +2.5
10 = all four present in beat 1 narration. Partial credit per element.

### e. visual_specificity (viral-critical -- threshold 8+)
For each beat's visual_description: is it specific enough for image-generator to produce a beat-aligned still?

Specificity test per beat (see `_patterns/visuals-align-narration.md`):
- Specific (8-10): names a concrete subject + action + specific visual element. Example: "Two browser windows side by side, $29 on left, $9 in teal on right, developer leaning back looking shocked."
- Thematic (4-6): names a category or topic but no specific scene. Example: "An AI product dashboard." Image-generator cannot align this to the narration.
- Empty/missing (0-2): no meaningful description.

Score: average of per-beat specificity scores across all beats. Because viral quality depends on beat-by-beat visual alignment, this dimension requires 8+ to pass (not 7+).

For each beat scoring below 7, output the beat number + current description + a rewrite suggestion the content-writer can implement.

### f. no_jump_cuts
Check each consecutive beat pair for narration-visual continuity. A jump cut occurs when the narration of beat N+1 describes a completely different scenario than the visual_description of beat N without a transition.
10 = no jump cuts. Deduct 1.5 per jump-cut pair identified.
For each jump cut found: output "Beat N to N+1: [narration excerpt from N] leads into [visual_description from N+1] -- visual jump."

## Pass/fail determination

Pass: all dimensions score 7+ AND visual_specificity scores 8+.
Fail: any dimension below threshold.

## Output format

Return a JSON object. All fields are required:
{
  "verdict": "pass" or "fail",
  "scores": {
    "beat_count_appropriate": X,
    "beat_completeness": X,
    "framing_anchoring": X,
    "opening_structure": X,
    "visual_specificity": X,
    "no_jump_cuts": X
  },
  "lowest_dimension": "name of lowest-scoring dimension",
  "failing_dimensions": ["dimension_a", "dimension_b"],
  "retry_feedback": "<one paragraph: summarize all failing dimensions with specific beat-level fixes>",
  "retry_guidance": [
    "Beat 4 visual_description is thematic -- rewrite: [specific suggestion]",
    "Beat 1 narration missing Payoff element -- add: [specific suggestion]"
  ],
  "pass_threshold_met": true or false
}

failing_dimensions: list ALL dimension names whose score is below threshold (7 for most; 8 for visual_specificity). Must be non-empty when verdict is "fail". The orchestrator uses this field to build the retry prompt.
retry_feedback: single-paragraph summary of ALL failing dimensions. Same content as retry_guidance but as a single string rather than a list. The orchestrator injects this into the persona's next-attempt user_input.
retry_guidance: per-item list with beat-level specifics. Use this format: "Beat N [dimension]: [current state] -- fix: [specific rewrite suggestion]".

## Retry behavior

On FAIL: provide retry_guidance with specific beat numbers and one-line rewrite suggestions. Do not just say "improve the visual descriptions" -- say "Beat 4: change 'a laptop in use' to 'close-up of developer hands pausing mid-type, staring at a 500 Internal Server Error message on a dark terminal window.'"

Content-writer fixes the flagged beats and resubmits. Max 3 retries per this judge instance.

After 3 FAIL verdicts: escalate to master with full score history and guidance. Do not auto-approve on 4th attempt.

## Budget

Per-call cost: approximately $0.02 (Haiku, evaluating outline.md which is typically 600-1500 tokens). Three retries max per sprint stage = approximately $0.06 budget. Within $5 external cap.

---

## Dimension g (appended 2026-04-21): visual_type_appropriate_for_beat

**Threshold: 8+**

For a sample of 3-5 beats (select beat 1, the final beat, and 1-3 beats from the middle), does each beat's visual_type match the narration content per the content-writer Visual Type Selection rules?

Selection rules summary (canonical source: content-writer AGENTS.md, "Visual Type Selection" section):
  - still: narration is emotion / story / scene / metaphor / human moment
  - slide: narration is list / steps / framework / stats / comparison / data claim / key definition
  - avatar: narration is first-person claim / direct call-out / opinion / direct address
  - b-roll: narration is ambient context / transition / "as you can see"
  - chart: narration is trend data / before-after measurement / growth or decline / benchmark comparison

Score per sampled beat:
  - 10: visual_type exactly matches narration category.
  - 7-8: visual_type is defensible but a better choice exists.
  - 4-6: visual_type is a mismatch (e.g., numbered-list narration assigned still instead of slide).
  - 0-3: visual_type is completely wrong (e.g., chart assigned to an emotion beat).

Aggregate dimension score: average of sampled beat scores. Pass threshold: 8+.

For each sampled beat scoring below 7, output in retry_guidance:
- Beat number
- Current visual_type value
- Narration excerpt (first 10 words)
- Mismatch description
- Recommended fix (e.g., "Change visual_type from still to slide")

Special case -- carousel format: ALL beats must be visual_type=slide. Any non-slide beat in a carousel scores 0 for that sample beat. Cite: "Carousel beats must all be visual_type=slide."

This dimension was added to validate slide-producer integration (2026-04-21). Beats routed to the wrong Stage 3 generator waste budget and produce mismatched assets.
