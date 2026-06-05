---
type: pattern
purpose: MUST be consulted by any master agent deciding how to dispatch 15+ homogeneous tasks or any workflow with complex inter-task dependencies before choosing flat master->agent dispatch -- because flat dispatch at that scale bloats master context with tracking state, prevents parallel wave execution, and produces an unrecoverable failure if master context fills before all workers return; skipping sub-orchestrator promotion means tracking complexity lives in the master layer where it degrades planning and routing for the entire session.
read_when: Before dispatching 15 or more homogeneous tasks or any workflow with complex inter-task dependencies from a master session.
tags: [orchestration, scale, batching, workers]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
---

# Sub-Orchestrator Pattern

When the work exceeds what a flat master->agent dispatch can handle, the master delegates orchestration itself. A sub-orchestrator is an agent whose job is not to do work, but to manage agents that do work.

## When to Use This Pattern

| Scenario | Flat dispatch (master->agents) | Sub-orchestrator |
|----------|-------------------------------|------------------|
| 5-15 independent tasks | Yes | Overkill |
| 15-30 tasks, same type | Maybe (wave dispatching) | Better |
| 30+ tasks, same type | No (master context bloats) | Yes |
| Mixed task types (audit + fix + validate) | Yes (one per type) | Per-type sub-orchestrator |
| Tasks with complex inter-dependencies | Case by case | Yes (orchestrator manages ordering) |

**Rule of thumb:** If you need more than 2 waves of dispatch, or the tracking logic itself is complex, promote the tracking to a sub-orchestrator.

## Architecture

```
MASTER (thin -- routes, approves, reviews)
  |
  |-- SUB-ORCHESTRATOR (manages N workers in batches)
  |     |-- Worker Agent 1
  |     |-- Worker Agent 2
  |     |-- ...
  |     |-- Worker Agent N
  |     |
  |     |-- Writes: progress log (.md file)
  |     |-- Returns: summary + log path + aggregate scores
  |
  |-- (other agents or sub-orchestrators)
  |
  MASTER: reviews summary, approves, next action
```

### Role Separation

| Role | Reads files? | Writes code? | Manages agents? | Talks to owner? | Heavy lifting? |
|------|-------------|-------------|----------------|----------------|---------------|
| Master | No (summaries only) | No | Yes (dispatches sub-orchestrators) | Yes | None -- routes and approves |
| Sub-orchestrator | Index file only | No | Yes (manages worker pool) | No (returns to master) | Aggregation only |
| Worker agent | Yes (all of them) | Yes (if needed) | No | No (returns to orchestrator) | ALL of it |

**The deeper you go, the more work is assigned.** Master decides WHAT. Sub-orchestrator manages WHEN and HOW MANY. Workers do ALL the actual work -- reading, analyzing, fixing, writing reports, building summaries. Results flow up as thin pointers and executive summaries. Detail stays at the bottom in files on disk.

## The Pattern in Detail

### 1. Master Dispatches Sub-Orchestrator

Master defines:
- **What:** the overall goal (e.g., "score and fix all 77 blog posts")
- **Rules:** quality criteria, scoring rubric, pass/fail thresholds
- **Batch size:** how many workers to run concurrently (default: 10)
- **Log file:** path where the sub-orchestrator writes progress
- **Return format:** what master needs back (summary stats, category breakdown, log path)

```
Master prompt to sub-orchestrator:

You are a sub-orchestrator managing blog post quality scoring.

GOAL: Score all 77 blog posts against the quality rubric. Fix any scoring below 85.
RUBRIC: [SEO score, AEO score, Quality score -- all must be 85+]
POSTS: [list of 77 file paths]
BATCH SIZE: 10 concurrent workers
LOG FILE: <workspace-path>/<project>/.logs/quality-audit-2026-03-26.md
DIVERGENT MODE: AUTO

Instructions:
1. Dispatch workers in batches of 10
2. Each worker scores one post, returns: filename, SEO/AEO/Quality scores, pass/fail, issues found
3. If a post fails (<85 on any metric): dispatch a fix agent, then re-score
4. Log every result to the log file as workers complete (append, don't overwrite)
5. After all 77 are done, aggregate results and return summary to master

Return format:
STATUS: OK (or PARTIAL if some posts couldn't be fixed)
LOG: [path to log file]
SUMMARY:
  Total: 77 | Pass: 63 | Fixed: 11 | Failed: 3
  By category: [table]
  Lowest scores: [bottom 5]
FILES_CHANGED: [list of modified post files]
```

### 2. Sub-Orchestrator Manages Batches

The sub-orchestrator maintains a **rolling pool** of concurrent workers:

```
remaining = [all 77 posts]
active = []
max_concurrent = 10

# Initial fill -- launch up to max_concurrent
while len(active) < max_concurrent and remaining is not empty:
    task = remaining.pop(0)
    agent = dispatch worker (background)
    active.append(agent)

# Rolling loop -- as each completes, backfill immediately
while active is not empty:
    completed = wait for any one agent to complete

    log result to .md file
    if failed:
        dispatch fix agent, re-score, log fix result

    active.remove(completed)

    if remaining is not empty:
        task = remaining.pop(0)
        agent = dispatch worker (background)
        active.append(agent)
```

