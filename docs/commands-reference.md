# Commands Reference

JitNeuro ships 12 commands and 5 shortcuts organized into 5 categories. All commands are read-only unless explicitly noted.

---

## Session Management

### /session [new|save|load|pulse|switch|rename|dashboard]
Manage the current session. Default (no subcommand) shows current session status, repos, dirty files, and next steps.

- **Subcommands:**
  - `new <name>` -- create fresh named session (checks for unsaved work first)
  - `save <name>` -- checkpoint to disk
  - `load <name|#>` -- restore from disk
  - `pulse` -- re-read shared state from other sessions
  - `switch <name|#>` -- save current + load another in one step
  - `rename <new-name>` -- rename current session
  - `dashboard` -- current session's blockers and NEEDS OWNER items

- **Tracking:** Active session resolved from `heartbeats/<session-id>` in `.claude/session-state/`. The session-id is injected into Claude's context by the SessionStart hook. The heartbeat file's content holds the JitNeuro session name; its mtime is the last heartbeat timestamp.
- **Tag rule:** Every response ends with `[session: <name>]`

Examples:
```
/session                     -- where am I, what's dirty, what's next
/session new sprint-auth     -- start fresh (prompts to save existing)
/session save                -- checkpoint current session
/session load 3              -- load session #3 from last /sessions list
/session pulse               -- what changed in other sessions since I last looked
/session switch 2            -- save current, load #2
/session rename sprint-auth-v2
/session dashboard           -- blockers for THIS session only
```

---

### /sessions [list|show|stale|clean|archive|delete|dashboard]
Manage all session checkpoints. Default shows a numbered list with NEEDS OWNER summary across all sessions and active work.

- **Subcommands:**
  - `<number>` or `show <name|#>` -- show full detail
  - `stale` -- list sessions >7 days old
  - `clean` -- delete stale sessions (confirms first)
  - `archive <name|#>` -- move to archive
  - `delete <name|#>` -- delete (confirms first)
  - `dashboard` -- aggregate NEEDS OWNER across all sessions

- **Note:** Active session marked with `*` in list output

Examples:
```
/sessions                    -- numbered list + NEEDS OWNER summary
/sessions 3                  -- show detail for session #3
/sessions archive 4          -- archive session #4
/sessions stale              -- which sessions are >7 days old
/sessions clean              -- delete all stale (confirms first)
```

---

## Memory

### /learn
Evaluate the current session for long-term knowledge updates and run a memory health check. Proposes updates to engrams, bundles, and MEMORY.md based on what happened during the session.

- **Arguments:** None
- **Note:** Writes to engrams and bundles

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

### /bundle <name>
Load a specific context bundle on demand. Bundles are curated knowledge sets that give Claude deep domain knowledge for a task.

- **Arguments:** `name` (required) -- bundle identifier

Example:
```
/bundle infrastructure
```
Loads the infrastructure bundle, giving Claude full awareness of servers, VMs, ports, and deploy patterns.

---

## Git Operations

### /gitstatus [fetch|dirty|behind|unpushed|repo]
Cross-repo git comparison showing local vs uat vs main status.

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
Returns a table of all repos with uncommitted changes.

---

### /diff [repo]
Show changes since last push or main divergence.

- **Arguments:** `repo` (optional) -- specific repo name; defaults to current repo

Example:
```
/diff auth-api
```
Shows a summary of all changed files since the last push, with line counts and change descriptions.

---

## Governance

### /enterprise
Display consolidated governance rules, trust zones, and review gates.

- **Arguments:** None

Example:
```
/enterprise
```
Shows trust zone table (GREEN/YELLOW/RED), approval workflow, branch rules, and sprint protocol.

---

### /audit [repo]
Scan one or all repos for security issues, git hygiene, and DOE compliance.

- **Arguments:** `repo` (optional) -- specific repo; omit to scan all

Example:
```
/audit auth-api
```
Scans for .env exposure, missing engrams, CLAUDE.md presence, git status, and guardrail compliance.

---

## Setup and Maintenance

### /onboard <repo>
Bootstrap a new repo into the DOE/JitNeuro framework.

- **Arguments:** `repo` (required) -- name of the repo to onboard
- **Note:** Writes new files (CLAUDE.md, engram, MEMORY.md entry)

Example:
```
/onboard NewProject
```
Creates CLAUDE.md, initializes engram, registers in MEMORY.md, confirms DOE compliance.

---

### /orchestrate
Auto-route tasks to agents with appropriate bundles.

- **Arguments:** None

Example:
```
/orchestrate
```
Analyzes the pending task, selects relevant bundles, and loads them before proceeding.

---

### /conversation-log [on|off|status]
Toggle conversation logging to .logs/ directory.

- **Arguments:** `on`, `off`, or `status` (optional, defaults to `status`)

Example:
```
/conversation-log on
```
Enables conversation logging with timestamped filenames.

---

## Shortcuts

These delegate to `/session` or `/sessions` based on the `shortcut_scope` preference in `.claude/session-state/.preferences`. Default scope: `session` (current).

| Shortcut | Default target (session) | Alternate target (sessions) |
|----------|--------------------------|----------------------------|
| `/save <name>` | `/session save` | `/session save` (always current) |
| `/load <name\|#>` | `/session load` | `/session load` (always current) |
| `/pulse` | `/session pulse` | `/session pulse` (always current) |
| `/status` | `/session` | `/sessions` |
| `/dashboard` | `/session dashboard` | `/sessions dashboard` |

Note: `/save`, `/load`, and `/pulse` always target the current session regardless of preference. Only `/status` and `/dashboard` switch scope.
