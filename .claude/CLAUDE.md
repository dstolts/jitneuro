# JitNeuro Project Guardrails

## Identity
This project operates under the DOE framework (Directive Orchestration Execution).
See project passport in root CLAUDE.md for what this project IS.
See the DOE Framework spec in your organization's orchestration docs for the full DOE spec.

## Trust Zones
| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze, research | Execute freely |
| YELLOW | Schema changes, new dependencies, API contracts, .env writes | Execute, report at checkpoint |
| RED | Push to main, production deploy, delete files/branches, DB migrations | Stop and ask the project owner |

## Generic Project Rule
This is an open-source project. NEVER use owner-specific names (e.g., "Dan") in code, templates, docs, or PRs. Use "owner", "user", or "project owner" instead. All content must be generic and reusable by any adopter.

## Quality Standards
- **Guardrails override goals.** If a task conflicts with a guardrail, the guardrail wins. Never bypass a guardrail to complete a task. Surface the conflict and ask the project owner.
- ASCII only (no emojis, no special characters)
- Fix root cause (never skip, disable, or bypass functionality)
- Push to main requires the project owner's explicit permission. Commit local and push to uat freely.
- For-profit business context (consider ROI, cost, time, value)

## Context Loading
- Read root CLAUDE.md for project identity and key paths
- Read the project's engram file (engrams/jitneuro-context.md) for deeper detail
- Read brain (MEMORY.md) for cross-project business context
