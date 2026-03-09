---
paths:
  - "src/components/**"
  - "components/**"
  - "app/components/**"
---

# UI Component Rules (Only loaded when working with component files)

<!--
  This rule file only loads into context when Claude is working with
  files matching the paths above. This is automatic path-scoped loading --
  a lightweight alternative to bundles for rules that are file-type specific.

  Use rules/ for: coding standards, linting preferences, file-type conventions
  Use bundles/ for: domain knowledge, architecture, commands, workflows
-->

- Components must be self-contained (own styles, types, tests)
- Props interface defined and exported for every component
- No direct API calls in components (use hooks or services)
- Accessibility: all interactive elements need aria labels
- Loading and error states required for async components
- Keep components under 200 lines (split if larger)
