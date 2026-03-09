# Ralph Integration with JitNeuro

How JitNeuro's memory management works with Ralph's autonomous execution loop.

## What Is Ralph?

Ralph (ralph-tui) is an autonomous AI coding loop. You give it a PRD with user
stories, it executes them one by one -- reading code, making changes, running tests,
committing. It works in its own terminal, its own context, its own git branch.

Ralph handles **execution**. JitNeuro handles **memory and context**.
They're complementary, not competing.

## The Integration Points

```
JITNEURO (memory layer)              RALPH (execution layer)
  |                                    |
  |-- MEMORY.md (routing weights)      |-- config.toml (agent config)
  |-- Bundles (domain knowledge)       |-- prd.json (stories + AC)
  |-- Engrams (project context)        |-- iterations/ (execution logs)
  |-- Session state (checkpoints)      |-- reports/ (results)
  |-- /learn (backpropagation)         |-- progress.md (status)
  |                                    |
  |-- Master session orchestrates -->  |-- Ralph executes autonomously
  |-- /save captures state       -->  |-- Ralph commits per-story
  |-- /learn updates knowledge   <--  |-- Ralph discovers patterns
```

## Workflow: Sprint with Ralph

### Phase 1: Planning (JitNeuro context, no code)

```
User: "Plan Sprint-UserAuth-001"

Master session:
  - Loads bundles: [sprint, api] via routing weights
  - Loads engram: aifs-api.md (project context)
  - Builds spec in .ralph-tui/specs/Sprint-UserAuth-001.md
  - Creates stories in .ralph-tui/tasks/Sprint-UserAuth-001/backlog.md
  - Waits for user approval
```

JitNeuro provides the **context** Claude needs to write a good spec:
- Bundle tells it sprint conventions (story format, naming, AC patterns)
- Engram tells it the project architecture (what files exist, what patterns to follow)
- Routing weights got it to the right bundles without being told

### Phase 2: Ralph Preview (JitNeuro evaluates Ralph's input)

```
User: "Approved. Run holistic review."

Master session:
  - Reads prd.json (Ralph's input)
  - Evaluates against current codebase state
  - Uses engram for: existing file conflicts, auth patterns, dependency readiness
  - Uses bundle for: story description accuracy, AC feasibility
  - Outputs: story-by-story table with risk/time/verdict
  - Waits for user approval
```

This is where JitNeuro's knowledge directly improves Ralph's execution quality.
Without the engram, the preview can't check "does this file already exist?"
Without the bundle, it can't check "does this follow our API patterns?"

### Phase 3: Ralph Executes (separate terminal)

```
User runs in separate terminal:
  cd D:\Code\AIFS-API; ralph-tui run

Ralph:
  - Reads prd.json
  - Executes stories 1-N autonomously
  - Each story: read code -> plan -> implement -> test -> commit
  - Writes progress.md, iteration logs, reports
  - Runs in its own context (no JitNeuro needed during execution)
```

Ralph runs independently. It doesn't need JitNeuro's bundles or routing --
it has its own context from prd.json and the codebase. JitNeuro's job is done
until Ralph finishes.

### Phase 4: Post-Execution Review (JitNeuro evaluates Ralph's output)

```
Ralph finishes. Back in master session:

User: "Ralph done. Run US-HER review."

Master session:
  - Loads bundles: [sprint, api] (routing weights)
  - Loads engram: aifs-api.md
  - Reads Ralph's output: progress.md, reports/, git log
  - Evaluates from 4 personas (architect, maintenance, reliability, security)
  - Flags bugs, dead code, spec deviations
  - Outputs: story-by-story table with status/verdict
  - Waits for user approval before push
```

### Phase 5: Learn (JitNeuro updates itself)

```
User: "Run /learn"

/learn evaluates:
  - Did Ralph discover new patterns? (update engram)
  - Did the sprint add new routes/files? (update engram)
  - Did the review reveal bundle gaps? (update bundle)
  - Did routing weights work? (update MEMORY.md if not)
  - System health check: all files within limits?
```

This is the **feedback loop**. Every sprint that runs through Ralph generates
knowledge that /learn can capture. The system gets smarter over time.

## What JitNeuro Gives Ralph

| JitNeuro provides | Ralph benefits |
|-------------------|----------------|
| Engram (project context) | Better spec -- Claude knows the codebase before writing stories |
| Bundle (domain knowledge) | Correct conventions -- stories follow established patterns |
| Routing weights | Right context loaded automatically -- no manual "read this file" |
| /save (checkpoint) | Sprint state preserved across /clear -- resume mid-sprint |
| /learn (backpropagation) | Post-sprint knowledge captured -- next sprint starts smarter |

## What Ralph Gives JitNeuro

| Ralph produces | JitNeuro captures via /learn |
|----------------|-------------------------------|
| New files created | Engram update: key files table |
| Architecture changes | Engram update: architecture section |
| New dependencies | Engram update: tech stack |
| Discovered patterns | Bundle update or new routing weight |
| Dead code found | Engram update: gotchas section |

## Multi-Repo Ralph Sprints

When a sprint spans repos (API + FE), the master session orchestrates:

```
1. Master session plans spec (both repos, one sprint)
2. prd.json created per repo (API prd.json, FE prd.json)
3. Ralph executes API repo first (separate terminal)
4. Master reviews API output (US-HER)
5. Deploy API to uat
6. Ralph executes FE repo (separate terminal)
7. Master reviews FE output (US-HER)
8. /learn captures cross-repo learnings
9. /save checkpoints the full sprint state
```

The master session never runs Ralph itself -- it plans the input, reviews the
output, and captures the learnings. Ralph runs in its own terminal with its own
context. Clean separation of concerns.

## File Locations

```
repo/
  .ralph-tui/
    config.toml          <-- Ralph config (agent, iterations, autoCommit)
    prd.json             <-- Ralph input (stories, AC, dependencies)
    specs/               <-- Sprint specs (written with JitNeuro context)
    tasks/               <-- Backlog files
    archive/             <-- Completed sprints
    iterations/          <-- Ralph execution logs
    reports/             <-- Ralph output reports

  .claude/
    bundles/             <-- JitNeuro domain knowledge
    engrams/             <-- JitNeuro project context
    commands/            <-- JitNeuro slash commands
    session-state/       <-- JitNeuro checkpoints
```

Ralph owns `.ralph-tui/`. JitNeuro owns `.claude/`. They integrate through
the master session -- never by reading each other's files directly.
