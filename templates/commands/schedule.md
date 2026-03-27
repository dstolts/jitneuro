# Schedule

Manage scheduled agents -- background timer agents that periodically interrupt master with housekeeping instructions.

## Instructions

When invoked as `/schedule`:

### /schedule or /schedule list (default)

1. Read `scheduledAgents` from `.claude/jitneuro.json`
2. Check which agents are currently running (check for active background agents by name)
3. Display status table:

```
Scheduled Agents:
  #  Name        Interval  Status    Instruction         Description
  1  autosave    30m       RUNNING   /save               Auto-save session state
  2  hub-sync    10m       STOPPED   UPDATE_HUB          Keep TodoWrite and Hub.md current
  3  deploy-mon  5m        DISABLED  NONE (monitoring)    Poll deploy pipeline

Tip: /schedule start|stop <name>, /schedule add|remove <name>
```

Status values:
- `RUNNING` -- timer agent is currently spawned and sleeping
- `STOPPED` -- enabled in config but not currently spawned (user stopped it, or not yet started)
- `DISABLED` -- `enabled: false` in config

Agent types (inferred from config):
- **simple** -- no `prompt` field. Sleeps, returns fixed instruction. (e.g., autosave)
- **smart** -- has `prompt` field, short evaluation. Reads 2-3 files max. (e.g., hub-sync)
- **enforcer** -- has `prompt` field with priority-ordered checks and multiple possible instructions. Reads files, evaluates conditions, returns the highest-priority instruction that fires. (e.g., housekeeper)

### /schedule start <name> [interval]

1. Find the agent config by name in scheduledAgents
2. If not found: "No scheduled agent named '<name>'. Use /schedule add to create one."
3. If already running: "Agent '<name>' is already running."
3b. If `[interval]` provided: use it instead of the config value (runtime override, does not change jitneuro.json). Confirm with: "Started 'autosave' at 45m (override). To change the default, edit .claude/jitneuro.json -> scheduledAgents -> autosave -> interval."
4. **Build the agent prompt from jitneuro.json config:**
   The agent itself never reads jitneuro.json. Claude reads the config, translates it into a literal prompt, and spawns the agent with that prompt. The translation:
   - `interval` → calculate sleep chain (see below) → write as literal Bash sleep steps
   - `instruction` → write as the exact string the agent returns after sleeping
   - `prompt` (if present) → insert as evaluation instructions between sleep and return
5. Calculate sleep chain: `interval / 10` rounded up = number of `sleep 600` calls. Remainder handled by a shorter final sleep.
6. Spawn the timer agent as a background Agent:

**For timer agents (no `prompt` field in jitneuro.json config):**

Timer agents are alarms. They sleep, ring, and die. Their value is discipline enforcement -- master forgets to save, the timer doesn't.

**End-to-end example:** autosave with `interval: 30`, `instruction: "/save"`

Config in jitneuro.json:
```json
{ "name": "autosave", "interval": 30, "instruction": "/save" }
```

Claude reads the config and builds this LITERAL prompt (no placeholders -- everything resolved):
```
Agent(
  run_in_background: true,
  description: "scheduled: autosave",
  prompt: """
You are a timer for scheduled agent "autosave".
Your ONLY job: sleep, then return one instruction. Nothing else.

Step 1: Run this exact command using the Bash tool:
sleep 600

Step 2: Run this exact command using the Bash tool:
sleep 600

Step 3: Run this exact command using the Bash tool:
sleep 600

Step 4: AFTER all three sleeps complete (30 minutes total), return EXACTLY this:
SCHEDULED: autosave
INSTRUCTION: /save

Do no other work. Do not read files. Do not analyze anything. Just sleep and return.
"""
)
```

The agent receives a fully resolved prompt. It doesn't read jitneuro.json. It doesn't calculate anything. Claude already did that work. The agent just runs three Bash sleep commands and returns the string.

When master receives `INSTRUCTION: /save`, the scheduled-agent-interrupts rule forces master to run /save immediately, then re-spawn the timer agent for the next cycle.

