# Team Context Manifest

This file indexes team-shared bundles and routing weights.
The orchestrator reads this to determine which bundles to load for a given task.

## Always Load (Team Baseline)

These load automatically for every team member:
- `.jitneuro/rules/` (team rules)
- `.jitneuro/engrams/` (team project context)
- `.jitneuro/cognition/` (team personas, decisions)

## Available Bundles

| Bundle | Path | Domain | Lines | Last Updated |
|--------|------|--------|-------|-------------|
<!-- Add team bundles here. Keep under 280 lines each. -->
<!-- Example:
| deploy    | .jitneuro/bundles/deploy.md    | CI/CD, containers, environments | ~60 | 2026-01-01 |
| api       | .jitneuro/bundles/api.md       | API design, auth, error handling | ~50 | 2026-01-01 |
| sprint    | .jitneuro/bundles/sprint.md    | Sprint protocol, task format     | ~70 | 2026-01-01 |
-->

## Routing Weights

Patterns that map task types to bundle combinations.
Update these as the team learns which bundles co-activate:

```
- Default task         -> bundles: []  (team baseline only)
<!-- Example routing weights:
- Deploy tasks         -> bundles: [deploy]
- API development      -> bundles: [api, testing]
- Sprint execution     -> bundles: [sprint]
- Bug investigation    -> bundles: [api, testing, deploy]
-->
```
