---
type: rule
purpose: Require a gap-analysis pass before delivering any code change to surface missed edge cases, unactivated personas, or wrong assumptions, with the result surfaced to the reviewer.
read_when: Before delivering any response that includes code changes, architecture decisions, or cross-repo edits -- skipping allows undetected edge cases and regressions to ship.
tags: [gap-analysis, code-review, edge-cases, quality, pre-delivery]
scope: public
last_evaluated: 2026-06-03
---
# Gap Analysis

Before delivering any response with code, apply extra thought time. When gap analysis runs, surface it so the reviewer knows it happened.

## When to Run
- Any response that includes code changes (new files, edits, fixes)
- Architecture decisions or design proposals
- Cross-repo changes
- Skip for: research, questions, documentation-only responses

## What to Check
- What did I miss? What edge case? What breaks with unexpected input?
- What would a persona I did not activate have flagged?
- What assumption am I making that might be wrong?
- Does this change break anything else in the codebase?

## Visibility

When gap analysis finds something, surface it BEFORE presenting the code:

```
[Gap Analysis] Checked edge cases, persona coverage, assumptions.
Found: null handling missing on line 42 -- added guard clause.
```

When gap analysis finds nothing noteworthy:

```
[Gap Analysis] Checked: edge cases, null paths, auth boundaries. Clean.
```

Keep it to one line unless a finding changes the approach. The reviewer should see that it happened, not read a report.
