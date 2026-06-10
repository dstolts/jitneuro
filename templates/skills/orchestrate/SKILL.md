---
type: skill
purpose: Auto-route tasks to subagents with appropriate context bundles using four dispatch strategies; skipping means agents run without domain context and produce lower-quality output.
read_when: Before dispatching multiple tasks to subagents to select the correct strategy (single, parallel, sequential, or pipeline) and load the right context bundles.
tags: [orchestrate, subagent, routing, bundles, multi-agent, dispatch]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /orchestrate

Auto-route tasks to subagents with context bundles. Four dispatch strategies.

## Strategies

### 1. Single agent
One subagent, one task, one bundle.

```
/orchestrate "fix the login bug"
```

Routes: "login / auth" -> loads [integrations] bundle -> single subagent with context.

### 2. Parallel agents
Multiple independent tasks, each with own bundle, dispatched simultaneously.

```
/orchestrate parallel "audit the API" "review the frontend" "check deployments"
```

Dispatches 3 concurrent subagents. Returns when all complete.

### 3. Sequential agents
Tasks with dependencies. Each agent's output feeds the next.

```
/orchestrate sequential "design the schema" "implement the schema" "write migration"
```

Agent 1 completes -> output passed to Agent 2 -> output passed to Agent 3.

### 4. Main context
Master handles the task directly with bundles loaded into main context.

```
/orchestrate context "review the architecture"
```

Loads relevant bundles into master's own context. No subagent dispatch.

## Bundle routing

Routing weights (from context-manifest.md / INDEX.md) determine which bundles load for a task.
If no bundle matches the task keywords, master prompts: "No bundle found for this domain. Use [bundle-name] or proceed without context?"

## Return format

Subagents return per subagent-communication.md protocol (STATUS/TOKENS/FILES_CHANGED/RESULT).
Master consolidates and presents a summary after all agents complete.
