---
type: skill
purpose: Manage scheduled agents (list, start, stop, add, remove) across three agent types using the sleep-chain pattern; skipping means housekeeping tasks like auto-save and hub-sync are never automated and must be run manually.
read_when: When configuring, starting, stopping, or auditing a scheduled or timer agent.
tags: [schedule, scheduled-agents, timer-agents, smart-agents, enforcer-agents, automation]
scope: public
status: canonical
graduation_target: skills/schedule/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /schedule

Manage scheduled agents. Three agent types.

## Agent types

### Simple timer agent
Wakes at interval, executes a fixed instruction, re-spawns.
- Example: auto-save every 10 minutes
- Config: `type: "timer"`, `interval: 600`, `instruction: "/save"`

### Smart agent
Wakes at interval, evaluates context, decides whether to act.
- Example: hub-sync checks if Hub.md is stale before updating
- Config: `type: "smart"`, `interval: 900`, `prompt: "..."`

### Enforcer agent
Monitors for rule violations, interrupts immediately on detection.
- Example: watch for trust-zone RED actions attempted without permission
- Config: `type: "enforcer"`, `watch: "..."`, `instruction: "ASK_USER ..."`

## Sleep chain pattern

Agents are one-shot (sleep, return, die). Master re-spawns after each return.

Implementation:
```
sleep 600 && echo "INSTRUCTION: /save"
```

Not an infinite loop. The sleep terminates the process. Master's re-spawn creates the next iteration.

## Operations

### `/schedule list`
Show all scheduled agents from jitneuro.json with status (running/stopped).

### `/schedule start <name>`
Spawn the named agent from config. Sets status to running.

### `/schedule stop <name>`
Signal the agent to not re-spawn after current cycle. Sets enabled: false.

### `/schedule add <name>`
Interactively create a new scheduled agent config entry in jitneuro.json.

### `/schedule remove <name>`
Remove a scheduled agent from jitneuro.json. Stops it first if running.

## Config location

Agent definitions in `<repo>/.jitneuro/jitneuro.json` under `scheduledAgents` array.

## Trust model

Configured agents are trusted. Their instructions execute without confirmation (per scheduled-agent-interrupts.md rule).
