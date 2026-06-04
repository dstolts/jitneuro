---
type: rule
purpose: BINDING for every devops and backend agent executing production container deploys -- the production active revision MUST be built from a main-branch image after Owner has merged the PR; deploying a feature-branch image as active production means unreviewed code serves real customer traffic with no rollback gate, and any incident requires emergency rollback under live-failure conditions.
trigger: any agent about to run az containerapp update, kubectl set image, or any equivalent command targeting a production environment, OR following a handoff plan that sequences deploy before PR open
tags: [deployment, production-safety, git-discipline, aca, pr-discipline]
scope: public
read_when: Before executing any production container deploy or image-update command targeting a live environment.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_no_feature_branch_to_active_prod.md) -- Knowledge session 2026-06-01
---

# No Feature Branch to Production

## Rule

Production deployments come ONLY from a main-branch image, AFTER the PR has been reviewed and merged by Owner.

Never deploy a feature-branch image as the active production revision -- not for "preview," not for "smoke test," not for any reason.

Correct sequence: open PR -> Owner reviews -> Owner merges -> build from main -> deploy.

If a per-session handoff instructs "deploy + open PR" in that order, treat it as a handoff bug and reorder: PR first.

For sandbox testing of a feature-branch image: deploy as an INACTIVE revision (e.g., `--revision-suffix <sha>`) and DO NOT route any traffic to it. Use the direct revision URL for smoke validation only.

When in doubt: roll back to the last known-good main image and ask Owner.

## Why

- Deploying before review bypasses all review gates. Code that has not been seen by Owner serves real customer traffic with no safety net.
- A broken feature-branch deployment on prod requires rollback under incident conditions, compounding the original error.
- Per-session plans that sequence deploy before PR reflect a planning error; the global rule (PR -> merge -> deploy from main) overrides any per-session ordering.

## What violates this rule

- Running `az containerapp update`, `kubectl set image`, or any equivalent prod-deploy command against a feature-branch-derived image.
- Setting traffic percentage > 0% to an inactive feature-branch revision.
- Using "I need to smoke-test it in prod" as justification for a pre-PR deploy.
- Following a handoff plan that says "deploy then open PR" without correcting the order first.

## Origin

2026-05-19 -- a feature deployment: a feature-branch image deployed as active 100%-traffic prod revision before any PR was open. Owner: "why does the PR come after the deployment, that seems backwards." Rolled back to last main image after ~34 minutes.
