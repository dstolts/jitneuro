---
type: skill
name: graduate
status: canonical
purpose: 'Promote a `status: wip-ready` WIP-Drafts file to its canonical home via `git mv` + frontmatter `status -> canonical` + open graduation PR. The mirror of /wip -- /wip captures, /graduate ships.'
tags: [slash-command, wip-drafts, graduation, recursive-improvement, jit-knowledge, lifecycle]
scope: public
authored_at: WIP-Drafts/skills/graduate.md
origin_date: 2026-05-27
origin_event: Knowledge session 2026-05-24 handoff item 2b. Pairs with /wip (item 2a, drafted 2026-05-27 in PR #232). Together they close the WIP-Drafts lifecycle: /wip captures into draft; iteration matures status to wip-ready; /graduate moves to canonical.
graduation_target: jit-knowledge/skills/graduate/SKILL.md
related_skills:
  - /wip -- conversation-context capture into WIP-Drafts (PR #232)
read_when: When promoting a wip-ready WIP-Drafts file to its canonical location in jit-knowledge via git mv and a graduation PR.
last_evaluated: 2026-06-03
---

# /graduate slash command (WIP draft)

## What it does

Take a `status: wip-ready` file in `WIP-Drafts/`, move it to its canonical
home (read from frontmatter `graduation_target:`), flip `status:` to
`canonical`, bump `last_evaluated:`, and open a graduation PR. The mirror of
`/wip`: capture in / graduate out.

Usage:

```
/graduate WIP-Drafts/skills/wip.md             # graduate by path
/graduate skills/wip                            # short form (resolve from name)
/graduate skills/wip --dry-run                  # show diff + planned PR, don't execute
/graduate skills/wip --target jit-knowledge/skills/wip/SKILL.md   # override target
/graduate skills/wip --repo-path <worktree-path>  # operate on a worktree
```

When operating in a worktree (worktree-discipline compliant -- the main clone stays on default branch; feature work happens in worktrees off origin/main), pass `--repo-path` so the tool operates on the worktree filesystem instead of resolving via `<CodeBasePath>/<Repo>` to the main clone.

## Gates -- must ALL hold before graduation executes

1. **Status check:** file's frontmatter `status:` must be `wip-ready`. If
   still `draft`, refuse with: "File is still draft. Iterate to wip-ready
   first, or use --force-from-draft if Owner explicitly approves."
2. **Graduation target check:** frontmatter `graduation_target:` must
   resolve to a path INSIDE `jit-knowledge/`. If missing, refuse and ask
   Owner to set it.
3. **Path conflict check:** the target path must not already exist. If it does,
   refuse with: "Target <path> exists. Open a refactor PR against the
   existing canonical instead, or pick a different name."
3a. **Topic conflict (lookup-before-promote) check:** scan the canonical
   surface (`rules/`, `_patterns/`, `playbooks/`, `workflows/`, `skills/`,
   `references/`) for files that cover the SAME topic as the WIP source.
   Topic match signals: tag overlap >=2, name substring match in the source's
   `name`, or purpose-keyword overlap above threshold. If matches are found,
   refuse the graduation and surface them to Owner:

   ```
   TOPIC CONFLICT -- existing canonical file(s) cover overlapping scope:
     - <path>  tags=[...]  purpose: "<one-line>"
     - <path>  tags=[...]  purpose: "<one-line>"

   Options:
     (a) Open a refactor PR against the existing canonical (merge the WIP
         into it; do not create a parallel file).
     (b) Re-scope the WIP to a distinct topic and update `graduation_target`.
     (c) If the WIP genuinely covers different ground that the existing file
         doesn't, pass `--accept-topic-conflict` to override after Owner
         explicit OK.
   ```

   Default is REFUSE. Owner must explicitly type `--accept-topic-conflict`
   (or the tool flag equivalent) to proceed past this gate. This prevents
   blind promotion of parallel files with overlapping scope -- the rule
   /graduate ships a file MUST be: merge into existing, or distinctly
   different. Never silently parallel.

   Origin: Owner directive 2026-05-28. Without this gate /graduate would
   blindly promote new WIP files even when an existing canonical already
   owns the topic, producing duplicate-source-of-truth violations the
   librarian-index sprints are explicitly designed to remove.

4. **PR checklist preview:** print the jit-knowledge `governance/PR-CHECKLIST.md`
   mandatory items and ask Owner to confirm each one in one line:
   `Promotion / Sanitization / Conflict / Compat / Frontmatter / INDEX / Tracking -- all OK?`
5. **Owner explicit confirm:** Owner must respond `yes` / `go` / `graduate`
   before the move + commit + push fire. (Unlike /wip's lightweight 1-line
   confirm, /graduate makes a permanent move + opens a PR; the bar is
   higher.)

## What Claude must do when invoked

1. **Resolve the source file.** Accept absolute path, repo-relative path, or
   `<surface>/<name>` short form. Confirm the file exists and lives under
   `WIP-Drafts/`.

2. **Read frontmatter.** Extract `status`, `graduation_target`, `type`,
   `name`, `purpose`, `tags`, `scope`, `last_evaluated`. Validate.

3. **Run the 6 gates above** (1, 2, 3, 3a, 4, 5). If any gate fails,
   surface the failure and stop. Do NOT make partial progress.

4. **Show the plan (dry run by default if --dry-run, else preview before
   executing):**
   - Source path -> target path
   - Frontmatter diff (status: wip-ready -> canonical; last_evaluated bump)
   - Branch name (`feat/graduate-<name>` or chore/refactor variant)
   - Draft PR title + body
   - INDEX.md updates required (the entry for the new canonical path)

5. **Wait for Owner explicit confirm** (gate 5).

6. **Execute the graduation:**
   - `git checkout -b feat/graduate-<name>` (off origin/main)
   - `git mv <source> <target>`
   - Edit frontmatter in target: `status: canonical`, `last_evaluated: <today>`
   - Run `python scripts/rebuild-manifest.py` to regenerate INDEX.md
   - `git add <target> INDEX.md`
   - `git commit -m "feat(graduate): <name> wip-ready -> canonical"`
     with a body listing the file's purpose + companion artifacts
   - `git push -u origin feat/graduate-<name>`
   - `gh pr create --base main` with the PR checklist pre-filled

7. **Post-create verification.** Per `rules/pr-conflict-check.md`:
   - `gh pr view <n> --json mergeable,mergeStateStatus`
   - If CONFLICTING: resolve (rebase onto origin/main, force-push) before
     reporting "ready"

8. **Surface to Owner:** PR URL, mergeable state, INDEX.md change summary,
   and any open-question follow-ups extracted from the source file's "Open
   questions" section (these become tracker items, NOT silent loss).

9. **Update TodoWrite.** Mark the original /wip capture's "graduate" tracker
   row as in_progress (or completed once PR merges -- post-merge step).

## What `/graduate` does NOT do

- Does not merge the PR. (Branch protection + Owner final-approval pattern.)
- Does not delete the original `WIP-Drafts/` entry without using `git mv` --
  history is preserved across the rename.
- Does not flip `status:` for files that don't have a `graduation_target:`
  set. If a draft has no target, it stays in WIP-Drafts indefinitely; the
  lifecycle is opt-in by setting `graduation_target:` in frontmatter.
- Does not auto-merge open questions into the canonical body. Open
  questions become tracker items so they get answered as separate work,
  not silently swept.

## Restrictions

- Branch protection: never push directly to `main`. Always via PR.
- `pull-before-pr.md`: branch is rebased off latest `origin/main` before
  the PR opens.
- `hub-guardrail.md`: never write secrets into the canonical body or
  commit message.
- `actionable-docs-require-tracking.md`: open questions extracted from
  the source file become TodoWrite rows in the same change set.

## Edge cases

- **Source has nested `graduation_target` (e.g., `skills/wip/SKILL.md`
  inside a directory):** `git mv` creates the target directory. Verify
  the new directory only contains the new file (no leftover paths) post-move.
- **Source body references its own WIP path (`WIP-Drafts/skills/wip.md`):**
  the graduation body should update self-references to the canonical path.
  Surface this as a pre-PR edit prompt to Owner.
- **--target override:** Owner can override `graduation_target:` from the
  command line. Useful when the original target turned out wrong. The
  override does NOT modify the frontmatter `graduation_target:` field in
  history -- it just redirects this graduation operation.
- **--dry-run:** print everything that would happen and exit without
  mutating state. Useful for review before commit.

## Related rules

- `rules/wip-drafts-lifecycle.md` -- 3-stage INBOX -> surface -> canonical
- `rules/lookup-before-promote.md` -- never blindly graduate a WIP file when
  an existing canonical owns the topic; merge or distinctly differentiate
- `governance/PR-CHECKLIST.md` -- mandatory checklist that gate 4 surfaces
- `governance/FRONTMATTER-SCHEMA.md` -- frontmatter validation
- `rules/pull-before-pr.md` -- rebase off target base before opening PR
- `rules/pr-conflict-check.md` -- post-create mergeability verification
- `rules/actionable-docs-require-tracking.md` -- open questions become
  tracker rows

## Open questions (for graduation review)

- Should `/graduate` support batch mode (`/graduate skills/wip skills/foo`)?
  Lean: no for now; one graduation = one PR is cleaner.
- Should `/graduate` auto-link the resulting PR back to the original
  capture conversation (via session-state file)? Lean: yes if the source
  frontmatter has a `session_origin:` field.
- Should `/graduate --rollback <pr>` exist for graduations that prove
  premature? Lean: defer; Git revert is sufficient for now.
- Should `/graduate` propose CHANGELOG.md updates when the artifact is
  consumer-facing? Lean: yes if `scope:public` -- otherwise no.

## Promotion checklist

- [ ] Live-trial in 2+ graduations; verify the 5 gates fire correctly
- [ ] Reconcile with `governance/PR-CHECKLIST.md` -- gate 4 should print
      the latest checklist version, not a hard-coded snapshot
- [ ] Decide canonical home: `jit-knowledge/skills/graduate/SKILL.md`
- [ ] Decide if `install.sh` should distribute a slash-command stub for
      Claude-Code-runtime consumers
- [ ] Status -> `wip-ready` once trial + reconciliation done; then
      self-`/graduate` to canonical (recursive!)
