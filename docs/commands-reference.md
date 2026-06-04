# Commands Reference

JitNeuro ships 17 commands and 5 shortcuts organized into 7 categories. All commands are read-only unless explicitly noted.

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
- **Watcher agent:** Both `new` and `load` automatically spawn scheduled agents (watcher agents) configured in the project's config file. These agents run in the background and periodically interrupt master for housekeeping (autosave, hub-sync, resume-tasks). If no agents are configured, a warning is displayed. The `session-guardrail` rule provides a backstop: if a session becomes active without going through `new` or `load` (e.g., context reset), the guardrail spawns the watcher.
- **Tag rule:** Every response ends with `[session: <name> | DIV: <MODE>]`

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

## Reasoning

### /divergent [auto|always|never|repo|workspace]
Toggle divergent thinking mode. Controls whether Claude evaluates multiple approaches (divergent) or takes the first reasonable path (serial).

- **Modes:**
  - `auto` (default) -- smart routing: diverge on production code, architecture, new features, tradeoffs. Serial on research, fixes, docs.
  - `always` -- force multi-path evaluation on every response
  - `never` -- force serial (first-fit) on every response

- **Hierarchy:** Repo-level overrides workspace-level. Both stored in `toggles.json`.
  - `divergent repo always` -- set at repo level
  - `divergent workspace auto` -- set at workspace level
  - `divergent repo clear` -- remove repo override

- **Agent inheritance:** Plan, discovery, analysis, and design agents inherit the mode. Explore, lookup, and monitor agents stay serial.
- **Session tag:** Mode appears on every response: `[session: <name> | DIV: <MODE>]`
- **Persistence:** Survives /clear (stored in toggles.json on disk)

Examples:
```
/divergent                   -- show current mode and source
/divergent always            -- force divergent (infers repo or workspace from cwd)
/divergent repo always       -- force divergent at repo level
/divergent workspace auto    -- reset workspace to auto
/divergent repo clear        -- remove repo override, fall back to workspace
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

## Diagnostics

### /test-tools
Smoke-test every available Claude Code tool and MCP server. Auto-discovers connected MCP servers and runs one safe read-only operation per server. Reports PASS/FAIL/SKIP for each tool.

- **Core tools tested:** Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch, TaskCreate
- **MCP servers:** Auto-discovered via ToolSearch -- no hardcoded list
- **Side effects:** Creates one temp file (cleaned up), creates one temp task (deleted)
- **Output:** ASCII table with PASS/FAIL/SKIP counts and remediation hints for failures

Example:
```
/test-tools
```

---

## Automation

### /schedule [list|start|stop|add|remove]
Manage scheduled agents -- background timer agents that periodically interrupt master with housekeeping instructions.

- **Subcommands:**
  - `list` (default) -- show all agents with status (RUNNING/STOPPED/DISABLED)
  - `start <name>` -- spawn the timer agent now
  - `stop <name>` -- stop re-spawning after current timer expires
  - `add <name> <interval> <instruction> [description]` -- add new agent to config
  - `remove <name>` -- remove from config

- **Default agents (ship with jitneuro):**
  - `housekeeper` (15m) -- unified agent: task enforcement, hub sync, autosave, heartbeat check, pending questions. Replaces legacy autosave and hub-sync agents.

- **Auto-spawn:** Watcher agents are automatically spawned when a session is created (`/session new`) or loaded (`/session load`). The `session-guardrail` rule provides a backstop for sessions that become active through other paths (context reset, fresh start).

- **Architecture:** Timer agent pattern. Agent sleeps for interval, returns instruction, dies. Master executes instruction and re-spawns. Agent context never grows. Runs indefinitely.

- **Guardrail:** Scheduled agent interrupts are MANDATORY. Master stops current work immediately and executes the instruction before resuming. See `rules/scheduled-agent-interrupts.md`.

Examples:
```
/schedule                    -- list all agents and status
/schedule start autosave     -- start the autosave timer
/schedule stop hub-sync      -- stop hub-sync after current cycle
/schedule add deploy-mon 5 NONE "Poll deploy pipeline"
```

---

## Setup and Verification

### /help
Display JitNeuro quick reference. Zero token cost -- reads and displays a static help file verbatim.

- **Arguments:** None
- **Source:** Reads `.claude/help.md` from the install root; falls back to the jitneuro templates `help.md`

Example:
```
/help
```
Displays the quick-reference card for all commands, shortcuts, and common workflows. Offers to open the file in the editor.

---

### /verify
Post-install health check. Reads the install root and validates all 9 framework components. Read-only -- does not modify any files.

- **Arguments:** None
- **Checks:** install version, commands directory, hook scripts, hooks config, hook paths, hook event names, bundles, engrams, context manifest

Example:
```
/verify
```
Returns a GREEN/YELLOW/RED table for each component with recommended remediation steps for any failures.

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
