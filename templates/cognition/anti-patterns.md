---
type: rule
scope: public
purpose: Catalog of learned anti-patterns agents must avoid -- high-severity constraints covering secrets, search rigor, pipeline verification, and E2E testing; skipping causes repeated behavioral failures that cost owner time and credibility.
read_when: When friction detection fires, a correction is received, or before proposing a new approach that matches any listed trigger condition.
last_evaluated: 2026-06-03
---

# Anti-Patterns (Learned Constraints)

This file is seeded with universal lessons. Add your own. Remove any that do not apply.
Over time, /learn (or equivalent session-learning tooling) proposes new entries from
corrections made during sessions.

## Anti-Patterns

| Anti-Pattern | Severity | Scope | Trigger |
|-------------|----------|-------|---------|
| Never put secrets in documentation -- reference secret store location only | high | All repos | Writing docs, README, setup guides |
| Never use private/non-routable IPs in external-facing configs (OAuth redirects, webhooks, callbacks) | high | All repos | Configuring OAuth, webhooks, DNS |
| Never claim a pipeline or workflow is done without triggering it end-to-end and verifying final output | high | All repos | Completing automation, CI/CD, workflow tasks |
| E2E tests must verify what the user actually sees (rendered output), not just DOM attributes or HTTP status | high | Frontend repos | Writing e2e or integration tests |
| Autonomous execution agents must be scoped to one repo -- cross-repo writes cause unexpected failures | medium | Multi-repo workspaces | Configuring automated sprints, agents |
| LLM API responses often wrap JSON in markdown fences -- always strip before parsing | medium | Any LLM integration | Parsing LLM API responses |
| Do not re-verify configs that already passed -- trust until failure, then investigate | low | All repos | Session start, repeated health checks |
| Never claim something is missing without multi-pattern search evidence (grep multiple folders, check inline definitions, read actual content) | high | All repos | Reporting missing files, functions, or configs |
| Never state external UI navigation paths as fact -- UIs change layouts frequently, cached knowledge is unreliable | medium | All repos | Giving instructions for web UIs (admin portals, cloud consoles, etc.) |
| Never present file paths to user without verifying they exist first | medium | All repos | Answering "where is X" questions, presenting references |

## Format for New Entries

| Anti-Pattern | Severity | Scope | Trigger |
|-------------|----------|-------|---------|
| [What went wrong -- state the rule, not the story] | high/medium/low | [Which repos/contexts] | [What triggers the check] |
