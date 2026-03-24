# Session

Manage the current session. Shows status by default, with subcommands for lifecycle operations.

## Commands

Trigger on these patterns (case-insensitive):
- `session` -- show current session status + blockers (alias: `status`)
- `session new <name>` -- create a fresh named session
- `session save <name>` -- checkpoint to disk (shortcut: `/save`)
- `session load <name|#>` -- restore from disk (shortcut: `/load`)
- `session pulse` -- re-read shared state from other sessions (shortcut: `/pulse`)
- `session switch <name|#>` -- save current + load another in one step
- `session rename <new-name>` -- rename current session
- `session close` -- mark current session as CLOSED (done with this work)
- `session dashboard` -- current session blockers and NEEDS OWNER items

Numbers reference the last `/sessions` list output.

## Current Session Tracking

Session identity is stored in `.claude/session-state/heartbeats/<session-id>` -- one file per active Claude Code instance. The `<session-id>` is Claude's native session ID, injected into context by the SessionStart hook as `[JitNeuro] session-id: <value>`. After compaction or context clear, SessionStart fires again and re-injects it.

**Resolve "my current" (get active session name):**
1. Find your session-id from the `[JitNeuro] session-id: ...` line in your context.
2. Read `.claude/session-state/heartbeats/<session-id>`. The content (one line) is the active session name.
3. If the file is missing or empty: no active session.

**Write "my current" (set active session name to `<name>`):**
1. Use Bash to write the session name: `echo -n "<name>" > ".claude/session-state/heartbeats/<session-id>"` (session-id from context). Create the `heartbeats/` directory with `mkdir -p` if it does not exist.
   **IMPORTANT:** Always use Bash for heartbeat writes, never Write/Edit tools. The PostToolUse heartbeat hook touches this file after every tool call, so Write/Edit will fail with "file modified since read." Bash echo is atomic and avoids the race.

**Clear "my current" (e.g. active session was deleted/archived):**
1. Remove `.claude/session-state/heartbeats/<session-id>` if it exists (session-id from context).

Updated by: `new`, `save`, `load`, `switch`, `rename`.
Read by: default view, `pulse`, `dashboard`, and the session tag rule.

## Session Tag Rule

**Every response must end with `[session: <name>]`** where `<name>` comes from **resolving "my current"** (see above).
If no active session: `[session: none]`.
This is non-negotiable -- it prevents context confusion across terminals.

## Shortcut Preference

Read `.claude/session-state/.preferences` for `shortcut_scope` setting.
- `session` (default): `/status`, `/dashboard`, `/save`, `/load`, `/pulse` -> `/session` subcommands
- `sessions`: `/status`, `/dashboard` -> `/sessions` subcommands (save/load/pulse always stay `/session`)

If `.preferences` doesn't exist, default to `session` scope.

## Instructions

### session (default) -- current session status

1. **Resolve "my current"** (see Current Session Tracking) to get active session name.
2. If no active session: "No active session. Run `/session new <name>` to start one."
3. Read the session state file `.claude/session-state/<name>.md`
4. Read `.claude/bundles/active-work.md` for sprint context
5. For each repo listed in the session state:
   - Run `git -C [repo_path] status --short` for dirty files
   - Run `git -C [repo_path] branch --show-current` for current branch
   - Run `git -C [repo_path] log --oneline -1` for last commit
6. Display:

```
== Session: <name> == (checkpointed <age> ago)

Task: [current task]
Sprint: [active sprint if any]

| Repo | Branch | Dirty | Last Commit |
|------|--------|-------|-------------|
| app  | uat    | 3     | abc1234 fix: comments |
| api  | sprint | clean | def5678 feat: endpoints |

Next steps:
1. [from session state]
2. [from session state]

BLOCKED: [count] items needing attention
```

7. **Hub.md freshness check:** For each repo in the session, check `<repo>/.HUB/Hub-*.md`:
   - If Hub.md exists: show "Last Updated" date. If older than session checkpoint, flag: "Hub.md STALE -- last updated <date>, session saved <date>. Run /save to sync."
   - If Hub.md missing and session has tasks: flag: "No Hub.md -- task state is volatile only."
8. Flag issues: repos on main with dirty files, unpushed commits, behind remote

### session new <name>

1. **Resolve "my current"** to see if there is an active session.
2. If active session exists:
   - Read the session state file, check age of last checkpoint
   - Check if session has unsaved state (files modified, decisions made)
   - Prompt (one question, recommended first):
     "Active session '<name>' (last saved <age> ago, <N> files modified). Save + learn before starting new? (save+learn / save only / skip)"
   - If save+learn: run save flow, then suggest /learn
   - If save only: run save flow
   - If skip: proceed
3. Create `.claude/session-state/<name>.md` with initial template:
   ```markdown
   # Session: <name>
   **Checkpointed:** [current date/time]
   **Claude Session ID:** [session-id from context, or "unknown"]
   **Previous Claude Session ID:** (none -- new session)

   ## Current Task
   New session -- no task assigned yet.

   ## Repos Involved
   - (none yet)

   ## Key Decisions
   - (none yet)

   ## Next Steps
   - Awaiting direction
   ```
