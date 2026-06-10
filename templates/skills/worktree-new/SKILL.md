---
type: skill
name: worktree-new
status: canonical
purpose: Make the worktree-discipline rule frictionless. Encodes the canonical path convention `<CodeBasePath>/_worktrees/<repo>-<branch>/` and the standard create-worktree sequence so master cannot accidentally branch the main clone. Mechanical enforcement of the rule via a single command instead of remembering the 3-step git incantation.
tags: [slash-command, git, worktrees, jitneuro, branch-discipline, recursive-improvement]
scope: public
departments: [engineering]
authored_at: WIP-Drafts/skills/worktree-new.md
origin_date: 2026-05-28
origin_event: PR #234 (worktree-discipline rule) open questions item #1 -- "Should the rule include a `git worktree-add` slash command / helper script? Lean: yes -- a `/worktree-new <repo> <branch>` slash command would encode the path convention and make the right way frictionless." Knowledge session 2026-05-28 follow-up after batch graduation PR #239 merged the worktree-discipline rule as canonical.
graduation_target: <knowledge-root>/skills/worktree-new/SKILL.md
related_skills:
  - rules/worktree-discipline.md (the rule this skill makes mechanical)
  - skills/wip/SKILL.md (sibling: capture into WIP-Drafts)
  - skills/graduate/SKILL.md (sibling: promote wip-ready -> canonical)
  - skills/knowledge/SKILL.md (sibling: re-anchor + status display)
read_when: Before creating a new git worktree for any parallel or concurrent coding task to enforce the canonical path convention.
last_evaluated: 2026-06-03
---

# /worktree-new slash command (WIP draft)

## What it does

Create a new git worktree under the canonical workspace location, with the
canonical naming convention, off the canonical target base. One command
replaces the 3-step "main clone clean + worktree add + cd" incantation that
agents keep getting wrong.

Usage:

```
/worktree-new <repo> <branch>                  # branch off origin/<default-branch>
/worktree-new <repo> <branch> --from <base>    # branch off origin/<base>
/worktree-new <repo> <branch> --existing       # check out existing branch (no -b)
```

Examples:

```
/worktree-new jitneuro feat/qa-trial-1     -> <worktrees>/jitneuro-feat-qa-trial-1/
/worktree-new api-repo docs/api-update          -> <worktrees>/api-repo-docs-update/
/worktree-new app-repo-app feat/x --from uat        -> <worktrees>/app-repo-feat-x/ off origin/uat
```

## Canonical conventions encoded

- **Path:** `<CodeBasePath>/_worktrees/<repo>-<branch-slug>/`
  where `<branch-slug>` is the branch name with `/` replaced by `-`
  (e.g. `feat/wip-drafts` -> `feat-wip-drafts`).
- **Base:** the repo's default branch (`main` for jitneuro,
  `uat` for app-repo-API / app-repo-App / api-repo, etc.). `--from` overrides.
- **Source:** always fresh from `origin/<base>` (not local).
- **Main clone:** stays on its default branch. The slash command refuses
  to create a worktree if the main clone is on a non-default branch
  (worktree-discipline violation; master must switch back to main first
  in the main clone).

## What Claude must do when invoked

1. **Parse args:**
   - `<repo>` -- name of the repo (e.g. `jitneuro`). Resolve to main
     clone path via `~/.claude/url-resolver.md` (or
     `<CodeBasePath>/<repo>/` as fallback). Refuse if not found.
   - `<branch>` -- the new branch name. Validate as a sane git ref
     (no spaces, no leading `-`, max 100 chars).
   - `--from <base>` -- optional override of base branch.
   - `--existing` -- use existing branch instead of `-b`.

2. **Check main clone state:**
   - `cd <main-clone-path>`
   - `git rev-parse --abbrev-ref HEAD` must equal the default branch.
     If not, refuse with: "Main clone is on `<branch>`, expected
     `<default>`. Worktree-discipline says main clone stays on default;
     switch back first, then re-run."
   - `git status --porcelain` must be empty. If dirty, warn but allow
     (worktree add doesn't touch the main clone's working tree).

3. **Verify base branch is fetchable:**
   - `git fetch origin <base> --quiet`. If fetch fails (no such ref),
     refuse with the actual git error.

4. **Compute target path:**
   - `<branch-slug>` = `<branch>` with `/` replaced by `-`
   - `<target>` = `<CodeBasePath>/_worktrees/<repo>-<branch-slug>/`
   - Refuse if `<target>` already exists -- show the existing path and
     suggest `cd` instead of recreating.

5. **Create worktree:**
   - With `-b` (default): `git worktree add -b <branch> <target> origin/<base>`
   - With `--existing`: `git worktree add <target> <branch>`
   - On error, surface and stop. Do not retry silently.

