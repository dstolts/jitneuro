---
type: skill
name: wip
status: canonical
purpose: Capture the current conversation's working context into a WIP-Drafts file so the work survives session end and can graduate to canonical jit-knowledge later. Infers the right WIP-Drafts surface (rules / charters / patterns / playbooks / workflows / skills / references / INBOX) from content; confirms with Owner in a single line before staging. Stages the file but does NOT auto-commit -- Owner controls the commit boundary.
tags: [slash-command, wip-drafts, session-capture, recursive-improvement, jit-knowledge]
scope: public
departments: [all]
authored_at: WIP-Drafts/skills/wip.md
origin_date: 2026-05-27
origin_event: Knowledge session 2026-05-24 follow-up queue item 2a; Owner directive (see WIP-Drafts/README.md + rules/wip-drafts-lifecycle.md). The /knowledge command exists to re-anchor sessions to bootstrap; /wip is the complementary capture mechanism so insights surfaced mid-session don't evaporate.
graduation_target: jit-knowledge/skills/wip/SKILL.md
related_skills:
  - /knowledge -- bootstrap re-read + status display + auto task-list + auto-resume (WIP draft at WIP-Drafts/INBOX/knowledge-slash-command.md)
  - /graduate -- promote a `status: wip-ready` file to canonical via git mv + frontmatter flip + open PR (queued item 2b)
read_when: When you want to capture a rule, charter, pattern, or insight from the current session into WIP-Drafts before the session ends.
last_evaluated: 2026-06-03
---

# /wip slash command (WIP draft)

## What it does

Capture the current conversation's working artifact (a rule, charter, pattern,
playbook, workflow, skill, or reference -- or unknown surface) into a
WIP-Drafts file with proper frontmatter, then stage it for Owner commit.

Usage:

```
/wip <name>                            # infer surface from conversation content
/wip <surface>/<name>                  # explicit surface (rules/foo, skills/bar, etc.)
/wip <name> --inbox                    # force INBOX (skip inference, surface unclear)
```

## Decisions pre-locked (Owner 2026-05-24)

1. **Surface inference: infer + 1-line confirm.** Claude scans the current
   conversation's content + Owner's framing and proposes the surface
   (rule / charter / pattern / playbook / workflow / skill / reference). It
   asks Owner ONE line to confirm before staging: `Surface: <inferred>; OK?`
   If Owner declines or the inference is ambiguous, default to `INBOX` and
   capture surface as a graduation-time decision.

2. **Stage only; do NOT auto-commit.** `/wip` writes the file and runs
   `git add <path>` so the file is in the staging area, but stops there.
   Owner controls the commit boundary because commit timing is judgment
   (batch with related work? wait for sprint close? immediate?). Claude
   surfaces the path + a draft commit message Owner can copy-paste; Owner
   commits.

## What Claude must do when invoked

1. **Identify what to capture.** Scan the recent conversation (this turn +
   the last several turns) for the working artifact. If Owner provided a
   name argument, that names the file; otherwise propose a kebab-case slug
   from the content.

2. **Infer the surface.** Map content shape to WIP-Drafts subfolder:

   | Content shape | Surface |
   |---|---|
   | "must" / "never" / "always" + scope + violation list | `rules/` |
   | Role identity + authority + KPIs + guardrails | `charters/` (under `org/...`) |
   | Reusable process / decision template / how-to-think | `_patterns/` |
   | Step-by-step runbook tied to a recurring scenario | `playbooks/` |
   | Multi-step DAG / pipeline / workflow spec | `workflows/` |
   | Tool / slash command / agent capability | `skills/` |
   | External canonical reference / linked source | `references/` |
   | Anything ambiguous | `INBOX/` |

3. **Confirm with Owner (1 line).** Print:
   `Surface: <inferred> | Name: <slug> | File: WIP-Drafts/<surface>/<slug>.md
    -- OK? (yes / different surface / inbox / cancel)`

