---
type: rule
purpose: Define GREEN / YELLOW / RED permission zones for AI actions in a repo, with push-to-main and production deploys as RED requiring explicit user permission every time.
tags: [trust-zones, permissions, red-zone, git, deployment-safety]
scope: public
departments: [all]
read_when: At session start and before any push, deploy, delete, or schema-change action to determine whether the action is GREEN, YELLOW, or RED.
last_evaluated: 2026-06-03
---
# Trust Zones

Structured permission model for AI actions. Customize zones per team or repo.

| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze, research | Execute freely |
| YELLOW | Schema changes, new dependencies, API contracts, .env writes | Execute, report at checkpoint |
| RED | Push to main, production deploy, delete files/branches, DB migrations | Stop and ask user |

## Git

Commit locally and push to feature branches freely when inside the repo's
approved write scope.

Sprint fixes and CI fixes go to feature branches or `uat` first. If `uat` CI is
blocking, fix it on `uat`; do not bypass validation by pushing directly to
`main`.

Push to `main` or `master` is RED. It requires explicit Owner permission, even
when the change is small, urgent, or intended to unblock CI.

The only normal path to `main` is:

1. feature branch or `uat`
2. validation/CI
3. review gates
4. Owner-approved merge/push to `main`

## Customization

Adjust zones per your risk tolerance:
- Solo developer: might move "push to main" to YELLOW
- Enterprise team: might move "new dependencies" to RED
- CI/CD pipeline: might add "deploy to staging" as GREEN, "deploy to production" as RED

## Per-Repo Overrides (repo-local)

Individual repos may declare per-repo main-push permissions in their local
`jitneuro.json` (`mainPushAllowed` field) or equivalent config. Those overrides
are personal/repo-specific and do NOT belong in this canonical file.

When adding a per-repo override:
1. Document it in the consuming repo's `.jitneuro/rules/trust-zones-local.md`
2. Keep this canonical file free of instance-specific repo names and URLs
