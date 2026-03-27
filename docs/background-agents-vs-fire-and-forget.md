# Background Agents vs Fire-and-Forget

How JitNeuro's background agent hierarchy compares to the traditional fire-and-forget pattern -- and why the distinction matters for AI agent workflows.

---

## Fire-and-Forget: The Baseline

Fire-and-forget is the standard async pattern in Node.js, Go, and most event-driven systems. Run a task, ignore the result, log errors, never block the caller.

OpenClaw's `src/hooks/fire-and-forget.ts` is a clean 12-line implementation:

```typescript
export function fireAndForget(promise: Promise<unknown>): void {
  promise.catch((error) => {
    console.error("[fire-and-forget] Unhandled error:", error);
  });
}
```

This is the right tool for deterministic background work: audit logging, cache warming, analytics pings, webhook dispatches. The caller does not need the result. If the task fails, a log entry is sufficient.

**Characteristics:**
- One function, no tracking, no retry
- Caller continues immediately -- zero coupling to the background work
- Failure is acceptable and invisible to the caller
- No structured result, no completion notification

**Appropriate for:** Tasks where the answer is always "fire it and move on." The caller never needs to know what happened.

---

## The Problem: Fire-and-Forget in AI Workflows

In traditional async code, the background task is deterministic. "Write this row to the audit table" either works or it does not. The caller never needs the result because the result is always the same.

AI agent tasks are fundamentally different. The agent reasons, discovers, and sometimes hits ambiguity. A fire-and-forget agent that discovers something unexpected has no way to report it back:

- **Lost discovery:** Agent finds a security vulnerability during an audit scan. Fire-and-forget logs it to a file nobody reads. The vulnerability sits undiscovered until the next manual review.
- **Silent failure:** Agent cannot score a blog post because the rubric is ambiguous. Fire-and-forget silently skips it. The post appears unscored with no indication of why.
- **No coordination:** Agent finishes but its result contradicts another agent's output. Fire-and-forget cannot coordinate -- the contradiction persists until a human notices.

The cost is not the failure itself -- it is the invisibility. Work is lost, decisions are deferred, and the orchestrator has no signal to act on.

---

## JitNeuro's 7-Level Hierarchy

JitNeuro does not replace fire-and-forget. It starts there (Level 1) and builds upward. Each level adds capability that the previous level cannot provide.

### Level 1: Fire-and-Forget

```
Agent(run_in_background: true) -- master ignores result
```

Identical to traditional fire-and-forget. Master dispatches and moves on. The agent's return value is never read.

**Use for:** Deploy monitoring, heartbeat updates, non-critical logging. Tasks where master genuinely does not need the result.

**This is the entry point, not the ceiling.**

### Level 2: Fire-and-Notify

```
Agent(run_in_background: true) -- master reads result when notified
```

Master dispatches and continues working. When the background agent completes, master reads the structured result and incorporates it into its current work.

**Use for:** Audit scans, git status checks, code analysis. Tasks where the result informs but does not block current work.

**Difference from Level 1:** Master processes the return. The agent's work is not lost.

### Level 3: Fire-and-React

```
Agent returns STATUS: OK / BLOCKED / PARTIAL
Master takes different action based on the status
```

Master dispatches, continues working, and reacts to the structured return using the [subagent communication protocol](../templates/rules/subagent-communication.md). An OK result gets processed normally. A BLOCKED result means the agent needs a decision. A PARTIAL result means some work completed but the rest needs attention.

**Use for:** Sprint agents that may hit a question, research agents that find conflicting information, any task where the agent might need help.

**Difference from Level 2:** Master's behavior changes based on the return status. Not just "read it" but "act on it differently."

### Level 4: Fire-and-Continue

```
Agent returns STATUS: BLOCKED with a question
Master answers via SendMessage
Agent continues with its full context intact
```

The agent hits a blocking question but does not die. Master provides the answer via SendMessage and the agent resumes with its full context -- all prior reasoning, file reads, and partial work preserved.

**Use for:** Complex multi-step agents that may need one clarification mid-execution. The alternative is killing the agent, losing its context, and re-dispatching from scratch.

**Difference from Level 3:** The agent survives. No context loss. No re-dispatch cost.

### Level 5: Fire-and-Orchestrate

```
Sub-orchestrator manages a rolling pool of worker agents
Master dispatches the orchestrator, not the workers
```

