# Session State Directory

One file per named session. Sessions are cross-repo by design.

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
- Stale after 3 days (flagged on resume, not auto-deleted)
- Delete manually when a task is fully complete
