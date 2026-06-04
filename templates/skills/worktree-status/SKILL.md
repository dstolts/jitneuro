---
type: skill
name: worktree-status
status: canonical
purpose: Audit worktrees for a repo (or all repos with --all). Per-worktree, surface branch, ahead/behind default, dirty state, PR status (none / open / merged / closed), age, and a one-word recommendation (ready-to-remove / in-flight / stale / needs-review / blocked). Lets Owner or master scan worktree fleet at a glance instead of running 5 git commands per worktree.
tags: [slash-command, git, worktrees, audit, lifecycle, jit-knowledge, branch-discipline]
scope: public
authored_at: WIP-Drafts/skills/worktree-status.md
origin_date: 2026-05-28
origin_event: PR #241 (/worktree-remove) open questions item #3 -- "Should there be a /worktree-status <repo> skill that audits all worktrees for staleness? Lean: yes -- queue as a future skill alongside /worktree-new + /worktree-remove for full lifecycle visibility." Authored as that follow-up.
graduation_target: jit-knowledge/skills/worktree-status/SKILL.md
related_skills:
  - skills/worktree-new/SKILL.md (sibling: create)
  - skills/worktree-remove/SKILL.md (sibling: remove)
  - rules/worktree-discipline.md (the rule this trio implements end-to-end)
read_when: When auditing open worktrees for staleness, before starting a session with concurrent tasks, or during end-of-sprint cleanup.
last_evaluated: 2026-06-03
---

# /worktree-status slash command (WIP draft)

## What it does

One-screen dashboard of every worktree under a repo (or under all repos
in the workspace with `--all`). Each row tells Owner exactly what state
the worktree is in and what the next action is.

Usage:

```
/worktree-status <repo>            # one repo (e.g. jit-knowledge)
/worktree-status --all             # every repo with worktrees
/worktree-status --stale-only      # only rows recommending action
/worktree-status --json            # machine-readable output (for piping)
```

## Output (table)

```text
=== jit-knowledge worktrees ===

 #  branch                                 ahead/behind  dirty?  PR        age   recommend
 1  feat/qa-trial                          2/0           clean   #245 OPEN 2d    in-flight
 2  feat/wip-draft-old                     1/14          clean   none      9d    stale  -- run /wip-something or /worktree-remove
 3  chore/path-cleanup                     0/0           clean   #239 MERGED 4d  ready-to-remove
 4  feat/dirty-branch                      3/0           DIRTY!  none      3d    needs-review -- commit or stash first
 5  codex/readonly-rule                    -             -       -         -     skip -- foreign agent (codex/), not mine

Summary: 5 worktrees; 1 in-flight, 1 ready-to-remove, 1 stale, 1 needs-review, 1 foreign
Recommendations:
  - /worktree-remove jit-knowledge chore/path-cleanup
  - Decide on feat/wip-draft-old (stale 9d)
  - Resolve feat/dirty-branch dirty state
```

## Per-worktree fields

| Field | How computed |
|---|---|
| **branch** | `git rev-parse --abbrev-ref HEAD` in the worktree |
| **ahead/behind** | `git rev-list --left-right --count origin/<default>...HEAD` |
| **dirty?** | `git status --porcelain` (empty = clean) |
| **PR** | `gh pr list --head <branch> --state all --json number,state` (first match) |
| **age** | hours since most recent commit on branch (rounded to d/h) |
| **recommend** | derived per rules below |

## Recommendation rules

- **ready-to-remove:** PR is MERGED or CLOSED; 0 dirty; 0 unpushed.
  Next action: `/worktree-remove <repo> <branch>`
- **in-flight:** PR is OPEN; 0 dirty OR small dirty delta consistent with
  active work. No action.
- **stale:** no commits in > 7 days AND PR is none OR MERGED. Owner
  decides: resurrect, finish, or remove.
- **needs-review:** working tree dirty OR commits ahead of remote.
  Action: commit or stash; surface what's uncommitted.
- **blocked:** PR has merge conflict OR CI failure OR is BLOCKED by branch
  protection. Action: resolve PR-side blocker.
- **foreign:** branch prefix matches another agent system (codex/, oc/, etc.)
  per `multi-agent-repo-coordination.md`. SKIP -- this skill never
  recommends action on another agent's worktrees.
- **unknown:** falls through all the above. Surface as-is for Owner.

## What Claude must do when invoked

1. **Resolve repo(s).** Single repo: validate path via url-resolver. `--all`:
   enumerate every directory under `<CodeBasePath>/_worktrees/`
   that has a `.git` link.

