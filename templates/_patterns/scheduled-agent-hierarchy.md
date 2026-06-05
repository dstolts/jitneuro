---
type: pattern
purpose: Defines the taxonomy of recurring/scheduled agent work -- from in-session housekeeping interrupts to unattended cron-triggered routines; MUST be consulted before configuring any scheduled or timer agent, because choosing the wrong tier (an unattended cron routine where an in-session interrupt was needed, or the reverse) produces agents that fire at the wrong lifecycle moment, miss their trigger, or run unattended with no supervision path.
read_when: Before configuring any scheduled or timer agent to ensure the correct tier (timer, enforcer, cron, or batch) is selected for the execution context.
tags: [agents, scheduling, automation, lifecycle]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
---

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
  "version": "0.4.0",
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
