---
type: rule
purpose: BINDING rule for every consuming repo or agent runtime with a `.jit-knowledge/` clone, submodule, subtree, or generated mirror; read before editing files under `.jit-knowledge/` so canonical knowledge changes go through the `jit-knowledge` project instead of creating consumer-local drift.
read_when: Before editing or generating any file inside a consuming repo's `.jit-knowledge/` directory -- direct edits create consumer-local drift that breaks the next submodule pin update.
tags: [jit-knowledge, read-only, submodule, consuming-system, canonical-source, drift-prevention]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---

# jit-knowledge Consumer Read-Only Rule

`.jit-knowledge/` inside any consuming repo is read-only.

It is a pinned copy of the canonical `jit-knowledge` project, not a workspace
scratchpad. Do not edit, patch, generate into, or hand-resolve knowledge content
inside a consumer's `.jit-knowledge/` directory.

## Required Path For Changes

When a change is needed in shared knowledge:

1. Stop editing in the consuming repo's `.jit-knowledge/` tree.
2. Make the change in the canonical `jit-knowledge` repo on a feature branch.
3. Run the relevant `jit-knowledge` validation (`rebuild-manifest.py --check`,
   lint workflows, frontmatter checks, or artifact-specific checks).
4. Open and merge a `jit-knowledge` PR.
5. Update the consuming repo's pin or submodule pointer in a separate consumer PR.

The consumer PR may change the `.jit-knowledge` gitlink/pin only. It must not
contain content edits inside `.jit-knowledge/`.

## If Local Edits Already Exist

Treat local `.jit-knowledge/` edits as drift.

1. Stash or export the local diff for audit.
2. Update `.jit-knowledge/` to the current approved canonical pin.
3. Reapply the stash only to inspect whether any idea still matters.
4. Promote still-valid content through the canonical `jit-knowledge` repo.
5. Drop the consumer-local edits after the canonical path is opened or merged.

Do not preserve consumer-local edits by committing them inside `.jit-knowledge/`.

## What Is Allowed In Consumers

- Updating the submodule gitlink or configured pin after a canonical merge.
- Updating consumer-local instructions that point at a new pin.
- Adding repo-specific context under `<repo>/.jitneuro/`.
- Adding tool-specific adapters that resolve and read canonical `jit-knowledge`
  files without modifying them.

## What Is Not Allowed

- Editing `.jit-knowledge/INDEX.md` in a consuming repo.
- Editing `.jit-knowledge/rules/`, `.jit-knowledge/skills/`,
  `.jit-knowledge/org/`, `.jit-knowledge/horizon/`, or any other canonical
  artifact from inside a consumer repo.
- Resolving `.jit-knowledge` merge conflicts by hand in the consumer and
  treating the result as source of truth.
- Copying consumer-local fixes back into `.jit-knowledge/` without a canonical
  `jit-knowledge` PR.

## Why

Consumer-local `.jit-knowledge/` edits create hidden forks of organizational
rules, skills, charters, and strategy. Agents then behave differently depending
on which repo they happen to be in. That breaks the single-source contract and
makes pin bumps unsafe.

The canonical repo owns knowledge. Consumers own pins and repo-local context.

## Cross-References

- `governance/PIN-POLICY.md` -- how consumers choose and bump pins
- `governance/SYNC-MECHANISMS.md` -- how runtimes discover canonical artifacts
- `governance/PROMOTION-CRITERIA.md` -- when local learnings belong in canonical
  `jit-knowledge`
- `rules/routing-single-source.md` -- INDEX.md is the only routing source
