---
type: pattern
purpose: Any content agent or content-role orchestrator MUST consult this before drafting or publishing customer-facing copy -- firing at session start for any content role and at the monthly cadence audit -- because skipping it causes individual content roles to drift from the canonical voice, producing inconsistent tone across publications that undermines brand recognition and erodes audience trust over time.
read_when: At session start for any content role, and before any monthly brand-voice audit or cadence review.
tags: [brand-voice, content, cmo, monthly-audit, llm-as-judge]
scope: public
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Brand Voice Pattern

**Used by:** CMO (owns), Brand Voice & Moat Mgr (maintains), all content roles (consume).
**Purpose:** Single source of truth for brand voice. All content roles load this file
at boot. Updates flow once from the source; all writers comply automatically.

---

## Ownership Model

| Role | Responsibility |
|------|---------------|
| CMO | Approves BRAND-VOICE.md changes. Signs off on monthly audit results. |
| Brand Voice & Moat Mgr | Authors + maintains BRAND-VOICE.md. Runs monthly LLM-as-judge audit. Files violations as [BRAND-VOICE] issues. |
| All content roles | Load BRAND-VOICE.md at task start. Reference it for tone, vocabulary, moat words, banned phrases. |
| CCO | Reviews BRAND-VOICE.md quarterly for compliance and legal exposure. |

---

## File Location and Format

Canonical path: `<repo-root>/brand/BRAND-VOICE.md`

Target size: 1,000-2,000 tokens. Above 2K, the Brand Voice & Moat Mgr must
compress -- voice rules that require 3 paragraphs to explain are not rules,
they are guidelines. Convert to bullet + example pairs.

Required sections in BRAND-VOICE.md:

1. **Voice in one sentence** -- the governing constraint all other rules serve.
2. **Tone spectrum** -- where we sit on formal/casual, direct/exploratory, etc.
   Expressed as "sounds like X, never sounds like Y" pairs.
3. **Core vocabulary** -- 10-20 words/phrases that are on-brand. With usage examples.
4. **Banned phrases** -- words/patterns that violate brand identity or moat.
   One line each: banned phrase + why + acceptable alternative.
5. **Moat words** -- proprietary terminology that differentiates us. Never diluted
   by defining them the same way a competitor would.
6. **Format defaults** -- sentence length, paragraph length, header style, CTA pattern.
7. **Audience voice match** -- how tone shifts for technical vs executive vs general audiences.

---

## Content Role Boot Sequence

Every content-producing role includes this step before generating output:

```
1. Read BRAND-VOICE.md (full file -- it is small by design).
2. If artifact type matches an audience segment, load the tone-match for that segment.
3. Generate artifact.
4. Self-check: does this output pass the "sounds like X, never sounds like Y" test?
5. Submit for L4 CCO review (which includes brand-voice compliance).
```

Roles do not need to be told to load the file on each task. It is a standing
pre-condition, not a per-task instruction.

---

## Update Flow

Changes to BRAND-VOICE.md follow this path:

1. Brand Voice & Moat Mgr proposes a change in a PR with before/after diff.
2. CMO approves (YELLOW zone action -- executes after approval).
3. Merge. All future content roles pick up the new version automatically.
4. Brand Voice & Moat Mgr posts a change summary to the content team channel
   so in-flight drafts can be checked.

Changes do NOT require per-role notification. Each role reads the file fresh at task start.

---

## Monthly Audit

Brand Voice & Moat Mgr runs a monthly LLM-as-judge audit:

- Selects 10-15 published artifacts from the prior month (mix of types).
- Runs each through an LLM scorer with BRAND-VOICE.md as the rubric.
- Score below 85: file a [BRAND-VOICE] issue with the artifact path + failing criterion.
- Score above 85: log as passing.
- Presents audit summary to CMO within 3 days of month end.

---

## Cross-References

- `_patterns/validation-gates.md` -- L4 review layer includes brand-voice compliance
- `_patterns/producer-validator-pattern.md` -- LLM-produced drafts validated against BRAND-VOICE.md
- `_patterns/autonomous-execution-with-validators.md` -- brand-voice check runs continuously without human in the loop
