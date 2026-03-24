# Ralph Integration with JitNeuro

How JitNeuro's memory management works with Ralph's autonomous execution loop.

## What Is Ralph?

Ralph (ralph-tui) is an autonomous AI coding loop. You give it a PRD with user
stories, it executes them one by one -- reading code, making changes, running tests,
committing. It works in its own terminal, its own context, its own git branch.

Ralph handles **execution**. JitNeuro handles **memory and context**.
They're complementary, not competing.

## Two Engines, Different Jobs

JitNeuro has two execution models. Choosing the wrong one wastes time or produces lower quality.

| | Subagents | Ralph-tui |
|---|-----------|-----------|
| Duration | Seconds to minutes | Minutes to hours per story |
| Scope | Read-heavy, small targeted edits | Full implement-test-commit cycles |
| Isolation | Runs inside a session | Each story IS a session |
| Parallelism | Many agents, one session | Multiple sessions, one per story group |
| Context | Shares master context budget | Fresh full context per story |
| Testing | No -- returns data, doesn't iterate | Yes -- builds, tests, fixes, re-tests |

### When to Use Ralph

Ralph is the right choice when the work requires a **complete development cycle** -- code changes that must be built, tested, and validated before they count as done.

- Feature implementation (new endpoints, components, workflows)
- Bug fixes that require testing to verify
- Refactoring across multiple files that must stay consistent
- Sprint execution (multiple user stories)
- Any change where "it compiles" is not enough -- it must PASS TESTS
- Cross-file changes that need atomic commits
- Work that takes 10+ minutes per story

### When NOT to Use Ralph

Ralph has overhead: PRD creation, story splitting, headless execution setup. For these work types, that overhead is wasted.

**Markdown and documentation:** No build/test cycle exists. Ralph's strength (implement-test-commit loop) adds nothing when there's nothing to test. Use direct editing or a subagent. Exception: docs generated FROM code (API docs, schema docs) where the generation script needs to run.

**Research and analysis:** Reading codebases, analyzing patterns, comparing approaches. Subagents are purpose-built for this: read many files, return a summary. Ralph would create a full session per research task -- massive overkill. Research produces knowledge (memory/bundles), not code changes.

**Planning and architecture:** Designing systems, evaluating tradeoffs, writing specs. This is a conversation needing human input at decision points. Ralph runs headless -- it can't ask clarifying questions. Do planning in master context (strategy mode). Once planning is DONE, the resulting PRD goes to ralph.

**Quick fixes (1-3 files, under 5 minutes):** The overhead of writing a PRD exceeds the work itself. Fix the bug, run the test, commit. Exception: if the "quick fix" is one of many similar fixes (e.g., update 15 config files), batch them into a ralph PRD.

**Content creation (blog posts, marketing, copy):** Content doesn't compile or have test suites. Quality is subjective -- needs human review, not automated testing. Better pattern: subagent drafts, owner reviews, subagent revises.

**Scans, audits, health checks:** /health, /audit, /gitstatus are purpose-built. They use subagents for bulk reads and return structured summaries. Ralph would create a full session just to read files.

**Configuration changes:** Updating .env, config.json, vercel.json. No build/test cycle needed. Exception: config changes requiring restart + smoke test validation.

### Decision Framework

```
What kind of work is this?

1. Reading/analyzing files?
   -> Subagent. Always.

2. Writing markdown, docs, content?
   -> Direct edit or subagent. No build/test = no ralph.

3. Planning, designing, discussing?
   -> Master context (strategy mode). Needs human in the loop.

4. Single quick code fix (< 5 min, 1-3 files)?
   -> Direct in master. PRD overhead > the work.

5. Code change that needs testing?
   -> Ralph if part of a batch (sprint, multiple stories).
   -> Direct if one-off.

6. Multiple code changes across files/repos?
   -> Ralph PRD. This is ralph's sweet spot.

7. Sprint (5+ stories)?
   -> Ralph PRD with dependency mapping.
   -> /orchestrate groups independent stories for parallel execution.
```

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

### Phase 3: Ralph Executes

Ralph can run in the same terminal, a separate terminal, or be launched by Claude Code directly.

