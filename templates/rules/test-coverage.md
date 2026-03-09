---
paths:
  - "tests/**"
  - "**/*.test.*"
  - "**/*.spec.*"
  - "__tests__/**"
  - "jest.config.*"
  - "vitest.config.*"
  - ".nycrc*"
---

# Test Coverage Rules (Project-Level Override)

<!--
  LAYERED RULES EXAMPLE:

  This file demonstrates the "Rule of Lowest Context" for test coverage.
  Coverage requirements vary by project -- a payment API needs higher
  coverage than a marketing site. Instead of one-size-fits-all in CLAUDE.md,
  layer the rules:

  LEVEL 1 - Global CLAUDE.md (brainstem):
    "All projects must have tests. Minimum 60% coverage."

  LEVEL 2 - Project .claude/rules/test-coverage.md (this file):
    Override the global minimum for this specific project.
    Only loads when working on test files.

  LEVEL 3 - Bundle (optional):
    Domain-specific testing patterns (e.g., "API tests must include
    auth token expiry scenarios") loaded on demand.

  HOW TO USE:
  1. Set your global minimum in CLAUDE.md (applies to all repos)
  2. Copy this file to .claude/rules/ in repos that need different thresholds
  3. Edit the coverage targets below for that project
  4. Claude sees the project rule when working on tests, global rule otherwise

  WHY THIS MATTERS:
  Without layering, you either set coverage too low (miss bugs in critical
  services) or too high (waste time on throwaway scripts). Layering lets
  each project define what "good enough" means.
-->

## Coverage Targets (edit per project)

| Metric | Minimum | Target | Notes |
|--------|---------|--------|-------|
| Line coverage | 80% | 90% | Adjust based on project criticality |
| Branch coverage | 70% | 85% | Critical for payment/auth code |
| Function coverage | 85% | 95% | Every exported function should be tested |
| Uncovered lines | < 50 | < 20 | Absolute cap on untested lines |

## Rules

- New code must meet or exceed the Target column
- Existing code must meet or exceed the Minimum column
- Never reduce coverage to merge a PR
- Coverage exceptions must be documented with a comment explaining why
- Critical paths (auth, payments, data mutations) require 95%+ regardless of project minimum
- Run coverage check before every commit (integrate with pre-commit hook or CI)
- Coverage reports should be human-readable (not just a number -- show uncovered lines)

## Example: Global vs Project Override

Global CLAUDE.md (all repos):
  "Tests required. Minimum 60% line coverage."

Project A (.claude/rules/test-coverage.md) -- payment API:
  Line: 80% min, 90% target
  Branch: 70% min, 85% target

Project B (.claude/rules/test-coverage.md) -- marketing site:
  Line: 40% min, 60% target
  Branch: not required

Project C (no override) -- uses global 60% default
