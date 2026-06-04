---
type: pattern
purpose: Post-deploy verification rule requiring Playwright VISIBLE+ACTIONABLE check after every UI app push; read when setting up deployment automation or determining what counts as a successful deploy.
read_when: Before declaring a UI app deploy complete or when setting up post-deploy verification in a deployment pipeline.
tags: [deployment, playwright, verification, trust-ratchet]
scope: public
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# UI App Push Verification

**Used by:** Engineering Lead, QA Lead, DevOps/SRE Lead
**Purpose:** Post-deploy verification rule for UI app pushes. A deploy is not "done" until
the change is confirmed VISIBLE and ACTIONABLE in the running UI -- not just deploy SUCCESS.

---

## Purpose

UI app deploys can fail silently. Build succeeds, deploy pipeline reports green, but the
change is not visible -- cache serving stale, route mismatch, server-side rendering error, or
hydration failure. Until confidence in push reliability is established, every push requires
verification that the change actually rendered correctly and works as designed.

This rule closes the gap between "deploy succeeded" and "the owner can act on this." Deploy
success is necessary but not sufficient.

---

## Rule (binding until trust ratchet promotes)

After any push to the UI app:

1. Agent runs Playwright (or equivalent: curl-with-DOM-check, screenshot-diff, real-browser smoke)
   against the live app URL.
2. Verification must confirm TWO conditions:
   - **Visible:** DOM contains the expected element, content, or state change
   - **Actionable:** clicking or interacting with the element triggers the expected behavior;
     forms submit; data flows; no console errors on interaction
3. "Done" state requires Playwright PASS. Deploy SUCCESS alone does not qualify.
4. Log result to `ui-app-push-verification.log` (per audit pattern).

See `rules/smoke-real-browser-before-done.md` -- this pattern applies the same
discipline to UI app deploys specifically.

---

## Trust Ratchet

| Tier | Condition | Verification requirement |
|---|---|---|
| T3 (current) | Low confidence; establishing baseline | Playwright on EVERY push; failure blocks "done" |
| T2 | After 10 successful pushes with passing verification | Proposal + 60-min owner veto; Playwright on flagged or high-risk pushes |
| T1 | After 15 more pushes without failure at T2 | Decide-and-log; spot-check Playwright weekly |

Promotion from T3 to T2 requires: 10 consecutive verified pushes, no silent failures, QA Lead
signs off. Update this file when tier promotes.

---

## Failure Handling

- Playwright fails: revert the push OR flag as known-broken with a GitHub issue in the app
  repo containing: reproduction steps, failure screenshot or DOM snapshot, expected vs actual.
- 3 consecutive Playwright failures across different pushes: halt push automation; surface
  to the owner before the next push attempt.
- Verification log: append one line per push to `ui-app-push-verification.log`:
  ```
  2026-05-06T14:32:00Z | push: <commit-sha> | result: PASS | element: <selector> | action: <what-was-verified>
  2026-05-06T14:32:00Z | push: <commit-sha> | result: FAIL | reason: <DOM snapshot note> | action: revert
  ```

---

## Verification Scope

What counts as VISIBLE + ACTIONABLE:

| Verification type | Sufficient for "done" |
|---|---|
| HTTP 200 on app URL | No -- necessary but not sufficient |
| Build pipeline reports success | No -- necessary but not sufficient |
| DOM contains new element (`page.locator('...')`) | Visible only; need actionable check too |
| DOM check + click triggers expected state change | Yes -- both conditions met |
| Form submits and data flows to backend | Yes -- full critical path |

Use Playwright selectors that are stable (aria roles, data-testid, text content) not CSS classes.
Avoid `[class*=...]` patterns; prefer `h3:has-text("...")` or `button:has-text("...")`.

---

## Cross-References

- `rules/smoke-real-browser-before-done.md` -- general rule this pattern extends
- `rules/critical-paths-defined-and-tested.md` -- critical paths discipline
- `_patterns/validation-gates.md` -- 4-layer validation chain; deploy verification is layer 1
- `_patterns/autonomous-execution-with-validators.md` -- agent-validators pattern
