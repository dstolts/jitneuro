---
type: rule
purpose: BINDING for every QA and E2E-test-authoring agent -- each test MUST assert the real customer outcome (data persisted in DB, correct content rendered in DOM, UX indicators present) against the real deployed environment with no mocks; skipping means mechanism-only tests stay green while customer-facing breakage ships undetected.
trigger: any agent writing, reviewing, or declaring PASS on an E2E or Playwright test for a customer-facing flow
read_when: Before writing, reviewing, or declaring PASS on any E2E or Playwright test for a customer-facing flow.
tags: [testing, e2e, quality, customer-outcome, playwright]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_e2e_tests_validate_user_outcome_not_checklist.md) -- Knowledge session 2026-06-01
---

# E2E Tests Validate User Outcome

## Rule

Every E2E test must validate the outcome the customer actually experiences, not the mechanism by which it was triggered. The four required dimensions:

1. **Data saved** -- PUT/POST -> read back from the real DB -> value persisted and correct.
2. **Data returned** -- response / SSE `data` field has substantial, correct content (assert length + shape + sample), not just that an event or 200 occurred.
3. **It looks correct** -- content renders in the DOM as the customer would see it (not a no-data fallback, not an empty container header).
4. **UX is good** -- progress/loading states present, ordering sensible, counters and indicators visible, no silent failures.

Drive the real customer surface: real browser, real network, real deployed environment. No mocks, no route-substitution, no API-bypass shortcuts for the path under test. A test that bypasses the network path it claims to validate is a unit test in disguise and does not count as E2E coverage.

Any existing test not meeting this bar must be redone. `test.fixme()`, skipped tests, and envelope-only assertions are coverage failures, not coverage.

## Why

- Mechanism-only tests (asserting an SSE envelope fired, or that a 200 was returned) let real customer-facing breakage ship while tests stay green.
- "Green" is not "done." Done means the customer outcome is verified.
- Tests that check the envelope but abort before reading the `data` field cannot detect empty content, malformed responses, or UX failures.

## What violates this rule

- Asserting an SSE event type or envelope without reading and validating the `data` field content.
- A PUT test that does not read the value back from the real DB to confirm persistence.
- A render test that uses `page.route()` to substitute the API response -- the network path is bypassed.
- Reporting a test as "PASS" when the assertion only confirms a mechanism ran, not that the customer got the right result.

## Origin

2026-06-01 -- a streaming-feature incident: multiple "PASS" verdicts asserted only that SSE envelopes fired, and aborted before reading the data. Real session: the feature showed a header + badge with no content, settings saves returned 500, the action double-charged quota, and the counter never rendered. None of it was caught by the tests. The lesson: the point of e2e testing is to see what the user sees, not to check something off a list.
