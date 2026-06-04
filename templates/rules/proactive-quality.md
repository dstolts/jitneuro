---
type: rule
purpose: Require proactive end-to-end verification of every code change and comprehensive post-deploy E2E coverage so issues are surfaced before reviewers or users encounter them.
tags: [quality, proactive, e2e, verification, post-deploy]
scope: public
read_when: Before making any code change or executing any deploy that touches customer-facing functionality.
last_evaluated: 2026-06-03
---
# Proactive Quality

Proactively identify and flag issues before they reach reviewers or users. Do not wait to be told.

When making ANY code change:
1. Verify the change works end-to-end, not just syntactically
2. Check logs for errors, fallbacks, timeouts after every test run
3. Compare configured vs actual -- if a dependency is configured but never succeeds, investigate immediately
4. When touching external service configs, test against the actual API
5. When touching calculations or business logic, verify outputs match expectations
6. Surface what needs attention -- don't wait to be asked

## Post-deploy E2E discipline

After any deploy/merge, run comprehensive E2E test covering ALL customer-facing routes + full customer flows. Single-endpoint smoke is insufficient. Iterate until fully green per `iterate-until-success.md`.

## Related

- `iterate-until-success.md` -- loop until all gates pass
- `verify-before-presenting.md` -- verify before asking anyone else to look
- `testing-critical-path.md` -- test the full path, not just individual endpoints
