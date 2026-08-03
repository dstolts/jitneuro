---
type: reference
purpose: Template for creating per-project engram files with canonical sections and size guidance.
tags: [engram, template, per-project, context, memory]
scope: internal
status: canonical
graduation_target: templates/engrams/example.md
read_when: Before authoring a new per-project engram file to apply the canonical sections and stay within the 150-line target.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# [Project Name] -- Engram

**Last Updated:** [date]
**Line count:** [N] / 150 target

## Identity

What this project IS in one paragraph. Purpose, audience, business context.

- **Repo:** github.com/org/repo
- **Phase:** [Active Development / Maintenance / Deprecated]
- **Version:** v[X.Y.Z]
- **Stack:** [Language / Framework / Runtime]

## Architecture

Key architectural decisions and patterns. What makes this project's structure unique.

```
src/
  routes/     -- Express route handlers
  services/   -- Business logic
  models/     -- DB models
  utils/      -- Shared helpers
```

## Key Files

| File | Purpose |
|------|---------|
| src/server.ts | Express app entry + middleware |
| src/routes/index.ts | Route registration |
| .env.example | Required environment variables |
| docs/ARCHITECTURE.md | Deeper architecture docs |

## Conventions

- [Convention 1, e.g., "All API responses use { data, error } envelope"]
- [Convention 2]
- [Convention 3]

## Integrations

| Service | Purpose | Auth method |
|---------|---------|------------|
| Stripe | Payments | API key in .env |
| Resend | Email | API key in .env |

## Gotchas

- [Known pitfall 1, e.g., "SQL Server requires GO between DDL and DML"]
- [Known pitfall 2]

## History

Key decisions that shaped the current architecture. Useful for understanding WHY, not just WHAT.

- [Date]: [Decision and reason]
- [Date]: [Migration or major change]

---

*Size target: 50-150 lines. Update via /learn at sprint completion or on architecture change.*