Master dispatches a single sub-orchestrator agent. That orchestrator manages its own pool of worker agents: dispatching batches, handling failures, retrying, and consolidating results. Master gets one clean result back instead of managing N agents directly.

**Use for:** Bulk operations that exceed a single agent's capacity. Scoring 77 blog posts in parallel. Auditing 50 files against a ruleset. Any workload that requires batch management.

**Difference from Level 4:** Master delegates orchestration entirely. The sub-orchestrator handles parallelism, batching, and failure recovery. See [sub-orchestrator-pattern.md](sub-orchestrator-pattern.md) for the full pattern.

### Level 6: Watcher Enforcers

```
Self-looping enforcer agent:
  Every N minutes:
    1. Read TaskList
    2. Count pending/in_progress tasks
    3. If tasks remain AND master appears idle:
       Return: INSTRUCTION: RESUME_TASKS
    4. If all tasks complete:
       Return: INSTRUCTION: NONE
```

Claude has a known behavioral pattern: it stops working and summarizes when it still has open tasks. It presents a summary as if the work is done, but the task list has pending items. This is not a configuration issue -- it is a model behavior where Claude "decides" it is done prematurely.

Watcher enforcers defeat this. They are background agents that monitor master's task queue and force it back to work when tasks remain. The enforcer does not ask permission. It issues an INSTRUCTION that the [scheduled agent interrupt rule](../templates/rules/scheduled-agent-interrupts.md) makes mandatory.

| Claude behavior | Without watcher | With watcher enforcer |
|----------------|-----------------|----------------------|
| Stops with 5 tasks pending | Owner discovers hours later | Enforcer tells Claude: resume NOW |
| Summarizes as "done" | Owner trusts the summary | Claude never stops while tasks remain |
| Loses context on what is left | Tasks forgotten after /clear | Tasks in TodoWrite + Hub.md, enforcer keeps driving |

**Difference from Level 5:** Levels 1-5 are dispatched to do work. Level 6 watches master and enforces discipline. The watcher does not do the work -- it ensures master does.

### Level 7: Task-Driven Agents

```
Research agent (background):
  Prompt: "Research top 10 security best practices for Node.js APIs.
  For each, add a task to TodoWrite with acceptance criteria.
  Write detailed findings to .logs/research-node-security.md."

  Agent runs in background while master works on other tasks.
  Agent adds 10 tasks to TodoWrite (or writes to Hub.md).
  When master finishes current work, it checks TodoWrite -- 10 new tasks waiting.
  Master picks up next task. No human intervention needed.
```

Background agents at this level do not just execute work -- they create work for master. They research, discover, and queue new tasks. Master picks them up when it runs out of work or gets interrupted by an enforcer.

**Two patterns for agent-to-master task handoff:**

| Pattern | How it works | When to use |
|---------|-------------|-------------|
| Agent writes to TodoWrite | Agent uses TaskCreate directly. Master sees new tasks on next TaskList check. | When master is in the same session and will check TodoWrite naturally. |
| Agent writes to Hub.md | Agent appends tasks to the session's Hub.md section. Master reads Hub.md on next checkpoint or when enforcer fires UPDATE_HUB. | When tasks need to survive /clear or be visible across sessions. |

**Difference from Level 6:** Level 6 monitors existing tasks. Level 7 generates new tasks. The agent becomes a work source, not just a work executor.

---

## Scheduled Agents Extend Further

Background agents (Levels 1-7) are one-shot by default. Scheduled agents add recurrence, priority, and lifecycle management on top of the same foundation.

| Capability | Fire-and-forget | Background agent | Scheduled agent |
|-----------|----------------|-----------------|----------------|
| Non-blocking | Yes | Yes | Yes |
| Completion notification | No | Yes | Yes |
| Structured result | No | Yes | Yes |
| Retry / continue | No | Yes (SendMessage) | Yes (re-spawn) |
| Recurring execution | No | No (one-shot) | Yes (timer/cron) |
| Self-looping | No | No | Yes (smart agents) |
| Priority levels | No | No | Yes (enforcer > timer) |
| Lifespan management | No | No | Yes (maxHours/maxLoops) |

Four scheduled agent types build on the background agent hierarchy:

