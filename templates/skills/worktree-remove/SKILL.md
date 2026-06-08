---
type: skill
name: worktree-remove
status: canonical
purpose: Safely remove a git worktree after its branch's work is retired. Enforces lifecycle discipline -- refuses to remove a worktree with unpushed commits, open PR, or dirty working tree. The cleanup half of /worktree-new; together they implement the rules/worktree-discipline.md lifecycle ("created with branch; removed when branch retires").
tags: [slash-command, git, worktrees, lifecycle, cleanup, jit-knowledge, branch-discipline]
scope: public
departments: [engineering]
authored_at: WIP-Drafts/skills/worktree-remove.md
origin_date: 2026-05-28
origin_event: PR #240 (/worktree-new) open questions item #4 -- "Should /worktree-remove <repo> <branch> be a sibling skill in the same PR? Lean: separate PR; cleanup discipline is enough scope on its own." Authored as that separate follow-up PR. Also addresses rules/worktree-discipline.md "Worktree lifecycle is mandatory ... created with branch, removed when branch retires" + the related feedback_worktree_lifecycle_create_use_cleanup memory.
graduation_target: jit-knowledge/skills/worktree-remove/SKILL.md
related_skills:
  - skills/worktree-new/SKILL.md (sibling: create)
  - rules/worktree-discipline.md (the rule this skill's cleanup half implements)
read_when: When retiring a branch and removing its worktree after the PR has merged or the work is abandoned.
last_evaluated: 2026-06-03
---

# /worktree-remove slash command (WIP draft)

## What it does

Safely remove a git worktree after its branch's work is retired. Replaces
the "remember to cleanup" discipline with 5 gates that refuse-and-explain
if the worktree isn't truly safe to remove.

Usage:

```
/worktree-remove <repo> <branch>            # remove worktree for this branch
/worktree-remove <repo> <branch> --dry-run  # show what would happen
/worktree-remove <repo> <branch> --force    # skip optional gates (gates 1-3 still hard)
/worktree-remove <repo> --all-merged        # batch: remove all worktrees whose PR has merged
```

## Five gates (must ALL hold; --force skips gates 4-5 only)

1. **Worktree exists.** `<target> = _worktrees/<repo>-<branch-slug>/` must
   resolve to an actual worktree. If not, refuse with "no such worktree."
2. **Working tree clean.** No dirty files, no untracked WIP. Refuse with
   the list of dirty paths if violated.
3. **No unpushed commits.** Local branch must be at or behind its remote
   tracking branch. Refuse with the count of unpushed commits + the commit
   subjects if violated.
4. **No open PR (optional gate, --force skips).** If a PR exists for this
   branch and is OPEN, refuse with the PR URL and current state. If the
   PR is MERGED or CLOSED, gate passes.
5. **Branch was merged into target base (optional gate, --force skips).**
   If the branch's tip is not reachable from origin/<default-base>, refuse
   with "branch not merged; use --force to remove anyway." Catches the
   "deleted the worktree but the work never landed" footgun.

## What Claude must do when invoked

1. **Parse args.** Same resolution as /worktree-new for `<repo>` (via
   url-resolver or workspace path fallback). Validate `<branch>` as a
   sane git ref.

2. **Compute target path.** Same convention as /worktree-new:
   `<branch-slug>` = `<branch>` with `/` -> `-`;
   `<target>` = `<CodeBasePath>/_worktrees/<repo>-<branch-slug>/`.

3. **Run the 5 gates in order.** Stop at the first failure (don't pile
   on errors). For each gate, show the specific evidence (dirty paths,
   unpushed commit subjects, PR URL + state, merge-base check).

4. **If --dry-run:** print the plan + "dry-run, no action taken" and stop.

5. **Execute removal:**
   - `git worktree remove <target>` (from main clone)
   - If `git worktree remove` complains about lock files, surface the
     error -- do NOT pass `--force` to git automatically.
   - Optionally: `git branch -d <branch>` if the local branch should also
     go. Default: leave the local branch; Owner removes manually if
     desired. Reason: the branch ref is cheap and might still be useful
     for cherry-picks / history navigation.

6. **Report:** path removed, branch state (kept / deleted), suggestion to
   `git fetch origin --prune` to clean remote-tracking refs if the
   upstream branch was also deleted.

## What `/worktree-remove` does NOT do

- Does NOT push, commit, or otherwise mutate code state. Pure cleanup.
- Does NOT remove the upstream branch on the remote. Owner runs
  `git push origin --delete <branch>` separately if desired (or the
  PR's auto-delete-branch handles it).
- Does NOT remove the local branch by default (kept for history).
  Use `--prune-branch` to also delete the local branch.
- Does NOT batch-remove unless `--all-merged` is explicit. One worktree
  per invocation by default.

## --all-merged batch mode

For end-of-session cleanup. Iterates over `git worktree list`,
checks each non-main worktree against gates 1-5, removes those that
pass. Surfaces a summary:

```text
Removed: 4
  - jit-knowledge-feat-wip-skill-draft (PR #232 merged)
  - jit-knowledge-feat-graduate-skill-draft (PR #233 merged)
  - jit-knowledge-feat-worktree-discipline-rule-capture (PR #234 merged)
  - jit-knowledge-chore-status-active-to-canonical-sweep (PR #235 merged)

Skipped: 2
  - jit-knowledge-feat-qa-trial (working tree dirty)
  - jit-knowledge-codex-readonly-rule (not mine; codex/* prefix, different agent)
```

`--all-merged` NEVER removes worktrees owned by other agent runtimes
(branch prefixes `codex/`, `oc/`, etc.) -- those belong to sibling
sessions per `multi-agent-repo-coordination.md`.

## Edge cases

- **Worktree path was modified outside `_worktrees/`:** if Owner created
  a worktree somewhere else, this skill refuses to find/remove it (the
  canonical-path convention is enforced). Owner cleans up manually.
- **Branch was force-pushed and tip diverged from local:** gate 3 catches
  this -- "remote has commits you don't have locally" surfaces with the
  unique-to-remote commit subjects.
- **Branch was renamed:** the worktree's branch ref might be stale.
  Surface as "branch `<old>` was renamed to `<new>`; nothing to remove
  under the old name."
- **Worktree is the current cwd:** `git worktree remove` refuses to
  remove the worktree you're standing in. Surface clear error and
  suggest `cd ..` first.
- **Locked worktree (`.git/worktrees/<name>/locked`):** surface the lock
  file path. Owner inspects the reason (manual lock vs. crash artifact)
  and decides whether to `git worktree unlock` first.
- **Windows directory-on-disk lock (the partial-cleanup case):** Even
  after `git worktree remove --force` succeeds in removing the
  worktree from `git worktree list`, the directory on disk may remain
  if any process has a file handle inside it (most commonly: the shell
  whose CWD is inside that worktree). Symptom: `git worktree remove`
  prints `failed to delete '<path>': Permission denied`, and the
  directory persists, but `git worktree list` no longer shows it.
  Recovery: `cd` outside the worktree first; then either re-run
  `git worktree remove --force <path>` OR fall back to
  PowerShell `Remove-Item -Recurse -Force '<path>'` per
  `feedback_windows_rm_fallback_powershell` -- different file-handle
  semantics. Do NOT retry bash `rm -rf` in a loop; it won't release.
  See: 2026-05-28 PR #255/#256/#257 cleanup sequence where every
  worktree exhibited this on Windows because the calling shell was
  inside the worktree at remove time.

## Companion script (optional)

`<CodeBasePath>/scripts/worktree-remove.ps1` -- PATH-accessible
helper. Same logic as the slash command but invokable from any terminal.
Drafted body to be added when the script ships via install.sh distribution
(deferred until /worktree-new's companion ships).

## Honors

- `rules/worktree-discipline.md` (PR #234 / #239) -- this skill is the
  cleanup half of that rule's lifecycle requirement
- `feedback_worktree_lifecycle_create_use_cleanup` (workspace memory) --
  the directive that "cleanup at per-PR retire point (not deferred);
  end-of-session sweep mandatory; do NOT touch worktrees you did not create"
- `rules/multi-agent-repo-coordination.md` -- batch mode skips other
  agents' worktrees by branch prefix

## Open questions for graduation

- Should `--all-merged` run by default at session-end as part of a
  hypothetical `/session close` skill? Lean: yes, but as a SEPARATE
  decision in that skill's PR -- this skill stays explicit.
- Should the skill auto-remove the local branch when the PR is squashed
  to a different SHA (so `git branch -d` complains)? Lean: prompt Owner;
  squash-merge is the common case and silently delete-local-branch is
  surprising.
- Should there be a `/worktree-status <repo>` skill that audits all
  worktrees for staleness? Lean: yes -- queue as a future skill alongside
  /worktree-new + /worktree-remove for full lifecycle visibility.
- Should this skill be paired with a pre-merge GitHub Action that
  reminds the PR author to run /worktree-remove after merge? Lean: nice
  to have; out of scope for now.

## Promotion checklist

- [ ] Live-trial: end-of-session cleanup sweep using `--all-merged` on
      a session with 2+ retired worktrees; verify gates fire correctly
- [ ] Live-trial: gate refusal case (dirty working tree); verify the
      surface message is actionable
- [ ] Decide: ship companion PowerShell script via install.sh? (pair
      with /worktree-new's script decision)
- [ ] Decide: add `/worktree-status <repo>` audit skill as sibling
- [ ] Status -> `wip-ready` after trial; then `/graduate` to
      `jit-knowledge/skills/worktree-remove/SKILL.md`
