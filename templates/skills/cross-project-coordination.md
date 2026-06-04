---
type: skill
purpose: 'BINDING cross-repo contract discipline -- whenever a change touches an API endpoint signature, shared data model, event payload, or auth interface that ANOTHER repo CONSUMES (most common pattern: an API repo route change that an App repo calls), the contract MUST be written FIRST and both sides MUST ship paired PRs in the same sprint. Any agent about to modify a route handler, response schema, payload shape, status-code, or auth interface MUST consult this skill AND the integration map BEFORE writing code, or backend and frontend ship divergent versions and the mismatch is discovered during integration testing after both sides claim "complete".'
tags: [skill, cross-repo, api-contract, coordination, integration, api-app-pattern, schema-coupling, pre-code, dispatch-rule]
scope: public
read_when: Before modifying any API endpoint, shared data model, event payload, or auth interface that another repo consumes.
last_evaluated: 2026-06-03
---

# Cross-Project Coordination

When a change touches two repos that integrate, define the API contract first. Both sides implement to the same contract. If the contract changes, both sides update in the same sprint.

## When to Apply

Any time a change modifies:
- An API endpoint signature (path, method, request shape, response shape, status codes)
- A shared data model or schema used by multiple repos
- An event payload or webhook format
- An authentication or authorization interface

## Core Process

1. **Before writing any code:** write the contract. The contract is the API spec: endpoint path, HTTP method, request payload schema, response schema, error codes.
2. **Share the contract with both sides.** Backend implements to it. Frontend consumes it. Neither side starts coding until both have read and acknowledged the contract.
3. **Open both PRs in the same sprint.** A backend PR that changes a contract endpoint must be paired with a frontend PR that updates the consumer. They are reviewed and merged together.
4. **If the contract changes mid-sprint:** update the spec first, then notify both sides. Do not patch one side and leave the other on the old contract.
5. **Check the MEMORY.md integration map** before assuming which repos connect to which. The integration map is the authoritative source.

## Contract Change Notification

When an API contract changes, downstream consumers must be notified immediately. Do not wait until the sprint ends. Notification goes to: the implementing agent, the consuming agent, and sys-architect.

## What to Avoid

- Starting backend implementation before the contract is written
- Merging a contract-breaking PR without a linked consumer PR
- Assuming "it's a small change" exempts from contract parity
- Discovering the mismatch during integration testing after both sides are complete

## Integration

Used by: architect, backend, frontend, orchestrator, and repo-steward roles
