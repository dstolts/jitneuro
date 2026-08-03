---
type: reference
purpose: Template for creating domain knowledge bundles -- self-contained, under 180 lines, loaded on-demand.
tags: [bundle, template, domain-knowledge, context, memory]
scope: internal
status: canonical
graduation_target: templates/bundles/example.md
read_when: Before creating a new domain knowledge bundle to ensure it follows the canonical structure and line-count guidance.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# [Domain Name] Bundle

**Last Updated:** [date]
**Line count:** [N] / 180 target

## What This Covers

2-3 sentences describing the domain this bundle serves. When would an agent load this bundle?

## Key Files

| File | Purpose |
|------|---------|
| path/to/file.ts | [What this file does] |
| path/to/config.json | [What this config controls] |

## Conventions

- [Convention 1, e.g., "All DB queries go through the service layer, never directly from routes"]
- [Convention 2]
- [Convention 3]

## Commands

Relevant slash commands for this domain:
- `/bundle [name]` -- reload this bundle
- `/audit` -- check for hygiene issues in this area

## Architecture Decisions

Key decisions that affect work in this domain:

- **[Decision 1]:** [Rationale] (chosen over [alternative] because [reason])
- **[Decision 2]:** [Rationale]

## Common Patterns

```typescript
// Pattern 1: [Name]
// [Brief explanation]
const example = doSomething({ key: value });
```

```bash
# Pattern 2: [Name]
command --with-flags
```

## Gotchas

- [Pitfall 1, e.g., "Stripe webhooks must validate signature before processing -- never skip"]
- [Pitfall 2]
- [Pitfall 3]

---

*Size target: under 180 lines. Split if approaching 280 lines. Update via /learn.*
