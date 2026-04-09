# User Story: Document Background Agents vs Fire-and-Forget

**Created:** 2026-03-27
**Priority:** 50/100
**Status:** Ready for execution
**Handoff:** Agent-ready

## Summary

Create a section in the existing `docs/multi-agent-orchestration-01.md` (or a standalone doc if too large) comparing JitNeuro's background agent system to the traditional fire-and-forget pattern used by frameworks like openclaw.

This matters because developers coming from Node.js/async backgrounds will expect fire-and-forget semantics. They need to understand why JitNeuro's approach is different and what they gain.

## Acceptance Criteria

### AC-1: Add comparison section

Cover these points:

**Fire-and-forget (traditional):**
- Run a task, ignore the result. Log errors, never block.
- Simple: one function, no tracking, no retry.
- Use case: audit logging, analytics, cache warming -- tasks where failure is acceptable.
- Problem: no visibility. Did it work? Did it fail? Nobody knows unless they check logs.

**JitNeuro background agents:**
- Run a task, get notified on completion. Structured result. Retry capability.
- Five levels of capability, from simplest to most complex:

| Level | Pattern | Example |
|-------|---------|---------|
| 1. Fire-and-forget | `Agent(run_in_background: true)` -- master ignores result | Deploy monitoring, heartbeat updates |
| 2. Fire-and-notify | Same, but master reads result when notified | Audit scans, git status checks |
| 3. Fire-and-react | Master acts on structured return (OK/BLOCKED/PARTIAL) | Sprint agent that may need a question answered |
| 4. Fire-and-continue | Master uses SendMessage to continue a BLOCKED agent | Agent needs one answer to proceed, keeps its full context |
| 5. Fire-and-orchestrate | Sub-orchestrator manages rolling pool of workers | 77 blog posts scored in parallel with batch management |

- Every level above 1 is impossible with fire-and-forget.
- Level 1 IS fire-and-forget -- it's the entry point, not the ceiling.

**Scheduled agents extend background agents further:**

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

**Why this matters for AI-first workflows:**
- In traditional async code, fire-and-forget is fine because the task is deterministic (cache this, log that).
- In AI agent workflows, the task involves REASONING. The agent might discover something unexpected, hit ambiguity, or need a decision. Fire-and-forget means that discovery is lost.
- JitNeuro's approach: let agents report back. Most of the time it's "done, here's the summary." Sometimes it's "blocked, need this answered." That BLOCKED path is where the real value is -- no work is lost.

**The cost of fire-and-forget in AI:**
- Agent finds a security vulnerability during an audit scan -- fire-and-forget logs it to a file nobody reads.
- Agent can't score a blog post because the rubric is ambiguous -- fire-and-forget silently skips it.
- Agent finishes but the result contradicts another agent's output -- fire-and-forget can't coordinate.

JitNeuro's structured returns (STATUS + RESULT + FILES_CHANGED) mean the orchestrator can act on every outcome, not just the happy path.

**Level 6: Watcher agents (defeating Claude's early-stop bug):**

Claude has a known behavioral pattern: it stops working and summarizes when it still has open tasks. It presents a summary as if the work is done, but TodoWrite has pending items. This is not a configuration issue -- it's a model behavior where Claude "decides" it's done prematurely.

JitNeuro solves this with watcher agents -- enforcers that do not ask permission. They TELL Claude to get back to work:

```
Watcher agent (self-looping enforcer):
  Every N minutes:
    1. Read TaskList
    2. Count pending/in_progress tasks
    3. If tasks remain AND master appears idle:
       Return: INSTRUCTION: RESUME_TASKS
       (master rule: RESUME_TASKS = read TaskList, pick next pending, execute)
    4. If all tasks complete: Return: INSTRUCTION: NONE
```

This is not a suggestion. The enforcer interrupt rule forces master to stop summarizing and start executing the next pending task. No user confirmation needed -- the user already approved the task list.

| Claude behavior | Without watcher | With watcher enforcer |
|----------------|-----------------|----------------------|
| Stops with 5 tasks pending | User discovers hours later | Enforcer tells Claude: resume NOW |
| Summarizes as "done" | User trusts the summary | Claude never stops while tasks remain |
| Loses context on what's left | Tasks forgotten after /clear | Tasks in TodoWrite + Hub.md, enforcer keeps driving |

**Level 7: Task-driven agents (agents that CREATE work for master):**

Background agents don't just monitor -- they can research, discover, and add new tasks to the queue. Master picks them up when it runs out of work or gets interrupted.

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

**Two patterns for agent -> master task handoff:**

| Pattern | How it works | When to use |
|---------|-------------|-------------|
| **Agent writes to TodoWrite** | Agent uses TaskCreate directly. Master sees new tasks on next TaskList check. | When master is in the same session and will check TodoWrite naturally. |
| **Agent writes to Hub.md** | Agent appends tasks to the session's Hub.md section. Master reads Hub.md on next checkpoint or when enforcer fires UPDATE_HUB. | When tasks need to survive /clear or be visible across sessions. |

**Master's idle behavior (rule):**
When master completes its current task and has no user input pending:
1. Read TaskList -- any pending tasks? Execute next one.
2. If TaskList empty, read Hub.md -- any unclaimed tasks? Pull into TodoWrite and execute.
3. If both empty, inform user: "All tasks complete."

This creates a pull-based work queue. Agents push tasks in. Master pulls them out. The watcher enforcer ensures master never sits idle while tasks exist. The loop runs until the queue is drained or the user intervenes.

**Combined example:**
```
1. User says: "Research Node.js security and implement the top findings"
2. Master creates research agent (background)
3. Master continues working on current sprint tasks
4. Research agent reads docs, evaluates, writes 10 tasks to TodoWrite
5. Research agent returns: STATUS: OK, 10 tasks added
6. Master finishes current work, checks TodoWrite -- 10 new tasks
7. Master starts executing task 1
8. Watcher enforcer ensures master doesn't stop at task 3 and summarize
9. Master completes all 10 tasks
10. Watcher sees empty queue, returns INSTRUCTION: NONE
```

### AC-2: Reference openclaw as concrete example
- Cite `src/hooks/fire-and-forget.ts` (12 lines, promise error swallowing)
- Position it as Level 1 in JitNeuro's 5-level hierarchy
- Not a criticism -- it's the right tool for simple async hooks. JitNeuro just goes further because AI agents need more than simple async.

### AC-3: Tone
- Technical comparison, not a sales pitch
- Acknowledge fire-and-forget is simpler and appropriate for some cases
- Show where it breaks down for AI agent workflows specifically
