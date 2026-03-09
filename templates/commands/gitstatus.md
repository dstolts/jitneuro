# GitStatus

Cross-repo git status showing the difference between local, uat, and main
for every active repo. One table, one glance, full picture.

## When to Use
- Start of day to see where everything stands
- Before a cross-repo sprint to verify clean baselines
- After a long session touching multiple repos
- When the user asks "I don't know what's where"

## Instructions

When invoked as `/gitstatus`:

### Step 1: Get Repo List

Read MEMORY.md project table. Collect all repos with status "Active Dev", "Active",
or "Prod". Skip "Maintenance" and "Active Docs" unless user asks for them.

If MEMORY.md is not available, dynamically discover repos by scanning the workspace
root directory for subdirectories containing a `.git` folder. Example:

```bash
# Find all git repos under the workspace root
for dir in /path/to/workspace/*/; do
  if [ -d "$dir/.git" ]; then
    echo "$dir"
  fi
done
```

### Step 2: For Each Repo, Gather Git State

Run these commands (use git -C to avoid cd):

```bash
# Current branch
git -C [repo] branch --show-current

# Dirty files count
git -C [repo] status --short | wc -l

# Check if branches exist
git -C [repo] rev-parse --verify uat 2>/dev/null
git -C [repo] rev-parse --verify main 2>/dev/null
git -C [repo] rev-parse --verify master 2>/dev/null

# Commits ahead/behind between branches (if they exist)
# local branch vs uat
git -C [repo] rev-list --left-right --count HEAD...uat 2>/dev/null

# local branch vs main (or master)
git -C [repo] rev-list --left-right --count HEAD...main 2>/dev/null

# uat vs main
git -C [repo] rev-list --left-right --count uat...main 2>/dev/null

# Last commit on each branch
git -C [repo] log --oneline -1 HEAD
git -C [repo] log --oneline -1 uat 2>/dev/null
git -C [repo] log --oneline -1 main 2>/dev/null

# Remote/upstream comparison (only with --fetch or /gitstatus fetch)
git -C [repo] remote -v  # check if remote exists
git -C [repo] fetch --all --quiet  # only if fetch flag is set
git -C [repo] rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
git -C [repo] rev-list --left-right --count main...origin/main 2>/dev/null
git -C [repo] rev-list --left-right --count uat...origin/uat 2>/dev/null
```

### Step 3: Present Cross-Repo Table

```
== Git Status Across Repos == [date]

| Repo | Branch | Dirty | Local vs UAT | UAT vs Main | Last Commit |
|------|--------|-------|-------------|-------------|-------------|
| my-app | uat | 3 | -- | 5 ahead | abc1234 feat: comments |
| my-api | sprint-blog | 0 | 2 ahead | 3 ahead | def5678 fix: auth |
| my-tools | master | 5 | no uat | -- | ghi9012 docs: hooks |
| my-site | main | 1 | no uat | -- | jkl3456 add: feature |
| my-auth | main | 0 | no uat | -- | mno7890 v1.0.1 |
| ... | | | | | |

With `fetch` flag, add upstream columns:
| Repo | Branch | Dirty | Local vs UAT | UAT vs Main | Local vs Remote | Last Commit |
|------|--------|-------|-------------|-------------|-----------------|-------------|
| my-app | uat | 3 | -- | 5 ahead | 2 ahead | abc1234 feat: comments |
| my-api | sprint-blog | 0 | 2 ahead | 3 ahead | in sync | def5678 fix: auth |
| my-tools | master | 5 | no uat | -- | no remote | ghi9012 docs: hooks |
```

Column meanings:
- **Branch**: current checked-out branch
- **Dirty**: number of uncommitted changes
- **Local vs UAT**: commits ahead/behind between current branch and uat
- **UAT vs Main**: commits ahead/behind between uat and main
- **Last Commit**: most recent commit on current branch (short hash + message)

Format ahead/behind as:
- "2 ahead" = local has 2 commits not in target
- "1 behind" = target has 1 commit not in local
- "2 ahead, 1 behind" = diverged
- "--" = same branch or branches are equal
- "no uat" / "no main" = branch doesn't exist

### Step 4: Flag Issues

After the table, list any concerns:

```
Flags:
  [!] my-app: 3 dirty files on uat (should commit or stash)
  [!] my-site: 1 dirty file on main (should be on feature branch)
  [i] my-api: uat is 3 ahead of main (push to main when ready)
  [i] my-tools: no uat branch (single-branch repo, OK)
```

Flag types:
- [!] = needs attention (dirty on main, diverged branches)
- [i] = informational (ahead of main, no uat)

### Step 5: Offer Actions

"Pick a repo for details, or:"
- `/diff [repo]` -- see full changes for one repo
- `/audit` -- full hygiene check
- "push uat" -- I can push all clean repos to uat (with approval)

## Arguments

- `/gitstatus` -- all active repos, local branches only (no network)
- `/gitstatus fetch` -- all active repos + fetch from remotes (shows local vs remote)
- `/gitstatus [repo]` -- single repo, detailed view with full branch comparison
- `/gitstatus dirty` -- only repos with uncommitted changes
- `/gitstatus behind` -- only repos where uat is behind main
- `/gitstatus unpushed` -- only repos with commits not pushed to remote (implies fetch)

## Important
- This is READ-ONLY. Never modifies any files or git state.
- Run git commands in parallel where possible for speed.
- If a repo directory doesn't exist, skip it with a note.
- If git fetch is needed for accurate remote comparison, ask first (network operation).
- Keep the table compact. Detail on demand.
- This replaces the need to cd into each repo and run git status manually.
