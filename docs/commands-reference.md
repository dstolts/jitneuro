# Commands Reference

JitNeuro ships 15 slash commands organized into 5 categories. All commands are read-only unless explicitly noted.

---

## Memory Management

### /save <name>
Checkpoint session state before /clear. Writes current context, active tasks, and working state to a named snapshot so nothing is lost when the conversation resets.

- **Arguments:** `name` (required) -- identifier for the checkpoint
- **Note:** Writes to `D:\Code\.claude\session-state\`

Example:
```
/save sprint-blog-progress
```
Saves the current session as "sprint-blog-progress". Confirmation shows files written and context captured.

---

### /load <name>
Restore session state after /clear. Rehydrates context, active tasks, and working state from a previously saved checkpoint.

- **Arguments:** `name` (required) -- identifier of the checkpoint to restore

Example:
```
/load sprint-blog-progress
```
Restores the "sprint-blog-progress" checkpoint. Claude resumes with full awareness of where you left off.

---

### /learn
Evaluate the current session for long-term knowledge updates and run a memory health check. Proposes updates to engrams, bundles, and MEMORY.md based on what happened during the session.

- **Arguments:** None
- **Note:** Writes to engrams and bundles in `D:\Code\.claude\`

Example:
```
/learn
```
Analyzes the session, identifies new patterns or facts worth persisting, checks for stale or conflicting memory entries, and proposes updates for review.

---

### /health
Standalone memory system diagnostic. Checks engram freshness, bundle consistency, MEMORY.md accuracy, and cross-reference integrity without requiring a full /learn evaluation.

- **Arguments:** None

Example:
```
/health
```
Returns a table of all memory components with status (current, stale, missing, conflict) and recommended actions.

---

## Governance

### /enterprise
Display consolidated governance rules, trust zones, and review gates. Surfaces the full DOE compliance framework in one view so you know exactly what requires approval and what runs freely.

- **Arguments:** None

Example:
```
/enterprise
```
Shows trust zone table (GREEN/YELLOW/RED), approval workflow, branch rules, and sprint protocol in a single consolidated view.

---

### /audit [repo]
Scan one or all repos for security issues, git hygiene, and DOE compliance. Checks for exposed secrets, missing CLAUDE.md files, uncommitted changes, and framework conformance.

- **Arguments:** `repo` (optional) -- specific repo name to audit; omit to scan all repos

Example:
```
/audit auth-api
```
Scans auth-api for .env exposure, missing engrams, CLAUDE.md presence, git status, and guardrail compliance. Returns a pass/fail table with remediation steps.

---

## Git Operations

### /gitstatus [fetch|dirty|behind|unpushed|repo]
Cross-repo git comparison showing local vs uat vs main status. Gives a bird's-eye view of all repos or filters by condition.

- **Arguments (all optional):**
  - `fetch` -- fetch remotes before comparing
  - `dirty` -- show only repos with uncommitted changes
  - `behind` -- show only repos behind remote
  - `unpushed` -- show only repos with unpushed commits
  - `repo` -- specific repo name to check

Example:
```
/gitstatus dirty
```
Returns a table of all repos with uncommitted changes, showing branch name, modified file count, and last commit date.

---

### /diff [repo]
Show changes since last push or main divergence. Summarizes what has changed in the working tree and staged files relative to the remote branch.

- **Arguments:** `repo` (optional) -- specific repo name; defaults to current repo

Example:
```
/diff auth-api
```
Shows a summary of all changed files in the auth-api repo since the last push, with line counts and change descriptions.

---

## Context Management

### /bundle <name>
Load a specific context bundle on demand. Bundles are curated knowledge sets (e.g., deploy pipeline, infrastructure details, API design patterns) that give Claude deep domain knowledge for a task.

- **Arguments:** `name` (required) -- bundle identifier (e.g., `deploy`, `infrastructure`, `api-design`, `integrations`, `testing`)

Example:
```
/bundle deploy
```
Loads the deploy bundle, giving Claude full awareness of the deployment pipeline, environment configs, and release process.

---

### /orchestrate
Auto-route tasks to agents with appropriate bundles. Analyzes the current request, determines which bundles and context are needed, and loads them automatically based on routing weights.

- **Arguments:** None

Example:
```
/orchestrate
```
Claude analyzes the pending task, selects relevant bundles (e.g., deploy + infrastructure for a cross-repo task), and loads them before proceeding.

---

### /status
Quick "where am I" snapshot. Shows current branch, dirty files, active sprint, and working context in a compact summary.

- **Arguments:** None

Example:
```
/status
```
Returns: current repo, branch, uncommitted file count, active sprint name, and last checkpoint timestamp.

---

### /dashboard
Aggregate all NEEDS DAN items into one prioritized triage view. Pulls pending decisions, blockers, and approval requests from all active sprints and repos into a single actionable list.

- **Arguments:** None

Example:
```
/dashboard
```
Returns a prioritized table of items requiring attention: approvals, blockers, decisions, and review requests across all active work.

---

## Setup and Maintenance

### /onboard <repo>
Bootstrap a new repo into the DOE/JitNeuro framework. Creates CLAUDE.md guardrails, initializes engram, registers in MEMORY.md, and sets up the .claude directory structure.

- **Arguments:** `repo` (required) -- name of the repo to onboard
- **Note:** Writes new files (CLAUDE.md, engram, MEMORY.md entry)

Example:
```
/onboard NewProject
```
Creates `D:\Code\NewProject\.claude\CLAUDE.md`, initializes `D:\Code\.claude\engrams\newproject-context.md`, adds the repo to the MEMORY.md project table, and confirms DOE compliance.

---

### /sessions
List, inspect, and clean session checkpoints. Manages the saved states created by /save, showing age, size, and contents of each checkpoint.

- **Arguments:** None

Example:
```
/sessions
```
Returns a table of all saved checkpoints with name, date, size, and a brief description. Offers to clean stale checkpoints older than 7 days.

---

### convlog [on|off|status]
Toggle conversation logging to .logs/ directory. When enabled, full session transcripts are saved for audit and review purposes.

- **Arguments:** `on`, `off`, or `status` (optional, defaults to `status`)
- **Note:** No leading slash -- this is invoked as `convlog`, not `/convlog`

Example:
```
convlog on
```
Enables conversation logging. All subsequent messages are written to `D:\Code\.claude\.logs\` with timestamped filenames. Use `convlog status` to check current state.
