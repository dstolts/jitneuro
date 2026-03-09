---
paths:
  - "src/api/**/*.ts"
  - "src/routes/**/*.ts"
---

# API Rules (Only loaded when working with API files)

<!--
  This rule file only loads into context when Claude is working with
  files matching the paths above. This is automatic path-scoped loading --
  a lightweight alternative to bundles for rules that are file-type specific.

  Use rules/ for: coding standards, linting preferences, file-type conventions
  Use bundles/ for: domain knowledge, architecture, commands, workflows
-->

- All API routes must validate input before processing
- Return consistent error format: { error: string, code: number }
- Use middleware for auth checks, never inline
- Log all mutations to audit trail