4. **Write "my current"** (session name).
5. Confirm: "Session '<name>' created."

### session save <name>

1. **Determine session name:**
   - If name provided, use it (lowercase, hyphens, task-descriptive)
   - If no name: **resolve "my current"**. If active session, use that name.
   - If no name and no active session: suggest one based on current work, ASK to confirm
   - **Multiple tasks:** If session touched more than one distinct task,
     ask: "This session touched [task A] and [task B]. Save as one or separate?"

2. **Gather current session state:**
   - What task am I working on?
   - Which repos are involved?
   - Which bundles are currently loaded/active?
   - What files have been modified this session?
   - What decisions were made that haven't been persisted?
   - What are the immediate next steps?
   - Any key findings or discoveries worth preserving?

3. **Write state to `.claude/session-state/<name>.md`:**

   The checkpoint must be a **"ready to resume on load"** document. A new session
   (or a post-compaction reload) reads ONLY this file to get started. If the next
   session has to re-read code, re-trace decisions, or guess what to do, the
   checkpoint failed.

   ```markdown
   # Session: <name>
   **Checkpointed:** [current date/time] ([Nth save -- brief reason])
   **Claude Session ID:** [session-id from context, or "unknown"]
   **Previous Claude Session ID:** [if a previous session-id is known from loading a checkpoint, write it here; otherwise omit this line]

   ## Current Task
   [One-line status. What is done, what is next.]

   ## PICKUP INSTRUCTIONS (read this FIRST after load)

   ### Context Recovery (do these in order)
   1. Read THIS file for full context
   2. Read the Hub: [path to Hub-XX.md]
   3. [Any other files needed: plan docs, specs, PRDs]

   ### What Was Just Done
   [Concise summary of work completed this sub-session. For bug fixes,
   include root cause + fix. For new features, include brief architecture.
   Group by logical change, not by file.]

   ### What to Do Next
   [Numbered steps with success/failure branches. The next session should
   be able to start executing within 60 seconds of reading this.]
   1. [First action]
   2. [Second action -- depends on #1 result]
   3. If [success condition]: proceed to [next phase]
   4. If [failure condition]: debug [specific thing to check]

   ### Process State (things that die with the session)
   [Background servers, running processes, open connections, dashboard state.
   List commands to restart them. Skip this section if nothing to restore.]

   ## Modified Files
   [Group by type for quick scanning:]
   **New:**
   - [path] -- [purpose]
   **Changed:**
   - [path] -- [what changed and why]
   **Settings/Config:**
   - [path] -- [what was wired]
   **Deleted:**
   - [path] -- [why removed]

   ## Repos Involved
   - [repo path] -- [what's happening here]

   ## Active Bundles
   - [bundle1.md] -- [why it's loaded]

   ## Key Decisions
   - [decision and reasoning -- especially non-obvious choices]

   ## Key Findings
   - [Non-obvious discoveries that won't be in code or git history.
     Things the next session needs to know but can't derive.]

   ## Remaining Tasks
   - [task] [status: pending/blocked] -- [brief context]
   ```

   **Quality bar:** After writing, re-read the PICKUP INSTRUCTIONS section.
   Ask: "Could a fresh session execute the next step in under 60 seconds
   from reading this?" If not, add what's missing.

4. **MANDATORY: Sync Hub.md** (do NOT skip this step):

   Hub.md is the durable task record. Session state and TodoWrite are volatile -- lost on /clear or crash.
   If you skip this step, weeks of work become invisible. This has happened and caused real problems.

   For each repo involved in this session:
   a. Check if `<repo>/.HUB/` exists. If not, create it.
   b. Find or create `Hub-<NN>.md` (use next available number if creating).
   c. Find or create a **session section** using the session name as the heading:
      ```markdown
      ## <session-name> (sync)          <-- session name + brief focus area
      **Last Updated:** 2026-03-23
      - [ ] Fix sync retry logic
      - [x] Add timeout handling (2026-03-23)
      **Decisions:** Use exponential backoff (matches existing pattern)
      **Files:** src/sync/retry.ts, src/sync/config.ts
      ```
      Multiple sessions in the same repo get their own sections. Each session only
      reads/writes its own section -- never touch another session's section.
   d. Sync ALL of the following into the session's section:
      - **Active tasks:** All TodoWrite items as checkboxes
      - **Completed tasks:** Mark completed items as DONE with date
      - **Session status:** Current sprint name, phase, blockers
      - **Key decisions:** Any decisions made this session that affect the project
      - **Modified files:** List of files changed (brief, not full paths for every line)
   e. Update the "Last Updated" date in the session's section header
   f. If Hub.md hasn't been touched in 3+ days, flag it in save confirmation
   g. Leave a top-level "Last Updated" date at the file header for quick staleness checks

   **Verification:** After writing, read Hub.md back and confirm in output:
   ```
   Hub.md synced (<repo>): <N> tasks updated, <N> decisions logged, last updated: <date>
   ```
   If Hub.md sync fails or is empty, WARN the user -- do not silently skip.