**For smart agents (has `prompt` field in jitneuro.json config):**
Smart agents evaluate a condition before deciding what to return. They read 2-3 files, check state, and return the appropriate instruction -- or NONE if no action needed. Example: housekeeper checks task state, hub drift, heartbeat, and save staleness.
```
Agent(
  run_in_background: true,
  description: "scheduled: <name>",
  prompt: """
You are a timer for scheduled agent "<name>".
Your job: sleep, evaluate briefly, then return one instruction.

SLEEP: <interval> minutes.
<sleep_instructions>

When you wake, evaluate:
<prompt from config>

Then return ONE of these formats:

If action needed:
SCHEDULED: <name>
INSTRUCTION: <instruction from config>
CONTEXT: <one line explaining why>

If no action needed:
SCHEDULED: <name>
INSTRUCTION: NONE

Keep evaluation lightweight. Read at most 2-3 files. Decide in under 10 seconds.
"""
)
```

**For enforcer agents (has prompt field with priority-ordered checks):**

Enforcer agents have a prompt that describes multiple conditions to check in priority order. Each condition maps to a different instruction. The agent evaluates top-down and returns the FIRST instruction that fires.

Valid enforcer instructions include all standard instructions plus:
- `RESUME_TASKS` -- master should check Hub.md for pending tasks and resume the highest-priority one
- `ASK_USER <message>` -- surface a message to the user

```
Agent(
  run_in_background: true,
  description: "scheduled: <name>",
  prompt: """
You are an enforcer agent for "<name>".
Your job: sleep, evaluate conditions in priority order, return the highest-priority instruction that fires.

SLEEP: <interval> minutes.
<sleep_instructions>

When you wake, evaluate these checks IN ORDER (stop at the first that fires):
<prompt from config>

Return format:
SCHEDULED: <name>
INSTRUCTION: <the instruction from the first check that fired, e.g., RESUME_TASKS, UPDATE_HUB, /save, ASK_USER <msg>, or NONE>
CONTEXT: <one line: which check fired and why>
REMINDER: Surface pending questions.

Read Hub.md and heartbeat files as needed. Keep total evaluation under 15 seconds.
"""
)
```

**Sleep instruction generation:**
- interval <= 10: `Run: sleep <interval * 60>`
- interval 20: `Run these in sequence: sleep 600 then sleep 600`
- interval 30: `Run these in sequence: sleep 600 then sleep 600 then sleep 600`
- interval N: chain `sleep 600` calls, final call is `sleep <remainder * 60>` if not evenly divisible

**Full expanded example (15-minute housekeeper):**
The `<sleep_instructions>` placeholder in the prompt template gets replaced with the literal chain. The agent receives:
```
You are a timer for scheduled agent "housekeeper".
Your job: sleep, evaluate briefly, then return one instruction.

Step 1: Run this exact command using the Bash tool:
sleep 600

Step 2: Run this exact command using the Bash tool:
sleep 300

Step 3: AFTER both sleeps complete (15 minutes total), evaluate:
[evaluation checks here]

Step 4: Return in this format:
SCHEDULED: housekeeper
INSTRUCTION: [result]

Do NOT return before both sleeps complete. Each sleep is a separate Bash tool call.
```

**Why this matters:** Agents that receive vague instructions like "sleep 15 minutes" will not chain correctly. They may delegate the sleep to a background task and return immediately, or try a single `sleep 900` that exceeds the 600-second Bash timeout. The literal step-by-step format above is the proven pattern.

6. Confirm: "Started scheduled agent '<name>' (every <interval>m). Next interrupt in ~<interval> minutes."

### /schedule stop <name>

1. Mark the agent as stopped in the session's runtime state
2. Note: the currently sleeping agent will still return when it wakes. When it does, the scheduled-agent-interrupts rule checks if it's stopped and skips re-spawn.
3. Confirm: "Stopped scheduled agent '<name>'. Current timer will expire without re-spawn."

### /schedule add <name> <interval> <instruction> [description]

1. Validate: name is unique, interval is a positive number
2. Add to scheduledAgents array in jitneuro.json:
```json
{
  "name": "<name>",
  "interval": <interval>,
  "enabled": true,
  "instruction": "<instruction>",
  "description": "<description or 'Custom scheduled agent'>"
}
```
3. Ask: "Start '<name>' now? (yes/no)"
4. If yes: run /schedule start <name>

### /schedule remove <name>

