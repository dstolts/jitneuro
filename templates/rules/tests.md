---
paths:
  - "tests/**"
  - "**/*.test.*"
  - "**/*.spec.*"
  - "__tests__/**"
---

# Testing Rules (Only loaded when working with test files)

<!--
  This rule file only loads into context when Claude is working with
  files matching the paths above. This is automatic path-scoped loading --
  a lightweight alternative to bundles for rules that are file-type specific.

  Use rules/ for: coding standards, linting preferences, file-type conventions
  Use bundles/ for: domain knowledge, architecture, commands, workflows
-->

- Test behavior, not implementation
- One assertion concept per test (multiple asserts OK if testing same behavior)
- Name tests: "should [expected behavior] when [condition]"
- No test should depend on another test's state
- Mock external services, never hit real APIs in unit tests
- Include both happy path and error cases
- Clean up test fixtures after each test