5. **Write "my current"** (session name).
6. Confirm with Hub.md sync status:
   ```
   Saved '<name>'.
   Hub.md: [repo1] synced (3 tasks, 1 decision) | [repo2] synced (clean)
   Safe to /clear. Use `/session load <name>` to reload.
   ```
7. Suggest: "Run `/learn` first if this session had learnings worth persisting."

**Size guidance:** Target 40-80 lines. Under 30 is missing pickup context. Over 120 is too verbose -- move detail into Hub.md or plan docs and reference them. The PICKUP INSTRUCTIONS section should be 15-30 lines (the most critical part).

### session load <name|#>

1. **Determine which session:**
   - If name/number provided: resolve to session file
   - If no name: **resolve "my current"**. If exists, load that.
   - If no name and no current: list sessions, ask user to pick
   - If number: resolve from last `/sessions` list output

2. **Read the session state file**

3. **Note previous session-id:** Read the `**Claude Session ID:**` field from the checkpoint. This is the Claude session-id that last saved this checkpoint. Remember it in context as "previous session-id" -- write it to `**Previous Claude Session ID:**` on the next `/save`.

4. **Read active bundles** listed in session state (only those listed)

5. **Read `.claude/context-manifest.md`** for bundle awareness

6. **Write "my current"** (session name).

7. **Report:**
   ```
   Loaded: <name> (checkpointed <date>)
   Task: [current task]
   Repos: [list]
   Loaded bundles: [list]
   Previous Claude Session ID: [id from checkpoint, if any]
   Next steps:
   1. [from session state]
   ```

8. If session is stale (>7 days), mention it and ask if still relevant

### session pulse

1. **Resolve "my current"** to identify active session.
2. Read shared state files in parallel:
   - `.claude/bundles/active-work.md`
   - All `.claude/session-state/*.md` (exclude archive/, _autosave.md)
   - Hub.md files for repos in current session
3. Compare to what's in current context
4. Report:
   ```
   Pulse (date/time):
     active-work.md  -- [unchanged | N changes detected]
     sessions         -- [N active, new/removed since last check]
     Hub.md (repo)    -- [unchanged | updated]

   Changes:
     - Sprint-X marked complete (was: in progress)
     - New session "feature-y" appeared
   ```
5. If nothing changed: "Pulse -- all shared state unchanged."
6. If active-work.md changed significantly, suggest `/bundle active-work`

### session switch <name|#>

1. Run `session save` flow for current session (auto-save, no name prompt needed)
2. Prompt: "Learnings worth persisting before switching? (yes -> /learn / no -> switch now)"
3. Run `session load` flow for target session
4. **Write "my current"** (new session name).

### session rename <new-name>

1. **Resolve "my current"** to get active session name.
2. If no active session: "No active session to rename."
3. Rename `.claude/session-state/<old-name>.md` to `<new-name>.md`
4. **Write "my current"** (new name).
5. Update the `# Session:` header inside the file
6. Confirm: "Renamed '<old>' -> '<new>'."

### session close

1. **Resolve "my current"** to get active session name.
2. If no active session: "No active session to close."
3. Run `session save` flow first (checkpoint + Hub.md sync).
4. Add `**Status:** CLOSED` to the session state file header.
5. **Clear "my current"** (remove the active session pointer).
6. Confirm: "Session '<name>' closed. Work saved. Use `/session load <name>` to reopen."

Closed sessions appear in the "Closed" section on the dashboard (collapsed, greyed out). They are not deleted -- just marked done. Use this when the work is complete and you don't want the session cluttering the active/idle lists.

### session dashboard

1. **Resolve "my current"** to get active session.
2. Read the session state file
3. Read `.claude/bundles/active-work.md`
4. Read Hub.md files for repos in this session only
5. Filter for items related to THIS session's repos/sprint
6. Display:
   ```
   == Session Dashboard: <name> ==

   BLOCKED (cannot proceed):
     1. [item] -- [source] -- [what's needed]

   APPROVAL NEEDED:
     2. [item] -- [source] -- [what to approve]

   DECISIONS:
     3. [item] -- [options]

   Next steps:
     1. [from session state]
   ```
7. If no items: "Session '<name>' is clear -- no blockers."
8. **Hub.md freshness:** Check each repo's Hub.md age. If stale (>3 days or older than session checkpoint), add to BLOCKED section: "Hub.md stale for <repo> -- run /save to sync."

## Important
- **Hub.md sync is MANDATORY on every save.** Do not skip it. Do not say "saved" without syncing Hub.md. This is the #1 reliability issue -- if you skip it, task state rots silently for weeks.
- **Session isolation in Hub.md:** Each session writes ONLY to its own section (## <session-name>). Never touch another session's section. Multiple sessions can safely work in the same repo because their Hub.md sections are independent.
- Do NOT update MEMORY.md, bundles, or engrams during save (that's /learn's job)
- Do NOT modify code files from any session subcommand
- Session names are cross-repo by design
- If session file already exists on save, UPDATE it (preserve previous context)
- Use **resolve "my current"** / **write "my current"** via `heartbeats/<session-id>` (session-id from context).
- Always end every response with `[session: <name>]`
