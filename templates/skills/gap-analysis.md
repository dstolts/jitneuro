---
type: skill
purpose: Pre-delivery self-check that surfaces missed edge cases, unactivated persona blindspots, and wrong assumptions before presenting code to Owner. Read this when an agent is about to deliver a code change or architecture proposal.
tags: [skill, gap-analysis, quality, pre-delivery, code-review]
scope: public
read_when: Before delivering any code change or architecture proposal to Owner to surface missed edge cases and blindspots.
last_evaluated: 2026-06-03
---

# Gap Analysis

Before delivering any code response, apply deliberate extra thought to find what was missed. Surface findings visibly so the Owner knows the check ran.

## When to Apply

- Any response that includes code changes (new files, edits, fixes)
- Architecture decisions or design proposals
- Cross-repo changes
- Skip for: research, questions, documentation-only responses

## Core Process

1. After drafting the solution but before presenting it, pause and run the checklist:
   - What edge case did I not handle? What breaks with null, empty, or unexpected input?
   - What would a persona I did not activate have flagged? (e.g., security engineer, SRE)
   - What assumption am I making that might be wrong?
   - Does this change break anything else in the codebase?
2. If a gap is found: fix it inline, then note it in the gap analysis output.
3. Surface the result before the code -- one line if clean, one line per finding if issues were caught.

## Output Format

When findings exist:
```
[Gap Analysis] Checked edge cases, persona coverage, assumptions.
Found: null handling missing on line 42 -- added guard clause.
```

When clean:
```
[Gap Analysis] Checked: edge cases, null paths, auth boundaries. Clean.
```

## What to Avoid

- Skipping gap analysis on "simple" fixes -- most production bugs hide in simple code
- Running gap analysis as a mental note without surfacing it -- visibility is required
- Writing a full report -- one line per finding maximum
- Treating gap analysis as a code review (it is a pre-delivery self-check, not a review)

## Integration

Used by: sys-architect, sys-backend, sys-frontend, sys-security, sys-qa, sys-code-reviewer, security-developer, mssp-engineer
