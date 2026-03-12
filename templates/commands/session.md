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
- `session dashboard` -- current session blockers and NEEDS DAN items

Numbers reference the last `/sessions` list output.

## Current Session Tracking

The active session name is stored in `.claude/session-state/.current` (one line, just the name).
Updated by: `new`, `save`, `load`, `switch`, `rename`.
Read by: default view, `pulse`, `dashboard`, and the session tag rule.

## Session Tag Rule

**Every response must end with `[session: <name>]`** where `<name>` comes from `.current`.
If no active session: `[session: none]`.
This is non-negotiable -- it prevents context confusion across terminals.

## Shortcut Preference

Read `.claude/session-state/.preferences` for `shortcut_scope` setting.
- `session` (default): `/status`, `/dashboard`, `/save`, `/load`, `/pulse` -> `/session` subcommands
- `sessions`: `/status`, `/dashboard` -> `/sessions` subcommands (save/load/pulse always stay `/session`)

If `.preferences` doesn't exist, default to `session` scope.

## Instructions

### session (default) -- current session status

1. Read `.claude/session-state/.current` to get active session name
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

7. Flag issues: repos on main with dirty files, unpushed commits, behind remote

### session new <name>

1. Check `.current` for active session
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

   ## Current Task
   New session -- no task assigned yet.

   ## Repos Involved
   - (none yet)

   ## Key Decisions
   - (none yet)

   ## Next Steps
   - Awaiting direction
   ```
4. Write session name to `.current`
5. Confirm: "Session '<name>' created."

### session save <name>

1. **Determine session name:**
   - If name provided, use it (lowercase, hyphens, task-descriptive)
   - If no name: read `.current`. If active session, use that name.
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
   ```markdown
   # Session: <name>
   **Checkpointed:** [current date/time]

   ## Current Task
   [task name and brief status]

   ## Repos Involved
   - [repo path] -- [what's happening here]

   ## Active Bundles
   - [bundle1.md] -- [why it's loaded]

   ## Modified Files
   - [repo/file:line] -- [what changed]

   ## Key Decisions
   - [decision and reasoning]

   ## Pending / Unresolved
   - [items awaiting input or follow-up]

   ## Next Steps
   1. [immediate next action]
   2. [following action]

   ## Key Findings
   - [discoveries worth preserving across /clear]
   ```

4. Write session name to `.current`
5. Confirm: "Saved '<name>'. Safe to /clear. Use `/session load <name>` to reload."
6. Suggest: "Run `/learn` first if this session had learnings worth persisting."

**Size guidance:** Target 30-60 lines. Under 30 probably missing something. Over 80 too verbose.

### session load <name|#>

1. **Determine which session:**
   - If name/number provided: resolve to session file
   - If no name: read `.current`. If exists, load that.
   - If no name and no `.current`: list sessions, ask user to pick
   - If number: resolve from last `/sessions` list output

2. **Read the session state file**

3. **Read active bundles** listed in session state (only those listed)

4. **Read `.claude/context-manifest.md`** for bundle awareness

5. **Write session name to `.current`**

6. **Report:**
   ```
   Loaded: <name> (checkpointed <date>)
   Task: [current task]
   Repos: [list]
   Loaded bundles: [list]
   Next steps:
   1. [from session state]
   ```

7. If session is stale (>3 days), mention it and ask if still relevant

### session pulse

1. Read `.current` to identify active session
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
4. Update `.current` to new session name

### session rename <new-name>

1. Read `.current` to get active session name
2. If no active session: "No active session to rename."
3. Rename `.claude/session-state/<old-name>.md` to `<new-name>.md`
4. Update `.current` to new name
5. Update the `# Session:` header inside the file
6. Confirm: "Renamed '<old>' -> '<new>'."

### session dashboard

1. Read `.current` to get active session
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

## Important
- Do NOT update MEMORY.md, bundles, or engrams during save (that's /learn's job)
- Do NOT modify code files from any session subcommand
- Session names are cross-repo by design
- If session file already exists on save, UPDATE it (preserve previous context)
- `.current` is the single source of truth for active session
- Always end every response with `[session: <name>]`
