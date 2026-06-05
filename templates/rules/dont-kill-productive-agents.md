---
type: rule
purpose: Prohibit stopping in-flight agents due to priority shifts when those agents are making productive progress, preserving already-committed token value.
read_when: When a priority shift occurs and the orchestrator is tempted to kill an agent that is currently making progress.
tags: [agent-management, token-efficiency, priority-shift, orchestrator, runaway-prevention]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Don't Kill Productive Agents Mid-Flight

When priorities shift, let in-flight agents that are doing productive work FINISH.
Their return cost is near-free -- the tokens are already committed.

## The Violation Pattern

An agent is dispatched and begins making progress. A priority shift occurs. The
orchestrator kills the agent before it can return its output. The committed tokens
produce zero value because the output never landed.

## Rule

Stop agents ONLY for:
- (a) fundamentally wrong-architecture work (e.g., agent building for a platform
  that was abandoned after dispatch)
- (b) runaway / spiral patterns burning significant ADDITIONAL tokens
- (c) blatantly off-track behavior

Priority shifts DO NOT justify stopping agents. Let them return, land their PRs,
and move on to new priorities in parallel.

## Why

When an agent is killed mid-flight:
- All tokens already consumed produce zero output
- Partially completed work may leave the repo in an inconsistent state
- Picking up where the agent left off requires re-reading context already paid for

When an agent is allowed to finish:
- The output arrives at near-zero marginal cost (tokens already committed)
- The orchestrator can decide whether to use or discard the output after seeing it
- The repo state is clean (agent either succeeds or fails atomically)

## Exceptions

These DO justify stopping an agent:
- Runaway process: agent is consuming disproportionate resources with no signs of
  useful progress (see runaway-process-prevention.md)
- Wrong architecture: owner has abandoned the approach the agent is implementing
- Off-track: agent has clearly misunderstood the task and is producing irrelevant output

## Related

- `runaway-process-prevention.md` -- the flip side: when you MUST stop an agent
