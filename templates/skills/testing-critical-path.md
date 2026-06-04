---
type: skill
purpose: Defines the process for identifying and testing every segment of the customer journey end-to-end (not just entry and exit points), including setup of CRITICAL-PATHS.md inventory and the Playwright runner. Read this when setting up critical-path testing in a new repo or when declaring a customer-facing PR test-complete.
tags: [skill, testing, critical-path, playwright, e2e]
scope: public
read_when: Before marking any customer-facing PR test-complete or setting up critical-path testing in a new repo.
last_evaluated: 2026-06-03
---

# Testing Critical Path

Test the path every user hits every time. Happy-path testing validates the easiest scenario and misses real production failures.

## When to Apply

Mandatory before any customer-facing PR is test-complete. Every critical journey must have an executable Playwright spec. A missing or blocked test is a coverage failure that blocks release.

## Core Process

1. **Define the critical path first.** What is the sequence of steps every user traverses? Entry point -> processing -> delivery mechanism -> result.
2. **Map every segment.** Do not only test start and end. Identify every intermediate step: auth check, DB query, stream open, webhook fire, cache read.
3. **Write a test for each segment.** If a delivery mechanism (SSE, websocket, polling) is part of the path, it needs its own test. Not just "did the result arrive" -- "did the delivery mechanism work."
4. **Verify tests fail before they pass.** A test that always passes is not a test.
5. **Document the path** in the test file as a comment so future contributors know what is being protected.

## Setting Up in a New Repo

### 1. Create CRITICAL-PATHS.md inventory

See `rules/critical-paths-defined-and-tested.md` for the full format. At minimum:

```yaml
---
repo: your-repo-name
version: 0.1
last_updated: YYYY-MM-DD
owner: team-name
---

# Critical Paths -- your-repo-name

## Purpose
[3-4 sentences explaining why critical paths matter for this repo]

## Inventory

| id | name | start_url | owner | test_path | status |
|----|------|-----------|-------|-----------|--------|
| cp-01 | Free scan discovery | https://example.com | team | e2e/critical-paths/cp-01-scan-discovery.spec.ts | implemented |
| cp-02 | Paid upgrade | https://example.com | team | e2e/critical-paths/cp-02-paid-upgrade.spec.ts | missing-test |
```

Valid status: `implemented` (test exists and passes), `missing-test` (temporary placeholder), `blocked` (known blocker documented below).

### 2. Wire the runner

Reference implementation: a `runner.mjs` that parses CRITICAL-PATHS.md and runs each implemented spec.

The runner:
- Parses CRITICAL-PATHS.md
- Runs all implemented specs via Playwright
- Reports missing-test and blocked entries as coverage failures
- Exits non-zero if any path fails or has no test

Wire to npm script in package.json:

```json
{
  "scripts": {
    "test:critical-paths": "node e2e/critical-paths/runner.mjs"
  }
}
```

For non-Node repos, adapt the pattern to your language: read CRITICAL-PATHS.md, loop specs, report results, exit non-zero on failures.

### 3. Acceptance Checklist

Before declaring the setup complete, confirm:

- [ ] CRITICAL-PATHS.md exists at repo root with valid YAML frontmatter
- [ ] At least one path is `implemented` (no "all missing-test" repos)
- [ ] Runner script exists and runs without config errors
- [ ] `npm run test:critical-paths` (or equivalent) invokes the runner
- [ ] CI runs the critical-paths gate on PRs to the default branch
- [ ] Each implemented path has a corresponding .spec.ts file that actually runs

### 4. Write Your Specs

Each spec:
- Runs against real production infrastructure (no page.route() mocks, no stubbed API calls)
- Performs actions a real customer would perform
- Asserts the customer's expected outcome (DOM element, network response, DB side-effect)
- Includes a comment at the top documenting the critical path

Reference: a `cp-NN-*.spec.ts` spec file, one per critical path, named for the journey it covers.

## Anti-Pattern

```
[trigger] --> ... untested middle ... --> [result check]
```
Tests pass. Bug ships in the middle. Users hit it. Nobody saw it coming.

## Correct Pattern

```
[trigger] --> [auth/input] --> [processing] --> [delivery] --> [result check]
```

## What to Avoid

- Writing only "happy path" tests (valid input, no errors)
- Skipping delivery mechanism tests because "we only need to check the output"
- Marking a PR test-complete when only entry and exit are covered
- Writing tests that mock the component they are supposed to test
- Marking a path `implemented` without writing the accompanying spec
- Adding all paths as `missing-test` as a permanent state (missing-test is temporary)

## Integration

Used by: sys-qa, sys-backend, sys-frontend, sys-sre, code-reviewer, security-engineer
