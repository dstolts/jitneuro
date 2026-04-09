# User Story: Watcher Agent Architecture

**Created:** 2026-03-27
**Priority:** 90/100
**Status:** Needs planning (divergent thinking recommended)
**Handoff:** Agent-ready after planning phase

## Problem

JitNeuro currently defines scheduled agents as single-purpose: one agent per concern (autosave every 30m, hub-sync every 10m). As we add more enforcement behaviors (task watcher, pending questions, session ID checkpoints, proactive monitoring), this creates agent sprawl:

```
Current:
  autosave         (30m)  -- /save
  hub-sync         (10m)  -- UPDATE_HUB

Proposed (single-purpose):
  autosave         (30m)  -- /save
  hub-sync         (10m)  -- UPDATE_HUB
  task-watcher     (5m)   -- RESUME_TASKS
  pending-q-sync   (15m)  -- sync pending questions to Hub.md
  session-id-check (30m)  -- verify session ID in checkpoint
  bg-task-monitor  (1m)   -- check background agent outputs for red flags
```

Six agents all self-looping, all consuming context, all interrupting master. That's overhead.

## Key Question

**Should multiple enforcement behaviors merge into a single watcher agent with multiple check functions?**

Example merged agent:
```
"housekeeping-enforcer" (5m, self-loop):
  Every cycle:
    1. Check TaskList -- tasks pending but master idle? -> RESUME_TASKS
    2. Check Hub.md drift -- TodoWrite out of sync? -> UPDATE_HUB
    3. Check last /save timestamp -- stale? -> /save
    4. Check pending questions -- any unanswered? -> surface them
    5. Check background agent outputs -- red flags? -> ALERT
    6. If nothing needed -> NONE (self-loop continues)
```

One agent, one context, one interrupt cadence. But is that actually better?

## Evaluate (divergent thinking -- consider multiple approaches)

### Approach A: Single Merged Watcher

One `housekeeping-enforcer` agent handles all enforcement checks in a single evaluation loop.

```json
{
  "name": "housekeeping",
  "type": "enforcer",
  "interval": 5,
  "selfLoop": true,
  "maxHours": 8,
  "enabled": true,
  "prompt": "Evaluate all housekeeping checks. Return the HIGHEST PRIORITY instruction needed.",
  "checks": [
    { "name": "task-resume", "instruction": "RESUME_TASKS", "priority": 1 },
    { "name": "hub-sync", "instruction": "UPDATE_HUB", "priority": 2 },
    { "name": "autosave", "instruction": "/save", "priority": 3 },
    { "name": "pending-questions", "instruction": "SURFACE_QUESTIONS", "priority": 4 },
    { "name": "bg-monitor", "instruction": "ALERT", "priority": 5 }
  ]
}
```

**Pros:**
- One agent, one context allocation, one interrupt
- Checks can share state (e.g., "I just checked TaskList, hub-sync can reuse that")
- Simpler to manage -- one config entry
- Priority ordering built in (task resume > hub sync > save)

**Cons:**
- Agent context grows over self-loop cycles (doing 5 checks per cycle)
- If one check is slow (reading many files for hub-sync), all checks are delayed
- Single point of failure -- if the agent crashes, ALL enforcement stops
- Different checks need different intervals (save every 30m, task watch every 5m)

### Approach B: Separate Agents per Concern

Current model extended. Each behavior is its own agent with its own interval.

**Pros:**
- Each agent is simple, focused, easy to debug
- Different intervals per concern (task watcher at 5m, save at 30m)
- One agent crashing doesn't kill the others
- Easy to enable/disable individual behaviors

**Cons:**
- Agent sprawl (6+ background agents)
- Each agent has its own context allocation
- Multiple interrupts hitting master in quick succession
- Harder to coordinate (hub-sync and save might fire simultaneously)

### Approach C: Tiered Watchers (hybrid)

Two agents: one fast enforcer (high-priority, short interval) and one slow housekeeper (lower-priority, longer interval).

```json
[
  {
    "name": "enforcer",
    "type": "enforcer",
    "interval": 5,
    "selfLoop": true,
    "prompt": "Check: (1) Tasks pending but master idle? -> RESUME_TASKS. (2) Background agent output has red flags? -> ALERT. If neither, NONE.",
    "description": "Fast enforcement -- task resume + background monitoring"
  },
  {
    "name": "housekeeper",
    "type": "timer",
    "interval": 20,
    "prompt": "Check: (1) Hub.md drift? -> UPDATE_HUB. (2) Last save >30m ago? -> /save. (3) Pending questions unsurfaced? -> SURFACE_QUESTIONS. Return highest priority.",
    "description": "Periodic housekeeping -- sync, save, questions"
  }
]
```

