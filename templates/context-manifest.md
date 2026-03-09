# Context Manifest

This file indexes all available context bundles and tracks session state.
The orchestrator reads this to determine which bundles to load for a given task.

## Always Load (Brainstem)
These load automatically at session start via CLAUDE.md:
- `~/.claude/CLAUDE.md` (global rules)
- `.claude/CLAUDE.md` (project rules)
- `MEMORY.md` (first 200 lines -- routing weights)

## Available Bundles

| Bundle | Path | Domain | Lines | Last Used |
|--------|------|--------|-------|-----------|
| example | .claude/bundles/example.md | Example template | ~30 | never |

<!-- Add your bundles here. Keep under 80 lines each. -->
<!-- Example entries:
| deploy    | .claude/bundles/deploy.md    | CI/CD, containers, environments | ~60 | 2026-03-09 |
| api       | .claude/bundles/api.md       | API design, auth, error handling | ~50 | 2026-03-09 |
| sprint    | .claude/bundles/sprint.md    | Sprint protocol, task format     | ~70 | 2026-03-08 |
| testing   | .claude/bundles/testing.md   | Test strategy, commands, fixtures | ~40 | 2026-03-07 |
-->

## Routing Weights

Patterns that map task types to bundle combinations.
Update these as you learn which bundles co-activate:

```
- Default task         -> bundles: []  (brainstem only)
<!-- Example routing weights:
- Deploy tasks         -> bundles: [deploy, infra]
- API development      -> bundles: [api, testing]
- Sprint execution     -> bundles: [sprint, cross-repo]
- Bug investigation    -> bundles: [api, testing, deploy]
- Documentation        -> bundles: []  (brainstem sufficient)
-->
```

## Session State

Updated by /checkpoint skill. Read by /resume skill after /clear.

```
active_bundles: []
current_task: none
modified_files: []
pending_decisions: []
next_steps: []
key_findings: []
```
