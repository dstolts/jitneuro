---
type: template
purpose: Managed thin AGENTS.md bridge for Codex and other AGENTS-aware clients; canonical behavior lives in workspace AGENTS.md and jit-knowledge.
tags: [template, codex, agent-client, bootstrap, jit-knowledge, agents-md, force-pull]
scope: internal
read_when: When onboarding a repo or repo group to consume jit-knowledge through Codex or another AGENTS.md-aware client.
last_evaluated: 2026-07-10
---

<!-- jit-knowledge-managed: codex-agents-v1 -->

# jitneuro -- AGENTS.md

This file is a thin bridge. Do not duplicate canonical jit-knowledge rules here.

## Pull Latest First (required, every session)

Two or more developers work across several machines against the same repos
-- never assume the local clone is current. The BINDING per-session
requirement is scoped to THIS repo (your lane's working repo):

```
git -C /Users/danstolts/Code/jitneuro pull --ff-only
```

If refused (dirty tree or diverged branch), SURFACE it and resolve
(commit/stash/rebase) before mutating anything in this repo.

Knowledge/tooling currency (jit-knowledge, HubCentral) is separate and
NON-DISRUPTIVE by design. Codex has no SessionStart hook, so run the same
two pulls best-effort at bootstrap:

```
git -C /Users/danstolts/Code/jit-knowledge pull --ff-only
git -C /Users/danstolts/Code/HubCentral pull --ff-only
```

These only fast-forward `main` (which advances solely via CI-gated merged
PRs), so they can never disturb in-flight branch/worktree work. If one is
refused because the clone is dirty, that lane is mid-work on this machine:
LEAVE IT ALONE, continue with the stale warning, and let that lane resolve
its own clone. Full rule:
`<KnowledgeRoot>\rules\master-agent-operational-requirements.md` ("Current
repos").

## Resolve Roots

- Repo root: `/Users/danstolts/Code/jitneuro`
- Workspace root: `/Users/danstolts/Code`
- KnowledgeRoot: `/Users/danstolts/Code/jit-knowledge`

If `/Users/danstolts/Code/jit-knowledge` is unavailable, resolve KnowledgeRoot in this order:

1. `JIT_KNOWLEDGE_ROOT`
2. `~/.claude/workspace.json`
3. `<repo>\.jit-knowledge`
4. `%USERPROFILE%\Code\jit-knowledge`

Warn once if KnowledgeRoot cannot be resolved, then continue with repo-local
context only.

## SQL-Derived Knowledge Routing

Before reading `<KnowledgeRoot>\INDEX.md`, run:

```
bash "/Users/danstolts/Code/jit-knowledge/scripts/knowledge-reboot-handoff.sh" sql-bootstrap --root "/Users/danstolts/Code/jit-knowledge"
```

Authorized Owner machines use direct SQL when configured. Other machines use
their machine-local HubCentral refresh credential to mint a short-lived
`dash.knowledge.read` token. Accept only a non-degraded result whose
`sourceCommit` equals the local Knowledge HEAD; otherwise use Git files.

## Required Bootstrap

Before substantive work, read:

1. `/Users/danstolts/Code\AGENTS.md` when present
2. `<KnowledgeRoot>\AGENTS.md`
3. `<KnowledgeRoot>\COMPANY.md`
4. `<KnowledgeRoot>\README.md`
5. `<KnowledgeRoot>\INDEX.md`
6. Repo-local context when present:
   - `.agents\context.md`
   - `AGENTS.md`
   - `CLAUDE.md`
   - `.HUB\Hub.md`
   - `.HUB\agent-inbox.md`
   - `.HUB\agent-goals.md`
   - `.HUB\agent-permissions.md`
   - `.HUB\questions.md`
   - `todo\backlog.md`
   - `.jitneuro\engrams\context.md`
   - `.knowledge\index.md`
   - `.cursor\rules\*.mdc`

Shared behavior, routing, binding rules, skills, playbooks, and governance come
from the workspace `AGENTS.md` and KnowledgeRoot. Durable repo-local context
belongs in `.agents\context.md`. This repo file only ensures Codex and
AGENTS-aware tools find that chain.

## Continuation + Questions

After bootstrap, apply `<KnowledgeRoot>\rules\agent-goals.md`,
`<KnowledgeRoot>\rules\multi-agent-repo-coordination.md`, and
`<KnowledgeRoot>\rules\session-working-tree-context.md`,
`<KnowledgeRoot>\rules\autonomous-execution.md`, and
`<KnowledgeRoot>\rules\session-guardrail.md`, and
`<KnowledgeRoot>\rules\hubcentral-lane-registration.md`. Codex has no session
hooks, so register this session's HubCentral lane (the stable repo, not the
branch) at start and poll inbox/ready/blocked at task boundaries by running the
shared scripts explicitly: `bash ~/.claude/hooks/session-start-lane-register.sh`
at start and `bash ~/.claude/hooks/intercom-agent-poll.sh` at task boundaries.
For any dependency owned by another lane, create its target-lane `Ready` ticket
and send Intercom with that ticket ID via
`~/Code/HubCentral/scripts/cross-lane-handoff-curl.sh`. Never leave ticket
creation for the Owner or receiving session.
Verify the current working
directory against the active hub/session state's working-tree context before
mutating files or dispatching workers. Discover the configured Intercom surface
(DB/API tracker, deterministic scripts, watcher config, or file-backed
`agent-inbox.md` spool), then read the active hub's `agent-inbox.md`,
`agent-goals.md`, and `agent-permissions.md` files. Set the active task goal to
clear the approved executable backlog for this repo or repo group lane. Codex
does not run Claude slash commands; use Codex-native goal, plan-continuation,
automation, or hook facilities when present, otherwise keep the active plan
moving manually through the same contract.

Owner questions go in the active hub's `questions.md` file, preserving the
repo's existing hub directory case (`.hub\questions.md` or
`.HUB\questions.md`). When a question is added, open that file in the current
window when the runtime supports it.

