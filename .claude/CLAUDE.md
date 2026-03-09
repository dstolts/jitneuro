# DOE Framework - jitneuro - Guardrails

## Identity
This project operates under the DOE framework (Directive Orchestration Execution).
See project passport in root CLAUDE.md for what this project IS.
See D:\Code\Automation\Projects\Orchestration\DOE-Framework-Spec-04.md for full DOE spec.

## Trust Zones
| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze, research | Execute freely |
| YELLOW | Schema changes, new dependencies, API contracts, .env writes | Execute, report at checkpoint |
| RED | Push to main, production deploy, delete files/branches, DB migrations | Stop and ask Dan |

## Quality Standards
- ASCII only (no emojis, no special characters)
- Fix root cause (never skip, disable, or bypass functionality)
- Push to main requires Dan's explicit permission. Commit local and push to uat freely.
- For-profit business context (consider ROI, cost, time, value)

## Context Loading
- Read root CLAUDE.md for project identity and key paths
- Read D:\Code\.claude\engrams\jitneuro-context.md for deeper detail
- Read brain (MEMORY.md) for cross-project business context
