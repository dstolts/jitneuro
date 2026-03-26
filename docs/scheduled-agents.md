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

## Hybrid Architecture: Why No External Tool Dependency

### The Decision

JitNeuro does not depend on any external workflow engine for scheduling. The scheduler is native -- jitneuro.json + a launcher script + system cron.

### Why

1. **Zero dependencies.** JitNeuro is markdown + bash. Adding "also install and configure [workflow tool]" kills the 10-minute setup promise. Every dependency is a reason not to adopt.

2. **Claude Code is already the runtime.** It can spawn agents, manage context, read/write files, call APIs, and execute commands. The only thing it can't do natively is fire on a wall-clock schedule -- that's what system cron handles. One thin launcher script bridges the gap.

3. **Config portability.** jitneuro.json travels with the repo. `git clone` + `install.sh` gives you working schedules. External workflow configs live in external tools, not in git.

4. **No fragility.** If an external tool is down, misconfigured, or gets replaced, JitNeuro schedules keep running. Zero coupling means zero breakage.

### The Hybrid Model

JitNeuro and external tools are peers, not dependencies. The integration is simple and bidirectional:

```
JITNEURO -> ANY EXTERNAL TOOL:
  Claude agent calls any API, webhook, or CLI as part of its prompt.
  No integration code. Just: "after finishing, curl this webhook" or "send this email via Resend API."

ANY EXTERNAL TOOL -> JITNEURO:
  Any tool that can run a shell command can trigger Claude:
  claude --print --prompt "Load session X, do Y"
```

**Neither depends on the other.** JitNeuro schedules and executes work natively. If you also use a workflow engine, you can wire them together. If you don't, nothing breaks.

### When to Use an External Workflow Engine

JitNeuro handles the vast majority of scheduled automation natively. External workflow engines (N8N, Temporal, Airflow) are only needed for:

- **Real-time event-driven triggers** where 5-15 minute polling latency is unacceptable
- **Complex multi-system ETL** with retry logic, backoff, and transactional guarantees
- **Visual workflow design** where non-technical users build the routing

Everything else -- monitoring APIs, drafting responses, scoring content, triaging requests, sending notifications -- Claude handles directly with markdown instructions and zero custom code.

### Example: Working Together

A real-time Stripe webhook needs instant acknowledgment (workflow engine handles that). But the smart follow-up work is Claude's strength:

```
1. Workflow engine receives Stripe webhook (real-time, < 1 second)
2. Engine validates the event, stores it, sends 200 OK to Stripe
3. Engine triggers Claude:
   claude --print --prompt "New subscription: {customer_name}, {plan}, {amount}.
   Read their history from Salesforce. Draft a personalized onboarding
   email that references their industry and use case. Write to
   .claude/drafts/onboard-{customer_id}.md. Update .logs/revenue-{date}.md."
4. Claude drafts the email with real context (not a template)
5. Owner reviews draft, approves send
```

The workflow engine does what it's good at: instant webhook receipt, payload validation, reliable delivery. Claude does what it's good at: reading context across systems, understanding the customer, writing something a human would actually send. Neither tries to do the other's job.

---

## Real-World Business Automation

The power of scheduled agents is that Claude understands context. Traditional automation tools need rigid schemas, API mappings, and custom code for every trigger. A Claude agent gets markdown instructions and figures out the rest. No webhook parsers, no schema transforms, no glue code.

### Why This Works Without Dedicated Tooling

Traditional approach to "monitor Stripe for new purchases and onboard the customer":
- Build a Stripe webhook endpoint (code, deploy, SSL, monitoring)
- Parse the webhook payload (schema mapping, error handling)
- Write onboarding logic (CRM update, email, access provisioning)
- Handle retries, failures, idempotency
- Maintain all of it as APIs change

JitNeuro approach:
- Cron agent checks Stripe API every 15 minutes
- Prompt says: "Check for new purchases since last run. For each, create onboarding task, update CRM, draft welcome email."
- Claude reads the Stripe API, understands the data, takes action
- If the Stripe API changes fields, Claude adapts -- no code to update

The tradeoff: cron polling instead of real-time webhooks. For most business operations, 5-15 minute latency is fine. When sub-second response matters, any tool that can run a shell command can trigger Claude directly.

### Inbound Marketing Monitor

