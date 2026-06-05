---
type: rule
purpose: Require the orchestrating session to delegate file reads, code changes, bulk ops, and research to subagents by default, preserving orchestrator context for coordination and decisions.
tags: [orchestrator, delegation, subagents, context-protection, efficiency]
scope: public
departments: [all]
read_when: At session start for any orchestrating or master agent before beginning multi-task work that involves file reads, bulk operations, or research.
last_evaluated: 2026-06-03
---
# Orchestrator Delegation (Context Protection)

## Rule

The orchestrating session MUST delegate tasks to subagents whenever it does not specifically
need to do the work itself. Default behavior is delegation, not retention.

## What the Orchestrator Keeps

- Cross-task coordination (ordering, dependency tracking)
- Direct user interaction (questions, approvals, status reporting)
- Sequential decisions that depend on prior task results
- Session and task-list management

## What the Orchestrator Delegates

- File reads and analysis (use Explore or research agents)
- Code changes and edits (use general-purpose or specialized agents)
- Bulk operations (audits, scans, batch updates)
- Research and discovery
- Test execution
- Any work that accumulates context the orchestrator does not need to retain

## Why

Orchestrator context is the scarcest resource. Every file read, code edit, and tool output
consumes context that cannot be recovered. When the orchestrator accumulates context from
work it could have delegated, it hits memory exhaustion faster, loses earlier conversation
history to compaction, and degrades its ability to coordinate.

Subagents run in isolated processes with their own context. Their work returns as a concise
summary (per subagent-communication.md protocol), keeping the orchestrator thin.

## How to Apply

Before starting any task, ask: "Does the orchestrator need to hold this context?" If no,
spawn an agent. If yes, proceed directly. When in doubt, delegate.

When Owner has already approved execution, delegate before explaining. The
worker prompt is the place for operational detail; the Owner-facing message is
for concise status, blockers, and verified results.

## Sizing Guidance

- **Too small:** 1 agent per file -- dispatch overhead exceeds value
- **Right size:** 1 agent per logical unit (category, module, priority tier, file group)
- **Too large:** 1 agent for "fix everything" -- defeats the purpose

Splitting strategies that work:

| Strategy | When to use |
|---|---|
| One per category/module | Validation across many similar units |
| One per priority tier | Fixes at different severity levels (P0/P1/P2) |
| One per file group | Changes that naturally cluster |
| One per task type | Different kinds of work (tests, static analysis, builds) |

Tasks that touch different files run in parallel. Tasks that touch the same file must be sequenced or combined into one agent. Before dispatching, map which files each agent will touch.

## Memory-Exhaustion Guardrails

Claude Code's JS runtime crashes with `MemoryExhaustion` when a single response accumulates too much context. Multi-agent dispatching is the primary defense -- subagents run in isolated processes with their own heap.

- **Max 25 files per agent.** For larger sets, batch into groups of 20-25 across multiple agents
- **Use subagents for bulk reads.** Scanning, auditing, reviewing many files must use subagents; the orchestrator dispatches and aggregates only
- **Avoid accumulating large tables.** Classification across 50+ items: build incrementally across responses or split across subagents
- **Wave dispatching.** More than 25-30 agents: dispatch in waves of 15. Collect results, then dispatch the next wave. Avoids API rate limits + heap pressure.
- **Stream results, don't collect.** Report findings per-batch rather than collecting into one massive response

## Anti-Patterns

- **Orchestrator reads files "to understand context"** -- the #1 context killer. Let agents read.
- **One mega-agent for everything** -- runs out of context, forces session reset
- **Agents with overlapping file writes** -- race conditions, overwrites
- **No return format specified** -- agents return 200-line analyses that bloat orchestrator context
- **Sequential when parallel is possible** -- if tasks are independent, run them together

## Related

- `subagent-communication.md` -- return format subagents must use to keep orchestrator context thin
- `context-safety.md` -- memory exhaustion prevention; batching limits; concurrency caps
