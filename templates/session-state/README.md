# Session State Directory

One file per named session. Sessions are cross-repo by design.

## Usage
- `/checkpoint <name>` creates or updates `<name>.md`
- `/resume <name>` loads from `<name>.md`
- `/resume` with no name lists all available sessions

## Naming
Name describes the TASK, not the repo:
- Good: `firstmover-stripe-checkout`, `blog-comments-api`, `aibm-dealer-research`
- Bad: `jitai`, `session1`, `work`

## Lifecycle
- Created by /checkpoint
- Read by /resume
- Stale after 3 days (flagged on resume, not auto-deleted)
- Delete manually when a task is fully complete