| Type | Context | Purpose |
|------|---------|---------|
| timer | Internal (live session) | Periodic housekeeping: auto-save, Hub sync |
| enforcer | Internal (live session) | Discipline enforcement: task completion, rule compliance |
| cron | External (launches session) | Nightly audit, batch scoring, content pipeline |
| batch | External (launches session) | One-time bulk operations with agent pool management |

See [scheduled-agents.md](scheduled-agents.md) for full configuration and lifecycle details.

---

## Why Structured Returns Matter

The core difference between fire-and-forget and JitNeuro's agent hierarchy is the structured return:

```
STATUS: OK
FILES_CHANGED:
  - /path/to/file1.ts (created)
  - /path/to/file2.ts (modified)
SUMMARY_DOC: /path/to/detailed-report.md
RESULT:
[concise findings, under 15 lines]
```

This structure gives the orchestrator three things fire-and-forget cannot provide:

1. **Actionable status.** OK means process the result. BLOCKED means answer a question. PARTIAL means some work needs follow-up. The orchestrator's next action is determined by one word.

2. **Scope tracking.** FILES_CHANGED tells the orchestrator exactly what was touched -- critical for commit scoping, PR descriptions, and avoiding file conflicts between parallel agents.

3. **Context efficiency.** SUMMARY_DOC points to detailed output without forcing the master to read it. Master stays thin. Detail is available on demand but does not consume master context by default.

Fire-and-forget provides none of this. The caller gets nothing back. Every outcome -- success, failure, partial completion, unexpected discovery -- is invisible.

---

## Master Idle Behavior

When master completes its current task and has no user input pending, it follows a pull-based work queue:

1. Read TaskList -- any pending tasks? Execute next one.
2. If TaskList empty, read Hub.md -- any unclaimed tasks? Pull into TodoWrite and execute.
3. If both empty, inform user: "All tasks complete."

This creates a loop:
- Task-driven agents (Level 7) push tasks in.
- Master pulls them out.
- Watcher enforcers (Level 6) ensure master never sits idle while tasks exist.
- The loop runs until the queue is drained or the user intervenes.

---

## Combined Example: The Full Loop

```
1.  User says: "Research Node.js security and implement the top findings"
2.  Master dispatches research agent (background, Level 7)
3.  Master continues dispatching other sprint agents
4.  Research agent reads docs, evaluates, writes 10 tasks to TodoWrite
5.  Research agent returns: STATUS: OK, 10 tasks added
6.  Master checks TodoWrite -- 10 new tasks
7.  Master dispatches agent for task 1 (background)
8.  Master dispatches agent for task 2 (background, no file overlap with task 1)
9.  Watcher enforcer (Level 6) monitors -- tasks remain, agents working
10. Agents complete and return, master dispatches next tasks from queue
11. All 10 tasks complete (agents did the work, master orchestrated)
12. Watcher sees empty queue, returns INSTRUCTION: NONE
13. Master reports: "All 10 security tasks complete."
```

Master orchestrates -- it dispatches agents and collects results. It does not execute tasks directly. The deeper the work, the more it belongs to an agent.

No human intervention between steps 1 and 13. The research agent generated the work. The watcher enforcer ensured completion. The structured returns kept everything coordinated. Fire-and-forget could handle step 2 -- and nothing after it.

---

## When to Use What

| Scenario | Level | Why |
|----------|-------|-----|
| Log an event, warm a cache | 1 (fire-and-forget) | Result does not matter. Simplest pattern wins. |
| Check git status while working | 2 (fire-and-notify) | Result is informational. Read it when it arrives. |
| Sprint agent that might hit a question | 3 (fire-and-react) | BLOCKED status needs a different response than OK. |
| Complex agent needs one clarification | 4 (fire-and-continue) | Killing the agent loses 5 minutes of context. Answer and continue. |
| Score 77 blog posts in parallel | 5 (fire-and-orchestrate) | Master cannot manage 77 agents. Delegate to a sub-orchestrator. |
| Ensure Claude finishes all tasks | 6 (watcher enforcer) | Claude's early-stop behavior requires external enforcement. |
| Research a topic and queue tasks | 7 (task-driven agent) | Agent creates work. Master consumes it. No human in the loop. |

Fire-and-forget is Level 1. It is not wrong -- it is insufficient for AI agent workflows where reasoning, discovery, and coordination matter.
