# Status

Quick "where am I" snapshot across repos. Answers the most common question
after a break: what was I working on, what's dirty, what branch am I on.

## When to Use
- Start of a session to orient yourself
- After switching between repos or tasks
- Before /save to see what needs checkpointing
- When Dan asks "where was I"

## Instructions

When invoked as `/status`:

### Step 1: Check Active Session State

Read `.claude/session-state/` directory. List any sessions modified in the last 24 hours.
If a recent session exists, note its task and repos.

### Step 2: Check Active Work Bundle

Read `.claude/bundles/active-work.md` for current sprint status and NEEDS DAN items.

### Step 3: Scan Repos for Dirty State

For each repo listed in the active session state (or MEMORY.md project table if no session):
- Run `git -C [repo_path] status --short` to check for uncommitted changes
- Run `git -C [repo_path] branch --show-current` to get current branch
- Run `git -C [repo_path] log --oneline -1` to get last commit

Only check repos that are marked "Active Dev" or "Active" in MEMORY.md.
Skip repos marked "Maintenance" or "Active Docs" unless they appear in a recent session.

### Step 4: Present Summary

```
== Status ==

Last session: [name] ([time ago])
Task: [current task from session state]

| Repo | Branch | Dirty | Last Commit |
|------|--------|-------|-------------|
| jitai | uat | 3 files | abc1234 fix: blog comments |
| AIFieldSupport-API | sprint-blog-001 | clean | def5678 feat: comment endpoints |
| jitneuro | master | 5 files | ghi9012 docs: hook templates |

Active sprint: [from active-work bundle]
NEEDS DAN: [count] items (run /dashboard for full list)
```

### Step 5: Flag Issues

- Repos on main/master with dirty files (should be on feature branch)
- Repos with unpushed commits
- Repos where local branch is behind remote

## Important
- This is READ-ONLY. Never modifies any files.
- Keep it fast -- only check repos likely to be active.
- If no session state exists, fall back to MEMORY.md project table.
- Show max 10 repos. If more are dirty, summarize as "and N more".
