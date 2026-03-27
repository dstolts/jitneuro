# Users Directory

Per-developer spaces, auto-created on first `/save` or `/learn`.

## Structure

```
users/
  <username>/           -- matches git config user.name
    active-work.md      -- current task, branch, blockers (auto by /save)
    lessons.md          -- /learn captures, team promotion staging
    rules/              -- personal repo-level rules (loaded for this user only)
    afk-log.md          -- autonomous execution tracking (auto by session)
```

## Privacy Model

- Everything in `users/` is committed to git (team-visible for review)
- Only YOUR `users/<name>/rules/` are loaded into YOUR Claude context
- Other users' rules are visible in git but not loaded for you
- Truly private state stays in `.claude/` (gitignored)

## Auto-Creation

The first time a user runs `/save` or `/learn` in a repo with `.jitneuro/`,
their `users/<username>/` folder is created automatically using `git config user.name`.
No manual setup required.
