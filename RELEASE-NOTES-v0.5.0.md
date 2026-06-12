# JitNeuro v0.5.0 Release Notes

**Release Date:** June 12, 2026
**Stability:** Stable
**Breaking Changes:** None
**Action Required:** YES -- re-run the installer to update the command/skill templates, and run `/knowledge` in any open session (see "How to update" below)

---

## Summary

v0.5.0 fixes a session-load bug that caused the statusline (and the session tag) to show `none`/`?` even after a successful `/load`, and clarifies where the session tag belongs and what `DIV` actually confirms.

The load procedure deferred its one mechanical step -- writing the heartbeat -- to the middle of the flow. When the owner appended a question to the load command (e.g. `/load my-session what's broken?`), the assistant treated the message as "answer the question," ran the answer, and never wrote the heartbeat. The session was effectively never loaded: the statusline had no name to read, and the session tag silently dropped.

**Who should update:** Everyone. The fix lives in the `load`, `session`, and the `load`/`session` skill templates.

---

## The bug

`/load <name>` delegates to `session load`, whose heartbeat write -- the single action the statusline reads -- sat at step 6, after several file reads. Two things then went wrong together:

1. **Buried mechanical step.** Any interruption between resolving the name and step 6 left the heartbeat unwritten.
2. **Appended-text trap.** When extra prose rode along with the command, the assistant prioritized the prose and skipped the load procedure entirely -- including the heartbeat write.

Result: `heartbeats/<session-id>` was never created, the statusline's lookup fell through to `?`/none, and the session tag had no name to print, so it was dropped for the whole session. It looked like a statusline failure; it was a load failure.

## The fix

The heartbeat write is now the **first, unconditional action** of any load:

- `templates/commands/load.md` -- new **step 0**: write the heartbeat before reading preferences or answering anything, with an explicit "appended-text trap" warning (appended text is an additional request, never a replacement for the load).
- `templates/commands/session.md` -- `session load` writes the heartbeat the instant the name resolves (step 1), not at step 6. Step 6 re-affirms it; the write is idempotent.
- `templates/skills/load/SKILL.md` and `templates/skills/session/SKILL.md` -- same reordering, so the skill surfaces match the command surfaces.

## Session tag clarification

The same release sharpens the session tag rule, because the bug exposed a conflation of two distinct displays:

- The **statusline** mechanically carries the session **name**, read from the heartbeat by the statusline script. It is configured once and updates itself.
- The **Stop tag** `[session: <name> | DIV: <MODE>]` is authored by the orchestrator at the **end of every response**. It is the per-turn confirmation that the orchestrator is **actively routing** -- consciously deciding, this turn, what mode applies. `DIV` is that routing confirmation, sourced from `toggles.json`; dropping the tag means routing was skipped.

New, binding clarification in both `session.md` and the session skill: **an empty heartbeat means a broken load, not a missing tag.** If the heartbeat is empty when a session should be active, fix the load (write the heartbeat) -- do not silently print `none` or drop the tag.

## How to recognize you are affected

If, after running `/load <name>` (especially with a question appended), you have seen:

- The statusline show `?` or no session name despite a "loaded" session
- The `[session: ... | DIV: ...]` tag missing from responses
- A session that behaves as though nothing was restored

then you are affected.

---

## How to update

1. Pull the latest JitNeuro (v0.5.0 or later).
2. Re-run the installer for your platform, in the same mode you originally used:
   - macOS / Linux / Git Bash: `bash install.sh`
   - Windows PowerShell: `pwsh -File install.ps1`
   The installer refreshes the `load`/`session` command and skill templates with the corrected procedure.
3. **For sessions already open:** the command/skill files are read at invocation time, so the next `/load` or `/session` call already uses the corrected flow -- nothing to restart. The session-tag clarification, however, is auto-loaded knowledge; run `/knowledge` in each open session to re-read it (or just start a new session).

---

## What changed in this release

- `templates/commands/load.md` -- step 0: write heartbeat first/unconditionally + appended-text trap.
- `templates/commands/session.md` -- `session load` writes heartbeat on name-resolve; session tag rule clarified (Stop output vs statusline; DIV = routing confirmation; empty heartbeat = broken load).
- `templates/skills/load/SKILL.md` -- heartbeat-first reordering + appended-text note.
- `templates/skills/session/SKILL.md` -- heartbeat-first reordering; session tag rule clarified.
- No changes to hooks, bundles, engrams, or any other JitNeuro feature.

## Notes

- Fix-only behavior change; no breaking changes and no new features.
- The statusline script itself was always correct -- it had nothing to read because the load never wrote the heartbeat.
