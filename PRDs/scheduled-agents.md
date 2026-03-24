# PRD: Scheduled Agents System

**Feature:** Scheduled Agents (Timer Agent Pattern)
**Version:** v0.4.0
**Status:** Approved
**Date:** 2026-03-24
**GitHub Issue:** #16 (autosave), new issue for system

## Problem

Master gets tunnel vision during deep coding work. It forgets housekeeping:
- Session state goes unsaved for hours
- TodoWrite and Hub.md drift out of sync with actual progress
- Deploy failures go unnoticed
- Users return to stale status boards

Manual discipline fails because master deprioritizes housekeeping under cognitive load.
The PreCompact hook only fires at compaction -- not on a regular interval.

## Solution

A generic **scheduled agent system** that spawns lightweight timer agents. Each agent sleeps for a configured interval, then returns an instruction that master MUST execute immediately. The agent is an interrupt mechanism -- it forces master to stop current work and do housekeeping.

## Architecture

### Timer Agent Pattern

```
Master (session start) -> spawns timer agent (background)
Timer agent: sleep N minutes -> return INSTRUCTION -> dies
Master: receives notification -> executes instruction -> re-spawns timer
```

### Constraints (verified)
- Subagents CANNOT spawn subagents (no Agent tool available)
- Bash sleep max 600s per call (chain for longer intervals)
- Agent context is fixed-size per instance (never grows)
- Master is the only entity that can spawn agents

### Why Agent Does NOT Do The Work
The agent is a timer + instruction generator. Master does the actual work because:
1. Master has full session context (knows what changed, what's dirty)
2. Master has the TodoWrite state in memory
3. Master can run /save with full context
4. Agent doing heavy reads/writes would grow its context needlessly

## Config Schema

`jitneuro.json` new top-level key:

```json
{
  "scheduledAgents": [
    {
      "name": "autosave",
      "interval": 30,
      "enabled": true,
      "instruction": "/save",
      "description": "Auto-save session state every 30 minutes"
    },
    {
      "name": "hub-sync",
      "interval": 10,
      "enabled": true,
      "instruction": "UPDATE_HUB",
      "prompt": "Check if TodoWrite tasks and Hub.md are in sync with current work. If drift detected, update both. Report what changed.",
      "description": "Keep TodoWrite and Hub.md current every 10 minutes"
    }
  ]
}
```

Fields:
- `name`: unique identifier
- `interval`: minutes between cycles (chains sleep 600 calls)
- `enabled`: boolean, can be toggled at runtime via /schedule
- `instruction`: what master should do. Either a slash command or a keyword:
  - `/save`, `/health`, etc. -- run the command
  - `UPDATE_HUB` -- sync TodoWrite to Hub.md
  - `ASK_USER <message>` -- surface a question to the user
  - `NONE` -- log only, no action (for monitoring agents)
- `prompt` (optional): for smart agents, additional context the timer agent evaluates before returning. If prompt is set, the agent reads state and may override the default instruction.
- `description`: human-readable purpose

## User Stories

### US-001: Auto-launch scheduled agents on session start
**As a** user loading a session
**I want** all enabled scheduled agents to start automatically
**So that** I get housekeeping interrupts without remembering to start them

**Acceptance criteria:**
- SessionStart hook reads scheduledAgents from jitneuro.json
- For each enabled agent, master spawns a background timer agent
- Agents begin their first sleep cycle immediately
- No user action required

### US-002: Autosave agent (default, 30 min)
**As a** user in a long session
**I want** session state saved automatically every 30 minutes
**So that** I never lose more than 30 minutes of context on crash/compact

**Acceptance criteria:**
- Timer agent sleeps 30 minutes, returns INSTRUCTION: /save
- Master executes /save immediately on receiving the instruction
- Master re-spawns the timer agent
- Runs indefinitely until session ends or user stops it

### US-003: Hub-sync agent (default, 10 min)
**As a** user deep in coding
**I want** TodoWrite and Hub.md kept in sync automatically
**So that** my task status is always accurate for /dashboard and session recovery

**Acceptance criteria:**
- Timer agent sleeps 10 minutes
- On wake, reads TaskList and Hub.md, checks for drift
- Returns INSTRUCTION: UPDATE_HUB if drift detected, NONE if in sync
- Master updates Hub.md immediately when instructed
- Master re-spawns the timer agent

### US-004: /schedule command for runtime management
**As a** user
**I want** to list, start, stop, add, and remove scheduled agents at runtime
**So that** I can control which agents are active without editing config

**Acceptance criteria:**
- `/schedule` or `/schedule list` -- show all agents with status (running/stopped/enabled/disabled)
- `/schedule start <name>` -- spawn the timer agent now
- `/schedule stop <name>` -- mark as stopped (do not re-spawn on next return)
- `/schedule add <name> <interval> <instruction>` -- add a new agent to config
- `/schedule remove <name>` -- remove from config

### US-005: Mandatory interrupt guardrail
**As a** user who configured scheduled agents
**I want** master to ALWAYS obey the agent's instruction immediately
**So that** housekeeping actually happens even when master is deep in work

**Acceptance criteria:**
- Guardrail rule loaded every session
- Master stops current work when scheduled agent returns
- Master executes instruction before resuming
- No confirmation needed -- scheduled agents are user-configured and trusted

### US-006: Smart agent with prompt evaluation
**As a** user
**I want** some scheduled agents to evaluate state before returning
**So that** unnecessary interrupts are avoided (e.g., hub-sync skips if already in sync)

**Acceptance criteria:**
- If agent config has `prompt`, agent executes the prompt logic on wake
- Agent may return INSTRUCTION: NONE if no action needed
- Master still re-spawns the timer (NONE means "nothing this cycle")

## Timer Agent Prompt Template

### Simple (command-only):
```
You are a timer for scheduled agent "{name}".
Your job: sleep, then return one instruction. Nothing else.

SLEEP: {interval} minutes. Use chained `sleep 600` bash calls.
For {interval} min: {sleep_chain}

When you wake, return EXACTLY:
SCHEDULED: {name}
INSTRUCTION: {instruction}

Do no other work. Do not read files. Do not analyze anything.
Just sleep and return.
```

### Smart (with prompt):
```
You are a timer for scheduled agent "{name}".
Your job: sleep, evaluate, then return one instruction.

SLEEP: {interval} minutes. Use chained `sleep 600` bash calls.
For {interval} min: {sleep_chain}

When you wake:
{prompt}

Then return one of:
SCHEDULED: {name}
INSTRUCTION: {resolved_instruction}
CONTEXT: {brief explanation if relevant}

Or if no action needed:
SCHEDULED: {name}
INSTRUCTION: NONE

Keep evaluation lightweight. Read at most 2-3 files. Decide fast.
```

## Out of Scope (v0.4.0)
- Agent-to-agent communication (future: agents coordinating schedules)
- Persistent agent state across re-spawns (each instance is fresh)
- Web UI for schedule management
- Cron-style scheduling (just intervals for now)
