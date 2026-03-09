# Diff

Show what changed in a repo since last push or since diverging from main.
Formatted for quick review before push or PR.

## When to Use
- Before pushing to verify what's going out
- Before creating a PR to review changes
- To understand what a feature branch contains
- When Dan asks "what did we change"

## Instructions

When invoked as `/diff` or `/diff <repo>`:

### Step 1: Determine Repo

- If repo name provided: use D:\Code\[repo]
- If no repo: use current working directory
- If working directory is D:\Code (workspace root): ask which repo

### Step 2: Gather Diff Information

Run these git commands:

```bash
# Current branch
git -C [repo] branch --show-current

# What's the base branch (usually main or master)
git -C [repo] symbolic-ref refs/remotes/origin/HEAD 2>/dev/null

# Uncommitted changes (staged + unstaged)
git -C [repo] status --short

# All commits since diverging from base
git -C [repo] log --oneline [base]..HEAD

# Full diff since base (stat summary)
git -C [repo] diff --stat [base]..HEAD

# Unpushed commits (local vs remote)
git -C [repo] log --oneline @{upstream}..HEAD 2>/dev/null
```

### Step 3: Present Summary

```
== Diff: [repo] ==
Branch: [branch] (from [base])
Commits: [N] since [base] ([M] unpushed)

Files changed: [count]
  [stat summary -- insertions, deletions per file]

Uncommitted:
  [M] modified: [file]
  [A] added: [file]
  [D] deleted: [file]

Commit log:
  abc1234 feat: add comment endpoints
  def5678 fix: auth token refresh
  ghi9012 refactor: extract blog service
```

### Step 4: Offer Actions

After presenting the diff:
- "Ready to push?" (if unpushed commits exist)
- "Want to see the full diff for any file?"
- "Create a PR?"

## Important
- This is READ-ONLY. Never modifies any files or git state.
- If base branch detection fails, default to main.
- If repo has no remote, skip unpushed check.
- Keep file-level diff summary (--stat), not full patch (too verbose).
- Full patch only on request for specific files.
