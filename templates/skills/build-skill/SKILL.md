---
name: build-skill
description: Build, audit, or improve a Claude skill to the Anthropic-aligned standard. Use when asked to create a skill, turn a repetitive task or a one-off prompt into a skill, audit existing skills for a missing tools layer or poor composability, or add an improvement loop to a skill.
type: skill
purpose: BINDING procedure for the interactive master agent before creating, auditing, or improving any Claude skill; defines the raised Anthropic-aligned standard (three-layer skills, real tools layer, composability, improvement loop, evaluation-driven, right-sized models) so skills stop shipping as flat prompt-only files.
tags: [skill, build-skill, meta-skill, skills, anthropic, composability, recursive-improvement]
scope: public
owner_role: skill-builder
read_when: Before creating, auditing, or improving any Claude skill to ensure it meets the three-layer standard and composability requirements.
last_evaluated: 2026-06-03
workflow: recursive-improvement-loop
---

# build-skill

The skill for building skills. Operationalizes the four-rule standard in
`docs/triage/Anthropic-Engineers-Prompting.md` into a procedure the skill-builder
role (`agents/skill-builder/CHARTER.md`) follows.

## Operating Principle

- A skill is three layers: **description** (when Claude invokes it),
  **instructions** (the playbook), and **tools** (scripts, saved scripts,
  reference files). The leverage is in the tools layer -- most skills underinvest
  there. A skill with no tools layer must justify the absence.
- **Composable, not custom.** Small, single-goal skills that chain. Monolithic
  skills are rejected.
- **Evaluation-driven.** 3-5 concrete test scenarios are written BEFORE the skill.
- **Right-sized models.** Each step gets the cheapest sufficient tier. Never
  default to Sonnet.
- **PR-gated.** Skills land via PR. The builder never merges to main.
- **The skill improves every session** (Rule 4). Every skill carries a post-run
  improvement step.

## When to Use This Skill

- Create a new skill from a repetitive task or a recurring one-off prompt.
- Turn a manual procedure (something the Owner does by hand each time) into a skill.
- Audit existing skills: missing tools layer, monolithic scope, weak description.
- Improve a skill after use (Rule 4 loop): fold a recurring fix into the skill.

## Procedure

### 1. Decide it is a skill, and check for reuse first

Confirm the task is repetitive or recurring -- a one-off is not a skill. Then
search `skills/` and `scripts/` for an existing skill that already covers it or
most of it. Rule 3: build a composable skill that chains to existing ones; do not
rebuild a capability. If an existing skill is close, the job may be "improve that
skill", not "build a new one".

### 2. Write 3-5 test scenarios FIRST

Before authoring anything, write `skills/<name>/test-scenarios.md`: concrete
input -> expected-output cases. Cover the primary path, at least one edge case,
and at least one error/reject case. The scenarios are the acceptance bar -- the
skill is not done until they pass.

### 3. Scaffold

Run `scaffold-skill.py` (sibling script) to create `skills/<name>/SKILL.md` and
`skills/<name>/test-scenarios.md` skeletons from the Anthropic template.

### 4. Design the three layers

**Description (Layer 1) -- the discovery trigger.** Lead with the primary use
case. Use natural language the Owner would actually say. This is what Claude reads
to decide whether to invoke the skill; vague descriptions lose the skill.
Combined `description` + `when_to_use` is capped at 1,536 chars -- key trigger first.

**Instructions (Layer 2) -- the playbook.** Numbered, specific steps. SKILL.md
under 500 lines; move long detail to referenced files (`reference.md`,
`examples/`) so they load on demand.

**Tools (Layer 3) -- the leverage.** Identify every deterministic sub-step and
give it a script, saved inside the skill directory (Rule 3, Pattern 1: code is
deterministic, repeatable, and free of token cost; have a model write the script
once, then rerun it). A skill that is pure instructions with no tools layer must
state why in the SKILL.md.

### 5. Decompose by model tier (right-size every step)

