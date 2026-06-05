---
type: rule
purpose: BINDING for every agent cutting a feature or fix branch -- run git fetch origin and verify the remote default-branch state before branching; skipping means the new branch may diverge from commits already on origin and open with an immediate merge conflict before any review begins.
trigger: any agent about to run git checkout -b or git switch -c to create a new branch, especially when bumping submodule pins or working across multiple active sessions
read_when: Immediately before running git checkout -b or git switch -c to create any new branch.
tags: [git, branching, submodule, stale-state, pre-branch]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_verify_origin_before_branch.md) -- Knowledge session 2026-06-01
---

# Fetch Before Branch

## Rule

Before cutting any feature or fix branch, fetch origin and verify the remote default
branch state. Do not branch from local state without confirming it matches origin.

Required pre-branch checklist:
1. `git fetch origin`
2. `git log origin/<default-branch> --oneline -5` -- see what landed since last sync
3. For submodule bumps: `git ls-tree origin/<default-branch> <submodule-path>` to get
   the canonical pin from origin, not local state

Only then run `git checkout -b <branch> origin/<default-branch>`.

## Why

The local working tree can be stale relative to origin: missed merges from other
contributors, prior PRs from other sessions, or an outdated submodule pin. Branching
from stale local state produces a branch that immediately has a merge conflict against
the current origin tip.

Origin incident (2026-05-12): OC PR #7 (submodule bump v1.0.2 -> v1.1) hit a merge
conflict on open because the local jit-knowledge submodule pin was read from the stale
local working tree. Two prior PRs (#5/#6) had already moved the pin forward on
origin/main. The branch conflicted before a single review comment.

The fix is one `git fetch` before every branch creation. Zero cost, eliminates the class.

## What violates this rule

- Running `git checkout -b feature/X` immediately after prior work without fetching.
- Assuming local state is current because no other agent ran recently.
- For submodule bumps: reading the pin from `cat .gitmodules` or local `.git/modules/`
  instead of `git ls-tree origin/<branch>`.

## Origin

Owner correction 2026-05-12 OC submodule bump session. PR #7 opened with a merge
conflict traceable to local stale submodule pin vs origin/main state.
