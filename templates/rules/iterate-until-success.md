---
type: rule
purpose: Require a comprehensive E2E test loop after every deploy or merge and mandate continuing to fix and redeploy until all customer-facing gates are green before handing off.
read_when: After any deploy, merge, or infrastructure change that ships customer-facing functionality -- stopping after partial success ships broken customer paths.
tags: [testing, e2e, iterate-until-green, deployment, quality-gate]
scope: public
last_evaluated: 2026-06-03
---
# Iterate Until Success

After any deploy, merge, or infrastructure change that ships customer-facing functionality, run a COMPREHENSIVE E2E test loop. Any failure = dispatch fix, redeploy, re-test. Loop until fully green.

## The rule

Do NOT hand off after one partial success. Keep iterating.

## The pattern

1. Deploy/merge completes
2. Run comprehensive E2E covering all customer-facing routes + flows
3. If ANY regression: file fix -> rebuild + redeploy -> re-run E2E
4. Loop until ALL green
5. Only THEN report success + hand off

## Applies to

- API deploys
- Frontend deploys
- Infrastructure cutovers (DNS, certs, cron migrations)
- Migration events (DB schema, hosting platform, etc.)
- Any service re-deploys

## What violates this rule

- Handing off after "most tests pass" or "the main flow works"
- Stopping when a regression is found without filing a fix first
- Treating a partial green as a green
- Asking a reviewer to check something you have not verified fully yourself
