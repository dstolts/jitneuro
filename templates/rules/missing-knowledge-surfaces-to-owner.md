---
type: rule
purpose: BINDING rule requiring agents to surface missing jit-knowledge artifacts to the Owner rather than silently proceeding; a missing rule, charter, playbook, or pinned file is an alarm that removes a capability or guardrail, not an absent-by-design no-op.
read_when: When resolving any jit-knowledge artifact reference that cannot be found -- silently proceeding means guardrails and capabilities are dropped without anyone knowing.
tags: [governance, missing-knowledge, owner-surface, alarm, silent-failure-prevention, jit-knowledge, session-start]
scope: public
last_evaluated: 2026-06-03
---

# Missing Knowledge Surfaces to Owner

When an agent or any tool references a jit-knowledge artifact and that file is NOT
FOUND, the agent MUST surface the gap to the Owner. It must not silently proceed as
though the knowledge were intentionally absent.

A missing knowledge file is an alarm, not a no-op.

## Rule

When ANY of the following are referenced but cannot be resolved:

- A rule file listed in `rules/` (e.g., `rules/interactive-master-orchestrator.md`)
- A playbook, charter, or skill file listed in `INDEX.md` or a SKILL.md procedure
- An entry in a `CLAUDE.md` or `AGENTS.md` import list (e.g., `load: - rules/foo.md`)
- A submodule-pinned file inside `.jit-knowledge/`
- Any artifact the SessionStart hook or a capability-dispatch procedure names as required

The agent MUST immediately surface the gap to the Owner with:

1. **Which file** -- the exact filename or logical artifact name that could not be found
2. **Expected path** -- where it was looked for (resolved root + relative path)
3. **Why it matters** -- what capability, guardrail, or context is now missing from
   the session

The agent MUST NOT proceed as though the file were present or as though its absence
is an intentional design choice.

## Reference Implementation

The SessionStart hook (`templates/claude-hooks/session-start-master-orchestrator-rule.sh`)
prints an explicit `[jit-knowledge] WARNING` when `rules/interactive-master-orchestrator.md`
cannot be found:

```
[jit-knowledge] WARNING: master-orchestrator rule not found at <path>.
Identity rule NOT loaded. Session may run as a generic coding agent.
```

This is the model for how every missing-knowledge surface message should read: cite
the artifact, cite the path, state the consequence in plain English.

## Why

The master-orchestrator identity rule exists precisely to prevent sessions from
operating as generic coding agents without the binding ownership, delegation, and
judgment rules that govern JIT AI portfolio work. If that rule is missing -- or any
other binding rule, charter, or playbook -- the session's behavior is undefined and
potentially harmful (wrong ownership assumptions, skipped guardrails, wrong
trust-zone decisions).

Silently skipping a missing import signals to the agent that the knowledge was
never needed. It is not. An import that fails to resolve is a DEPLOYMENT GAP that
must be visible to the Owner before any substantive work proceeds.

Origin: 2026-05-19 RCA -- the identity rule was present in `AGENTS.md` but
never mechanically reached context; the session ran as a generic coding agent
throughout. The SessionStart hook was introduced to fix the mechanical gap. This
rule fixes the behavioral gap: even when the hook fires and the file is missing,
the agent must tell the Owner rather than continuing blind.

## How to Apply

1. Whenever your session-start or capability-resolution chain reads a file, verify
   it was actually found before proceeding.
2. If a required file is missing, emit the surface message BEFORE doing any other
   work in the session.
3. Format: one focused paragraph -- artifact name, expected path, missing capability.
   Not a bullet list. Not a multi-section report. One readable paragraph Owner can
   act on in 30 seconds.
4. After surfacing, stop and wait for Owner direction (install jit-knowledge,
   provide the missing file, or explicitly say "proceed without it").
5. Do NOT infer what the missing rule or charter would have said. The absence of a
   guardrail is not permission to proceed without that guardrail.

## What Violates This Rule

- Silently skipping a missing import and executing the requested task as though
  all context were present.
- Noting the missing file in a status line buried in the middle of a long response
  without halting for Owner acknowledgment.
- Treating a missing pinned file in `.jit-knowledge/` as "the submodule is just
  behind" and proceeding without warning.
- Swallowing a not-found error (e.g., `cat: file: No such file or directory`)
  without telling the Owner.
- Inferring the content of a missing rule from its filename and applying that
  inferred version without flagging that the real rule was not read.

## Cross-References

- `templates/claude-hooks/session-start-master-orchestrator-rule.sh` -- reference
  implementation; prints `[jit-knowledge] WARNING` on a missing rule
- `rules/interactive-master-orchestrator.md` -- the binding identity rule that
  this guardrail is most likely protecting
- `governance/SYNC-MECHANISMS.md` -- how consuming systems discover and validate
  pinned jit-knowledge artifacts
- `governance/PIN-POLICY.md` -- how consumers pin and verify their jit-knowledge ref
- `skills/install/SKILL.md` -- how to install jit-knowledge on a new machine if it
  is missing entirely
