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

### /schedule start <name>

1. Find the agent config by name in scheduledAgents
2. If not found: "No scheduled agent named '<name>'. Use /schedule add to create one."
3. If already running: "Agent '<name>' is already running."
4. Calculate sleep chain: `interval / 10` rounded up = number of `sleep 600` calls. Remainder handled by a shorter final sleep.
5. Spawn the timer agent as a background Agent:

**For simple agents (no prompt field):**
```
Agent(
  run_in_background: true,
  description: "scheduled: <name>",
  prompt: """
You are a timer for scheduled agent "<name>".
Your ONLY job: sleep, then return one instruction. Nothing else.

SLEEP: <interval> minutes.
<sleep_instructions>

When you wake, return EXACTLY this and nothing else:
SCHEDULED: <name>
INSTRUCTION: <instruction>

Do no other work. Do not read files. Do not analyze anything. Just sleep and return.
"""
)
```

**For smart agents (has prompt field):**
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

**Sleep instruction generation:**
- interval <= 10: `Run: sleep <interval * 60>`
- interval 20: `Run these in sequence: sleep 600 then sleep 600`
- interval 30: `Run these in sequence: sleep 600 then sleep 600 then sleep 600`
- interval N: chain `sleep 600` calls, final call is `sleep <remainder * 60>` if not evenly divisible

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

## Important
- Scheduled agents are one-shot timer agents. They sleep once, return once, die. Master re-spawns them per the guardrail rule.
- The /schedule command manages config and spawns. The guardrail rule in scheduled-agent-interrupts.md handles the interrupt + re-spawn cycle.
- Sleep uses chained `sleep 600` (10 min max per bash call). Forward slashes in all paths.
- Agent descriptions use "scheduled: <name>" prefix so they're identifiable in agent lists.
- Smart agents (with prompt) should keep evaluation under 10 seconds and read at most 2-3 files.
- Do not spawn agents for disabled entries (enabled: false).
