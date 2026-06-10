---
type: skill
name: knowledge
status: canonical
purpose: Force Claude to re-read the full session-start bootstrap chain on demand, then print the Mandatory Session Preflight block AND a "How I'm acting" report (identity / posture / divergent mode / active session / loaded rules / pending Owner actions / open tasks / brief summary). Manual override for the SessionStart hook + bootstrap-required HARD GATE.
read_when: When a session feels off-route, after a correction signal fires, or whenever the bootstrap HARD GATE must be manually re-triggered mid-session.
tags: [slash-command, bootstrap, session-management, master-orchestrator, identity, jitneuro, recursive-improvement]
scope: public
departments: [all]
authored_at: ~/.claude/commands/knowledge.md
origin_date: 2026-05-27
origin_event: RCA 2026-05-27 -- Claude observed skipping session-start bootstrap, writing to deprecated tracker surface (.HUB/Hub.md instead of <repo>/todo/backlog.md), violating actionable-docs-require-tracking.md (PRs without same-change tracker rows), and skipping verification gates (relayed agent STATUS:OK without gh pr view confirmation). The SessionStart hook injects only the identity rule mechanically; the rest of the bootstrap chain requires Claude to actively read files, which it forgot.
graduation_target: <knowledge-root>/skills/knowledge/SKILL.md
last_evaluated: 2026-06-03
changelog:
  - 2026-05-27 -- initial WIP capture (PR #228)
  - 2026-05-27 -- added auto-resume behavior: step 6 (refresh full task list to production deployment + sync TodoWrite + Hub.md) + step 7 (continue pre-assigned work without waiting). Default behavior is now to keep executing the queue; --stop / "stop" / "hold" / "wait" suffix opts out.
---

# /knowledge slash command (WIP draft)

## Status

This is the WIP draft of a slash command currently live in Owner's workspace
at `~/.claude/commands/knowledge.md`. It is operational
locally (visible in the Claude Code skills list as `knowledge: /knowledge`).
It has NOT yet been graduated to canonical `<knowledge-root>/skills/knowledge/`.

When graduating, decide:
- Does this stay as a slash command (Claude Code specific) or become a portable
  SKILL.md the install.sh distributes to consuming runtimes?
- Should the chain Claude reads be parameterized by repo type (the active repo uses
  `<repo>/todo/backlog.md`; other repos use `.HUB/Hub.md`; some use both)?
- Should `/knowledge` print Pending Owner Actions automatically, or only when
  invoked with `--actions`?

## Why this exists

Two distinct gates need to fire at session-start, and only one is mechanical:

1. **SessionStart hook (mechanical):** injects the identity rule from
   `<jitneuro>/rules/interactive-master-orchestrator.md` into the
   context window before any tool runs. Output is the line
   `** jitneuro loaded -- master-orchestrator identity rule active **`.
   This part is reliable.

2. **Bootstrap chain reads (NOT mechanical):** requires Claude to actively
   open and read `<workspace>/AGENTS.md` -> jitneuro `AGENTS.md/COMPANY.md/
   README.md/INDEX.md` -> binding rules -> repo-local instructions including
   `<repo>/AGENTS.md`, `<repo>/CLAUDE.md`, `<repo>/.HUB/Hub.md`, and
   `<repo>/todo/backlog.md` where present. This is discipline, not mechanism.

Claude skips #2 sometimes. The `/knowledge` slash command is the manual
override that forces #2 to run when Owner notices the session is off-route.

## What Claude must do when invoked

(See the live skill at
`~/.claude/commands/knowledge.md` for full procedure.)

Summary:
1. STOP all in-progress executable work
2. Read the chain top-to-bottom, no skipping
3. Identify the active session via heartbeat
4. Print the Mandatory Session Preflight block (Role / Loaded / Repo /
   Work type / Execution route / Direct edits allowed / Verification gate)
5. Print the "How I'm acting" report (identity / posture / divergent mode /
   active session / loaded rules / pending Owner actions / open tasks /
   brief 2-3 sentence summary)
6. **Refresh the full task list to production deployment.** Identify the
   production-deployment endpoint for current work (PRs merged + deployed +
   verified live, OR feature shipped + customer-visible + tested per
   `definition-of-done`). Compile the FULL ordered task list -- include PR
   reviews, merges, post-merge verification, deploy steps, smoke tests,
   follow-ups, and Owner-blocked items as named tasks so the path-to-prod is
   visible. Push the list into TodoWrite (`TaskCreate`), mark first executable
   task `in_progress`. Mirror the list into the active context's Hub.md
   (`<repo>/.HUB/Hub.md` or workspace `.HUB/Hub.md`). Honor `hub-guardrail.md`
   -- no secrets in Hub.md ever. Display: `Tasks updated: N total, M
   in_progress, K blocked-on-Owner`.
7. **Continue pre-assigned work.** Pick the next executable task NOT blocked
   on Owner / RED zone / external dependency. Execute per
   `autonomous-execution.md`. DO NOT wait for Owner direction unless the next
   task explicitly needs Owner input -- `/knowledge` was invoked to re-anchor,
   not to stop. On completion: update TodoWrite + Hub.md, surface one-line
   completion note, pick next task. Continue until queue is empty or
   genuinely blocked.

**Explicit stop exception:** Owner may type `/knowledge --stop` (or follow
`/knowledge` with "stop" / "hold" / "wait") to skip steps 6-7 and end on the
status display. Default is auto-execute steps 6-7.

## Restrictions

- `/knowledge` itself does not mutate state. No edits, no commits, no PR
  operations, no agent dispatches during the bootstrap pass.
- Reading files and running read-only `git` / `gh` queries is allowed.
- If a file in the chain is missing, surface a one-line warning and continue.

## Companion rules (added 2026-05-27 alongside this skill)

- "Bootstrap Required (HARD GATE -- session-start)" in `<workspace>/AGENTS.md`,
  `<workspace>/CLAUDE.md`, and `~/.claude/CLAUDE.md`
- "Handoff Rule (BINDING)" in same three files -- Step 1 of every handoff
  document is "Bootstrap" (the writer carries the chain; the reader executes
  it on load)

## Promotion checklist

- [ ] Decide canonical home: `<knowledge-root>/skills/knowledge/SKILL.md`
- [ ] Decide if `install.sh` should also distribute a slash-command stub for
      Claude-Code-runtime consumers (similar to existing rules drop pattern)
- [ ] Reconcile tracker-surface conflict: `.HUB/Hub.md` vs `<repo>/todo/backlog.md`
      across repos. Currently both are read; promotion may want to parameterize.
- [ ] Audit: is there overlap with `/load`, `/save`, `/session`, `/health`
      already in workspace commands? If so, what does each NOT cover?
