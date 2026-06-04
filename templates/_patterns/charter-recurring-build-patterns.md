---
type: pattern
purpose: MUST be consulted by any master agent or orchestrator on the third occurrence of a repeated build task before dispatching another blind agent -- because re-dispatching ad-hoc prompts for the same recurring build task means the discipline drifts every run, cannot be audited, and never improves; skipping the chartering step means every future instance re-invents the standard from scratch instead of inheriting it.
read_when: On the third occurrence of any repeated build task, before dispatching another ad-hoc agent prompt for it.
tags: [charter, meta-skill, recurring-work, skill-building, agent-dispatch, recursive-improvement]
scope: public
last_evaluated: 2026-06-03
---

# Charter Recurring Build Patterns

The first time a build task appears, doing it inline is fine. The second and
third time, stop re-dispatching blind agents that re-invent the discipline in
each prompt. Charter the pattern: author a charter, a meta-skill, and its tools
once, and every future instance inherits the discipline by construction.

## Rule

When a build task has recurred (roughly the third occurrence, or sooner if the
discipline is non-trivial):

1. Author a charter that defines the role and its quality bar.
2. Author a meta-skill that encodes the build procedure.
3. Author the tools the meta-skill needs.
4. Future instances invoke the chartered skill -- they do not re-describe the
   discipline in a fresh prompt.

A blind agent dispatched with an ad-hoc prompt re-invents the standard each
time, and the standard drifts. A chartered skill holds the standard in one
place where it can be reviewed and improved.

## Why

Re-dispatching blind agents for recurring work means the discipline lives only
in whatever prompt was written that day. It is never the same twice, never
improves, and cannot be audited. A charter plus meta-skill makes the discipline
a durable, improvable artifact.

Skill-building specifically must use the official Anthropic skill
template/format and the raised standard for skill authoring -- it is itself a
recurring build pattern and is chartered for exactly this reason.

## How to apply

- Track recurring build tasks. On the third occurrence, charter it.
- The charter + meta-skill + tools land together as one body of work.
- Improve the charter over time; do not fork a new ad-hoc prompt.

## Origin

2026-05-21, skill-builder / build-skill authoring (Knowledge-Master session).
