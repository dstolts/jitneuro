# Scheduled Agents

How JitNeuro handles recurring work -- from housekeeping interrupts inside a live session to unattended nightly routines triggered by system cron.

---

## The Two Worlds

Scheduled agents live in two fundamentally different execution contexts:

| Context | Who starts it | Human trigger? | Claude session | Examples |
|---------|--------------|----------------|----------------|----------|
| **Internal** | SessionStart hook or master agent | No -- auto-started by config | Already running | Save every 30m, sync Hub.md, enforce discipline |
| **External** | System cron / Task Scheduler | No -- auto-started by schedule | Launches one | Nightly audit, batch scoring, content pipeline |

Internal agents run INSIDE a live session. They can be started two ways: automatically by the SessionStart hook (reads jitneuro.json, presents enabled agents for launch) or manually at any time via `/schedule start <name>`. Most are configured once in jitneuro.json and auto-started every session -- agent-enforced rules that need no human reminder. But the human can also add, start, or stop agents mid-session whenever needed.

External agents START a session, do work, and exit. Both live in `jitneuro.json`, both follow the same schema, but their lifecycles are different.

---

## Agent Types

### timer (internal)

The original pattern. A background subagent that sleeps for an interval, returns an instruction to master, and dies. Master executes the instruction and re-spawns the agent.

```json
{
  "name": "autosave",
  "type": "timer",
  "interval": 30,
  "enabled": true,
  "instruction": "/save",
  "description": "Auto-save session state every 30 minutes"
}
```

**Lifecycle:** Master spawns -> agent sleeps -> agent returns instruction -> master executes -> master re-spawns -> repeat.

**Priority:** `User input > Scheduled agent > Current task`. Timer interrupts are mandatory but master processes user input first.

**Use for:** Housekeeping that should happen periodically but isn't urgent enough to block user interaction.

### enforcer (internal)

Same mechanism as timer but with elevated priority and stricter execution rules. Enforcers exist because timer instructions can get deprioritized during complex multi-step operations. An enforcer MUST execute immediately -- no batching, no deferring, no "I'll do it after this next step."

```json
{
  "name": "hub-enforcer",
  "type": "enforcer",
  "interval": 20,
  "enabled": true,
  "instruction": "UPDATE_HUB",
  "prompt": "Read TaskList. Compare to Hub.md. If drift detected, return UPDATE_HUB. If in sync, return NONE.",
  "description": "Enforce Hub.md stays current with TodoWrite"
}
```

**What makes enforcers different from timers:**

| Behavior | Timer | Enforcer |
|----------|-------|----------|
| Can master finish current tool call before handling? | Yes | No -- stop mid-tool |
| Can master batch multiple instructions? | Yes (process together) | No -- one at a time, immediately |
| Can master deprioritize if in a complex flow? | Yes (within reason) | Never. This is the point. |
| Retry on failure | Re-spawn, try next cycle | Re-spawn immediately with shorter interval |

**Use for:** Discipline that master provably forgets during deep work. Hub.md sync, context checkpoints before risky operations, state validation.

### cron (external)

Triggered by system cron (Linux/Mac) or Task Scheduler (Windows). The launcher script reads jitneuro.json, finds cron agents due to run, spawns Claude Code CLI with the agent's prompt, and logs results.

