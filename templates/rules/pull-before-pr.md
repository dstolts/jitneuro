---
type: rule
purpose: Require every branch to fetch and integrate the target base before opening or updating a PR, so reviewers are not handed avoidable merge conflicts.
tags: [git, pull-request, merge-conflicts, review-hygiene, owner-time]
scope: public
departments: [engineering]
read_when: Before opening a PR, updating a PR branch, or telling a reviewer the branch is ready for review.
last_evaluated: 2026-06-03
---

# Pull Before PR

Before opening a PR, updating a PR branch, or telling Owner a PR is ready for
review, the branch must be current with the target base branch.

## Rule

1. Fetch the target base branch.
2. Merge or rebase the branch onto the fetched base.
3. Resolve generated-file conflicts locally.
4. Run the branch's validation checks.
5. Push the updated branch.
6. Confirm local mergeability against the fetched base before asking for review.

The target base branch varies per repo. Some repos promote `uat -> main`, some
promote feature branches straight to `main`, and some use other workflows.
**Do not assume `main` or `uat` globally.** Look up the target base in the
target repo's own contribution / governance docs (e.g. `CONTRIBUTING.md`,
`AGENTS.md`, `governance/`, or the repo's `.claude/CLAUDE.md`).

Generic minimum check (replace `<target-base>` with the repo-specific target):

```bash
git fetch origin <target-base>
git merge origin/<target-base>   # or: git rebase origin/<target-base>
# run repo-specific validation (build / test / manifest rebuild / etc.)
git push
```

If the repo has a generated/derived file that conflicts on merge (e.g.
`INDEX.md` for jit-knowledge), resolve by regenerating from the merged
file set, not by hand-editing conflict markers.

### Repo-specific target bases

| Repo class | Target base | Reference |
|---|---|---|
| jit-knowledge | `main` (no `uat`) | `governance/PR-CHECKLIST.md` |
| Repos promoting via uat | `uat`, then `uat -> main` | that repo's CLAUDE.md / AGENTS.md |
| Repos that merge straight to main | `main` | that repo's CLAUDE.md / AGENTS.md |

This rule states the PROCESS; the per-repo branch model is documented in each
consuming repo. Do not edit this rule to encode a specific repo's branch
choice -- update the consuming repo's docs instead.

## Verification

After pushing, verify one of:

- GitHub reports the PR as mergeable against the target base.
- Local `git merge-tree --write-tree origin/<base> origin/<branch>` exits 0.
- A clean temporary worktree can merge the branch into the target base without
  conflicts.

If the base moves again before review, repeat the process. Review-ready means
mergeable now, not mergeable when the PR was first opened.

## Why

Avoidable merge conflicts consume Owner review time and hide the actual change
behind generated-file noise. The author owns keeping the branch mergeable.