For each step assign the cheapest sufficient tier and record it:

| Step nature | Tier |
|---|---|
| Deterministic (parse, fetch, transform, validate) | Script -- NO model |
| Reformatting, summarization, lookup, classification | Haiku |
| Reasoning, code authoring, ambiguous instructions | Sonnet |
| Ambiguous architecture, judgment calls | Opus / master |

Set the `model:` frontmatter field when the skill runs predominantly at one tier.
Never default to Sonnet because it is convenient.

### 6. Set invocability flags

Per the side-effect risk of the skill (Anthropic skill schema):

- Default (both flags unset): user- and model-invocable. Reference/action hybrid.
- `disable-model-invocation: true`: only the user can run it via `/name`. Use for
  side-effect workflows -- deploy, commit, send, publish.
- `user-invocable: false`: hidden from the slash menu; agent-only background
  knowledge.

### 7. Author SKILL.md

Frontmatter carries BOTH the Anthropic fields (`name`, `description`, invocability
flags, `model` if applicable) AND the jit-knowledge required fields (`type`,
`purpose`, `tags`, `scope`, `last_evaluated`) per `governance/FRONTMATTER-SCHEMA.md`.
Body: Operating Principle, When to Use, Procedure, QA Gates, Improvement Loop,
Cross-references. Reference bundled files rather than inlining them.

### 8. Build the tools layer

Write the scripts identified in step 4-5. Save them in the skill directory. Each
script: clear inputs, deterministic, errors loudly on bad input, never guesses.

### 9. Self-test against the scenarios

Run every scenario from step 2, dry-run where the skill supports it. Fix until all
pass. A skill that does not pass its own scenarios is not done.

### 10. Open a PR

Branch, commit (conventional-commits format), run `scripts/rebuild-manifest.py`,
open a PR. Never merge -- jit-knowledge is PR-gated; Owner approves.

### 11. Wire the improvement loop (Rule 4)

The skill's SKILL.md ends with an `## Improvement Loop` section instructing: after
each use, ask "is this a one-time fix or should it be in the skill permanently?"
If permanent, update the skill (add the rule, example, or edge case) -- do not
just fix the one output. The skill gets smarter every session or it is just a
prompt in a folder.

## Required Fields / Inputs

- `<skill-name>` -- lowercase, hyphens, max 64 chars.
- `<task description>` -- what the skill should do; the recurring task it replaces.
- `<destination>` -- project (`.claude/skills/`), personal (`~/.claude/skills/`),
  or jit-knowledge (`skills/`). Default jit-knowledge for cross-system skills.

## Example Usage

```
build-skill youtube-transcript-to-doc "given a YouTube URL, fetch the transcript, clean it, write a markdown reference doc"
```

## QA Gates

Reject or revise if any is true:

- Description fails the discovery test (a clean-context agent cannot predict when
  to invoke the skill from the description alone).
- No tools layer and no justified reason for its absence.
- Monolithic -- more than one clear goal; should be split into composable skills.
- Any test scenario fails.
- Frontmatter invalid per `governance/FRONTMATTER-SCHEMA.md`.
- SKILL.md over 500 lines with detail that belongs in referenced files.
- Model tier not assigned per step, or defaults to Sonnet without reason.
- No `## Improvement Loop` section.

## Improvement Loop

After using build-skill, review the session: did the standard miss a case; did a
step need explanation that is not in this file. If the gap is permanent, update
this SKILL.md -- build-skill improves every session like any other skill.

## Cross-References

- `agents/skill-builder/CHARTER.md` -- the role that runs this skill.
- `agents/skill-builder/TOOLS.md` -- tools used.
- `docs/triage/Anthropic-Engineers-Prompting.md` -- the four-rule standard.
- `governance/FRONTMATTER-SCHEMA.md` -- frontmatter contract.
- `skills/validate-frontmatter/SKILL.md` -- frontmatter validation (reused).
- `skills/_template/SKILL.md` -- SKILL.md skeleton.
