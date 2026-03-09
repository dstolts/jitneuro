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
  firstmover-stripe-checkout    2h     Sprint-FirstMover-Checkout US-003 AIFS-API, jitai
  blog-comments-api             1d     Sprint-BlogComments-001 testing   AIFS-API
  jitneuro-deploy          1d     Deploy jitneuro to D:\Code   jitneuro
  aibm-dealer-research          3d     Dealer script Phase 2 research    Automation
  seo-automation-planning       5d     Sprint-SEO-Automation-001 spec    SEO
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
- Stale threshold is 3 days -- adjustable if Dan changes preference
- This skill is read-only except for clean/archive/delete operations
