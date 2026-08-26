# JitNeuro v0.5.2 Release Notes

**Release Date:** June 13, 2026
**Stability:** Stable
**Breaking Changes:** None
**Action Required:** Re-run the installer to update the command/skill/rule templates; run `/knowledge` in any open session (see "How to update").

---

## Summary

v0.5.2 fixes the **new-session** form of the heartbeat bug that v0.5.1 fixed for **load**. Creating a session (via `/session new`, or auto-create on a fresh conversation) could skip writing the named heartbeat, so the statusline showed `none` and the session tag dropped -- exactly the symptom v0.5.1 addressed for `/load`, now closed on the creation path too.

---

## The bug

The named heartbeat write -- the single action the statusline reads -- was deferred:

- `/session new` wrote the heartbeat at **step 4**, after the save-prompt and after creating the session-state file. Any interruption before step 4, or an appended task riding along with the command, left the heartbeat unwritten.
- **Auto-create** (a fresh conversation with no `/load`) instructed "auto-create a new session" but never made the heartbeat write a *first* action -- so the assistant could jump straight to the user's first request and never write it.

Result: `heartbeats/<session-id>` was never created with the session name, the statusline fell through to `none`, and the session tag had no name to print. Same class as the v0.5.1 load bug, on the creation path.

## The fix

The named heartbeat write is now the **first action** on session establishment:

- `templates/commands/session.md` -- `/session new` writes the heartbeat the instant the name is known (new **step 3**), before creating the state file, with an explicit appended-text-trap warning. The old step-4 write is removed (now redundant).
- `templates/rules/session-guardrail.md` -- **auto-create** must write the named heartbeat as its FIRST action before answering anything, with the same trap warning.
- `templates/skills/session/SKILL.md` -- `/session new` heartbeat write reordered to first, with the trap warning.

## Why "first" matters

The named heartbeat is the only thing the statusline reads, and only the assistant can supply the name (it is derived from the task). A SessionStart hook can create the file but writes `none` for a new session -- it cannot know the name. So the assistant writing the name first, unconditionally, is the fix. Deferring it is what let it get skipped.

## How to recognize you are affected

After starting a NEW session (especially with a task appended to `/session new`, or just starting to chat), if you have seen:

- The statusline show `none` or no session name
- The `[session: ... | DIV: ...]` tag missing from responses

then you are affected.

---

## How to update

1. Pull the latest JitNeuro (v0.5.2 or later).
2. Re-run the installer in the same mode you originally used:
   - macOS / Linux / Git Bash: `bash install.sh`
   - Windows PowerShell: `pwsh -File install.ps1`
3. **For sessions already open:** command/skill/rule files are read at invocation time, so the next `/session new` already uses the corrected flow. Run `/knowledge` in each open session to re-read the session-guardrail change (or start a new session).

---

## What changed in this release

- `templates/commands/session.md` -- `/session new` heartbeat-first (step 3) + appended-text trap; redundant step-4 write removed.
- `templates/rules/session-guardrail.md` -- auto-create writes the named heartbeat first, before any other work.
- `templates/skills/session/SKILL.md` -- `/session new` heartbeat-first + trap warning.
- No changes to hooks, bundles, engrams, or any other JitNeuro feature.

## Notes

- Fix-only behavior change; no breaking changes, no new features.
- Sibling to v0.5.1 (load-side fix). Together they close the heartbeat-skip bug on both the load and create paths.
