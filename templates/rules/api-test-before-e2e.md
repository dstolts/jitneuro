---
type: rule
purpose: Require API-level smoke testing against live endpoints before running browser E2E tests, ensuring the contract is proven before exercising the rendered surface.
read_when: Before running any browser-based E2E test suite, or when declaring a customer-facing flow change ready for review.
tags: [testing, api-smoke, e2e, test-sequence, quality-gate]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---
# API Test Before E2E

Always run API-level testing against the actual production (or staging) endpoints before running browser-based E2E tests. API smoke is the floor; browser E2E is the bar; both happen before declaring work ready for review.

## Why

API smoke catches the floor-level bugs (validation, persistence, side effects) faster and cheaper than driving a browser. A browser-driven E2E that fails on a 400 from the API wastes the browser run and obscures the real cause. API smoke FIRST proves the contract; browser E2E SECOND proves the rendered surface matches.

If API smoke fails, browser E2E is not run and the work is not ready. If API smoke passes, browser E2E exercises what API cannot see (rendering, state, redirects, browser cookies, CORS preflight, CSP).

## Sequence (binding)

For any change to a customer-facing flow:

1. Unit tests (vitest / jest / equivalent) -- pass with mocks
2. **API smoke against the real endpoint with the real customer payload.** Submit the request a customer would submit. Read the response. Poll for the delivered outcome (DB row, email arrival, tier in result). Use the actual production or staging endpoint, not localhost.
3. Browser E2E (Playwright headless or live) -- only after API smoke passes
4. Customer-artifact check (open the PDF / receive the email / view the dashboard the customer would see)
5. Hand off for review

If any step fails, fix and re-run from the failing step. Do not skip to a later step.

## What "API smoke" requires

- Hits the actual deployed endpoint at its public URL (or signed staging URL)
- Sends the same payload shape the production frontend would send
- Authenticates the same way (cookies, tokens, headers)
- Reads the response body and checks structural correctness
- Polls or queries the persistent state (DB row, queue depth, sent-email log) to verify the side effect actually happened
- Reports the actual values found, not just "200 OK"

## What violates this rule

- Declaring a flow "tested" because tsc + vitest + build all pass
- Skipping API smoke and going straight to browser E2E
- Skipping API smoke and asking a reviewer to verify
- "I curled the endpoint" without verifying the side effect (DB row, email, queue insertion) -- 200 OK is necessary, not sufficient
- Using mocked clients in API smoke; the smoke runs against real services

## Related

- `smoke-real-browser-before-done.md` -- step 3 of this sequence
- `smoke-real-db-before-done.md` -- DB-side discipline; complements API smoke
- `verify-before-presenting.md` -- never ask a reviewer to check before verifying yourself
- `iterate-until-success.md` -- keep iterating across all gates until fully green
- `testing-method.md` -- every test result states the method used
