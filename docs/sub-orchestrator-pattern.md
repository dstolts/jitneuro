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

| Role | Reads files? | Writes code? | Manages agents? | Talks to owner? |
|------|-------------|-------------|----------------|----------------|
| Master | No (summaries only) | No | Yes (dispatches sub-orchestrators) | Yes |
| Sub-orchestrator | No (summaries only) | No | Yes (dispatches workers in batches) | No (returns to master) |
| Worker agent | Yes | Yes (if needed) | No | No (returns to sub-orchestrator) |

Master never reads file content. Sub-orchestrator never reads file content. Only workers touch actual files. This keeps both master and sub-orchestrator context thin enough to handle large-scale operations.

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
LOG FILE: D:\Code\Automation\blog\.logs\quality-audit-2026-03-26.md
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
- **Claude Code heap:** The sub-orchestrator's own context grows with each result it processes. If managing 50+ workers, keep return summaries under 10 lines each.
- **Start conservative:** Begin with 5, observe resource usage, scale up. Better to run 8 smoothly than 15 with thrashing.

### 3. Worker Agents Do the Actual Work

Each worker gets a self-contained prompt:

```
Score this blog post against the quality rubric.

FILE: D:\Code\Automation\blog\content-drafts\ai-security-basics.md
RUBRIC:
  SEO: [criteria]
  AEO: [criteria]
  Quality: [criteria]

Return:
STATUS: OK
SCORES: SEO=87 AEO=91 Quality=83
PASS: false (Quality below 85)
ISSUES:
  - Quality: Missing FAQ section
  - Quality: CTA uses wrong cal.com link
```

Workers are disposable. They read one file, score it, return 10 lines. Their context is fully consumed and freed.

### 4. Sub-Orchestrator Returns to Master

After all 77 posts are processed:

```
STATUS: OK
LOG: D:\Code\Automation\blog\.logs\quality-audit-2026-03-26.md
SUMMARY:
  Total: 77 | Pass: 63 | Fixed: 11 | Failed: 3

  By category:
  | Category    | Count | Pass | Fixed | Failed | Avg SEO | Avg AEO | Avg Quality |
  |-------------|-------|------|-------|--------|---------|---------|-------------|
  | AIBM        | 15    | 12   | 3     | 0      | 91      | 89      | 88          |
  | JitAI MSP   | 12    | 10   | 2     | 0      | 88      | 87      | 86          |
  | Claude Code  | 10    | 8    | 1     | 1      | 85      | 84      | 82          |
  | CovenAI     | 8     | 5    | 2     | 1      | 83      | 86      | 84          |
  | JitNeuro    | 6     | 5    | 1     | 0      | 90      | 92      | 89          |
  | pSEO        | 26    | 23   | 2     | 1      | 86      | 85      | 85          |

  Failed posts (could not reach 85+):
  1. claude-code-context-limits.md -- Quality=79 (structural issues)
  2. covenai-launch-strategy.md -- AEO=78 (missing key_points)
  3. pseo-local-plumber-template.md -- SEO=74 (keyword stuffing)

FILES_CHANGED:
  - [list of 11 modified post files]
```

Master reviews the summary, decides what to do about the 3 failures (manual fix, different approach, or accept).

## The Log File

The sub-orchestrator's log file is critical. It serves three purposes:

1. **Progress visibility:** Owner can read it mid-run to see how things are going
2. **Crash recovery:** If the sub-orchestrator dies, the log shows what completed
3. **Audit trail:** Post-run record of every score, fix, and decision

### Log Format

```markdown
# Quality Audit Log
**Started:** 2026-03-26 14:00
**Rubric:** SEO/AEO/Quality, threshold 85+
**Total posts:** 77

## Batch 1 (posts 1-10)
| # | File | SEO | AEO | Quality | Pass | Action |
|---|------|-----|-----|---------|------|--------|
| 1 | ai-security-basics.md | 87 | 91 | 83 | FAIL | Fixed -> 87 |
| 2 | aibm-marina-marketing.md | 92 | 88 | 90 | PASS | -- |
| 3 | ... | ... | ... | ... | ... | ... |

## Batch 2 (posts 11-20)
...

## Summary
[populated after all batches complete]
```

## Divergent Thinking Integration

Sub-orchestrators follow the divergent mode rules:

