---
type: rule
purpose: Require every code-generation prompt that modifies an existing application to include a HARD RULE 0 regression guard with an explicit inventory of preserved components.
read_when: Before authoring or reviewing any prompt sent to a code-generation tool that will modify an existing application.
tags: [code-generation, regression-guard, ai-tools, preservation, quality-gate]
scope: public
last_evaluated: 2026-06-03
---
# Code-Gen Regression Guard (HARD RULE #0 Pattern)

When handing a prompt to ANY code-generation tool (AI coding assistant, code-gen agent, etc.)
that will modify an existing application, the prompt MUST include a regression guard at the
very top. Without it, the tool will routinely rewrite, rename, or "modernize" unrelated
sections under the banner of "improving the codebase."

## The Pattern

Every such prompt starts with a section titled:

```
## HARD RULE #0 -- PRESERVE EXISTING <APP> (REGRESSION GUARD)
```

The section content MUST include:

1. **A preservation statement** -- "Do not remove, rename, reorder, or re-label any of the existing sections / files / components / routes / API endpoints listed below."
2. **An explicit inventory** -- every existing section / nav item / route / component / file / endpoint that must be preserved, listed by NAME. Cite the file where it lives.
3. **Additive-only directive** -- "Your only change to `<entry-point-file>` is additive. Do not refactor."
4. **Stop-and-report clause** -- "If you discover that adding the new feature requires rewriting existing logic in a way that would change existing behavior, STOP and report. Do not proceed with a rewrite."
5. **PR requirements** -- "Your PR description must include a 'Preserved' checklist listing every item from the inventory as unchanged. Include a diff-stat line showing no existing file was modified except the explicit additive edits listed in this prompt."
6. **Pre-merge acceptance gate** -- "The requester will manually verify every existing section still renders and works. A regression on any existing component BLOCKS the PR merge, regardless of how well the new feature itself works."

## Why This Is Necessary

Code-generation tools optimize for "shiny code." When given a prompt like "add feature X to this app," they often:

- Rename sections because the new naming is "more consistent"
- Refactor routing because the new pattern is "cleaner"
- Upgrade dependencies because newer versions are "better"
- Restructure files because it "matches modern conventions"
- Delete code marked "unused" without verifying it is actually unused

Each of those decisions may be defensible in isolation but collectively destroys the user's
working surface area. Context (what clicked where, which tab held which data, which credential
lived in which file) gets invalidated without warning.

## When to Apply

- Any AI code-gen prompt that inserts a new feature into an existing app
- Any migration / upgrade prompt that touches shared routing, layout, or auth
- Any refactor prompt that claims to be scoped to one feature
- Any prompt that contains "clean up" or "modernize" verbs alongside a feature request

## When This Is NOT Needed

- Greenfield scaffold (no existing app to protect)
- Pure backend-only endpoint additions (prompts that only add routes, touch no UI)
- Pure documentation / spec writing
- Internal tooling builds where regression is acceptable

## Verification on Return

When the generator opens its PR:

1. Read the PR description -- confirm the "Preserved" checklist is present and matches the prompt's inventory
2. Open the PR diff -- confirm no existing-file modifications outside the explicit additive edits
3. Check out the branch locally and manually verify every preserved section still works
4. On ANY regression: reject, cite the specific regression with file + line, ask generator to redo the PR preserving existing state

## Anti-Patterns to Reject

- Trusting the generator's self-report that "no existing sections were affected" without verification
- Accepting a PR that modifies router / layout files beyond the explicit additive edit specified in the prompt
- Merging under time pressure without the pre-merge acceptance gate
- Issuing a "fix regression" follow-up prompt when the better move is to reject + require rebuild from the preservation inventory