## Mechanical contracts (hook parity)

Claude Code enforces these via hooks; Codex has none, so apply manually,
every session:

1. **Ticket sweep before create.** Before any `devops-task create`, list
   New/Ready/Active/Blocked in the target lane(s) and grep titles
   case-insensitively for your keywords; any hit means read that ticket
   first. Include `SWEEP_EVIDENCE="lanes=... kw=... found=#id(disposition)..."`
   with the create. Fully covered -> extend the existing ticket, do not
   create; related -> create then `link-dep --dep-type blocks`. A remembered
   ticket is not a sweep.
2. **Audit existing surfaces.** Never plan or ticket a new page, form,
   module, or endpoint without inventorying overlapping surfaces and reading
   their bodies (a grep/index hit is not understanding). Extend or merge the
   best of each; never parallel-create. Canonical rule pending #4339.
3. **Planning input contracts.** User stories/outcomes with a prior-art
   inventory are required before any contract is valid. State effort in
   machine-hours with parallelizability and critical path, never
   days/weeks. Canonical rule pending #4339.
4. **Lane discipline.** Resolve your lane ONLY from your own session
   surfaces (git toplevel, heartbeat, session env). Never poll or resolve
   another lane's intercom inbox, even when a tool or stale env suggests it.
   `<KnowledgeRoot>\rules\multi-agent-repo-coordination.md`.
5. **Education deliverables.** A feature is not Resolved without its
   user-education deliverables (in-product help, quickstart) per
   `<KnowledgeRoot>\rules\definition-of-done.md` condition 2.

## Session checkpoints and follow-up tracking (binding)

Named-lane and `/knowledge`-style runs share a resumable lane, so honor two
conventions that Claude Code's slash commands and hooks enforce but Codex must
apply manually:

- **Resume the canonical lane; do not self-name a checkpoint.** If this session
  writes durable session/checkpoint state, write it under the WORKSPACE-level
  .sessions directory keyed by the canonical lane/session name a resuming
  session would load (for this workspace,
  `C:\Users\dstolts\Code\.sessions\<Lane>.md`). Never write a
  self-named, dated checkpoint into the repo-local `.sessions\`
  folder -- that directory is gitignored per-clone and no resuming session or
  `/load` can discover it, so the lane's history silently forks.
- **Actionable follow-ups become DB DevOps tasks, not `hub.md` rows.** Any
  defect, remediation, or actionable follow-up you surface is created as a DB
  DevOps task through the `devops-tasks` skill
  (`~/Code/HubCentral/scripts/devops-task-curl.sh`, `dbo.devops_backlog`,
  `/api/devops/tasks`) with `--lane` and `--repo` set. `hub.md` tracks active
  progress and blockers only; a hand-written ticket row in `hub.md` is not a
  trackable ticket and will not appear in any lane's executable queue. If
  HubCentral auth is unavailable, write the fallback task file and reconcile it
  through the skill -- do not substitute a `hub.md` row.
