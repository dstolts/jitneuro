---
type: skill
name: handoff
status: canonical
purpose: 'At a logical stopping point with high context, perform a clean session handoff -- save state, run /learn (persist memories), reconcile TodoWrite + Hub.md to current truth, then author a handoff document so a fresh session can continue without losing continuity. Differs from /save (checkpoint only) and /knowledge (re-anchor current session); /handoff TRANSFERS the work to a new session.'
tags: [slash-command, session-handoff, save, learn, hub-sync, todo-sync, new-session, context-budget, recursive-improvement]
scope: public
departments: [all]
origin_date: 2026-05-28
origin_event: 'Owner directive 2026-05-28: "add to todowrite new slash command handoff when at a logical stopping point, save, learn, update todowrite and hub.md, create handoff document to continue in a new session since context is high." Fires when current session is near compaction OR Owner explicitly wants to break to a fresh session WITHOUT losing TodoWrite + active context. Companion to /knowledge (re-anchor) + /save (checkpoint) + /session-close (cleanup) -- the four are the full session-lifecycle quartet.'
graduation_date: 2026-05-29
graduation_pr: 280
read_when: When context is high and work must transfer to a fresh session without losing TodoWrite continuity or active state.
last_evaluated: 2026-06-03
---

# /handoff slash command

## Usage

```
/handoff             # default -- wait for logical stopping point; refuse if mid-flight
/handoff --urgent    # interrupt-now mode -- skip the stopping-point gate; capture in-flight state in the handoff doc and stop immediately
```

## What it does

When Owner invokes `/handoff`, Claude performs a session-ending handoff
sequence in this order, then stops with a clean handoff doc the next session
can resume from:

1. Run `/save` (or its mechanical equivalent) -- persist session state to
   `<workspace>/.sessions/<name>.md`
2. Run `/learn` (mechanical equivalent) -- evaluate the session for memory
   updates; persist approved facts to `~/.claude/projects/.../memory/`
3. Reconcile TodoWrite against `<repo>/.HUB/Hub.md` -- ensure both reflect
   current truth (pending, in-progress, completed, blocked); update Hub.md
   inline; mark completed items
4. Author the **handoff document** at
   `<repo>/.HUB/handoff-<session-name>-<YYYY-MM-DD>.md` following the
   Handoff Rule (BINDING -- see `<workspace>/AGENTS.md` "Handoff Rule")
5. Surface the handoff path + a one-line summary to Owner and STOP -- do not
   continue substantive work after `/handoff` completes

## Why this is different from sibling skills

| Skill | Purpose | When to invoke |
|---|---|---|
| `/save` | Checkpoint session state | Mid-session, recovery insurance |
| `/learn` | Persist memories to long-term storage | After a learning moment |
| `/knowledge` | Re-anchor CURRENT session to bootstrap | Mid-session drift correction |
| `/session-close` | Cleanup worktrees + close current session cleanly | End of work, no new session |
| `/handoff` | **TRANSFER work to a new session** | Context high, want to continue in fresh session |

`/handoff` is the only one of the five that explicitly TRANSFERS work to a
new session via a Handoff Rule-compliant document.

## Gates -- must hold before /handoff executes

1. **Logical stopping point check.** Refuse if any executable in-flight work
   is mid-step (uncommitted code changes that aren't a complete logical unit,
   a PR mid-creation, a subagent dispatched but not yet returned). Surface
   the in-flight state to Owner and ask: "Finish in-flight work first, or
   re-run with --urgent to handoff immediately?"

   **`--urgent` bypasses this gate.** Used when Owner wants to break to a
   fresh session NOW (context hard-pressed, urgent context switch, AFK
   trigger mid-task). When --urgent is set:
   - In-flight state is CAPTURED (not finished) in the handoff doc under a
     new section "In-flight interrupt state"
   - Any background subagents still running are listed by ID + last-known
     status; the next session's first action is to check their return
   - Any uncommitted edits in worktrees are listed by path + git status;
     the next session decides whether to finish, revert, or extend them
   - Open PRs are listed with mergeable state + CI status as-of interrupt
2. **Hub.md exists for the active repo OR workspace.** If not, create
   `.HUB/Hub.md` (per `rules/hub-guardrail.md`) before proceeding. (--urgent
   does NOT bypass this; Hub.md is mandatory for handoff to be useful.)
3. **No secrets in handoff body.** Per `rules/hub-guardrail.md`, the handoff
   document MUST reference env-var names + locations, never the value.
   (--urgent does NOT bypass this; secrets-in-Hub.md is categorical.)

## What the handoff document MUST contain (Handoff Rule binding format)

Per `<workspace>/AGENTS.md` "Handoff Rule (BINDING)":

```
# Handoff -- <session-name> -- <date>

## Step 1 -- Bootstrap (do NOT skip)
Read in order:
1. <workspace>/AGENTS.md
2. <knowledge-root>: AGENTS.md, COMPANY.md, README.md, INDEX.md
3. Every rule in workspace AGENTS.md "Binding Rules"
4. THIS handoff
5. <active-repo>/AGENTS.md, CLAUDE.md, .HUB/Hub.md, todo/backlog.md

After reading, print the Mandatory Session Preflight block.

## Context (what just happened)
<2-3 sentence summary of the session that just ended>

## Active TodoWrite snapshot
<full TodoWrite list at handoff time, with statuses>

## Pending Owner actions
<questions awaiting Owner judgment, with paths to evidence>

## Open PRs
<list with URL + state + blocker per PR>

## Files modified this session
<by path, with one-line purpose>

## Next-session pickup instructions
<explicit ordered list of FIRST actions the next session should take>
```

## What Claude must do when invoked