- **Workers:** Always serial. They score one file against a rubric -- no ambiguity, no multi-path evaluation needed.
- **Sub-orchestrator:** Serial for batch management. Divergent mode doesn't add value to "dispatch 10, collect, dispatch 10 more."
- **Master:** Divergent when deciding WHAT to do with the results (fix strategy, priority order, which failures to accept vs retry).

The divergent mode prompt (`DIVERGENT MODE: <MODE>`) passes from master to sub-orchestrator to worker only when the task type warrants it. Scoring against a rubric doesn't warrant it. Deciding how to fix a failing post might.

## Nested Sub-Orchestrators

For very large operations, sub-orchestrators can dispatch their own sub-orchestrators:

```
MASTER
  |-- Sub-Orchestrator: "Audit all 6 business verticals"
        |-- Sub-Orchestrator: "Audit AIBM posts (15)"
        |     |-- Workers (batches of 10)
        |-- Sub-Orchestrator: "Audit JitAI posts (12)"
        |     |-- Workers (batches of 10)
        |-- ...
```

**Use sparingly.** Each nesting level adds dispatch overhead and return aggregation complexity. Two levels (master -> sub-orch -> workers) handles most real workloads. Three levels is the practical maximum.

## When NOT to Use Sub-Orchestrators

- **Less than 15 tasks:** Flat dispatch from master is simpler and faster
- **Tasks require owner decisions mid-stream:** Use flat dispatch so master can ask the owner between agents
- **Tasks are highly heterogeneous:** Different task types with different prompts are better as separate flat dispatches
- **Debugging:** When something is going wrong, flatten the hierarchy so you can see each agent's behavior directly

## Comparison to Flat Dispatch

| Aspect | Flat (master->agents) | Sub-orchestrator |
|--------|----------------------|------------------|
| Master context cost | O(N) -- one dispatch + result per task | O(1) -- one dispatch + result total |
| Tracking complexity | Master tracks all N tasks | Sub-orchestrator tracks, master sees summary |
| Crash recovery | Master re-dispatches failed agents | Sub-orchestrator handles retries internally |
| Owner visibility | Owner sees each result as it arrives | Owner sees summary after completion (log file for mid-run visibility) |
| Batch management | Master manages waves manually | Sub-orchestrator manages waves automatically |
| Latency | Lower for small N (no orchestrator overhead) | Lower for large N (master doesn't bottleneck) |

## Real-World Examples

### Content Quality Audit (77 blog posts)

**Problem:** 77 blog posts needed scoring against SEO/AEO/Quality rubric. Posts below 85 needed automated fixes. Owner wanted category-level reporting.

**Solution:** Master dispatched one sub-orchestrator with the full post list, rubric, and batch size of 10. Sub-orchestrator managed 8 batches of workers. Each worker scored one post. Failed posts got a fix-and-rescore cycle within the same batch. Sub-orchestrator maintained a log file throughout. After completion, returned aggregate scores by category with visual breakdown.

**Result:** 63 passed, 11 auto-fixed to passing, 3 required manual attention. Owner reviewed the summary and log file, spent 15 minutes on the 3 failures instead of hours on all 77.

### Cross-Repo Dependency Audit

**Problem:** 22 repos needed checking for outdated dependencies, security advisories, and version alignment.

**Solution:** Master dispatched a sub-orchestrator with the repo list. Sub-orchestrator ran workers in batches of 8 (lighter than content scoring -- no file writes). Each worker ran `npm audit`, checked `package.json` versions against the tech stack standard, and returned a risk score. Sub-orchestrator aggregated by severity.

### Multi-Vertical Content Generation

**Problem:** Generate draft content across 6 business verticals, each with different voice, audience, and keyword targets.

**Solution:** Master dispatched 6 sub-orchestrators (one per vertical). Each sub-orchestrator managed its own batch of content-generation workers. Each worker drafted one post. Sub-orchestrators scored drafts against vertical-specific rubrics and fixed below-threshold content. Master received 6 summaries with per-vertical quality metrics.

## Implementation Checklist

When setting up a sub-orchestrator:

- [ ] Define the goal (one sentence)
- [ ] Define the worker prompt template (what each worker does)
- [ ] Define the scoring/success criteria
- [ ] Set batch size (default 10, lower for heavy workers, higher for lightweight)
- [ ] Define log file path and format
- [ ] Define the return summary format (what master needs)
- [ ] Define fix-and-retry behavior (auto-fix? how many retries? escalation threshold?)
- [ ] Include DIVERGENT MODE in the prompt chain if applicable
- [ ] Test with 2-3 items before scaling to full set
