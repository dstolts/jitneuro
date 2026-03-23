# Multi-Agent Orchestration Pattern

## The Problem

Complex validation, refactoring, and build tasks across large codebases consume master context fast. A single agent reading 50+ files, analyzing them, and making fixes will hit context limits before finishing -- losing all progress.

## The Pattern: Thin Master, Fat Agents

The master agent acts as a **dispatcher and aggregator only**. It never reads file content directly. Subagents do all the heavy lifting in isolated contexts, then return short structured summaries.

### Roles

| Role | Responsibility | Context usage |
|------|---------------|---------------|
| Master | Dispatch tasks, collect results, report to owner, make decisions | Minimal -- summaries only |
| Subagent | Read files, analyze, fix, build | Full -- but disposable |

### Rules

1. Master never reads file content -- only dispatches and aggregates
2. Each subagent gets a self-contained prompt with everything it needs (file paths, what to check, expected values)
3. Subagents return short structured results (pass/fail + issues found, under 15 lines)
4. All independent agents run in parallel (background)
5. Master consolidates into one report when all complete

## How to Split Work

### By independence

Tasks that touch **different files** can run in parallel. Tasks that touch the **same file** must be sequenced or combined into one agent.

Before dispatching, map which files each agent will touch. If two agents would edit the same file, merge them into one agent or run them sequentially.

### By scope

| Split strategy | When to use | Example |
|----------------|------------|---------|
| One per category/module | Validation across many similar units | 14 categories, 1 agent each |
| One per priority tier | Fixes at different severity levels | P0 agent, P1 agent, P2 agent |
| One per file group | Changes that naturally cluster | "all template.yml files", "all router files" |
| One per task type | Different kinds of work | "run tests", "static analysis", "build new templates" |

### Sizing guidance

- **Too small:** 1 agent per file -- overhead of dispatching exceeds value
- **Right size:** 1 agent per logical unit (category, module, priority tier)
- **Too large:** 1 agent for "fix everything" -- defeats the purpose

## Real Example: Prompt Quality Validation Sprint

### Phase 1: Validation (17 agents, all parallel)

```
Agent A:  npm test (Jest suite)
Agent B:  fail-fast behavior test
Agent C:  legacy template cleanup check
Agents D1-D14:  one per category (automotive, marine, computer, etc.)
```

Each category agent checked:
- Scoring criteria present
- Expertise levels use correct terms
- No emoji characters
- Model references current
- Parts-sourcing uses correct model
- No fabricated part numbers

Each returned a 5-10 line table: check name, PASS/FAIL, details.

Master consolidated into one report showing all 14 categories, pattern detection (Tier 1 vs Tier 2 categories), and prioritized fix list.

### Phase 2: Fixes (5 agents, all parallel)

Based on the consolidated report, master dispatched fix agents by **file group** (not by category) to avoid conflicts:

```
Agent 1:  P0 fail-fast gaps (category-templates.js, analysis-service/index.js)
Agent 2:  P0+P1 stale models + expertise (heavy_equipment/template.yml, schema doc, router-v2.js)
Agent 3:  P1 expertise metadata (automotive/template.yml, computer/template.yml)
Agent 4:  P1 marine prompt fixes (5 prompt files, template.yml)
Agent 5:  V2.5 build + activation (new directory, config files)
```

No file overlap between agents -- all ran in parallel safely.

### Phase 3: Cleanup (1 agent)

Rename/standardize agent swept codebase for terminology consistency.

## How to Think About It

1. **Start with the full scope.** What needs to be validated, fixed, or built?
2. **Map the file dependencies.** Which tasks touch which files?
3. **Group by independence.** Tasks with no file overlap = parallel. Same files = combine or sequence.
4. **Write self-contained prompts.** Each agent needs: exact file paths, what to look for, expected values, and a report format.
5. **Cap the return.** Tell agents to keep reports under 10-15 lines. Master context is the bottleneck.
6. **Consolidate and decide.** Master builds one report, identifies patterns, prioritizes next wave.
7. **Repeat.** Validation -> Fix -> Validation is the loop.

## Anti-Patterns

- **Master reads files "to understand context"** -- this is the #1 context killer. Let agents read files.
- **One mega-agent for everything** -- if it runs out of context, all progress is lost.
- **Agents with overlapping file writes** -- race conditions and overwrites.
- **No report format specified** -- agents return 200-line analyses that bloat master context.
- **Sequential when parallel is possible** -- if tasks are independent, run them together.

## Runtime Safety: Memory Exhaustion Prevention

Claude Code's JavaScript runtime (WebKit/Electron) crashes with `MemoryExhaustion` when a single response accumulates too much context. This has caused crashes during large-batch file analysis (e.g., scanning 89 files against 26 rules in one pass).