**Headless mode (recommended for automation and Claude Code launch):**
```bash
ralph-tui run --headless --no-setup --prd path/to/prd.json
```

**Key flags:**
| Flag | Purpose |
|------|---------|
| `--headless` (or `--no-tui`) | No interactive TUI -- structured logs to stdout. Required for Claude Code to launch ralph. |
| `--no-setup` | Skip interactive setup prompts. Required for unattended execution. |
| `--prd <path>` | Path to prd.json (auto-selects JSON tracker). |
| `--iterations <n>` | Max iterations per story (0 = unlimited). Safety cap. |
| `--model <name>` | Override model (opus, sonnet). |
| `--agent <name>` | Override agent plugin (claude, opencode). |
| `--verify` | Run preflight check before starting. |

**Verified working (2026-03-23):** `ralph-tui run --headless --no-setup --iterations 3 --prd prd.json` executes stories, edits files, validates acceptance criteria, and exits cleanly with a summary. No prompts, no TUI.

**Claude Code can launch ralph in a new named terminal:**

The master session opens a new terminal tab, names it after the sprint/session, runs ralph with TUI for visual monitoring, and the tab auto-closes when ralph completes.

**Windows Terminal** (`wt` command -- requires Windows Terminal installed, not available on Windows Server):
```bash
wt new-tab --title "Ralph: sprint-api" -- bash -c "cd /d/Code/my-api && ralph-tui run --no-setup --prd .ralph-tui/prd.json"
```
Opens a named tab. Ralph runs with TUI. Tab auto-closes when ralph completes.

Multiple instances:
```bash
wt new-tab --title "Ralph: API" -- bash -c "cd ~/projects/backend && ralph-tui run --no-setup --prd .ralph-tui/prd.json"
wt new-tab --title "Ralph: FE" -- bash -c "cd ~/projects/frontend && ralph-tui run --no-setup --prd .ralph-tui/prd.json"
```

**PowerShell** (works everywhere, opens a new console window):
```powershell
Start-Process cmd -ArgumentList '/c title Ralph: sprint-api && cd /d C:\Projects\my-api && ralph-tui run --no-setup --prd .ralph-tui\prd.json' -WindowStyle Normal
```
Opens a new window titled "Ralph: sprint-api". Window auto-closes when ralph completes (`/c` flag).

**tmux** (Git Bash / Linux / Mac):
```bash
tmux new-session -d -s "ralph-api" "cd ~/Code/my-api && ralph-tui run --no-setup --prd .ralph-tui/prd.json"
```
Creates a named detached session. Attach with `tmux attach -t ralph-api` to watch. Session auto-closes on completion.

**How it works:**
- Claude launches ralph in a NEW terminal/tab/session with a descriptive name
- Ralph runs with full TUI (progress cards, iteration logs, status bars)
- User can glance at the named tab/window anytime to monitor
- When ralph completes, the terminal auto-closes (process exits)
- Master session continues working on other tasks in parallel
- For multiple instances, each gets its own named terminal

**Headless fallback (when no separate terminal needed):**
```bash
ralph-tui run --headless --no-setup --prd .ralph-tui/prd.json
```
Runs in the master session's terminal. Structured log output, no TUI. Good for CI/CD or when Claude needs to capture ralph's output directly.

**TUI mode, fully automated (best for watching in a separate terminal):**
```bash
ralph-tui run --no-setup --prd .ralph-tui/prd.json
```

Drop `--headless` and you get the full visual TUI (task cards, iteration logs, status bars) while ralph still runs fully automated. The TUI is a monitoring interface, not an input interface -- once the PRD is provided, ralph needs no interaction. Add `--force` if a stale lock exists from a previous session.

**Parallel mode (multiple stories simultaneously within one instance):**
```bash
ralph-tui run --no-setup --prd .ralph-tui/prd.json --parallel 3
```

Ralph's built-in `--parallel N` runs up to N stories simultaneously within a single ralph instance. This is separate from jitneuro's multi-instance pattern (multiple ralph processes across repos). Use `--parallel` for independent stories within one repo. Use separate ralph instances for cross-repo parallelism.

**Summary of launch modes:**