This is a **rolling pool, not batch-and-wait.** The sub-orchestrator launches 10 workers initially. When worker #1 finishes, worker #11 launches immediately -- there are always 10 running (until the remaining queue empties). This maximizes throughput because fast workers don't wait for slow ones in the same batch.

**Key behaviors:**
- Maintains max_concurrent active workers at all times (rolling, not batch-and-wait)
- Logs results as they arrive (progress is visible even if sub-orchestrator crashes)
- Fix-and-rescore happens inline when a worker completes, before backfilling the slot
- Sub-orchestrator itself stays thin -- it reads worker summaries, not file content

**Sizing max_concurrent:**
The right pool size depends on the machine's resources and the work each agent does:
- **CPU/memory:** Each agent consumes runtime memory. Monitor system resources and reduce pool size if the machine is under pressure.
- **Agent weight:** Lightweight agents (score one file, return 10 lines) can run 10-15 concurrently. Heavy agents (read 20+ files, write code, run tests) may need a pool of 3-5.
- **Claude Code heap:** The sub-orchestrator's own context grows with each result it processes. Workers should write heavy output to files and return only a pointer + executive summary (see "Write to File, Return the Pointer" below).
- **Start conservative:** Begin with 5, observe resource usage, scale up. Better to run 8 smoothly than 15 with thrashing.

### 3. Worker Agents Do the Actual Work

**Core principle: the deeper you go, the more work is assigned.** Workers do ALL the heavy lifting -- reading files, analyzing, fixing, writing reports, building summaries. The orchestrator layer above them should never have to dig into details to make routing decisions.

Each worker gets a self-contained prompt:

```
Score this blog post against the quality rubric.

FILE: <workspace-path>/<project>/content-drafts/ai-security-basics.md
RUBRIC:
  SEO: [criteria]
  AEO: [criteria]
  Quality: [criteria]

Write your full analysis to: <workspace-path>/<project>/.logs/scores/ai-security-basics.md
Start the file with an EXECUTIVE SUMMARY section (scores, pass/fail, issues -- everything
the orchestrator needs to act without reading the rest of the file).
Append the log index file: <workspace-path>/<project>/.logs/quality-audit-2026-03-26.md

Return to orchestrator (keep under 5 lines):
STATUS: OK
SCORES: SEO=87 AEO=91 Quality=83
PASS: false (Quality below 85)
DETAIL: .logs/scores/ai-security-basics.md
```

Workers are disposable. They read files, do the analysis, write the output to disk, update the shared log, and return a minimal pointer. Their context is fully consumed and freed.

### Write to File, Return the Pointer

**This is the most important pattern for keeping orchestrator context thin.**

Workers and sub-orchestrators should never pass heavy output up the chain. Instead:

1. **Worker writes full results to an .md file** -- analysis, findings, fix details, everything
2. **Worker writes an executive summary as the FIRST section** of that file -- scores, pass/fail, action needed. The orchestrator can read just this section if it needs more than the return line.
3. **Worker appends a one-line entry to a shared index/log file** -- the sub-orchestrator reads this file for aggregate status without collecting individual returns
4. **Worker returns to orchestrator: status + scores + file path** -- 3-5 lines max

```
Output hierarchy (worker produces all three):

1. Full report:    .logs/scores/ai-security-basics.md     (owner reads later)
   [EXECUTIVE SUMMARY at top -> full analysis below]

2. Index entry:    .logs/quality-audit-2026-03-26.md       (orchestrator reads for aggregate)
   | ai-security-basics.md | SEO=87 | AEO=91 | Quality=83 | FAIL | .logs/scores/ai-security-basics.md |

3. Return message: STATUS: OK / SCORES / PASS / DETAIL path  (orchestrator receives directly)
   [3-5 lines, just enough to route]
```

**Why the executive summary matters:** If the sub-orchestrator needs to make a decision about a worker's output (retry? escalate? skip?), it reads the executive summary section of the output file -- NOT the full report, and NOT a verbose return message. The worker already did the thinking and distilled it. The orchestrator just acts on the distillation.

**Why the index file matters:** The sub-orchestrator doesn't need to collect and assemble results from 77 individual returns. Workers append to a shared log as they complete. When all workers finish, the log IS the aggregate report. The sub-orchestrator reads it once, builds the final summary for master, done.

This pattern scales to any depth. A sub-orchestrator returning to master follows the same rule: write the detailed aggregate to a file, return the pointer + executive summary.

### 4. Sub-Orchestrator Returns to Master

The sub-orchestrator follows the same "write to file, return the pointer" pattern. Workers already built the index file as they ran. The sub-orchestrator reads that index, builds an executive summary, writes the detailed aggregate report to disk, and returns a thin summary to master.

After all 77 posts are processed:

```
STATUS: OK
LOG: <log-path>/quality-audit-2026-03-26.md
SUMMARY:
  Total: 77 | Pass: 63 | Fixed: 11 | Failed: 3
  By category: [table showing pass/fix/fail counts per category]
  Lowest scores: [bottom 5 posts with their scores]
FILES_CHANGED: [list of 11 modified post files]
```
