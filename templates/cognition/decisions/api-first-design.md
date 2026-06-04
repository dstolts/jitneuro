---
type: rule
scope: public
purpose: Decision model requiring all platforms to be fully API-manageable before adoption -- agents use this to evaluate new tools and reject GUI-only workflows that block automation; skipping allows GUI-locked platforms that break agent pipelines.
read_when: Before selecting or evaluating any new platform, service, or tool that agents or automation will need to operate.
last_evaluated: 2026-06-03
---

# Decision Model: API-First Platform Design

When choosing how to build or integrate with a platform, evaluate API-first.

## Principle

All platforms must be fully manageable via API. Never depend on a GUI for operations that
AI agents or automation need to perform. If the only way to do something is click a button
in a web UI, the platform is not ready for AI-assisted workflows.

## Evaluation Process

1. **List the operations** -- what does the agent need to do? (create, read, update, delete, configure)
2. **Check API coverage** -- does the platform's API support ALL of those operations?
3. **Identify GUI-only gaps** -- which operations require manual UI interaction?
4. **Assess gap severity** -- is the GUI-only operation a one-time setup or a daily task?
5. **Decide:**
   - All ops have API coverage -> proceed
   - Daily ops are GUI-only -> find alternative platform or build a wrapper
   - One-time setup is GUI-only -> acceptable, document the manual step

## Rules

- If an operation is needed more than once, it MUST have an API path
- Document every GUI-only step as a known limitation with a remediation plan
- When evaluating new tools/services, API completeness is a selection criteria
- Prefer platforms with webhook/event support for reactive automation