**Pros:**
- Fast things stay fast (task watcher at 5m)
- Slow things batched together (hub+save+questions at 20m)
- Only 2 agents, not 6
- Enforcer failure doesn't kill housekeeping and vice versa
- Clear mental model: urgent enforcement vs routine maintenance

**Cons:**
- Still two agents (more than A, fewer than B)
- Housekeeper bundles concerns that might want independent intervals later

### Approach D: Event-Driven Instead of Polling

Instead of interval-based checking, watchers fire on events:
- Master completes a task -> check if more tasks exist (no polling needed)
- /save hasn't run in 30m -> timer fires once
- Hub.md written by subagent -> master notified to sync

**Pros:**
- Zero overhead when nothing is happening
- Instant response (no 5-minute polling delay)
- No self-looping agents consuming context

**Cons:**
- Claude Code doesn't have native event hooks for "master completed a task" or "file was modified by subagent"
- Would need PostToolUse hooks to detect idle state (complex, fragile)
- Mixing hook-based and agent-based enforcement adds complexity
- Some checks are inherently periodic (save every 30m regardless of events)

## Evaluation Matrix

| Criterion | A: Single | B: Separate | C: Tiered | D: Event |
|-----------|-----------|-------------|-----------|----------|
| Agent count | 1 | 6+ | 2 | 0 (hooks) |
| Context cost | Medium (5 checks per cycle) | High (6 agents) | Low (2 lean agents) | Lowest |
| Reliability | Single point of failure | Most resilient | Good (2 failure domains) | Fragile (hook complexity) |
| Interval flexibility | One interval for all | Full flexibility | Two tiers | Event-driven |
| Simplicity | Simple config, complex agent | Simple agents, config sprawl | Balanced | Complex infrastructure |
| Debuggability | One agent to check | Clear per-concern | Two to check | Hard (hook chains) |
| Implementable today | Yes | Yes | Yes | Partially (needs hook work) |

## Recommendation

**Approach C (Tiered Watchers)** with a path to incorporate D (event-driven) later.

Two agents cover everything:
1. **enforcer** (5m, self-loop) -- RESUME_TASKS + ALERT (time-sensitive)
2. **housekeeper** (20m, timer) -- UPDATE_HUB + /save + SURFACE_QUESTIONS (periodic maintenance)

This matches how the concerns naturally group:
- "Is Claude working?" = urgent, check often
- "Is the bookkeeping up to date?" = important but not urgent, batch it

## Acceptance Criteria

### AC-1: Define the two-agent config
- [ ] `enforcer` agent config in jitneuro.json with prompt covering RESUME_TASKS + background monitoring
- [ ] `housekeeper` agent config replacing current `autosave` + `hub-sync` with a merged prompt
- [ ] Priority ordering documented: RESUME_TASKS > ALERT > UPDATE_HUB > /save > SURFACE_QUESTIONS
- [ ] Backward compatible: existing autosave + hub-sync configs still work if user prefers separate

### AC-2: Add RESUME_TASKS instruction
- [ ] Add to `scheduled-agent-interrupts.md`: `INSTRUCTION: RESUME_TASKS` -- read TaskList, pick next pending, execute
- [ ] Add to `scheduled-agent-interrupts.md`: `INSTRUCTION: SURFACE_QUESTIONS` -- read pending questions, display to user
- [ ] Add to `scheduled-agent-interrupts.md`: `INSTRUCTION: ALERT <message>` -- display alert box to user

### AC-3: Update documentation
- [ ] Update `docs/scheduled-agents.md` with tiered watcher pattern
- [ ] Add to `templates/help.md` the "I Wish..." entries for task enforcement
- [ ] Update `docs/configuration-reference.md` with new instruction types
- [ ] Document migration from separate agents to tiered (optional, not forced)

### AC-4: Port missing behaviors
- [ ] Hub.md <-> TodoWrite bidirectional sync (agents write to Hub.md, master pulls into TodoWrite)
- [ ] Pending questions persistence (save to Hub.md, reload on /load)
- [ ] Proactive background task monitoring (check output within 15-30s)
- [ ] Session ID checkpoint verification

### AC-5: Update jitneuro template
- [ ] `templates/jitneuro.json` ships with the two-agent tiered config as default
- [ ] Separate agent configs remain as alternative examples in docs
- [ ] Install script creates the tiered config, not the old separate config

## Open Questions

1. Should the enforcer check interval be configurable per-check? (e.g., task-resume every 5m but bg-monitor every 1m within the same agent)
2. Should the housekeeper be a timer (return-to-master) or enforcer (self-loop)? Timer is simpler, enforcer is more reliable for the /save concern.
3. When we add event-driven hooks later (Approach D), should they REPLACE the polling agents or supplement them? (Belt and suspenders vs single mechanism)
4. Should the merged agents support a `checks` array in jitneuro.json (structured, per-check config) or keep it prompt-only (flexible, Claude figures it out)?
