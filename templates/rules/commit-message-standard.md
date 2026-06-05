---
type: rule
purpose: Define a full commit-message and PR-description template using Conventional Commits so every merge to main carries sufficient context for audit, risk assessment, and follow-up tracking.
read_when: Before writing a commit message or opening a pull request to ensure the subject line, body, and test plan meet the required format.
tags: [git, commit-messages, pull-request, conventional-commits, documentation]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---
# Commit Message + PR Description Standard

Every commit message destined for a PR is also the PR subject after squash-merge. GitHub auto-fills the PR title from the commit subject; reviewers read the commit body when they open the PR. Thin commit = thin PR = thin merge audit trail. Write the commit well, the PR inherits 80% for free.

This rule governs BOTH commit messages and PR descriptions. They are the same artifact at different points in time.

## The standard (full template)

Apply to any commit destined for a PR (feat, fix, refactor, test infra, docs that span repos). Trivial commits (typo, formatting, WIP-to-be-squashed) may use subject-only.

```
<type>(<scope>): <subject -- describe the CHANGE, not the process>

## What
<1-3 sentences on what this adds / changes / removes>

## Why
<driver context -- problem solved, incident link, spec link, Owner directive>

## Risk
<blast radius, prod impact, dep additions, migration requirements>

## Test plan
<actionable checkboxes -- method specified per testing-method.md>

## Follow-ups
<what is queued to land after this -- so nothing escapes post-merge>

## Related
<issue numbers, RCA paths, other PRs, companion changes in other repos>
```

Sections that do not apply may be omitted, but the section order above is canonical.

## Subject line rules

- <=72 chars (hard). Truncates cleanly in `git log --oneline`, GitHub lists, terminals.
- Conventional Commits prefix: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `ci`, `perf`, `style`, `revert`
- Scope in parens: the subsystem touched (`feat(cors)`, `fix(scanner)`, `test(e2e)`). Omit if repo-wide.
- Imperative mood: "add CORS preflight handler" NOT "added CORS preflight handler" NOT "adding CORS preflight handler"
- Describes the CHANGE, not the process: "enforce CORS preflight" NOT "update server.ts"
- No trailing period.
- No Claude / AI attribution unless explicitly requested.

## Stacked-PR signal belongs in the subject

If a PR depends on another PR being merged first, the subject MUST signal it. Buried merge-order requirements get missed.

Good: `feat(e2e): critical-paths foundation [STACKED on #16]`
Bad: `feat(e2e): critical-paths foundation` with the dependency buried in the body.

After the upstream PR merges, strip the bracket before re-titling.

## Body rules

- Wrap at 100 chars.
- WHY is the most important section. The diff shows the WHAT; the body explains the WHY.
- Risk section is upfront. Reviewers need to know in 5 seconds whether this is "skim" or "deep review." Examples: "Zero production code changes," "Touches auth middleware -- needs security review," "Adds 3 new dependencies."
- Test plan uses actionable checkboxes with method specified (per testing-method.md):
  - `- [x] API returns 200 (method: curl to live uat endpoint)`
  - `- [x] Selectors stable (method: manual ChallengeForm.tsx diff)`
  - NOT: `- [x] Tested locally`
- Follow-ups are explicit so post-merge work does not escape. Link issue numbers.
- Related section lists cross-repo dependencies. Any change in another repo that must land together gets a bullet.

## When subject-only is OK

- Typo / comment-only edits
- CI / lint / formatting fixes with no behavior change
- Pre-squash WIP commits (will be rewritten by squash-merge)

## Anti-patterns

- Subject describes the process: "Updated X" or "Added tests for Y" -- say what the change DOES
- "Fixes bug" / "Quick fix" / "Small change" -- say what bug, what fix, what change
- Merge-order requirement buried in the body -- put it in the subject with `[STACKED on #N]`
- Test plan reads "Tested locally" -- useless; state the method
- Follow-ups listed as prose instead of checkboxes -- they escape tracking
- Description restates the diff -- diff is visible in the PR; body is for context the diff does not show

## PR title = squash commit subject

GitHub's default squash-merge takes the PR title as the commit subject on main. The subject rules above are BINDING on the PR title. If the PR title is thin, the main branch's history is thin.

Before opening a PR: re-read the commit subject. If it would not pass this rule's subject line checks, amend the commit first.

## Origin

2026-04-21 -- Owner feedback during AI-SEO CORS incident recovery: commit messages were thin. Squash-merge pattern means commit message IS the PR subject on main. Fixing the commit message fixes the PR for free.

Reinforces existing rules: `testing-method.md` (test plan checkboxes specify method), `file-references.md` (always include clickable URL in the same bullet).