```json
{
  "name": "inbound-monitor",
  "type": "cron",
  "schedule": "*/15 * * * *",
  "enabled": true,
  "session": "inbound-ops",
  "prompt": "Check for new inbound activity since last run. Sources: (1) Salesforce -- new leads, updated lead scores, form submissions. (2) Website -- new contact form entries via Ghost webhook log. (3) LinkedIn -- new connection requests and messages via Graph API. For each new item: classify priority (hot/warm/cold), draft appropriate response, write to .logs/inbound-{date}.md. Hot leads get immediate draft email in .claude/drafts/. Update .claude/state/inbound-last-run.md with current timestamp.",
  "timeout": 300,
  "description": "Monitor all inbound channels every 15 min"
}
```

No webhook infrastructure. No Zapier. No custom integration code. Claude reads the APIs directly, classifies with AI judgment (not rigid rules), and drafts responses that sound human.

### Stripe Purchase Monitor

```json
{
  "name": "stripe-monitor",
  "type": "cron",
  "schedule": "*/10 * * * *",
  "enabled": true,
  "session": "revenue-ops",
  "prompt": "Check Stripe for events since last run (read timestamp from .claude/state/stripe-last-run.md). Look for: payment_intent.succeeded, customer.subscription.created, customer.subscription.deleted, invoice.payment_failed. For each event: (1) Log to .logs/stripe-{date}.md. (2) If new subscription: create onboarding checklist in .claude/tasks/onboard-{customer}.md, draft welcome email to .claude/drafts/. (3) If payment failed: draft follow-up email, flag in .claude/alerts/. (4) If subscription cancelled: log churn reason, draft win-back sequence. Update last-run timestamp.",
  "timeout": 180,
  "description": "Monitor Stripe purchases, subscriptions, and churn"
}
```

Claude understands what a subscription cancellation MEANS. It can draft a win-back email that references what the customer was using, not just "we're sorry to see you go." No workflow tool can do that without custom code.

### Internal Support Request Handler

```json
{
  "name": "support-triage",
  "type": "cron",
  "schedule": "*/20 * * * *",
  "enabled": true,
  "session": "support-ops",
  "prompt": "Check for new support requests. Sources: (1) Shared mailbox via M365 Graph API -- unread emails in Support inbox. (2) GitHub issues labeled 'support' across all repos. For each request: (1) Read the full content. (2) Classify: bug report, feature request, how-to question, account issue. (3) For bug reports: search codebase for related code, draft initial diagnosis. (4) For how-to questions: search docs and write a draft answer. (5) Write all results to .logs/support-{date}.md. (6) For urgent items (production down, security): write to .claude/alerts/.",
  "timeout": 300,
  "description": "Triage support requests from email and GitHub"
}
```

The agent reads the support email, searches the codebase for relevant code, and drafts a response with actual technical context. A traditional triage tool just categorizes and routes.

### Multi-Channel Content Pipeline

```json
{
  "name": "content-pipeline",
  "type": "batch",
  "schedule": "0 6 * * 1",
  "enabled": true,
  "session": "content-ops",
  "taskFile": ".claude/batch-tasks/weekly-content.json",
  "maxConcurrent": 3,
  "logFile": ".logs/content-pipeline-{date}.md",
  "timeout": 3600,
  "description": "Weekly content pipeline: score, fix, schedule, repurpose"
}
```

Task file defines the pipeline stages:
1. Score all draft posts against quality rubric
2. Auto-fix posts below 85
3. Generate social media snippets from approved posts
4. Draft newsletter section from top 3 posts
5. Write publish schedule to .claude/state/publish-calendar.md

Each stage is a worker agent. The batch sub-orchestrator manages the flow.

### The Pattern: State Files Replace Databases

Notice the pattern across all examples: `.claude/state/<name>.md` files track last-run timestamps, current status, and running tallies. These are simple markdown files that Claude reads and writes naturally.

```
.claude/state/
  inbound-last-run.md       -- "2026-03-26T14:30:00Z"
  stripe-last-run.md        -- "2026-03-26T14:20:00Z"
  publish-calendar.md       -- upcoming publish dates and assignments
  support-queue.md          -- open items being tracked
```

No database. No ORM. No migrations. Claude reads a markdown file, updates it, writes it back. For business automation at this scale, it's enough. When you outgrow it, promote specific state to a real database -- but start here.

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
