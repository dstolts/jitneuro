---
type: rule
purpose: Cap single-response file analysis at 25 files and limit concurrent subagents to 10-12 to prevent orchestrator memory exhaustion and API rate-limit failures.
read_when: Before planning any bulk file analysis, audit, or multi-agent dispatch to determine batching strategy and concurrency limits.
tags: [context-safety, memory-exhaustion, batch-limits, concurrency, orchestrator]
scope: public
last_evaluated: 2026-06-03
---
# Context Safety (Memory Exhaustion Prevention)

Orchestrators (master sessions) accumulate context with every tool call. When a single
response accumulates too much context, the runtime can crash with out-of-memory errors.
This happens most commonly during large-batch file analysis, audits, and bulk scanning.

## File Analysis Guardrails

- **Batch file analysis:** Never scan more than 25 files in a single response. For larger
  sets, use subagents (each gets isolated memory) or batch into groups of 20-25.
- **Use subagents for bulk reads:** When analyzing many files (audit, review, scan), spawn
  Explore or general-purpose agents to do the reading. They run in separate processes with
  isolated memory.
- **Avoid accumulating large tables:** If building a classification table across 50+ items,
  build it incrementally across multiple responses, not all at once.
- **Stream results, don't collect:** When scanning files against rules, report findings
  per-batch rather than collecting all results into one massive response.
- **Pre-count before scanning:** Before starting a bulk operation, count the files first.
  If >25, plan the batching strategy before reading any files.

## Agent Concurrency Limits

Distinct from the 25-file memory batching limit above. API rate limits cap concurrent subagents.

- **Safe ceiling:** 10-12 concurrent background agents
- **Rate limit threshold:** ~20 concurrent agents triggers API rate limiting
- **Recovery:** Rate-limited agents return empty results. Must be re-dispatched after limits clear.
- **Pattern:** Maintain a pool of 10 active agents. As each completes, dispatch the next.
  Do not batch-launch more than 12 at once.

## Why

The crash occurs in the JS heap of the orchestrator's runtime, NOT the AI model context window.
Large single-pass operations (e.g., 89 files x 26 rules = thousands of lines accumulated in one
response) exceed the heap. The fix is batching across multiple responses, not reducing context
window size.

## Connection to Multi-Agent Orchestration

Single-agent operations hit memory ceilings on real workloads. Multi-agent orchestration
distributes work across isolated processes, each with its own heap, making bulk operations
safe by design. Every scan, audit, review, and sprint execution benefits from orchestrated
subagents rather than single-agent accumulation.

## Subagent Return Protocol

All subagents MUST follow a structured return protocol: STATUS line,
FILES_CHANGED paths, optional SUMMARY_DOC reference, conditional TRACKING block, and a result
under 15 lines. The orchestrator reads file paths and tracking metadata for scope but does NOT
read file contents or summary docs unless it needs more detail. This is the mechanism that keeps
orchestrator context thin while preserving work-item updates and surfaced artifact links.

## Related

- `orchestrator-delegation.md` -- when to delegate vs retain work in the orchestrator