| Mode | Command | Use when |
|------|---------|----------|
| TUI + automated | `ralph-tui run --no-setup --prd prd.json` | Watching progress in a separate terminal |
| Headless + automated | `ralph-tui run --headless --no-setup --prd prd.json` | Claude Code launches ralph, or CI/CD |
| TUI + parallel | `ralph-tui run --no-setup --prd prd.json --parallel 3` | Multiple independent stories in one repo |
| Headless + parallel | `ralph-tui run --headless --no-setup --prd prd.json --parallel 3` | CI/CD with parallel execution |

The TUI mode is better for watching progress visually. Headless mode is better for automation, CI/CD, and Claude Code integration.

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

## Parallel Ralph Execution (Multi-Session)

Ralph runs stories sequentially by default. But stories touching different repos or independent file groups can run in parallel via multiple ralph instances.

### How It Works

```
Owner writes PRD with dependency info
  -> /orchestrate analyzes PRD
  -> Groups stories by independence (file + repo analysis)
  -> Launches parallel ralph instances (one per group)
  -> Dashboard shows real-time progress across all instances
  -> Each story: implement -> test -> commit -> validate
  -> Deploy monitoring catches push failures automatically
  -> /learn captures knowledge post-sprint
  -> Hub.md records final state
```

### PRD Format for Parallel Execution

```json
{
  "userStories": [
    {
      "id": "US-001",
      "title": "Add auth middleware",
      "repo": "backend-api",
      "touches": ["src/middleware/auth.ts", "src/routes/index.ts"],
      "dependsOn": [],
      "priority": 1
    },
    {
      "id": "US-002",
      "title": "Add login page",
      "repo": "frontend-app",
      "touches": ["src/pages/login.tsx"],
      "dependsOn": ["US-001"],
      "priority": 1
    },
    {
      "id": "US-003",
      "title": "Update API docs",
      "repo": "docs",
      "touches": ["api-reference.md"],
      "dependsOn": [],
      "priority": 2
    }
  ]
}
```

- US-001 and US-003 run in parallel (different repos, no dependency)
- US-002 waits for US-001 (explicit dependency)
- `touches` enables file-conflict detection
- `priority` determines execution order within a group
- Stories touching the same repo: sequential (same branch)
- Stories touching different repos: parallel (separate branches/worktrees)

### Parallel Execution Concerns

**Git isolation:** Each parallel ralph instance needs its own branch or worktree. Two instances on the same branch cause merge conflicts. Pattern: `sprint-<name>-<group>` branches, merge to uat after all pass.

**Test isolation:** Two instances running tests simultaneously may conflict (shared DB, shared ports). Different repos are naturally isolated. Same repo must run sequentially.

**Context staleness:** If instance A updates an engram, instance B doesn't see it. Each instance snapshots context at launch. Post-sprint /learn reconciles.

**Monitoring:** Use `/pulse` from the master session to check status of all active sessions and agents. The dashboard (http://localhost:9847) shows real-time agent lifecycle -- running, completed, or blocked. For parallel ralph instances, each appears as a separate agent under the parent session. If an instance goes silent, `/pulse` surfaces it before the owner needs to investigate.

**Merge strategy:** After parallel instances complete on separate branches, auto-merge to uat if tests passed (GREEN zone). Owner reviews + merges to main (RED zone).

## Why Ralph Exists (The Testing Argument)

The core value of ralph is not automation -- it's **quality through mandatory testing**.

Without ralph, the natural tendency is:
1. Write code
2. "Looks right"
3. Commit
4. Move to next task
5. Discover bugs days later in production

With ralph, every story goes through:
1. Write code
2. Build (catch syntax/type errors)
3. Run tests (catch logic errors)
4. Validate acceptance criteria (catch spec deviations)
5. Only THEN commit
6. Next story starts with a clean, tested baseline

This is not optional. Ralph refuses to move to the next story until the current one passes. No human can skip the testing step. No "I'll add tests later." No "it works on my machine."

For enterprise clients (financial services, compliance-heavy industries), this audit trail is not a feature -- it's a requirement. Every commit traces to a story. Every story has validated acceptance criteria. The PRD is the spec, the git log is the proof.
