# Trust Zones

Structured permission model for AI actions. Customize zones per team.

| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze, research | Execute freely |
| YELLOW | Schema changes, new dependencies, API contracts, .env writes | Execute, report at checkpoint |
| RED | Push to main, production deploy, delete files/branches, DB migrations | Stop and ask user |

## Git

Commit local and push to feature branches freely.
Push to main requires explicit user permission.

## Customization

Adjust zones per your risk tolerance:
- Solo developer: might move "push to main" to YELLOW
- Enterprise team: might move "new dependencies" to RED
- CI/CD pipeline: might add "deploy to staging" as GREEN, "deploy to production" as RED
