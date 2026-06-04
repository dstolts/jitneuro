---
name: Viral Brief Judge
title: Stage 0 quality gate -- scores content briefs on 8 specificity + viral-signal dimensions before any production spend.
scores:
  - awareness_specificity
  - pain_specificity
  - dream_outcome_measurability
  - emotional_signature_singular
  - hook_candidate_stop_scroll
  - trigger_anchor_independence
  - social_currency_strength
  - idea_validation_gates
pass_threshold: 7
retry_max: 3
model: haiku
reference: _patterns/llm-as-judge.md
type: playbook
purpose: MUST be invoked by the content-pipeline orchestrator after content-brief is written and before any production spend is committed; scores specificity and viral signal across 8 dimensions. Skipping means vague briefs lacking pain specificity, measurable outcomes, or stop-scroll hooks drive all downstream production without a quality checkpoint.
read_when: After content-brief is written at Stage 0 and before any production agent or spend is dispatched.
tags: [llm-as-judge, viral-brief, idea-validation, content-pipeline, quality-gate]
scope: public
last_evaluated: 2026-06-03
---

# Viral Brief Judge -- Rubric

## Purpose

Score a `content-brief-<slug>.md` against the dimensions appropriate to its declared scope. Stage 0 completes when all applicable dimensions pass at 7/10 or above. Any failure triggers an auto-retry with specific remediation feedback injected into the next generation prompt.

This judge exists because vague briefs produce vague content. The moat-building brief (2026-04-20) would have been killed at dimension (a) awareness and dimension (g) social currency before $3 in production spend, replaced with a specific survivable brief -- if this judge had existed. That is the standard being enforced.

## Scope-aware rubric (read this FIRST)

Look at the brief frontmatter `scope` field. The rubric changes by scope:

**scope=full-viral:** score all 8 dimensions (a-h) below. All must pass at 7/10. This is the original discipline.

**scope=utility-asset:** score the Utility Asset Block instead:
- `scope_triage_correctness` (0-10): did Stage 0 correctly classify this as utility vs full-viral? A "Please Subscribe" bumper or outro card IS utility; a new thought-leadership piece is NOT. If this scores below 7, the whole brief fails and Stage 0 re-runs with scope reclassification.
- `purpose_clarity` (0-10): single-sentence clear purpose, not hand-wavy
- `fixed_audience_specificity` (0-10): concrete "anyone who just finished an Owner long-form video" not "viewers"
- `duration_target_precision` (0-10): specific seconds, not vague
- `visual_direction_quality` (0-10): a thoughtful senior designer would recognize this as shippable direction; brand elements named
- `narration_craftsmanship` (0-10): NOT begging, NOT meta-referential ("here's a four-second ask" FAILS), NOT generic ("see you in the next one" FAILS unless it actually earns the line). Every line justifiable for the specific purpose.
- `brand_rules_explicit` (0-10): palette + typography + logo policy named
- `kill_list_actionable` (0-10): specific language patterns to reject, not vague "avoid AI-speak"
Pass threshold: 7+ on all; 8+ on narration_craftsmanship (that is the viral-critical dimension for utility).

**scope=derived-variant:** score:
- `scope_triage_correctness` (0-10): source is actually approved + source brief exists
- `source_pointer_valid` (0-10): path exists, source is not stale
- `target_platform_config_match` (0-10): correct platform config referenced
- `venue_constraints_explicit` (0-10): source didn't already cover these; they're additive
Pass threshold: 7+ on all.

**scope=needs-human:** score:
- `scope_triage_correctness` (0-10): request ACTUALLY requires human judgment (not a dodge). If AI could have decided but chose "needs-human" to avoid work, this fails.
- `question_specificity` (0-10): ONE specific question for Owner, not a menu
- `recommended_default_present` (0-10): AI proposes what it would pick; Owner approves or redirects in 2 seconds
Pass threshold: 8+ on scope_triage_correctness (high bar -- needs-human should be rare).

**Hard rule across all scopes:** if the judge disagrees with Stage 0's scope classification (e.g., Stage 0 said utility-asset but the judge thinks it's actually full-viral content), verdict = "fail" with failing_dimensions = ["scope_triage_correctness"] and retry_feedback = "Reclassify scope to <correct-scope> and re-produce brief."

## How to Call This Judge

You are a content quality judge. Score the following content brief against 8 dimensions. Return JSON only.

Input: full text of `content-brief-<slug>.md`