**This is a primary motivator for the multi-agent pattern.** Single-agent operations hit memory ceilings on real workloads. Multi-agent orchestration distributes work across isolated processes, each with its own heap, making bulk operations safe by design.

### Guardrails

- **Max 25 files per agent.** Never have a single agent scan more than 25 files in one response. For larger sets, batch into groups of 20-25 across multiple agents.
- **Use subagents for bulk reads.** Scanning, auditing, reviewing many files must use subagents (each gets its own memory). The master dispatches and aggregates only.
- **Avoid accumulating large tables.** If building a classification table across 50+ items, build incrementally across multiple responses or delegate to subagents that each build a portion.
- **Stream results, don't collect.** Report findings per-batch rather than collecting all results into one massive response.
- **Pre-count before scanning.** Before starting a bulk operation, count the files first. If >25, plan the batching strategy before reading any files.
- **Wave dispatching.** If you need more than 25-30 agents, dispatch in waves of 15. Collect results, then dispatch the next wave.

### Why This Matters

The crash stack trace: `MemoryExhaustion: Crash intentionally because memory is exhausted` in `JavaScriptCore/heap/LocalAllocator.cpp`. This is the JS heap in Claude Code's Electron runtime, NOT the AI model context window. Large single-pass operations exceed the heap. The fix is multi-agent batching, not reducing context window size. Every scan, audit, review, and sprint execution benefits from orchestrated subagents rather than single-agent accumulation.

## Subagent Communication Protocol

Subagents can't proactively ask the master a question mid-execution. If a subagent hits ambiguity, it must signal this in its return. The master then decides: answer and re-dispatch, skip, or escalate to the user.

### Structured Return Schema

Every subagent must return one of three status codes as the first line:

```
STATUS: OK
[result data]

STATUS: BLOCKED
QUESTION: [what the agent needs to know]
CONTEXT: [what it found so far, so master doesn't re-do the work]
PARTIAL_RESULT: [any usable output before the block]

STATUS: PARTIAL
COMPLETED: [what was done]
SKIPPED: [what was skipped and why]
[partial result data]
```

**OK** -- agent completed all work. Master processes the result.

**BLOCKED** -- agent hit ambiguity it can't resolve. Master reads the question, either answers it (from context, rules, or by asking the user) and re-dispatches via `SendMessage`, or skips that agent's work.

**PARTIAL** -- agent completed some work but couldn't finish everything. Master uses what's available, dispatches a follow-up agent for the remainder if needed.

### SendMessage Relay (for BLOCKED agents)

When a subagent returns BLOCKED, the master can continue it with the answer:

```
1. Master dispatches Agent A (background)
2. Agent A returns: STATUS: BLOCKED / QUESTION: "Is this repo using ESM or CJS?"
3. Master checks engram or asks user
4. Master uses SendMessage to Agent A: "ESM. Package.json has type: module."
5. Agent A resumes with full context preserved, completes work
6. Agent A returns: STATUS: OK / [result]
```

The key advantage: Agent A doesn't lose its context. It already read the files, built its understanding, and just needs one answer to proceed. Re-dispatching a fresh agent would re-do all that work.

### Dashboard Integration

Subagents should write status to the dashboard JSON when configured:

**On dispatch** (master writes):
```json
{
  "id": "agent-001",
  "name": "Audit: backend-api",
  "status": "running",
  "repo": "backend-api",
  "started": "2026-03-23T15:00:00Z",
  "bundles": ["infrastructure"]
}
```

**On completion** (master updates after receiving result):
```json
{
  "id": "agent-001",
  "status": "completed",
  "duration": "12s",
  "result": "OK -- 3 issues found",
  "finished": "2026-03-23T15:00:12Z"
}
```

**On BLOCKED** (master updates):
```json
{
  "id": "agent-001",
  "status": "blocked",
  "question": "Is this repo using ESM or CJS?",
  "blockedAt": "2026-03-23T15:00:08Z"
}
```

The HTML dashboard polls this JSON and displays agent cards with live status. BLOCKED agents show a yellow card with the question, so the user can answer even before the master asks.

### Relay to User (Pending Questions Integration)

When a subagent returns BLOCKED and the master can't answer from its own context:

1. Master adds the question to the **pending questions queue** (see rules/pending-questions.md)
2. The question is surfaced at the end of the current response
3. When the user answers, master uses SendMessage to unblock the agent
4. If the user dismisses the question ("clear N"), master cancels the agent's work

This connects subagent communication to the pending questions system -- blocked agents become visible questions for the user, not silent failures.

## Context Budget Math

A master agent with 200K context can handle roughly:
- 20-30 agent dispatches (prompts ~500 tokens each)
- 20-30 agent results (summaries ~300 tokens each)
- System prompt + conversation overhead (~30K tokens)
- Leaves ~150K for owner interaction, decisions, and follow-up dispatches

If you need more than 30 agents, run in waves (dispatch 15, collect, dispatch 15 more).
