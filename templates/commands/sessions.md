# Sessions

List, inspect, and manage all session checkpoints. Numbered output for quick selection.

## Commands

Trigger on these patterns (case-insensitive):
- `sessions` or `sessions list` -- numbered list of all sessions + NEEDS DAN summary (alias: `dashboard`)
- `sessions <number>` -- show full detail of session at that number
- `sessions show <name|number>` -- show full detail
- `sessions stale` -- list sessions >3 days old
- `sessions clean` -- delete stale sessions (confirms first)
- `sessions archive <name|number>` -- move to session-state/archive/
- `sessions delete <name|number>` -- delete (confirms first)
- `sessions dashboard` -- same as default (all-sessions aggregate view)
- `sessions status` -- same as default

Numbers are assigned by the most recent list output (sorted newest first).
Anywhere a `<name>` is accepted, a `<number>` from the last list works too.

## Instructions

### sessions list (default)

1. List all `.md` files in `.claude/session-state/` (exclude archive/, exclude _autosave.md)
2. Sort by checkpoint date (newest first)
3. For each file, read the first 15 lines to extract:
   - Checkpointed date
   - Current Task line
   - Repos Involved
4. Assign sequential numbers starting at 1
5. Mark the active session (from `.current`) with `*`
6. Display as numbered table:

```
Sessions (5 active):                              [* = current]
  #  Name                          Age    Task                              Repos
  1* auth-api-refactor             2h     Sprint-Auth-Refactor US-003       auth-api, jitai
  2  checkout-bug-fix              1d     Sprint-Checkout-001 testing       auth-api
  3  deploy-pipeline-update        1d     Deploy pipeline v2 rollout        data-pipeline
  4  dashboard-redesign            3d     Dashboard Phase 2 research        marketing-site
  5  mobile-onboarding             5d     Sprint-Mobile-001 spec            mobile-app
```

7. Read `.claude/bundles/active-work.md` for NEEDS DAN / BLOCKED items
8. Scan Hub.md files across active repos for additional blocked items
9. Append aggregate summary:

```
NEEDS DAN:
  - [BLOCKED] Sprint-Auth-Refactor: push to main approval needed
  - [APPROVAL] Sprint-Checkout-001: plan review
  - [DECISION] Blog platform: Ghost vs custom

Pick a number to show details, or: sessions archive|delete <#>
```

10. If stale sessions exist (>3 days), note:
    "2 sessions are stale (>3 days). Run `sessions stale` to review."
11. If no NEEDS DAN items: omit that section
12. MANDATORY -- end the response with a plain text prompt. Do NOT use AskUserQuestion. Just print this line at the very end:

```
Enter a session # to open, or: show|archive|delete <#>, stale, clean
```

The user's next message will be a number or command. Never skip this prompt.

### sessions show <name|number>

1. Resolve name (if number, use last list assignment)
2. Read full `.claude/session-state/<name>.md`
3. Display contents

### sessions stale

1. List only sessions with checkpoint date >3 days old
2. For each, show number, name, age, task, and last next-step
3. Suggest: "Run `sessions clean` to delete all stale, or `sessions delete <#>` for one."

### sessions clean

1. List all stale sessions (>3 days)
2. Show each number, name, and task
3. Ask confirmation: "Delete these N stale sessions? (yes/no)"
4. On yes, delete the files
5. If active session (`.current`) is being deleted, clear `.current`
6. Report what was deleted

### sessions archive <name|number>

1. Create `.claude/session-state/archive/` if needed
2. Move `<name>.md` to `archive/<name>.md`
3. If archived session was active (`.current`), clear `.current`
4. Confirm: "Archived <name>. Still readable at session-state/archive/<name>.md"

### sessions delete <name|number>

1. Read the session file, show task and last checkpoint date
2. Ask confirmation: "Delete session '<name>'? (yes/no)"
3. On yes, delete the file
4. If deleted session was active (`.current`), clear `.current`
5. Confirm: "Deleted <name>."

## Important
- Never delete without confirmation
- Archive is preferred over delete for completed work (preserves history)
- Stale threshold is 3 days -- adjustable per user preference
- This skill is read-only except for clean/archive/delete operations
- Number assignments are ephemeral -- they reset each time list runs
- When user provides just a number (e.g., `sessions 3`), treat as `sessions show 3`
- Active session marked with `*` in list output
- Always end every response with `[session: <name>]`
