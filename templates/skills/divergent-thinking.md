---
type: skill
purpose: Generate 2-4 genuinely distinct approaches before converging on a solution, preventing tunnel vision on production code and architecture decisions. Read this when an agent needs to apply the FRAME-DIVERGE-EVALUATE-CONVERGE-EXECUTE cycle for non-trivial decisions.
tags: [skill, divergent-thinking, architecture, decision-making, agent-behavior]
scope: public
read_when: When an agent is about to make a production code change, architecture decision, or cross-repo change that warrants exploring multiple approaches.
last_evaluated: 2026-06-03
---

# Divergent Thinking

Generate multiple distinct approaches before converging on a solution. Prevents tunnel vision on production code, architecture decisions, and anything that ships to clients.

## When to Apply

- Production code changes
- Architecture decisions and new features
- Cross-repo changes
- Any decision with real trade-offs

Serial (skip divergent): research, exploration, simple fixes, documentation, questions.

## Core Process

1. **FRAME** -- Read the request fully. Activate relevant personas. Understand what is really being asked, not just what was literally said.
2. **DIVERGE** -- Generate 2-4 genuinely distinct approaches from different angles. These are not "Plan A and fallback" -- each must be a path that could legitimately be the best answer.
3. **EVALUATE** -- Score each path on speed, safety, maintainability, existing patterns, and cost to the Owner. Look for complementary strengths -- two approaches may each solve different parts better than either alone.
4. **CONVERGE** -- Pick the best path OR merge strongest elements from multiple paths into a hybrid. State the choice and why. Note rejected paths only if the reasoning is non-obvious.
5. **EXECUTE** -- Full commitment to the converged path. No hedging.

For significant decisions, show the DIVERGE/EVALUATE summary before executing so the Owner can redirect.

For major decisions (cross-repo, new services, architecture pivots): spawn 2-3 parallel subagents each thinking from a different persona, synthesize independently, then converge.

## What to Avoid

- Treating the first reasonable answer as the only answer
- "Plan A and backup plan" framing -- these are not divergent paths, they are ranked options
- Diverging on simple fixes, lookups, or research tasks (wastes tokens, adds no value)
- Showing all divergent paths to the Owner when the right answer is obvious after evaluation

## Integration

Used by: sys-architect, sys-backend, sys-frontend, sys-security, sys-qa, sys-orchestrator

Subagents that always run serial (never diverge): Explore agents, background monitors, simple file lookups.
Subagents that inherit divergent mode: Plan agents, review agents, spec writers.
