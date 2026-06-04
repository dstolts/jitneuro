---
type: pattern
purpose: A master orchestrator managing a persistent bug must escalate to 3 parallel independent-angle agents when a bug has resisted 5+ rounds of single-agent fixes or spans both frontend and backend layers -- because staying on the single-agent path at round 5+ entrenches the original hypothesis, prevents discovery of independent co-bugs, and produces an unbounded fix-loop that costs more than a one-time divergent dispatch.
trigger: round 5+ on the same failing spec or critical-path test; OR cross-repo bug with symptoms in both frontend and backend; OR a series of fixes that shift the symptom without resolving it
read_when: When a bug has survived 5+ single-agent fix rounds or symptoms span both frontend and backend layers simultaneously.
tags: [debugging, divergent-thinking, multi-agent, rca, persistent-bugs]
scope: public
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Divergent Triple-Agent RCA

## Pattern

Dispatch 3 parallel agents, each scoped to a different investigation angle, against the same bug evidence. No cross-contamination between agents. Master synthesizes convergence (highest confidence root cause) and independence (distinct bugs each angle found that others missed).

## When to use

- Round 5+ on the same failing spec or critical path test
- Cross-repo bug where symptoms appear in the frontend AND backend
- Bug that feels architectural: "how is this even possible at this layer?"
- Single-agent round-N has a pattern of wrong-layer fixes that shift but do not resolve

Not needed for Round 1-3, spec-only cosmetic flakes, or cases where the exact file and line are already known.

## Steps or structure

1. Master collects all available evidence (sweep failure trace, curl probes, recent PR diffs).
2. Dispatch 3 agents in parallel, each with the same evidence but a scoped investigation lens:
   - Angle A (frontend): component lifecycle, state management, render gates, ref freezing, mount/unmount timing.
   - Angle B (backend): API payload contents, request/response shape, branching logic, prompt templates, model parameters.
   - Angle C (QA/test): test tooling limitations, selector scoping, synthetic event behavior, animation timing, locator ambiguity.
3. Each agent returns independently: root cause hypothesis + confidence % + specific evidence (file:line or curl output).
4. Master synthesizes:
   a. CONVERGENCE -- where do 2+ agents independently agree? That is the highest-confidence root cause. Fix this first.
   b. INDEPENDENCE -- what did each agent find that the others missed? These may be distinct bugs each worth fixing.
   c. Rank by confidence; pick convergent + evidence-backed findings; discard speculation.
5. Dispatch fix agents (parallel if independent findings, sequential if convergent) per the synthesis.

## Cost-benefit

3 parallel Sonnet agents: approximately $3-5 in tokens, 10-20 minutes wall time.
Compared to: 1 round of single-agent dispatch at $0.50-1 + sweep rerun at $2-5 + owner review burden.
Round 7+ is cost-positive to diverge.

## Origin

Derived from applying divergent-thinking discipline to persistent multi-round bugs.

Result pattern: Angles A and C independently converged on a structural dual-render bug in a frontend form component (high-confidence structural cause). Angle B independently found an unrelated backend template variable bug (a variable never passed through to a fill function) affecting multiple active templates -- a bug A and C missed entirely. Two PRs dispatched; both were real bugs discovered only via the divergent approach.

Related: multi-layer-fix-pattern, `rules/divergent-thinking.md`, `rules/judgment-over-compliance.md`.