Return format:
```json
{
  "slug": "<slug>",
  "scores": {
    "awareness_specificity": <0-10>,
    "pain_specificity": <0-10>,
    "dream_outcome_measurability": <0-10>,
    "emotional_signature_singular": <0-10>,
    "hook_candidate_stop_scroll": <0-10>,
    "trigger_anchor_independence": <0-10>,
    "social_currency_strength": <0-10>,
    "idea_validation_gates": <0-10>
  },
  "verdict": "pass" | "fail",
  "failing_dimensions": ["<name>", ...],
  "retry_feedback": "<one paragraph: cite failing dimensions with specific missing elements and what would make each pass>"
}
```

Verdict is "pass" only if ALL 8 scores are >= 7. Any score below 7 = "fail".

## Dimension Rubrics

### (a) awareness_specificity -- 0-10

Evaluates: does the brief name a specific, evidenced audience at a specific Schwartz awareness level?

- **10:** Names a concrete role + situation + awareness level + evidence (e.g., "bootstrapped SaaS founder, 3-12 month runway, currently using Cursor, fear of AI clone saturation, Solution-Aware -- confirmed via 3 Reddit threads citing exact scenario")
- **7:** Names a role + situation + awareness level with light evidence
- **5:** Names an awareness level but audience description is generic ("AI developers")
- **3:** Awareness level named but no audience specificity
- **1:** No awareness level identified

Fail signal: "AI founders" or "technical audience" without role, situation, or evidence.
Pass signal: specific persona with confirmed awareness level and source citation.

### (b) pain_specificity -- 0-10

Evaluates: are the top 3 pains sourced from real data, quoted in the audience's own language?

- **10:** 3 pains each with exact quote from real source (Reddit post, review text, job posting language), source named, emotional intensity noted
- **7:** 2-3 pains with paraphrased source evidence, source type named
- **5:** Pains listed with "likely based on industry knowledge" framing
- **3:** Generic pains ("they want to be more efficient")
- **1:** No pains listed or pains are brand benefits framed as audience pain

Fail signal: "AI developers fear commoditization" with no source.
Pass signal: quoted language with source type (e.g., "r/SaaS thread: 'I shipped a product and now I have 400 files I can't read'").

### (c) dream_outcome_measurability -- 0-10

Evaluates: is the dream outcome one specific measurable transformation with a named Hormozi Value Equation lever?

- **10:** One sentence, specific metric or qualifier, Value Equation lever named (Increase Outcome / Increase Likelihood / Decrease Time / Decrease Effort), outcome cannot be achieved without the content's method
- **7:** Measurable outcome, lever implied but not named
- **5:** Specific but unmeasurable ("become a better developer")
- **3:** Vague transformation ("improve AI workflows")
- **1:** No dream outcome or goal is brand-level ("adopt our framework")

Fail signal: any outcome that applies to any AI article.
Pass signal: "Ship AI-assisted features in half the time while maintaining a codebase you can explain to any new hire in 30 minutes" + lever: Decrease Time + Decrease Effort.

### (d) emotional_signature_singular -- 0-10

Evaluates: is exactly ONE dominant emotion identified and justified with evidence from the pain map?

- **10:** One emotion from the valid set (Awe / Surprise / Anger / Joy / Usefulness), justified with explicit link to pain map language, no second emotion present
- **7:** One emotion named, brief justification
- **4:** Two emotions listed ("anger and usefulness")
- **2:** Emotion is vague ("motivating" / "empowering")
- **0:** No emotion identified

Fail signal: multiple emotions, or non-STEPPS vague descriptors.
Pass signal: "Usefulness -- reader gains a specific mental framework they can explain to their team tomorrow; sharing it signals competence to their engineering network. Derived from pain map: shame + capability debt pain resolves through practical reclaim."

### (e) hook_candidate_stop_scroll -- 0-10

Evaluates: do hook candidates each pass the 10-second stop-scroll test for the stated target audience?

- **10:** 3-5 hooks present; each labeled with mechanism (counterintuitive claim / specific number / direct address / consequence reveal); at least one counterintuitive + one direct address; none start with kill-list openings; each demonstrably targets stated audience's awareness level
- **7:** 3+ hooks, most labeled, avoid kill-list openers, test against awareness level is credible
- **5:** 2-3 hooks, no labeling, generic enough to fit any AI article
- **3:** 1-2 hooks, not differentiated
- **1:** No hooks or hooks use kill-list openers ("Let's dive in")

Fail signal: hooks that could appear on any generic AI article.
Pass signal: hooks that would make a specific target reader forward to a specific colleague.

### (f) trigger_anchor_independence -- 0-10

Evaluates: are trigger anchors short, memorable, and capable of traveling independently of the content?

