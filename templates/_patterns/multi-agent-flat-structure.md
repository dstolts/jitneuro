---
type: pattern
purpose: Any architect or agent building a new multi-agent system must place the orchestrator as a flat sibling of its sub-agents -- applying this at the moment a new agents/<system>/ directory is being created -- because a parent-encapsulation hierarchy breaks meta-orchestrator composition, requires special-casing for every new agent tier, and diverges from the industry-standard flat convention used by LangGraph, CrewAI, OpenAI Swarm, and Anthropic's own published patterns.
trigger: creating a new multi-agent system directory or deciding where to place an orchestrator file relative to its sub-agents
read_when: Before creating a new multi-agent system directory or deciding where to place an orchestrator file relative to its sub-agents.
tags: [multi-agent, architecture, orchestration, directory-structure, composition]
scope: public
last_evaluated: 2026-06-03
origin: promoted from personal memory (project_multi_agent_orchestrator_pattern.md) -- Knowledge session 2026-06-01
---

# Multi-Agent Flat Structure

## Pattern

The orchestrator in a multi-agent system is just another agent with a coordination capability. Place the orchestrator file as a sibling of its sub-agents, not in a parent directory that encapsulates them. Everything is an agent; some agents delegate.

NOTE: This pattern may overlap with `_patterns/agent-hierarchy-levels.md` if that file exists. Owner/jk-team to reconcile scope and merge or differentiate at graduation.

## When to use

- Building any new multi-agent system (gates, evaluation chains, autonomous pipelines, orchestrator networks)
- Deciding where to place an orchestrator file relative to the agents it coordinates
- When a meta-orchestrator needs to coordinate other orchestrators (flat structure makes this composition trivial)

Not prescriptive about file naming conventions within the directory -- only the flat sibling relationship is required.

## Steps or structure

Recommended directory shape for a multi-agent system named `<system>`:

```
agents/<system>/
  README.md
  orchestrator.mjs        (or gate.mjs, coordinator.mjs -- the coordinating agent)
  sub-agent-a.mjs
  sub-agent-b.mjs
  configs/
    config.json
```

Do NOT create:
```
systems/<system>/         (separate tier for orchestrators)
orchestrators/<system>/   (orchestrators in a different namespace from agents)
agents/<system>/
  index.mjs               (orchestrator masquerading as an index file)
  agents/
    sub-agent-a.mjs       (sub-agents nested under another agents/ directory)
```

Applying the pattern:
1. Create `agents/<system>/` as the root for the entire system.
2. Place the orchestrator file at `agents/<system>/orchestrator.mjs` (or equivalent name).
3. Place all sub-agents as siblings at `agents/<system>/sub-agent-*.mjs`.
4. If a meta-orchestrator needs to coordinate multiple systems, it lives at `agents/meta-orchestrator.mjs` alongside the system directories -- same level, same sibling convention.

## Why flat

- Enables composition: a meta-orchestrator treats every system's orchestrator as just another agent -- no special-casing needed.
- One mental model: everything is an agent; coordination capability is just a role, not a structural tier.
- Matches industry convention: LangGraph, CrewAI, OpenAI Swarm, and Anthropic's published multi-agent research all use flat sibling structures, not parent-encapsulation hierarchies.
- The master agent lives alongside specialists, not above them in the directory tree.

## Origin

2026-04-20: the flat-sibling convention was confirmed across LangGraph, CrewAI, OpenAI Swarm, and Anthropic's research-system engineering post, then applied in production multi-agent tooling.

Related: any existing `_patterns/agent-hierarchy-levels.md` (jk-team to reconcile at graduation).
