---
type: skill
name: session-close
status: canonical
purpose: One command at session end that runs the standard close-out checklist -- /worktree-status --all-merged (clean up retired worktrees), Hub.md final update for the session, session-state file refresh with pickup instructions, TodoWrite snapshot. Replaces the Owner's "did I remember to..." anxiety with a single explicit ceremony.
tags: [slash-command, session-end, hub-md, worktrees, session-state, jit-knowledge, recursive-improvement]
scope: public
authored_at: WIP-Drafts/skills/session-close.md
origin_date: 2026-05-28
origin_event: PR #241 + #242 open questions both ask "should --all-merged run at session-end via hypothetical /session-close skill?" -- this is that skill. After /knowledge as the session-start ceremony and the worktree trio as the lifecycle scaffolding, /session-close completes the bookend pattern.
graduation_target: jit-knowledge/skills/session-close/SKILL.md
related_skills:
  - skills/knowledge/SKILL.md (the open bookend: re-anchor + status)
  - skills/worktree-status/SKILL.md (invoked by step 2 with --all-merged)
  - skills/worktree-remove/SKILL.md (invoked by step 3 for each ready-to-remove)
  - skills/wip/SKILL.md (last-call invitation in step 5)
  - skills/save/SKILL.md (workspace command -- /session-close wraps + extends)
  - rules/session-handoff-readiness.md (BINDING -- this skill is the explicit fulfillment)
  - rules/hub-guardrail.md (Hub.md update honors monthly-scrub + no-secrets)
read_when: At the end of every session to run the close-out checklist and ensure Hub.md, worktrees, and session-state are finalized before closing.
last_evaluated: 2026-06-03
---

# /session-close slash command (WIP draft)

## Why

`/knowledge` opens a session with bootstrap + status + auto-resume.
`/session-close` mirrors that at the end: runs the close-out checklist
in one command instead of remembering to do 5 separate things.

Owner gets ADHD-friendly bookends: one open, one close. The system
remembers the cleanup so Owner doesn't have to.

## Usage

```
/session-close                # full close (default)
/session-close --dry-run      # show what would happen; don't execute
/session-close --keep-worktrees   # skip worktree cleanup step
/session-close --no-handoff   # skip session-state file rewrite
```

## The 7 steps

When invoked, in order:

### 1. Identify the session
- Read heartbeat at `<CodeBasePath>/.claude/session-state/heartbeats/$CLAUDE_SESSION_ID`
- If no active session, refuse with: "No active session; nothing to close."
- Otherwise, identify `<session-name>` and its session-state file.

### 2. Worktree fleet audit
- Internally call `/worktree-status --all` logic
- For each worktree owned by THIS session (heuristic: branch tip authored
  by current git user in the last 14 days), categorize per the
  /worktree-status recommendations
- Surface the table to Owner

### 3. Cleanup ready-to-remove worktrees
- For each worktree where /worktree-status says `ready-to-remove`,
  call /worktree-remove logic
- Honor the 5 gates from /worktree-remove (no surprises)
- If `--keep-worktrees`, skip this step
- Report: `Removed N worktrees: <list>`

### 4. Update Hub.md
- Locate Hub.md for the active context (per `<repo>/.HUB/Hub.md` or
  workspace `<CodeBasePath>/.HUB/Hub.md`)
- Append a "Session close 2026-MM-DD" sub-section that captures:
  - Tasks completed this session (from TodoWrite + git log)
  - PRs merged this session
  - PRs opened still pending review
  - Decisions locked (one-line each, from session-state notes)
  - Outstanding blockers (if any)
- Honor `rules/hub-guardrail.md`:
  - Never write secrets
  - Do NOT prune completed tasks mid-session (wait for scheduled monthly scrub)

### 5. Last-call WIP capture (optional, polite)
- Surface a one-line invitation: "Anything from this session worth
  capturing as a WIP-Drafts entry? Run /wip <name> with the body, or
  type 'skip'."
- If Owner provides input, dispatch to /wip; otherwise continue.

### 6. Refresh session-state file
- Update `.claude/session-state/<session-name>.md` to reflect:
  - "Step 1 -- Bootstrap" block (per handoff rule -- the reader executes this)
  - What was just done (commit list, PR list)
  - Pickup instructions for next session
  - Active branches + worktrees still alive (if --keep-worktrees was used)
  - Pending Owner decisions
- If `--no-handoff`, skip this step (but Hub.md still updates per step 4)

### 7. Final report
- One-screen summary covering all 6 prior steps
- Surface: "Session `<name>` closed. Run /load `<name>` to resume."

## What `/session-close` does NOT do

- Does NOT end the Claude Code process. Owner closes the terminal /
  window manually. The slash command is a cleanup ceremony, not a kill.
- Does NOT push code. If PRs are open and pending review, they stay
  open; the skill surfaces them in the report but does not force-merge.
- Does NOT delete session-state files. The session-state file persists
  so `/load <session>` can pick up later. Truly retired sessions move
  to an archive via a separate `/session-archive` skill (deferred).
- Does NOT touch worktrees owned by other agent runtimes (codex/, oc/)
  per multi-agent-repo-coordination -- same `foreign` row treatment
  as /worktree-status.