6. **Verify + report:**
   - `cd <target>`
   - `git status -b --short` must show `## <branch>` (sanity check)
   - Surface to Owner:
     - Created path
     - Branch + base
     - Suggested next commands:
       `cd <target>` (so Owner can pick up immediately)
       `code <target>` (open in editor if Owner uses VS Code)

7. **Update TodoWrite (optional, polite):**
   - Add a "cleanup worktree `<target>` when branch retires" reminder
     row per `feedback_worktree_lifecycle_create_use_cleanup`. This makes
     the cleanup obligation visible in the queue, not just memory.

## What `/worktree-new` does NOT do

- Does NOT switch the user's current shell to the new worktree (slash
  commands run in the agent's context). Owner has to `cd` manually --
  the response surfaces the exact command.
- Does NOT create branches in repos other than the named one. One worktree
  per invocation; no batch mode.
- Does NOT delete or remove worktrees. That's `/worktree-remove` (or
  `git worktree remove`); separate scope.
- Does NOT push the new branch. Owner pushes when ready, after the first
  commit (or `--set-upstream` on first push).
- Does NOT auto-checkout pre-existing local branches as worktrees -- it
  defaults to `-b` (new branch). Use `--existing` to opt into checking
  out a pre-existing branch.

## Restrictions

- Read-only operations on the main clone (fetch + status + rev-parse).
  Worktree-add IS a mutation but only against the worktrees directory,
  not the main clone's working tree.
- No commits, no pushes, no PR operations. Pure scaffolding.
- Refuses on main-clone-on-non-default-branch (mechanical enforcement
  of worktree-discipline).

## Edge cases

- **Branch name has `/`:** slugged with `-` in the target path. E.g.
  `feat/wip-drafts-inbox` -> `<worktrees>/jitneuro-feat-wip-drafts-inbox/`.
- **Branch name is very long:** path is allowed but Windows path-length
  caps apply (260 chars in some configurations). Surface a warning if
  the target path exceeds ~200 chars; otherwise proceed.
- **Repo with no `main` branch (uses `master` or other):** resolver looks
  up the default branch via `git symbolic-ref refs/remotes/origin/HEAD`.
  If that fails, refuse and ask Owner to pass `--from <base>` explicitly.
- **Repo has `uat` as default (app-repo-API / api-repo):** worktree branches
  off `origin/uat` by convention. `--from main` overrides if needed
  (e.g. for cherry-pick scenarios like api-repo PR #158).

## Companion tool

The PowerShell helper that implements this skill lives as a real executable
file -- NOT inlined here. Canonical path:

- **In jitneuro:** `tools/worktree-new.ps1`
- **Deployed:** `<CodeBasePath>/scripts/worktree-new.ps1` (PATH-accessible after install)

The tool resolves `<CodeBasePath>` at runtime per the chain in
`governance/path-conventions.md` section 3a (env `CODE_BASE_PATH` ->
`~/.claude/workspace.json` `codeBasePath` -> default `$HOME/Code` /
`%USERPROFILE%\Code`).

Inlining the script body into this markdown was the original draft style;
correction (Owner 2026-05-28): tools belong in real files, not embedded
code blocks. The .md describes the skill; the .ps1 IS the skill.

## Honors

- `rules/worktree-discipline.md` -- this skill is the mechanical
  enforcement of that rule's "create new work" recipe
- `~/.claude/url-resolver.md` -- canonical repo->path map (used by step 1)
- `rules/pull-before-pr.md` -- fetches origin before branching, so the
  new branch is current with remote

## Open questions for graduation

- Should `/worktree-new` ALSO be a Windows Task Scheduler integration
  for repeated branch-spawning patterns? Lean: no -- single invocation
  scope; loops are out of scope.
- Should the companion script be shipped as part of install.sh distribution?
  Lean: yes (drops to `<workspace>/scripts/worktree-new.ps1` like the other
  workspace tooling).
- Should `--existing` auto-detect (i.e. if `<branch>` already exists
  locally, treat it as `--existing` without the flag)? Lean: no -- explicit
  is safer; prevents accidental local-branch-shadowing-remote scenarios.
- Should `/worktree-remove <repo> <branch>` be a sibling skill in the
  same PR? Lean: separate PR; cleanup discipline is enough scope on
  its own.

## Promotion checklist

- [ ] Live-trial in 2+ real worktree creations across different repos
      (jitneuro + api-repo at minimum); verify the 5 main-clone-state
      checks fire correctly
- [ ] Decide if companion PowerShell script ships via install.sh
- [ ] Sibling `/worktree-remove` skill in follow-up PR (lifecycle cleanup)
- [ ] Status -> `wip-ready` after trial; then `/graduate` to
      `<knowledge-root>/skills/worktree-new/SKILL.md`
