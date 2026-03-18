# Session State Directory

One file per named session. Sessions are cross-repo by design.

## Per-session "current" (v0.1.4+)

- **`.session-id`** — Written by SessionStart hook (Claude Code). Contains this conversation's session ID. When present, "current" is resolved from `.current.d/<id>` so multiple chats can each have their own current session.
- **`.current`** — Legacy: one line = active session name. Fallback when `.session-id` is missing (e.g. Cursor).
- **`.current.d/<id>`** — One file per conversation; content = session name. Created when save/load/new/switch/rename run with `.session-id` set.

Commands and the Cursor rule resolve "my current" by: if `.session-id` exists, read `.current.d/<id>`; else read `.current`. They write to both when updating current.

## Usage
- `/save <name>` creates or updates `<name>.md`
- `/load <name>` loads from `<name>.md`
- `/load` with no name lists all available sessions

## Naming
Name describes the TASK, not the repo:
- Good: `project-a-stripe-checkout`, `blog-comments-api`, `research-phase-2`
- Bad: `my-app`, `session1`, `work`

## Lifecycle
- Created by /save
- Read by /load
- Stale after 7 days (flagged on resume, not auto-deleted)
- Delete manually when a task is fully complete