- **10:** 2-3 anchors, each 2-5 words, coined or specific metaphor that carries meaning outside content context, each anchor could become a term the audience uses in conversation (e.g., "capability debt", "the 30-minute test")
- **7:** 2+ anchors, reasonably specific, some memorability
- **5:** 1-2 anchors, generic concepts ("AI quality", "code maintainability")
- **3:** Anchors listed but they are just section headers repeated
- **1:** No anchors

Fail signal: anchors are generic domain terms.
Pass signal: coined phrases that would make a reader say "oh right, the [anchor]" when they encounter the problem later.

### (g) social_currency_strength -- 0-10

Evaluates: is the social currency analysis concrete and strong enough to predict sharing behavior?

- **10:** Answers all three: what the sharer signals about themselves (specific reputation gain), who specifically benefits from receiving it (role named), whether it is share-worthy vs save-only; currency is classified as strong enough to share
- **7:** Two of three answered with specificity
- **5:** Currency is "useful for target audience" without specific signal analysis
- **3:** Social currency mentioned but analysis is tautological ("people share useful content")
- **1:** No social currency analysis, or analysis concludes content is only save-worthy

Hard fail (score = 0): analysis concludes content is save-worthy but NOT share-worthy. This is a kill signal -- content proceeds at Owner's explicit discretion only.

Fail signal: "useful for AI developers" with no sharer-reputation analysis.
Pass signal: "Sharing signals to the sharer's engineering network that they are solving the capability-debt problem before it becomes standard. CTO shares to senior engineers as a 'we're getting ahead of this' signal. Engineer shares to peers as 'this explains what I was trying to describe.' Share-worthy, not just save-worthy."

### (h) idea_validation_gates -- 0-10

Evaluates: were 5-10 variants generated, scored through all 3 gates, and ONE survivor selected with reasoning?

- **10:** 5-10 variants present; each scored 0-10 on CTR / Retention / Differentiation gates; one survivor selected with average 7+ and no single gate below 5; all rejected variants logged with the gate that killed them; survivor variant ID in frontmatter
- **7:** 5+ variants, 3 gates scored, survivor chosen, some rejected variants noted
- **5:** 3-4 variants, gates mentioned but not numerically scored
- **3:** 2-3 variants, no gate scoring
- **1:** One variant only, no validation performed

Hard fail triggers for Section (h):
- Survivor has Differentiation gate below 5: score = 0, escalation flag set
- No rejected variants logged: score -= 2 (pipeline learns from rejected variants)
- Survivor variant ID missing from frontmatter: score -= 1

Fail signal: one idea presented as validated without competing variants.
Pass signal: 7 variants scored, V3 survives (CTR:8, Retention:7, Differentiation:8), V1 killed by Differentiation gate (score 3, "any AI blog could write this"), V5 killed by CTR gate (score 4, "no scroll-stop mechanism").

## Retry Prompt Injection

When verdict is "fail", inject this feedback into the next Stage 0 generation prompt:

```
JUDGE FEEDBACK (retry [N]/3):
The brief for [slug] failed the following dimensions:

[For each failing dimension, one paragraph:]
- [dimension_name] scored [score]/10. Missing: [specific element]. To pass: [one concrete instruction]. Example of pass: [one concrete example from rubric].

Do not change passing dimensions. Fix only what is listed above.
```

## Escalation Triggers

Fire an escalation (return `escalate: true` in JSON + include `escalation_message`) when:

1. **social_currency_strength = 0** (save-only, not share-worthy): "ESCALATION: Brief for [slug] scores 0 on social currency. The idea may not be viral-capable. Evidence: [quote the social currency section]. Recommendation: [re-angle to stronger sharer-benefit frame / kill / Owner decides]. Owner decision required before Stage 1."

2. **idea_validation_gates = 0 AND differentiation gate killed the survivor**: "ESCALATION: Brief for [slug] failed differentiation gate on retry 3. No variant survived. Evidence: [highest differentiation score achieved]. Recommendation: source proprietary data or case study that only Just In Time AI can cite, then re-run Stage 0 Section 8. Owner decision required."

3. **Any dimension fails on retry 3**: "ESCALATION: Brief for [slug] failed [dimension] gate on retry 3. Evidence: [score history across 3 retries]. Recommendation: [specific fix or Owner decision needed]. Pipeline halted at Stage 0."

Escalation goes to Owner as a 5-minute decision: re-angle, kill, or source additional data. Do NOT advance to Stage 1 with an escalated brief.

## Cost Note

This judge runs on Haiku (~$0.01-0.02 per call). At 3 retries max, Stage 0 judge cost ceiling is ~$0.06. This is the cheapest point in the pipeline to catch a bad brief. The alternative is catching it after Stage 3 generation (~$3+ in sunk production spend).