1. Find agent in config
2. If running, stop it first
3. Remove from scheduledAgents array in jitneuro.json
4. Confirm: "Removed scheduled agent '<name>' from config."

## Instruction Types

The `instruction` field supports:

| Instruction | What master does | Example |
|------------|-----------------|---------|
| `/save`, `/health`, etc. | Run the slash command | `"instruction": "/save"` |
| `UPDATE_HUB` | Sync TodoWrite to Hub.md | `"instruction": "UPDATE_HUB"` |
| `RESUME_TASKS` | Pick next pending task, execute | `"instruction": "RESUME_TASKS"` |
| `ASK_USER <msg>` | Surface message to user | `"instruction": "ASK_USER Check deploy status"` |
| `BASH <cmd>` | Run bash command | `"instruction": "BASH git fetch --all"` |
| `PWSH <cmd>` | Run PowerShell command | `"instruction": "PWSH Get-Process node"` |
| `NONE` | No action, just re-spawn | Returned by smart agents when no action needed |

**Examples with bash/PowerShell:**

```json
{
  "name": "git-fetch",
  "interval": 60,
  "enabled": true,
  "instruction": "BASH git fetch --all --prune",
  "description": "Keep all remotes fresh every hour"
}
```

```json
{
  "name": "test-runner",
  "interval": 30,
  "enabled": true,
  "instruction": "BASH cd /path/to/repo && npm test",
  "description": "Run tests every 30 minutes during development"
}
```

Smart agent with bash fallback:
```json
{
  "name": "deploy-check",
  "interval": 10,
  "enabled": true,
  "instruction": "BASH gh run list --limit 1 --json status,conclusion",
  "prompt": "Check if a deploy is in progress. If the latest GitHub Actions run is 'in_progress', return the BASH instruction. If completed or no runs, return NONE.",
  "description": "Monitor active deploys"
}
```

## Important
- Scheduled agents are one-shot timer agents. They sleep once, return once, die. Master re-spawns them per the guardrail rule.
- The /schedule command manages config and spawns. The guardrail rule in scheduled-agent-interrupts.md handles the interrupt + re-spawn cycle.
- Sleep uses chained `sleep 600` (10 min max per bash call). Forward slashes in all paths.
- Agent descriptions use "scheduled: <name>" prefix so they're identifiable in agent lists.
- Smart agents (with prompt) should keep evaluation under 10 seconds and read at most 2-3 files.
- Enforcer agents (with priority-ordered prompt) may read up to 5 files but should complete evaluation in under 15 seconds.
- Do not spawn agents for disabled entries (enabled: false).

## Sleep Reliability

Sleep instructions MUST be explicit and specific in the agent prompt. The agent must run `sleep <seconds>` via the Bash tool directly -- not delegate to a background task, not use run_in_background for the sleep itself, and not wrap sleep in any other construct.

Rules:
- Bash `sleep` has a per-call timeout limit (max 600 seconds / 10 minutes).
- For intervals >10 minutes, chain multiple `sleep 600` calls sequentially. Example: 15 minutes = `sleep 600` then `sleep 300`. 30 minutes = three `sleep 600` calls.
- The sleep chain must appear as literal instructions in the agent prompt (e.g., "Run: sleep 600 via Bash tool. Then run: sleep 300 via Bash tool."). Do not say "sleep for 15 minutes" -- the agent will not know to chain.
- Each `sleep` call must be a separate Bash tool invocation, not chained with `&&` or `;` in a single command. This ensures each call stays under the timeout.
- If a sleep call fails or times out, the agent should return immediately with its evaluation rather than retrying the sleep.

## Instruction Reference

All valid instructions that scheduled agents can return:
- `NONE` -- no action needed this cycle
- `/save` -- run /save command
- `UPDATE_HUB` -- sync TodoWrite state to Hub.md
- `RESUME_TASKS` -- master checks Hub.md for pending tasks and resumes the highest-priority one
- `SURFACE_QUESTIONS` -- display the pending questions queue immediately
- `ASK_USER <message>` -- surface a message to the user immediately
- `BASH <command>` -- run a bash command via Bash tool
- `PWSH <command>` -- run a PowerShell command via Bash tool (pwsh -Command "...")
- `/<command>` -- run any slash command
- `REMINDER: <text>` -- appended to any instruction, master executes alongside the main instruction
