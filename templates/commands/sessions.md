# Sessions

List, inspect, and manage checkpoint sessions.

## Commands

Trigger on these patterns (case-insensitive):
- `sessions` or `sessions list` -- list all sessions
- `sessions show <name>` -- show full detail of one session
- `sessions stale` -- list sessions older than 3 days
- `sessions clean` -- delete stale sessions (asks confirmation first)
- `sessions archive <name>` -- move to session-state/archive/
- `sessions delete <name>` -- delete a session (asks confirmation first)

## Instructions

### sessions list (default)

1. List all `.md` files in `.claude/session-state/` (exclude archive/ subdirectory)
2. For each file, read the first 10 lines to extract:
   - Checkpointed date
   - Current Task line
   - Repos Involved
3. Display as table:

```
Sessions (5 active):
  Name                          Age    Task                              Repos
  auth-api-refactor             2h     Sprint-Auth-Refactor US-003        auth-api, checkout-frontend
  checkout-bug-fix              1d     Sprint-Checkout-001 testing       auth-api
  deploy-pipeline-update        1d     Deploy pipeline v2 rollout        data-pipeline
  dashboard-redesign            3d     Dashboard Phase 2 research        marketing-site
  mobile-onboarding             5d     Sprint-Mobile-001 spec            mobile-app
```

4. If stale sessions exist (>3 days), note at bottom:
   "2 sessions are stale (>3 days). Run `sessions stale` to review."

### sessions show <name>

1. Read full `.claude/session-state/<name>.md`
2. Display contents

### sessions stale

1. List only sessions with checkpoint date >3 days old
2. For each, show name, age, task, and last next-step
3. Suggest: "Run `sessions clean` to delete all stale, or `sessions delete <name>` for one."

### sessions clean

1. List all stale sessions (>3 days)
2. Show each name and task
3. Ask confirmation: "Delete these N stale sessions? (yes/no)"
4. On yes, delete the files
5. Report what was deleted

### sessions archive <name>

1. Create `.claude/session-state/archive/` if it doesn't exist
2. Move `<name>.md` to `archive/<name>.md`
3. Confirm: "Archived <name>. Still readable at session-state/archive/<name>.md"

### sessions delete <name>

1. Read the session file, show task and last checkpoint date
2. Ask confirmation: "Delete session '<name>'? (yes/no)"
3. On yes, delete the file
4. Confirm: "Deleted <name>."

## Important
- Never delete without confirmation
- Archive is preferred over delete for completed work (preserves history)
- Stale threshold is 3 days -- adjustable per user preference
- This skill is read-only except for clean/archive/delete operations
