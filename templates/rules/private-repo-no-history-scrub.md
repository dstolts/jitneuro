---
type: rule
purpose: BINDING for every agent handling PII or sensitive content in any private repo -- a HEAD-only fix (git rm or move-to-proper-home PR) is the correct ceiling; proposing git filter-repo history rewrites without a concrete publicization, breach, or regulator trigger wastes force-push overhead, breaks all existing clones, and buys zero practical security benefit for repos that will never go public.
trigger: any agent discovering PII, sensitive content, or a security-adjacent finding in a private repo and considering what remediation to propose
tags: [git, security, pii, private-repo, history-rewrite]
scope: public
read_when: When discovering PII or sensitive content in a private repo and evaluating what remediation to propose.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_private_repo_no_history_scrub.md) -- Knowledge session 2026-06-01
---

# Private Repo -- No History Scrub Without Concrete Trigger

## Rule

When PII or sensitive content lands in a PRIVATE repo, removing it
from HEAD is the correct ceiling. Either:

- A PR that `git rm`s the file from the deploying branch, OR
- A move-to-proper-home migration (e.g., PII -> dedicated customers repo)

Do NOT propose `git filter-repo` history rewrites unless one of these concrete
triggers is present:

1. The repo is explicitly planned to go public (Owner-stated, not speculative).
2. An actual breach or regulator request demands history scrub.
3. A non-portfolio collaborator gained access who should not have had it.

## Why

Force-push storms carry real cost and risk:

- A typical 101-commit rewrite + 28-branch force-push is the minimum, not an edge case.
- Every existing clone (Owner's local, developer's, any CI runner) must `git fetch`
  and `git reset --hard` to realign -- silent breakage if any clone is missed.
- Branch protection on protected branches must be temporarily toggled.
- In-flight PRs can die or enter unresolvable conflict states.

This cost buys defense-in-depth against a future public-ization that has no concrete
plan. For a repo that "will never go public," it buys nothing.

## What violates this rule

- Offering history scrub as an option without confirming a concrete trigger.
- Re-offering filter-repo after Owner picked a HEAD-only fix, as a "close the loop" step.
- Assuming speculative public-ization risk justifies a live repo rewrite.

## Origin

2026-05-23: a private-repo PII handling case. Owner chose a move-to-proper-home HEAD fix. I
later re-offered filter-repo as a cleanup option; Owner approved. Owner then questioned
why it was needed at all given the repo will never go public. Scrub was real cost for zero
practical benefit. Rule: HEAD fix is sufficient for private repos; ask before escalating.