1. **Acknowledge** -- one-line confirmation to Owner: "Performing handoff. Stopping work after; resume with /load <session> + this handoff in a new session."

2. **Gate check** (above). If any gate fails, surface and ask Owner.

3. **Step 1: Save** -- write/update `<workspace>/.sessions/<name>.md` with current state. Reuse `/save` if available as a slash command; otherwise inline the save logic.

4. **Step 2: Learn** -- evaluate session for new lessons / new memory entries per `/learn` skill. Persist approved entries (or surface a table of candidates if user-interactive mode).

5. **Step 3: Hub.md + TodoWrite reconcile** -- read both; diff; update Hub.md inline so it matches TodoWrite truth. Per `rules/hub-guardrail.md` mid-session policy, completed tasks STAY in Hub.md as audit trail (monthly scrub removes; not /handoff).

6. **Step 4: Author handoff doc** -- write to `<repo>/.HUB/handoff-<name>-<date>.md` (or `<workspace>/.HUB/handoff-...` if no repo context). MUST start with the Step 1 Bootstrap block (verbatim from above).

7. **Step 5: Surface** -- print the handoff path + a one-line summary. Examples:
   ```
   Handoff written: <workspace>\.HUB\handoff-Knowledge-2026-05-28.md
   Next session: /load Knowledge + read that handoff. 5 PRs merged this session, 2 pending Owner.
   ```

8. **STOP** -- do not continue substantive work. The session is in handoff-complete mode. Subsequent Owner messages should be treated as conversation, not work directives, unless they explicitly say "actually keep going" (which converts the handoff back to a checkpoint).

## Restrictions

- /handoff does NOT close worktrees (that's /session-close)
- /handoff does NOT push uncommitted changes -- requires clean state first
- /handoff does NOT auto-load the new session -- Owner manually starts a new session and reads the handoff
- /handoff document MUST follow Handoff Rule (BINDING) -- Step 1 Bootstrap is the first section, no exceptions

## Edge cases

- **No active session:** Refuse with "No active session detected. Use /session new to start one, or this isn't a context that needs a handoff."
- **Workspace-only work (no repo context):** Write handoff to `<workspace>/.HUB/handoff-<name>-<date>.md`. Reference workspace-level Hub.md.
- **Context already compacted:** /handoff still works -- it reads durable state (Hub.md + session-state), so post-compaction handoff is supported. Note in handoff body: "context was compacted before handoff; durable state is authoritative."
- **`--urgent` override (Owner-explicit):** Skip the logical-stopping-point gate; proceed with handoff immediately. The handoff body MUST include an "In-flight interrupt state" section enumerating:
  - Background subagents still running (ID + dispatch prompt summary + last-known status)
  - Uncommitted edits per worktree (path + `git status --short` snapshot)
  - Open PRs at interrupt time (URL + mergeable state + CI status)
  - Owner's last directive (verbatim) + Claude's interpretation
  Next session's FIRST action after bootstrap is to triage in-flight items.
- **No git repo (workspace direct edits):** Same as workspace-only above; handoff covers all touched files via session-state file list.

## Tooling (companion `tools/handoff.ps1` -- optional)

If a mechanical companion is useful (similar to `tools/wip.ps1` /
`tools/graduate.ps1`), the script orchestrates:
- Resolve session name from heartbeat
- Compute Hub.md + TodoWrite delta
- Author the handoff doc from a template
- Print the surfaced path

For v1, the skill body is sufficient; a companion tool can come if the
slash command is heavily used and the steps benefit from mechanization.

## Honors

- `<workspace>/AGENTS.md` "Handoff Rule (BINDING)" -- the binding format
- `rules/hub-guardrail.md` -- Hub.md sync + no-secrets discipline
- `rules/wip-drafts-lifecycle.md` -- this file's own status flow
- `~/.claude/rules/session-handoff-readiness.md` (user-local) -- complementary trigger conditions

## Graduation resolutions (decided 2026-05-29)

The four open questions from WIP have been resolved by the v1 live-trial in
the Knowledge session on 2026-05-29:

1. **Sub-skill composition vs inline:** INLINE. Claude Code does not have a
   native skill-composition primitive; inlining the procedure is reliable.
   `/handoff` performs save / learn / Hub.md reconcile / handoff-doc-author
   as its own steps without delegating to other slash commands.
2. **Handoff doc location:** workspace `<workspace>/.HUB/handoff-<name>-<date>.md`
   when no repo context applies; `<repo>/.HUB/handoff-<name>-<date>.md` when
   one does. `.HUB/` is git-tracked on private/internal repos per
   `rules/hub-guardrail.md`, so handoff docs survive across machines.
3. **Companion tool:** DEFERRED. v1 ships as skill body procedure only. If
   the slash command is heavily used, `tools/handoff.ps1` can mechanize the
   steps later (template + path resolution + delta diff against Hub.md).
4. **Auto-fire on context threshold:** NO. `/handoff` remains Owner-initiated.
   `PreCompact` hook fires `/knowledge` (re-anchor in same session) rather
   than `/handoff` (transfer to fresh session). The two events have different
   intents.

## Live-trial validation (2026-05-29)

The Knowledge session itself exercised `/handoff`:

- All 5 procedure steps completed without errors
- The handoff doc at `<workspace>/.HUB/handoff-Knowledge-2026-05-29.md` followed the
  Handoff Rule (BINDING) format -- Step 1 Bootstrap as the first section
- Hub.md + TodoWrite reconciled cleanly across the prior compaction (the
  durable state was authoritative; in-memory state was lost as expected)
- The post-compact session was able to bootstrap from the handoff doc and
  continue without re-asking Owner for context
