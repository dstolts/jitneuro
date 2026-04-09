# Users Directory

Per-developer spaces, auto-created on first `/save` or `/learn`.

## Structure

```
users/
  <username>/               -- matches git config user.name
    <label>/                -- per-context folder (machine, worktree, environment)
      active-work.md        -- what this context is doing now (auto by /save)
      afk-log.md            -- AFK sessions in this context (auto by session)
    lessons.md              -- shared across all contexts (user-level)
    rules/                  -- personal repo-level rules (loaded for this user only)
```

### What is `<label>`?

The `<label>` subfolder comes from the `machineName` field in `.claude/jitneuro.json`
(personal config, gitignored). It is a **user-chosen label** -- not necessarily a
hostname. It can represent any workspace context the user wants to keep separate.

Examples:
- **Machine names:** `office-pc`, `home-laptop`, `server-01`
- **Git worktree names:** `worktree-main`, `worktree-feature-x` (multiple worktrees on the same machine)
- **Environment names:** `docker-dev`, `wsl-ubuntu`, `codespace-1`

This design lets a single user run multiple Claude Code sessions on one machine
(e.g., one per git worktree) with each session tracking its own active-work and
AFK state independently, while lessons remain shared at the user level.

## Privacy Model

- Everything in `users/` is committed to git (team-visible for review)
- Only YOUR `users/<name>/rules/` are loaded into YOUR Claude context
- Other users' rules are visible in git but not loaded for you
- Truly private state stays in `.claude/` (gitignored)

## Auto-Creation

The first time a user runs `/save` or `/learn` in a repo with `.jitneuro/`,
their `users/<username>/` folder is created automatically using `git config user.name`.
No manual setup required.