2. **For each worktree:**
   - `cd <worktree-path>`
   - Collect the fields (branch, ahead/behind, dirty, PR, age)
   - Compute recommendation per the rules above
   - Skip detailed gh pr lookup if `--no-pr` flag (fast mode)

3. **Sort:** ready-to-remove first (high signal-to-action ratio),
   then needs-review, then stale, then in-flight, then foreign.

4. **Render the table.** Use the format above for `/worktree-status`;
   `--json` outputs structured data for piping to other tools.

5. **Summary line:** count by recommendation type.

6. **Recommendations block:** an action list Owner can copy-paste:
   - `/worktree-remove <repo> <branch>` for each ready-to-remove
   - Decisions needed for stale + needs-review (one line each)

## What `/worktree-status` does NOT do

- Does NOT remove anything. Read-only audit.
- Does NOT create worktrees. Use `/worktree-new`.
- Does NOT update PR state. Use `gh pr` directly.
- Does NOT touch other agents' worktrees beyond surfacing them as
  `foreign` rows.

## Restrictions

- Read-only `git` + `gh` calls only.
- Polite about gh API rate limits: caches PR lookups per branch for the
  duration of a single invocation (avoids re-querying when the same
  branch appears across multiple repos).
- `--no-pr` flag skips the gh pr query entirely (offline mode, faster).

## Edge cases

- **Worktree on a branch deleted from origin:** ahead/behind shows
  `?/?`; recommendation is `stale` (the remote branch was deleted but
  the worktree wasn't cleaned up).
- **Detached HEAD:** branch = `(detached)`; PR lookup is N/A;
  recommendation is `needs-review` with reason "detached HEAD".
- **PR exists for a different repo on same branch name:** the `gh pr list
  --head <branch>` query scopes to current repo; cross-repo collisions
  are avoided.
- **Squash-merged PR:** PR is MERGED but the commit SHA on the worktree
  branch is not in origin/main. Recommendation is still `ready-to-remove`
  -- the LOGICAL work landed even though the commit SHA differs.
- **Foreign worktree (codex/, oc/) is also dirty:** still SKIP. Not mine
  to recommend on.

## Companion script (deferred)

`<CodeBasePath>/scripts/worktree-status.ps1` -- PATH-accessible
helper that produces the same table. Drafted body deferred until the
/worktree-new + /worktree-remove companion scripts ship via install.sh
distribution; this skill graduates first.

## Honors

- `rules/worktree-discipline.md` -- this skill is the visibility half
  of the worktree-discipline lifecycle (create / use / cleanup / audit)
- `rules/multi-agent-repo-coordination.md` -- `foreign` row type
  respects per-agent ownership; skill never recommends action on
  another agent's worktrees
- `workspace memory feedback_worktree_lifecycle_create_use_cleanup` --
  "end-of-session sweep mandatory; do NOT touch worktrees you did not
  create" -- this skill makes the sweep checkable in one command

## Open questions for graduation

- Should `/worktree-status --all` be the default invocation at session
  start (after /knowledge bootstrap)? Lean: not auto; opt-in -- avoids
  surprise gh API calls on every fresh session.
- Should the stale threshold (7 days) be configurable per-repo? Lean:
  yes -- some repos have slow-moving WIP branches that aren't actually
  stale. Configure via repo-local `.jitneuro/jitneuro.json`
  `worktreeStaleThresholdDays` field, default 7.
- Should `/worktree-status --stale-only --json` feed an automated
  cleanup workflow (cron / scheduled task)? Lean: yes for opt-in;
  separate skill.
- Should the `foreign` skip be configurable? E.g. Owner explicitly
  authorizes Knowledge session to clean up codex/* worktrees? Lean: no
  -- the rule is "do not touch worktrees you did not create" and
  multi-agent-repo-coordination is binding.

## Promotion checklist

- [ ] Live-trial: run /worktree-status on current jit-knowledge worktree
      tree (5+ worktrees expected) and verify accuracy of each row's
      recommendation
- [ ] Live-trial: run with --all across workspace, app-repo-API, api-repo,
      jit-knowledge worktrees; verify cross-repo PR lookup works
- [ ] Decide: --no-pr flag for offline use? (Probably yes for speed)
- [ ] Decide: ship companion PowerShell script via install.sh? (Pair
      with /worktree-new + /worktree-remove script decisions)
- [ ] Status -> `wip-ready` after trial; then `/graduate` to
      `jit-knowledge/skills/worktree-status/SKILL.md`