4. **Author the file.** Required frontmatter (per
   `governance/FRONTMATTER-SCHEMA.md`):
   - `type:` -- one of: rule, charter, pattern, playbook, workflow,
     skill-candidate, reference, doc
   - `name:` -- kebab-case slug
   - `status:` -- always `draft` initially
   - `purpose:` -- 1-2 sentence what + why
   - `tags:` -- comma-separated keywords
   - `scope:` -- `internal` default; `public` only if explicitly so
   - `origin_date:` -- today
   - `origin_event:` -- 1-2 sentence conversation context (what triggered
     the capture)
   - `last_evaluated:` -- today
   - `graduation_target:` -- canonical path when graduated

   Body should include: what / why / how-to-apply / what-violates /
   open-questions / related. The body must be self-contained enough that
   a reader who has not seen this conversation can apply it.

5. **Honor `hub-guardrail.md`** -- absolutely no secrets in the file
   (API keys, tokens, passwords, signing keys). Reference env-var names +
   locations instead.

6. **Stage the file.**
   - `git add WIP-Drafts/<surface>/<slug>.md`
   - Do NOT commit.

7. **Print the result for Owner.**
   - File path
   - Inferred surface (and how confidence was scored, in one line)
   - Suggested commit message (draft -- Owner edits before committing):
     `wip(<surface>): capture <slug> draft`
   - One-line summary of what the file contains
   - Open questions / things Claude was unsure about (so Owner can fill
     before commit)

8. **Update TodoWrite** -- if the captured artifact represents future work
   (graduation, validation, integration), add a tracker row referencing
   the file path. Per `actionable-docs-require-tracking.md`.

## What `/wip` does NOT do

- Does not commit. (Owner decision -- see Decision 2.)
- Does not push or open a PR. Graduation runs through `/graduate` once the
  draft matures from `status: draft` -> `status: wip-ready`.
- Does not load into any tool's auto-discovery surface. WIP-Drafts content
  is gitignored from runtime loaders by lifecycle design.
- Does not delete or replace existing WIP-Drafts files. If `<slug>` already
  exists, refuses with a one-line conflict message and proposes a versioned
  slug (`<slug>-02`).

## Restrictions

- Pure capture skill. No state mutation beyond writing one new file +
  `git add`.
- Reading files and running read-only `git` queries is allowed.
- If conversation context is sparse (Owner invoked `/wip` with no
  preceding substantive content), refuse with a one-line message: "No
  recent substantive content to capture. Provide context or a body, or
  type `/wip --inbox <name>` with explicit text."

## Related rules

- `rules/wip-drafts-lifecycle.md` -- 3-stage INBOX -> surface -> canonical
- `governance/FRONTMATTER-SCHEMA.md` -- required frontmatter fields
- `rules/actionable-docs-require-tracking.md` -- capture follows up with
  TodoWrite tracker rows
- `rules/hub-guardrail.md` -- no secrets in any committed/staged content

## Open questions (for graduation review)

- Should `/wip` also accept piped content (`/wip rule/X < draft.md`)?
- Should the 1-line confirmation be skippable with `--yes` for batch
  capture sessions?
- Should `/wip` auto-link to a parent session-state file in
  `.claude/session-state/` so the capture remembers its session origin?
- How does this interact with `/save` -- does `/save` enumerate staged
  WIP files in its session-state output?

## Promotion checklist

- [ ] Live-trial in 2+ real capture sessions; verify inference accuracy
- [ ] Reconcile with `/save` (some overlap in 'persist session insight'
      scope)
- [ ] Decide canonical home: `jit-knowledge/skills/wip/SKILL.md`
- [ ] Decide if `install.sh` should distribute a slash-command stub for
      Claude-Code-runtime consumers
- [ ] Status -> `wip-ready` once trial + reconciliation done; then
      `/graduate` to canonical
