---
type: rule
purpose: BINDING for every master/orchestrator session after a batch of subagent fix-agent merges -- before dispatching any subsequent diagnostic, sweep, or RCA agent from master's working tree, master MUST pull origin to advance its local HEAD; skipping means the sweep tests stale code and produces false-failure attributions for fixes that already landed.
trigger: one or more subagent PRs have been merged to uat or main and master is about to dispatch a sweep, diagnostic, or verification agent from its own working directory
tags: [git, multi-agent, worktree, diagnostic, stale-state]
read_when: After any subagent merges a PR to a shared branch and before dispatching any subsequent diagnostic, sweep, or verification agent -- skipping means sweep agents test stale code and attribute false failures to fixes that already landed.
scope: public
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_master_pull_after_merge.md) -- Knowledge session 2026-06-01
---

# Master Pull After Subagent Merge

## Rule

After any sub-agent merges a PR to a shared branch (uat, main, staging), master MUST
advance its own working tree before dispatching any subsequent diagnostic, sweep, or
RCA agent that operates from master's cwd.

Required steps before the next dispatch:
1. `git fetch origin --quiet`
2. `git pull --ff-only origin <branch>` (stash local dirty files if needed)
3. Verify `git rev-parse HEAD` matches `git rev-parse origin/<branch>`
4. Then dispatch the next agent

Exception: not required if the next sub-agent will create its own fresh worktree
branching from `origin/<branch>` -- those agents always start current.

## Why

Sub-agents work in isolated worktrees. When they commit, push, and clean up, master's
main working tree is untouched. It stays at the pre-merge SHA. A diagnostic agent
dispatched from master's cwd then reads stale local files against a post-merge deployed
build and produces false-failure attributions.

Origin incident (2026-05-28): 6 fix agents merged PRs #317-#322 to uat, advancing
origin/uat from `dda0b9b` to `766abb3`. Sweep #5 ran from master's cwd at `dda0b9b`.
Four fixes (cp-14, cp-18, cp-28, cp-29) were reported as "fix didn't work." All four
were actually landed. The sweep had tested the wrong code. Cost: 3 hours + ~$5 tokens.

The deployed bundle is always current. The local working tree is not. These are
independent.

## What violates this rule

- Dispatching a sweep or diagnostic agent immediately after a batch of fix-agent merges
  without pulling master's tree first.
- Assuming "deploy succeeded so local code is current."
- Skipping the pull because local Hub.md or session-state files are dirty
  (stash, pull, restore -- but do not skip).

## Origin

Owner correction 2026-05-28, a multi-agent E2E session. Sub-agent worktree lifecycle meant
master's tree never advanced across 6 merges; sweep #5 produced systematic
false-failure reports across 4 of 6 fix CPs.