- Does NOT force-close-if-dirty. If the working tree has uncommitted
  work, the skill SURFACES it and asks Owner to commit/stash first;
  it does not silently lose work.

## Restrictions

- Honors `hub-guardrail.md` -- no secrets, no mid-session task-line
  pruning, file never deleted.
- Honors `session-handoff-readiness.md` -- the session-state file
  written by step 6 must include the required sections (header,
  conversation digest, TodoWrite snapshot, in-flight agents, open
  PRs, open RCAs, queued GH issues, recent commits, files modified,
  environment state, pending Owner decisions, next-session pickup).
- Honors `worktree-discipline.md` -- cleanup only via /worktree-remove
  gates; never `git worktree remove --force` on dirty/unpushed branches.
- Honors `actionable-docs-require-tracking.md` -- if step 4 finds
  unmet TODOs in Hub.md or session-state, surface them in step 7.

## Tools used (real files this skill orchestrates)

`/session-close` is an ORCHESTRATOR -- it doesn't ship its own single
executable. It calls the tools backing other skills + reads/writes a few
state files. Explicit dependency map:

| Step | Tool / file | Status |
|---|---|---|
| 1 (heartbeat) | `<CodeBasePath>/.claude/session-state/heartbeats/<session-id>` | reads (read-only) |
| 2 (worktree audit) | `tools/git-clone-context.sh` (PR #243) | reads |
| 2 (worktree audit) | `tools/worktree-status.ps1` | DEFERRED -- script not yet shipped (PR #242 docs only) |
| 3 (worktree cleanup) | `tools/worktree-remove.ps1` | DEFERRED -- script not yet shipped (PR #241 docs only) |
| 4 (Hub.md update) | `<repo>/.HUB/Hub.md` (or workspace `.HUB/Hub.md`) | writes (appends close-out section; honors hub-guardrail no-secrets + monthly-scrub-only-prune) |
| 5 (last-call WIP capture) | `tools/wip.ps1` (or invokes /wip skill directly) | DEFERRED -- /wip companion script not yet shipped (PR #232 docs only) |
| 6 (session-state refresh) | `<CodeBasePath>/.claude/session-state/<name>.md` | writes (per session-handoff-readiness required sections) |

Until the deferred companion scripts ship, `/session-close` invokes the
corresponding SKILL.md procedures directly (the agent reads the skill
doc + executes the procedure). Once the scripts land, the skill switches
to invoking them. The SKILL.md is the spec; the tool is the executable.

When new tools land that this skill should invoke, add a row to this
table in the same PR so the dependency surface is visible.

## --dry-run mode

Runs steps 1, 2, 4-dry, 5-dry, 6-dry, 7-dry without mutating state.
Prints exactly what would happen. Useful for "show me what closing
would do before I commit to it."

## Edge cases

- **No worktrees this session:** step 2 + 3 report "0 worktrees to
  close" and continue.
- **Hub.md doesn't exist for this context:** step 4 surfaces "No
  Hub.md found. Create one? (y/n)" and waits for Owner decision.
- **Session-state file is missing:** step 6 creates one fresh with
  full required sections per session-handoff-readiness.
- **Owner aborts mid-flow (Ctrl+C):** the skill should be safe to
  re-run -- each step is idempotent.
- **TodoWrite has in_progress tasks:** step 4 surfaces them as
  "incomplete -- next session should pick these up" + writes them to
  session-state pickup instructions; does not mark them complete.

## Honors

- `skills/knowledge/SKILL.md` -- the matching session-start ceremony
- `skills/worktree-status/SKILL.md` + `skills/worktree-remove/SKILL.md`
  -- invoked by steps 2 + 3 (cleanup via gated removal, never force)
- `skills/wip/SKILL.md` -- step 5 last-call capture invitation
- `rules/session-handoff-readiness.md` -- session-state file must meet
  all required sections; this skill is the explicit fulfillment
- `rules/hub-guardrail.md` -- step 4 Hub.md update respects no-secrets
  + monthly-scrub-only-prune rules
- `rules/multi-agent-repo-coordination.md` -- step 2/3 skip foreign
  agent worktrees

## Open questions for graduation

- Should `/session-close` also call `/knowledge` first to verify the
  bootstrap chain is still correctly loaded? Lean: no -- /knowledge
  is the open bookend; calling it at close is redundant.
- Should the skill auto-commit + push uncommitted work in the worktrees
  it owns? Lean: NO -- never silently push; ask Owner explicitly.
- Should step 4 also write to a workspace-level `recent-sessions.md`
  ledger (rolling list of last 30 sessions)? Lean: yes; deferred to
  a `/session-archive` skill that handles the long-tail ledger.
- Should this be the default behavior when Owner types "we're done" /
  "end session" / "wrap up"? Lean: yes -- the Owner-language detection
  could trigger it, but requires Owner explicit "ok run it" before
  step 3 executes (worktree removal is destructive-ish).

## Promotion checklist

- [ ] Live-trial: end of a real session with 2+ worktrees ready-to-remove
- [ ] Live-trial: --dry-run mode produces no mutation
- [ ] Live-trial: session-state file written passes
      session-handoff-readiness "Step 1 -- Bootstrap" requirement
- [ ] Status -> `wip-ready` after trial; then `/graduate` to
      `jit-knowledge/skills/session-close/SKILL.md`
