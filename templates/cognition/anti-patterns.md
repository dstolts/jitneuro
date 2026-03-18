# Anti-Patterns (Learned Constraints)

This file is built over time by /learn. When the owner corrects a mistake,
/learn proposes an anti-pattern entry so the same mistake is never repeated.

Seeded with universal lessons. Add your own. Remove any that don't apply.
Over time, /learn proposes new entries from your corrections.

## Anti-Patterns

| Anti-Pattern | Severity | Scope | Trigger |
|-------------|----------|-------|---------|
| Never put secrets in documentation -- reference secret store location only | high | All repos | Writing docs, README, setup guides |
| Never use private/non-routable IPs in external-facing configs (OAuth redirects, webhooks, callbacks) | high | All repos | Configuring OAuth, webhooks, DNS |
| Never claim a pipeline or workflow is done without triggering it e2e and verifying final output | high | All repos | Completing automation, CI/CD, workflow tasks |
| E2E tests must verify what the user actually sees (rendered output), not just DOM attributes or HTTP status | high | Frontend repos | Writing e2e or integration tests |
| Autonomous execution agents must be scoped to one repo -- cross-repo writes cause sandbox failures | medium | Multi-repo workspaces | Configuring automated sprints, agents |
| LLM API responses often wrap JSON in markdown fences -- always strip before parsing | medium | Any LLM integration | Parsing LLM API responses |
| Do not re-verify configs that already passed -- trust until failure, then investigate | low | All repos | Session start, repeated health checks |
| Never claim something is missing without multi-pattern search evidence (grep multiple folders, check inline definitions, read actual content) | high | All repos | Reporting missing files, functions, or configs |
| Never state external UI navigation paths as fact -- UIs change layouts frequently, cached knowledge is unreliable | medium | All repos | Giving instructions for web UIs (Azure Portal, LinkedIn, etc.) |
| Never present file paths to user without verifying they exist first | medium | All repos | Answering "where is X" questions, presenting references |

## Format for New Entries

| Anti-Pattern | Severity | Scope | Trigger |
|-------------|----------|-------|---------|
| [What went wrong -- state the rule, not the story] | high/medium/low | [Which repos/contexts] | [What triggers the check] |
