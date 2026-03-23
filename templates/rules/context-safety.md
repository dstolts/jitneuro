# Context Safety (Memory Exhaustion Prevention)

Claude Code's JavaScript runtime (WebKit/Electron) can crash with MemoryExhaustion when a single response accumulates too much context. This happens during large-batch file analysis, audits, and bulk scanning operations.

## Guardrails
- **Batch file analysis:** Never scan more than 25 files in a single response. For larger sets, use subagents (each gets isolated memory) or batch into groups of 20-25.
- **Use subagents for bulk reads:** When analyzing many files (audit, review, scan), spawn Explore or general-purpose agents to do the reading. They run in separate processes with isolated memory.
- **Avoid accumulating large tables:** If building a classification table across 50+ items, build it incrementally across multiple responses, not all at once.
- **Stream results, don't collect:** When scanning files against rules, report findings per-batch rather than collecting all results into one massive response.
- **Pre-count before scanning:** Before starting a bulk operation, count the files first. If >25, plan the batching strategy before reading any files.

## Why
The crash occurs in `JavaScriptCore/heap/LocalAllocator.cpp` -- the JS heap in Claude Code's Electron runtime, NOT the AI model context window. Large single-pass operations exceed the heap. The fix is multi-agent batching, not reducing context window size.

## Connection to Multi-Agent Orchestration
Single-agent operations hit memory ceilings on real workloads. Multi-agent orchestration distributes work across isolated processes, each with its own heap, making bulk operations safe by design. Every scan, audit, review, and sprint execution benefits from orchestrated subagents rather than single-agent accumulation.
