---
type: rule
purpose: Define four mandatory conditions (value delivered, customer knows how to use it, customer validated, fully documented) that must all be met before any work item is considered done.
read_when: Before declaring any task, feature, or deliverable complete to verify all four conditions are satisfied.
tags: [definition-of-done, quality-gate, documentation, validation, completion]
scope: public
last_evaluated: 2026-06-03
---
# Definition of Done

Nothing is "done" until all four conditions are met:

1. **Value delivered** -- the work produces the intended outcome
2. **Customer knows how to use it** -- clear handoff, documentation, or walkthrough provided
3. **Customer validated** -- recipient confirmed it works for their use case
4. **Fully documented** -- setup, usage, and decisions are recorded

Applies to: code, content, workflows, client deliverables, internal tools.
If any condition is unmet, the work is "delivered" but not "done."

## Code Complete (prerequisite for Done)

Code complete is a technical bar that must pass before Done is evaluated:
- Build clean (tsc --noEmit or equivalent)
- Tests pass
- Acceptance criteria met
- Documentation complete
