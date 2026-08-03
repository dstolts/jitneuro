---
type: skill
purpose: Full session lifecycle management (new, save, load, pulse, switch, rename, close, and dashboard) for any master agent; skipping means sessions lack heartbeat tracking, Hub.md sync, and scheduled-agent spawning.
read_when: When creating, restoring, switching, or managing the lifecycle of any session checkpoint.
tags: [session, session-management, heartbeat, hub, checkpoint, lifecycle]
scope: public
departments: [all]
status: canonical
graduation_target: skills/session/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /session

Full session lifecycle management.

## Operations

### `/session new [name]`
Create a new session:
1. Generate session name from task if not provided
2. Write heartbeat: `echo -n "<name>" > heartbeats/$CLAUDE_SESSION_ID` (Bash, not Write tool)
3. Create `.sessions/<name>.md` with header
4. Create or update Hub.md entry
5. Spawn scheduled agents from jitneuro.json (enabled: true)
6. Display: `[session: <name> | DIV: AUTO]`

### `/session save [name]`
Checkpoint current state:
1. Write TodoWrite task list to Hub.md `## ACTIVE TODO` section (MANDATORY)
2. Write pending questions to Hub.md `## PENDING QUESTIONS` section
3. Write full checkpoint to `.sessions/<name>.md`
4. Update heartbeat timestamp
5. Display: `** Saved: <name> **`

### `/session load [name|#]`
Restore from checkpoint:
1. List available sessions if no name/# provided
2. Read checkpoint file
3. Restore TodoWrite task list
4. Set heartbeat (Bash echo)
5. Spawn scheduled agents if not running
6. Display session summary + next actions

### `/session pulse`
Re-read shared state:
1. Read Hub.md for updates from other sessions
2. Check for new NEEDS OWNER items
3. Update in-memory task list if changed
4. Display: `** Pulse: [changes found / no changes] **`

### `/session switch <name>`
Switch to a different active session:
1. Save current session (implicit save)
2. Load the target session

### `/session rename <newname>`
Rename current session:
1. Update heartbeat file
2. Rename checkpoint file
3. Update Hub.md reference

### `/session close`
Close session (requires explicit Owner permission):
1. Final save
2. Archive checkpoint to `.archive/` in session-state
3. Remove heartbeat file

### `/session dashboard`
Show blockers and NEEDS OWNER items for current session.

## Session tag rule

Every response ends with: `[session: <name> | DIV: <MODE>]`

- Get `<name>` from your OWN heartbeat file ONLY (one read, one file)
- Get `<MODE>` from toggles.json (AUTO / ALWAYS / NEVER)
- Add `| STRATEGY` when strategy mode is active

## Hub.md sync is MANDATORY on save

Saving to session-state without syncing TodoWrite to Hub.md = incomplete save. Hub.md is the durable copy; session-state is the detailed copy. Both must be current.
