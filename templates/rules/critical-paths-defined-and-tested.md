---
type: rule
purpose: Require every customer-facing repo to maintain a CRITICAL-PATHS.md inventory with executable Playwright specs covering each path, making untested paths a release blocker.
read_when: When setting up a new customer-facing repo, adding a new product flow, or evaluating release readiness for any customer-facing service.
tags: [testing, critical-paths, playwright, e2e, release-gate]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---
# Critical Paths Defined and Tested

Every customer-facing repo MUST have a CRITICAL-PATHS.md inventory and every listed path MUST have an executable Playwright spec. A path listed with status "missing-test" or "blocked" is a COVERAGE FAILURE that blocks release -- not a warning, a block.

## Why

Sub-agent success does not imply system success. Individual component tests passing green does not mean the combined system works. A journey-level gate -- testing the full browser -> network -> API -> response chain -- catches failures that per-endpoint smoke cannot.

## What a critical path IS

A critical path is the full customer journey from a specific entry point (a production URL the customer visits) to a verified outcome (a DOM state, a network response, a confirmed DB side-effect). It tests the combination of all parts -- browser, CDN, WAF, CORS, API, backend, database -- in a single end-to-end real-network run.

A critical path test:
- Runs against real production infrastructure (no mocks, no page.route() substitution)
- Navigates a real browser to the real URL
- Performs the actions a real customer would perform
- Asserts the customer's expected outcome (not just "the API returned 200" but "the result is rendered")
- Waits appropriately for async operations (scan results, email delivery signals, DB writes)

## What it is NOT

- A per-endpoint smoke test (those are a separate gate)
- A unit test (no mocked dependencies)
- Documentation (an entry in CRITICAL-PATHS.md without a spec is a COVERAGE FAILURE)
- A happy-path fragment that tests the entry but not the outcome

## CRITICAL-PATHS.md format

Every customer-facing repo must maintain CRITICAL-PATHS.md at the repo root. Required sections:

1. YAML frontmatter: repo, version, last_updated, owner
2. "Purpose" section: 3-4 sentences explaining what critical paths are for this repo
3. "Inventory" table: id | name | start_url | owner | test_path | status
4. "Seeded paths" section: per-path expanded entry with actions + success signal

Valid status values: "implemented" | "missing-test" | "blocked"

A path is only "implemented" when the spec file at test_path exists and passes. Marking "implemented" without a passing spec is a false declaration.

## Runner

Each repo must have a runner that:
- Parses CRITICAL-PATHS.md
- Runs all "implemented" specs via Playwright
- Reports "missing-test" and "blocked" entries as COVERAGE FAILURES
- Exits non-zero if any path fails or has no test
- Is wired to `npm run test:critical-paths` (or equivalent)

## Anti-patterns

- Declaring a path "covered" by tests that only test a fragment (entry point only, API only, DOM only)
- Adding an inventory entry without writing the accompanying spec
- Marking a path "implemented" when the spec file does not exist
- Using page.route() to substitute the API response -- this is a unit test in disguise and cannot catch the class of failure critical paths exist to prevent
- Writing a critical path test against a mock server or test environment instead of production

## When to add a new entry

Add a new CRITICAL-PATHS.md entry when:
- A new product feature has a distinct customer entry point (new page, new form, new conversion flow)
- A new integration is added to an existing journey (payment processor, email, webhook)
- An incident or near-miss reveals an untested journey segment

Write the spec in the same PR that adds the feature. The inventory entry and the spec land together. Never add an inventory entry as "missing-test" as a permanent state -- missing-test is a temporary blocker flag, not a long-term parking state.

## Sibling rules

- `smoke-real-browser-before-done.md` -- per-feature browser smoke before marking a feature done (pre-release dev discipline)
- `testing-critical-path.md` -- general discipline: test the critical path, not just the happy path
