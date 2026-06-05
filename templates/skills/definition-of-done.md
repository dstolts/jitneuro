---
type: skill
purpose: Defines the four conditions (value delivered, customer knows, customer validated, fully documented) that must all be met before any task is marked complete. Read this before marking a story, PR, or deliverable done.
tags: [skill, definition-of-done, quality, acceptance-criteria, delivery]
scope: public
departments: [all]
read_when: Before marking any task, story, PR, or deliverable complete to verify all four conditions are met.
last_evaluated: 2026-06-03
---

# Definition of Done

Nothing is done until all four conditions are met. "Delivered" and "done" are not the same thing.

## When to Apply

Before marking any task, story, or deliverable complete -- code, content, workflow, client deliverable, or internal tool.

## Four Conditions

1. **Value delivered** -- the work produces the intended outcome. The feature works. The content is published. The workflow runs. Not "I submitted it" -- "it works."
2. **Customer knows how to use it** -- a clear handoff, documentation, or walkthrough was provided. If the recipient does not know the feature exists or how to use it, the work is not done.
3. **Customer validated** -- the recipient confirmed it works for their use case. Not "I think they'll like it" -- explicit confirmation.
4. **Fully documented** -- setup, usage, and key decisions are recorded. Future maintainers can understand what was built and why.

## Code Complete (Prerequisite for Done)

Code must meet this bar before the four conditions are evaluated:
- Build clean (tsc --noEmit or language equivalent passes with zero errors)
- Tests pass
- Acceptance criteria from the story are met
- Documentation complete (inline comments, README update if needed)

## What to Avoid

- Calling a PR merged "done" -- it must be deployed and verified in the target environment
- Skipping the handoff because "they'll figure it out"
- Marking done when the recipient has not confirmed it solves their problem
- Treating "I wrote the code" as the end state

## Distinction: Delivered vs Done

Delivered: all four conditions have work in progress but at least one is unmet.
Done: all four conditions fully satisfied.

Report accurately. If work is delivered but not done, say so.

## Integration

Used by: all engineering and content roles -- sys-architect, sys-backend, sys-frontend, sys-qa, sys-devops, content-writer-*, assessment-generator, security-developer, mssp-engineer