```json
{
  "name": "nightly-audit",
  "type": "cron",
  "schedule": "0 2 * * *",
  "enabled": true,
  "session": "nightly-ops",
  "instruction": "/audit",
  "prompt": "Load session 'nightly-ops'. Run /audit on all repos. Write results to .logs/nightly-audit-{date}.md. If any repo has CRITICAL findings, write an alert to .claude/alerts/audit-{date}.md.",
  "timeout": 600,
  "description": "Nightly security and hygiene audit across all repos"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `schedule` | string | Cron expression (standard 5-field). Evaluated by the launcher script, not by Claude. |
| `session` | string | Session name to load before executing. Optional -- if omitted, starts fresh. |
| `prompt` | string | Full prompt passed to Claude CLI. Should be self-contained (everything the agent needs to do the work). |
| `timeout` | number | Max seconds before the launcher kills the Claude process. Default: 300. |

**Lifecycle:** System cron triggers launcher -> launcher reads jitneuro.json -> launcher spawns `claude --print --prompt "<prompt>"` -> Claude does work -> Claude exits -> launcher logs result.

**Use for:** Unattended recurring work. Nightly audits, weekly content scoring, daily git hygiene, scheduled backups.

### batch (external)

Like cron but reads a task list file and executes multiple tasks in sequence or parallel. The batch agent is a sub-orchestrator -- it manages workers based on a task config.

```json
{
  "name": "weekly-content-scoring",
  "type": "batch",
  "schedule": "0 3 * * 0",
  "enabled": true,
  "session": "content-scoring",
  "taskFile": ".claude/batch-tasks/content-scoring.json",
  "maxConcurrent": 5,
  "logFile": ".logs/content-scoring-{date}.md",
  "timeout": 1800,
  "description": "Score all blog posts weekly, fix any below 85"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `taskFile` | string | Path to a JSON file defining the batch tasks. Each task becomes a worker agent. |
| `maxConcurrent` | number | Rolling pool size (see sub-orchestrator-pattern.md). Default: 10. |
| `logFile` | string | Path for the progress log. `{date}` replaced with YYYY-MM-DD at runtime. |

**Lifecycle:** Launcher triggers -> loads session -> reads taskFile -> spawns sub-orchestrator Claude session -> sub-orchestrator manages rolling worker pool -> results written to logFile -> exits.

**Use for:** Large-scale recurring operations. Weekly content audits, dependency checks across repos, batch data processing.

---

## Configuration Schema (jitneuro.json)

All agent types live in the `scheduledAgents` array:

```json
{
  "version": "0.5.0",
  "scheduledAgents": [
    {
      "name": "autosave",
      "type": "timer",
      "interval": 30,
      "enabled": true,
      "instruction": "/save",
      "description": "Auto-save session state every 30 minutes"
    },
    {
      "name": "hub-enforcer",
      "type": "enforcer",
      "interval": 20,
      "enabled": true,
      "instruction": "UPDATE_HUB",
      "prompt": "Read TaskList. Compare to Hub.md. Return UPDATE_HUB if drift, NONE if in sync.",
      "description": "Enforce Hub.md stays current"
    },
    {
      "name": "nightly-audit",
      "type": "cron",
      "schedule": "0 2 * * *",
      "enabled": true,
      "session": "nightly-ops",
      "prompt": "Run /audit on all repos. Write results to .logs/nightly-audit-{date}.md.",
      "timeout": 600,
      "description": "Nightly security audit"
    },
    {
      "name": "weekly-scoring",
      "type": "batch",
      "schedule": "0 3 * * 0",
      "enabled": true,
      "session": "content-scoring",
      "taskFile": ".claude/batch-tasks/content-scoring.json",
      "maxConcurrent": 5,
      "logFile": ".logs/content-scoring-{date}.md",
      "timeout": 1800,
      "description": "Score all blog posts weekly"
    }
  ]
}
```

### Field Reference (all types)

| Field | Type | Required | timer | enforcer | cron | batch | Description |
|-------|------|----------|-------|----------|------|-------|-------------|
| `name` | string | Yes | X | X | X | X | Unique identifier |
| `type` | string | Yes | X | X | X | X | `timer`, `enforcer`, `cron`, or `batch` |
| `enabled` | boolean | Yes | X | X | X | X | Whether the agent is active |
| `description` | string | No | X | X | X | X | Human-readable description |
| `selfLoop` | boolean | No | X | X | -- | -- | Agent self-loops on NONE results instead of returning to master. Default: false for timer, true for enforcer with prompt. |
| `maxLoops` | number | No | X | X | -- | -- | Max evaluation cycles before agent returns for re-spawn. Default: 50. Only applies when selfLoop is true. |
| `maxHours` | number | No | X | X | -- | -- | Max hours before agent returns for re-spawn. Default: 8. Only applies when selfLoop is true. |
| `interval` | number | -- | X | X | -- | -- | Minutes between executions (internal agents) |
| `instruction` | string | -- | X | X | X | -- | What to execute when triggered |
| `prompt` | string | No | X | X | X | -- | Evaluation prompt (smart agents) or full task prompt (cron) |
| `schedule` | string | -- | -- | -- | X | X | Cron expression (external agents) |
| `session` | string | No | -- | -- | X | X | Session to load before executing |
| `taskFile` | string | -- | -- | -- | -- | X | Path to batch task definitions |
| `maxConcurrent` | number | No | -- | -- | -- | X | Rolling pool size (default: 10) |
| `logFile` | string | No | -- | -- | X | X | Output log path (`{date}` replaced at runtime) |
| `timeout` | number | No | -- | -- | X | X | Max seconds before kill (default: 300) |

---

## Internal Agent Execution (timer + enforcer)

Internal agents run INSIDE a live Claude Code session.

### Execution Models

There are two models for how internal agents cycle. The right choice depends on whether the agent needs master to act or can evaluate independently.

**Model 1: Return to master (simple timer agents)**

For agents with a fixed instruction that master must execute (e.g., `/save` requires master's session context):

```
1. Master spawns agent (background)
2. Agent sleeps for <interval> minutes
3. Agent wakes, returns: SCHEDULED: <name> / INSTRUCTION: /save
4. Master STOPS current work
5. Master executes the instruction
6. Master re-spawns the agent
7. Master resumes previous work
```

Master re-spawns the agent each cycle. The agent is stateless -- it sleeps once, returns once, dies.

**Model 2: Self-looping (smart agents)**

For agents with a `prompt` field that can evaluate independently, the agent loops internally and only returns to master when action is actually needed:

```
1. Master spawns agent (background)
2. Agent sleeps for <interval> minutes
3. Agent wakes, evaluates prompt (reads 2-3 files)
4. If no action needed: agent sleeps again (back to step 2)
5. If action needed: agent returns to master with instruction
6. Master executes the instruction
7. Master re-spawns the agent
```

The agent handles its own sleep/evaluate cycle. Master is only interrupted when there is real work to do. This eliminates unnecessary `INSTRUCTION: NONE` interrupts that break master's flow for no reason.

**When to use which:**

| Situation | Model | Why |
|-----------|-------|-----|
| Fixed instruction (`/save`, `/health`) | Return to master | Master must execute the instruction |
| Smart evaluation with frequent NONE results | Self-loop | Avoids interrupting master when nothing is wrong |
| Instruction requires master context (TodoWrite, session state) | Return to master | Agent can't access master's in-memory state |
| Instruction is file-based (write a log, check a file) | Self-loop | Agent can do it without master |

**Self-loop lifespan:** Self-looping agents accumulate context over cycles. They need a termination condition to avoid running until they crash. Two strategies:

| Strategy | How | Use when |
|----------|-----|----------|
| **Time-boxed** | Agent runs an "8-hour shift" -- loops for N hours, then returns to master for re-spawn with fresh context | Long-running monitors, steady-state ops |
| **Context-aware** | Agent tracks its own context usage. When approaching ~90% capacity (e.g., after N evaluations), returns to master for re-spawn | Variable workloads, unpredictable evaluation sizes |

Both are valid. Time-boxing is simpler and predictable. Context-aware is more efficient but requires the agent to estimate its own context consumption. In practice, tell the agent: "Loop for up to 8 hours or 50 evaluation cycles, whichever comes first. Then return to master for re-spawn."

The agent's return should include a status note so master knows why it returned:
```
SCHEDULED: hub-enforcer
INSTRUCTION: RESPAWN
REASON: shift complete (8h / 47 cycles, 0 actions taken)
```

Master re-spawns with fresh context. No work lost -- the agent is stateless between evaluations.

### Priority Rules

```
User input > Enforcer interrupt > Timer interrupt > Current task
```

- **User input** always wins. If the user types while an agent returns, handle user first.
- **Enforcer** beats timer. If both return simultaneously, enforcer executes first.
- **Timer** beats current work. Master stops what it's doing, handles the instruction, resumes.

### Managing Internal Agents

```
/schedule              -- list all agents with status
/schedule start <name> -- spawn the timer now
/schedule stop <name>  -- stop re-spawning after current timer expires
/schedule add <name> <interval> <instruction>
/schedule remove <name>
```

---

## External Agent Execution (cron + batch)

External agents run OUTSIDE any live session. A launcher script, triggered by system cron, starts Claude Code, does the work, and exits.

### The Launcher Script

The launcher (`jitneuro-cron.sh` / `jitneuro-cron.ps1`) is a thin shell script that:

1. Reads `scheduledAgents` from jitneuro.json
2. Filters for `type: "cron"` or `type: "batch"` agents that are `enabled: true`
3. Checks the cron schedule against current time (or uses a last-run timestamp file)
4. For each due agent:
   - Builds the Claude CLI command with the agent's prompt
   - If `session` is set: includes session load instruction in the prompt
   - Spawns Claude Code: `claude --print --prompt "<prompt>" --max-turns 50`
   - Captures output to the log file
   - Enforces timeout (kill after N seconds)
5. Writes structured execution summary to `.logs/cron-{date}.md` (one per day, appended)

### System Cron Setup

**Linux/Mac:**
```bash
# Run the launcher every 5 minutes. It checks which agents are actually due.
*/5 * * * * cd /path/to/workspace && bash .claude/scripts/jitneuro-cron.sh >> .logs/cron-stdout.log 2>&1
```

Note: `cron-stdout.log` captures raw shell output (for debugging cron issues). The launcher writes its own structured summary to `.logs/cron-{date}.md`.

**Windows Task Scheduler:**
```powershell
# Create a scheduled task that runs every 5 minutes
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File D:\Code\.claude\scripts\jitneuro-cron.ps1" -WorkingDirectory "D:\Code"
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) -Once -At (Get-Date)
Register-ScheduledTask -TaskName "JitNeuro-Cron" -Action $action -Trigger $trigger
```

The launcher runs frequently (every 5 minutes) but only fires agents whose cron schedule matches. This means you configure per-agent schedules in jitneuro.json, not in system cron.

### Batch Task File Format

For `type: "batch"`, the `taskFile` defines the worker tasks:

```json
{
  "description": "Score all blog posts against quality rubric",
  "rubric": "SEO 85+, AEO 85+, Quality 85+",
  "tasks": [
    {
      "id": "post-001",
      "file": "content-drafts/ai-security-basics.md",
      "action": "score",
      "fixIfBelow": 85
    },
    {
      "id": "post-002",
      "file": "content-drafts/aibm-marina-marketing.md",
      "action": "score",
      "fixIfBelow": 85
    }
  ]
}
```

The batch agent reads this file, spawns workers per the sub-orchestrator rolling pool pattern (see [sub-orchestrator-pattern.md](sub-orchestrator-pattern.md)), and writes results to the log file.

---

## Hybrid Architecture: Why Not N8N (or Any External Tool) as Primary

### The Decision

JitNeuro does not depend on N8N, Temporal, Airflow, or any external workflow engine for scheduling. The scheduler is native -- jitneuro.json + a launcher script + system cron.

### Why

1. **Adoption barrier.** Every external dependency is a reason not to adopt. JitNeuro is a markdown framework. Adding "also install and configure N8N" kills the 10-minute setup promise.

2. **Tight coupling creates fragility.** If N8N is down, scheduled agents don't run. If N8N changes its webhook format, the integration breaks. If the user switches from N8N to Temporal, all schedules need rewriting. Native scheduling has zero external dependencies.

3. **Claude Code is already the runtime.** Claude Code can spawn agents, manage context, read/write files, and execute commands. The only thing it can't do is fire on a wall-clock schedule -- that's what system cron handles. One thin launcher script bridges the gap.

4. **Config portability.** jitneuro.json travels with the repo. `git clone` + `install.sh` gives you working schedules. N8N workflows live in N8N, not in git.

### The Hybrid Model (Best of Both Worlds)

JitNeuro and external workflow tools are peers, not dependencies. Either can trigger the other:

```
JITNEURO -> N8N:
  Claude agent makes an HTTP call to N8N webhook
  Use case: "After nightly audit, trigger N8N workflow to send Slack summary"

N8N -> JITNEURO:
  N8N runs a CLI command: claude --print --prompt "..."
  Use case: "When a new lead arrives in CRM, trigger Claude to draft a response"

JITNEURO -> ANY TOOL:
  Claude agent calls any API, webhook, or CLI
  Use case: Trigger GitHub Actions, send email via Resend, post to Slack

ANY TOOL -> JITNEURO:
  Any tool that can run a shell command can trigger Claude
  Use case: CI/CD pipeline triggers Claude for post-deploy validation
```

**Neither depends on the other.** JitNeuro schedules work natively. If you ALSO have N8N, you can wire them together. If you don't have N8N, nothing breaks. If you replace N8N with Temporal tomorrow, JitNeuro schedules keep running.

### When to Use Each

| Scenario | Use | Why |
|----------|-----|-----|
| Save context every 30 minutes | JitNeuro timer | Internal to Claude session, no external tool needed |
| Nightly repo audit | JitNeuro cron | Claude does the work, no orchestration tool needed |
| Score 77 blog posts weekly | JitNeuro batch | Sub-orchestrator pattern handles this natively |
| Send Slack notification after audit | JitNeuro cron + webhook call | Claude makes the HTTP call as part of the prompt |
| New CRM lead triggers response draft | N8N -> Claude CLI | N8N watches the CRM, Claude does the writing |
| Complex multi-system workflow (CRM -> draft -> approve -> send -> log) | N8N orchestrates, Claude executes | N8N handles the multi-step routing, Claude handles the AI work |
| ETL pipeline with retries and backoff | N8N or Airflow | Workflow engines are built for this; Claude is not |

**Rule of thumb:** If the work is "Claude does AI things on a schedule," use JitNeuro. If the work is "route data between 5 systems with retry logic," use a workflow engine. If it's both, wire them together as peers.

### Integration Patterns

**Pattern 1: Claude triggers N8N at the end of scheduled work**
```
JitNeuro cron agent runs nightly audit
-> Audit completes, writes .md report
-> Agent's prompt includes: "curl -X POST https://auto.example.com/webhook/audit-complete -d @report.json"
-> N8N receives webhook, sends Slack message, updates dashboard
```

**Pattern 2: N8N triggers Claude for AI-specific work**
```
N8N watches Salesforce for new leads (every 15 min)
-> New lead detected
-> N8N runs: claude --print --prompt "Draft a response for this lead: {lead_data}"
-> Claude drafts response, writes to file
-> N8N picks up the draft, routes to approval queue
```

**Pattern 3: Bidirectional handoff**
```
JitNeuro batch agent scores content weekly
-> Finds 3 posts below threshold
-> Writes fix instructions to a task file
-> Calls N8N webhook: "3 posts need fixing, task file at X"
-> N8N creates tickets in task management
-> Owner reviews tickets, approves
-> Owner triggers: claude --print --prompt "Load session content-scoring, execute fixes from task file X"
-> Claude fixes the posts
```

---

## Examples

### Minimal: Save and sync only (default)

```json
"scheduledAgents": [
  {
    "name": "autosave",
    "type": "timer",
    "interval": 30,
    "enabled": true,
    "instruction": "/save"
  },
  {
    "name": "hub-sync",
    "type": "enforcer",
    "interval": 15,
    "enabled": true,
    "instruction": "UPDATE_HUB",
    "prompt": "Read TaskList. Compare to Hub.md. Return UPDATE_HUB if drift, NONE if in sync."
  }
]
```

### Production: Internal + external

```json
"scheduledAgents": [
  {
    "name": "autosave",
    "type": "timer",
    "interval": 30,
    "enabled": true,
    "instruction": "/save"
  },
  {
    "name": "hub-enforcer",
    "type": "enforcer",
    "interval": 15,
    "enabled": true,
    "instruction": "UPDATE_HUB",
    "prompt": "Read TaskList. Compare to Hub.md. Return UPDATE_HUB if drift, NONE if in sync."
  },
  {
    "name": "nightly-audit",
    "type": "cron",
    "schedule": "0 2 * * *",
    "enabled": true,
    "session": "nightly-ops",
    "prompt": "Run /audit on all repos. Write critical findings to .claude/alerts/. Write full report to .logs/.",
    "timeout": 600
  },
  {
    "name": "weekly-content-scoring",
    "type": "batch",
    "schedule": "0 3 * * 0",
    "enabled": true,
    "session": "content-ops",
    "taskFile": ".claude/batch-tasks/content-scoring.json",
    "maxConcurrent": 5,
    "logFile": ".logs/content-scoring-{date}.md",
    "timeout": 1800
  }
]
```

---

## Related Docs

- [Configuration Reference](configuration-reference.md) -- jitneuro.json full schema
- [Sub-Orchestrator Pattern](sub-orchestrator-pattern.md) -- How batch agents manage workers
- [Commands Reference](commands-reference.md) -- /schedule command usage
