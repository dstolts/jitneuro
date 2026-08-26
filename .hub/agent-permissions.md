---
type: policy
purpose: Repo-scoped agent permissions and branch authority for JitNeuro.
tags: [hub, agent-permissions, merge-authority, jitneuro]
scope: public
read_when: Before an agent pushes a branch, opens or merges a PR, or changes repository settings in JitNeuro.
last_evaluated: 2026-07-12
---

<!-- jit-knowledge-managed: agent-permissions-v1 -->

# Agent Permissions

This file is the repo-scoped allowlist and branch-authority policy for JitNeuro.
It is read before an agent pushes branches, opens or merges PRs, or changes
repository settings.

## Repo Branch Model

| Branch | Purpose | Agent merge authority | Owner approval |
|---|---|---|---|
| `main` | Production/default release branch | green PR merge/auto-merge | protected/RED gates and GitHub-required review only |
| `uat` | Staging and promotion branch | green PR merge/auto-merge | protected/RED gates only |

Direct pushes to `main` and `uat` are forbidden. All changes use PRs. A merge
grant does not bypass GitHub branch protection or required reviews.

## Agent System Allowlist

| Agent system | Scope in this repo | Branch prefix | Allowed actions | Merge authority | Notes |
|---|---|---|---|---|---|
| Codex interactive master | approved jitneuro-lane work | `codex/*` | create branches, edit files in scope, open/update/merge green PRs | routine PR merge | preserve contributor work and follow repo bootstrap |
| Claude Code interactive master | approved jitneuro-lane work | `claude/*` | create branches, edit files in scope, open/update/merge green PRs | routine PR merge | preserve contributor work and follow repo bootstrap |
| Cursor | approved jitneuro-lane work | `cursor/*` | create branches, edit files in scope, open/update/merge green PRs where tooling supports it | routine PR merge | preserve contributor work and follow repo bootstrap |

## Branch Permission Grants

| Grant ID | Branch/target | Allowed actors | Allowed action | Required gates | Owner approval needed | Expires/review |
|---|---|---|---|---|---|---|
| green-pr-merge | `uat`, `main` | Codex, Claude Code, or Cursor interactive master acting as merge coordinator | merge or arm auto-merge; no direct pushes | branch current with target; GitHub reports mergeable; all required CI and repo-specific validation green; review conversations resolved; no protected-path or RED blocker | only for protected/RED gates or a GitHub-required review | standing |

## JitNeuro Required Validation

The green-PR grant requires every check applicable to the changed scope:

- Repository CI and knowledge capability/index drift checks pass.
- Installer or PowerShell changes run the relevant install/upgrade validation.
- Hook, command, rule, agent, or skill changes run their focused tests and
  verify installed/routed behavior, not only source-file presence.
- Security-sensitive changes receive independent security review; no secrets,
  credentials, private data, or internal-only material enter the public repo.
- Public artifacts pass the applicable moat/public-disclosure and leak gates.
- Browser E2E, when applicable, is headless, timeout-bounded, non-interactive,
  and validates the real user outcome without leaving orphan processes.

## Protected Paths and RED Gates

Changes in these paths require protected review before merge:

- `.github/workflows/**`, `.hub/agent-permissions.md`, `install.sh`, and
  `install.ps1`;
- `templates/hooks/**`, `templates/rules/**`, `templates/agents/**`,
  `templates/dev-shop-pack/**`, and security-sensitive instruction surfaces;
- license, contribution-governance, release, signing, branch-protection, and
  public-disclosure policy files.

The following actions remain RED and are never authorized by `green-pr-merge`:

- production deploys or traffic changes;
- database/schema migrations or destructive data operations;
- credential, secret, authentication, or repository-security changes;
- destructive infrastructure or repository settings changes;
- bypassing required security, E2E, licensing, disclosure, or branch gates.

Protected review may be satisfied only by the reviewer or approval mechanism
required by the applicable repository rule or GitHub protection. Agents must
not use administrator bypasses to manufacture a green state.

## Coordination Notes

- One merge coordinator serializes merges into each target branch.
- Other agents may author and update PRs but must not race the coordinator.
- After every merge, the coordinator refreshes the next PR against the target
  and returns real conflicts to the originating lane.
- A grant for one PR never authorizes direct push, deploy, migration, secret,
  destructive, or repository-settings actions.
