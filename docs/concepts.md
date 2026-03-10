# JitNeuro Key Concepts

## Context Bundles

Self-contained knowledge files (50-80 lines max) covering one domain. Examples:
- `deploy.md` -- deployment pipeline, container commands, environments
- `api-design.md` -- API conventions, auth patterns, error handling
- `sprint.md` -- sprint protocol, task format, commit conventions

Bundles live in `.claude/bundles/` and are loaded **only when needed** by the
orchestrator or manually via "Read .claude/bundles/X.md".

## Engrams

Per-project deep context files. One file per project or repository.

In neuroscience, an engram is the physical trace a memory leaves in the brain --
the compressed representation of an experience. Each project's engram is exactly
that: not the codebase itself, but the compressed knowledge about it.

Engrams live in `.claude/engrams/` and are updated by `/learn`:
- `my-api.md` -- tech stack, key files, architecture, integrations, gotchas
- `my-frontend.md` -- framework setup, build config, deploy pipeline, known issues

Bundles and engrams are orthogonal:
- **Bundles** cut across projects by domain ("how to deploy")
- **Engrams** cut across domains by project ("everything about this repo")

## Routing Weights

Patterns in MEMORY.md that map task types to bundle combinations:
```
- Deploy tasks -> bundles: [deploy, infra]
- API work -> bundles: [api-design, testing]
- Sprint execution -> bundles: [sprint, cross-repo]
```
These improve over time as the system learns which bundles co-activate.

## Conversation Logging

Optional toggle that records every prompt and response to a daily log file:
- **Prompt-first:** User prompt is logged BEFORE any work starts (no data loss)
- **Response-after:** Concise summary appended after work completes
- **Daily files:** One file per day, append-only, sequential prompt numbering
- **Survives /clear:** Logs are on disk, not in context. Resume picks up logging state.
- **Gitignored by default:** `.logs/` excluded from commits (may contain sensitive prompts)

```
convlog on my-project    <-- enable with session name
convlog off              <-- disable
convlog status           <-- check current state
```

See [conversation-log.md](../templates/commands/conversation-log.md) for full spec.

## Compact Instructions

A section in CLAUDE.md that controls what auto-compaction preserves:
```markdown
# Compact Instructions
When compacting, always preserve:
- Active bundle list
- Modified file paths
- Full task list with status (all known tasks, not just current)
- Pending decisions
```
This fires automatically when context fills -- no user action needed.

## Rule of Lowest Context

The most important design principle in JitNeuro: **store context at the lowest level possible.**

Don't put everything in CLAUDE.md. A 500-line CLAUDE.md loads every session, wastes tokens
on irrelevant rules, and gets compressed away. Instead, push rules down to where they apply:

```
CLAUDE.md (brainstem, 30-40 lines)    -- universal rules only
  .claude/rules/schema.md              -- loads only for schema/**
  .claude/rules/api.md                 -- loads only for src/api/**
  .claude/rules/tests.md               -- loads only for tests/**
  .claude/rules/deployment.md          -- loads only for deploy/**, Dockerfile, .github/workflows/**
  .claude/bundles/deploy.md            -- loads on demand by orchestrator
  .claude/engrams/repo.md              -- loads on demand per project
  MEMORY.md                            -- routing weights (first 200 lines)
```

Each level only loads when relevant:
- **Rules** load automatically when Claude touches matching file paths (zero cost when not needed)
- **Bundles** load on demand when routing weights match the task
- **Engrams** load on demand when working on a specific project
- **CLAUDE.md** loads every session (keep it minimal)

This pattern scales across many repos without context bloat.

### Example: Layered Test Coverage

Rules can layer -- a global default in CLAUDE.md, overridden per project:

```
Global CLAUDE.md:        "Tests required. Minimum 60% line coverage."
Payment API rules/:      80% min, 90% target, 95% for auth/payment paths
Marketing site rules/:   40% min, 60% target, branch coverage not required
Scripts repo:            (no override -- uses global 60% default)
```

See `templates/rules/test-coverage.md` for a ready-to-use template.

## Context Budget

JitNeuro is designed to be lightweight. Here's what it actually costs:

### Always Loaded (every session)

| File | Lines | Est. Tokens | Purpose |
|------|-------|-------------|---------|
| CLAUDE.md (global) | ~50-140 | ~400-1,100 | Core rules, trust zones |
| CLAUDE.md (project) | ~30-50 | ~250-400 | Project identity, key paths |
| MEMORY.md | ~90-200 | ~700-1,600 | Routing weights, project index |
| **Total brainstem** | **~170-390** | **~1,350-3,100** | |

That's roughly **1-2% of a 200K context window**. The rest is your conversation and code.

### On-Demand (loaded only when needed)

| Category | Typical Load | Lines | Est. Tokens |
|----------|-------------|-------|-------------|
| 1 command (/save, /load, etc.) | Per invocation | ~65-185 | ~500-1,500 |
| 1-2 bundles | Per task routing | ~30-80 each | ~250-650 each |
| 1 engram | Per project | ~50-150 | ~400-1,200 |

A typical working session adds **~1-2%** more for on-demand context.

### Total: ~3-4% of context for full JitNeuro infrastructure

### Size Limits (enforced by /learn)

| Component | Limit | Why |
|-----------|-------|-----|
| MEMORY.md | 200 lines (hard) | Claude Code truncates beyond 200 -- content silently lost |
| Bundles | 80 lines each | Longer bundles get skimmed or partially read |
| Engrams | 150 lines each | Diminishing returns -- trim stale content |
| CLAUDE.md | 30-40 lines | Loaded every session -- keep minimal |
| Session state | 30-60 lines | Checkpoint, not transcript |

The `/learn` command monitors these limits and flags violations before they cause problems.
