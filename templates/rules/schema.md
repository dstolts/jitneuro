---
paths:
  - "schema/**"
  - "migrations/**"
  - "*.sql"
---

# Schema & Migration Rules (Only loaded when working with database files)

<!--
  This rule file only loads into context when Claude is working with
  files matching the paths above. This is automatic path-scoped loading --
  a lightweight alternative to bundles for rules that are file-type specific.

  Use rules/ for: coding standards, linting preferences, file-type conventions
  Use bundles/ for: domain knowledge, architecture, commands, workflows
-->

- Always check for existing table/column before CREATE
- Include rollback script for every migration
- Use consistent naming: snake_case for tables/columns
- Never DROP TABLE without explicit backup confirmation
- Add comments to complex constraints and indexes
- Test migrations against dev before staging/prod
- Document breaking changes in migration commit message
