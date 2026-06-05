---
type: rule
purpose: Require orchestrators to triage large decision batches before surfacing them, auto-applying reversible technical defaults and escalating only genuine judgment calls.
read_when: Before presenting a batch of 10 or more decisions, options, or open questions to the Owner or a downstream agent.
tags: [triage, decision-batches, auto-apply, escalation, orchestrator]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Auto-Apply Triage for Large Decision Batches

When a process surfaces many decisions at once (tens or more) -- Phase-0-style design gates,
large-scope audits, drain dedup rules, any "answer these N questions before we can continue"
moment -- the orchestrator MUST NOT dump the raw list on the requester. Instead: triage first,
escalate only the judgment-requiring subset.

## Why

Presenting 60+ decisions as a reference queue results in:
- Analysis paralysis
- Response: "I don't have enough context to answer any of these"
- Slower project velocity

Pre-triaged presentation closes the same 60+ decisions in minutes rather than hours.

## Triage Rules

### AUTO-APPLY when ALL of:
1. The source agent / spec made a clear recommendation
2. Decision is a technical / implementation choice (not business semantics or policy)
3. Decision is reversible without migration pain
4. No conflict with another decision in the batch
5. Recommendation does NOT contradict established rules / preferences / constraints

### ESCALATE when ANY of:
1. No clear recommendation from source
2. Two decisions conflict with each other
3. Business-semantics decision (changes how the system BEHAVES for the requester's workflow)
4. Security / privacy / legal implications
5. Requires context the AI does not have (e.g., team structure, budget authority, customer list)
6. Constraints call for a different answer than what the source recommended
7. High-cost reversibility (would require migration / rebuild if changed later)

### BORDERLINE -> prefer ESCALATE when in doubt

The requester can always say "apply your recommendation" fast. The orchestrator cannot
undo a bad auto-apply without cost.

## Presentation Format

The requester sees TWO artifacts:

**1. Auto-applied ledger** -- defaults applied; requester vetoes any by ID.
Tight per item: ID / source / 1-line question / applied default / rationale / veto slot.

**2. Escalation short list** -- 8-15 items max in plain language. Per item:
- ID + headline
- 2-3 sentence context (not technical jargon)
- 2-3 options with consequences
- Orchestrator's lean + why
- "Would need your input because: [rule that triggered escalation]"

## What This Replaces

Before this pattern: large raw decision queues were dumped on the requester to scan and
respond item-by-item. After: the orchestrator does the triage, surfaces only what genuinely
needs human judgment.
