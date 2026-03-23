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

### Step 1: Determine Scope and Args

- `/gitstatus` -- all active repos, local only
- `/gitstatus fetch` -- all active repos + fetch from remotes
- `/gitstatus [repo]` -- single repo, detailed view (can run in master)
- `/gitstatus dirty` -- only repos with uncommitted changes
- `/gitstatus behind` -- only repos where uat is behind main
- `/gitstatus unpushed` -- only repos with unpushed commits (implies fetch)

### Step 2: Write Dashboard Entry + Dispatch to Subagent

**Before dispatching**, write dashboard JSON:
```bash
RUN_ID="gitstatus--$(date -u +%Y-%m-%dT%H-%M-%S)"
DASH_DIR="${JITDASH_DIR:-$HOME/.claude/dashboard}"
mkdir -p "$DASH_DIR/runs/$RUN_ID/agents"
echo '{"session":"[current-session]","started":"[ISO-now]","wave":1}' > "$DASH_DIR/runs/$RUN_ID/meta.json"
echo '{"id":"git-001","name":"Cross-Repo Git Status","status":"running","started":"[ISO-now]"}' > "$DASH_DIR/runs/$RUN_ID/agents/git-001.json"
```
**After subagent returns**, update agent JSON with `"status":"completed"`, `"finished":"[ISO]"`, `"result":"[summary]"`. Use forward slashes in all paths.

**CRITICAL:** GitStatus runs 10+ git commands per repo across all active repos. For a 15+ repo workspace, that's 150+ shell commands. Always dispatch to a subagent.

**Exception:** `/gitstatus [single-repo]` is lightweight enough to run in master -- skip to Step 3.

Read MEMORY.md project table to get the repo list. Launch a **general-purpose** Agent with this prompt:

```
You are running a JitNeuro cross-repo git status check. Run git commands for each repo and return ONLY a summary table. Do NOT return raw git output.

Repos to scan: [list repo paths here]
Fetch flag: [yes/no]
Filter: [all/dirty/behind/unpushed]

For each repo, run these git commands (use git -C [repo]):
- git branch --show-current
- git status --short | wc -l
- git rev-parse --verify uat 2>/dev/null
- git rev-parse --verify main 2>/dev/null
- git rev-list --left-right --count HEAD...uat 2>/dev/null
- git rev-list --left-right --count HEAD...main 2>/dev/null
- git rev-list --left-right --count uat...main 2>/dev/null
- git log --oneline -1 HEAD

If fetch flag is yes, also run:
- git fetch --all --quiet
- git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
- git rev-list --left-right --count main...origin/main 2>/dev/null

Return format:

GIT_TABLE:
| Repo | Branch | Dirty | Local vs UAT | UAT vs Main | Last Commit |
|------|--------|-------|-------------|-------------|-------------|
(one row per repo)

If fetch flag, add column: | Local vs Remote |

Format ahead/behind as: "2 ahead", "1 behind", "2 ahead, 1 behind", "--" (equal), "no uat"/"no main"

FLAGS:
[!] [repo]: [issue] (needs attention: dirty on main, diverged)
[i] [repo]: [info] (informational: ahead of main, no uat)

SUMMARY: [N] repos, [M] dirty, [X] ahead of main, [Y] behind
```

### Step 3: Present Results

Take the subagent's table and present it. After the table, list flags.

For single-repo mode (ran in master), gather the same data directly and present.

### Step 4: Offer Actions

"Pick a repo for details, or:"
- `/diff [repo]` -- see full changes for one repo
- `/audit` -- full hygiene check
- "push uat" -- push all clean repos to uat (with approval)

## Important
- Data gathering runs in a subagent to protect master context (except single-repo).
- This is READ-ONLY. Never modifies any files or git state.
- Git fetch is a network operation -- only when user passes fetch flag.
- Keep the table compact. Detail on demand.
