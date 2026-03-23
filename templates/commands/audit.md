# Audit

Scan repos for hygiene issues: .env exposure, stale branches, uncommitted work,
missing CLAUDE.md, missing engrams, broken .gitignore. Security + hygiene in one pass.

## When to Use
- Periodic maintenance (weekly recommended)
- Before a push or release
- After onboarding a new repo
- When something feels off (files showing up that shouldn't be tracked)

## Instructions

When invoked as `/audit`:

### Step 1: Determine Scope

Check if arguments were provided:
- `/audit` -- scan all active repos from MEMORY.md project table
- `/audit [repo]` -- scan specific repo only

### Step 2: Write Dashboard Entry + Dispatch to Subagent

**Before dispatching**, write dashboard JSON (run appears on dashboard immediately):
```bash
RUN_ID="audit--$(date -u +%Y-%m-%dT%H-%M-%S)"
DASH_DIR="${JITDASH_DIR:-$HOME/.claude/dashboard}"
mkdir -p "$DASH_DIR/runs/$RUN_ID/agents"
echo '{"session":"[current-session]","started":"[ISO-now]","wave":1}' > "$DASH_DIR/runs/$RUN_ID/meta.json"
echo '{"id":"audit-001","name":"Repo Audit","status":"running","started":"[ISO-now]"}' > "$DASH_DIR/runs/$RUN_ID/agents/audit-001.json"
```
**After subagent returns**, update agent JSON with `"status":"completed"`, `"finished":"[ISO]"`, `"result":"[summary]"`. Use forward slashes in all paths.

**CRITICAL:** Audit reads files and runs git commands across many repos. For a workspace with 15+ repos, this is 50+ file reads and 30+ shell commands. Always dispatch data gathering to a subagent to protect master context from memory exhaustion.

For `/audit [single-repo]`: Still use a subagent (runs ~10 checks with file reads + git commands).

Launch a **general-purpose** Agent with this prompt (fill in repo list from MEMORY.md or the single repo argument):

```
You are running a JitNeuro audit. Scan the following repos and return ONLY a summary table. Do NOT return file contents.

Repos to scan: [list repo paths here]

For each repo, run these checks:

**Security:**
- .env files not tracked in git: git -C [repo] ls-files | grep -i '\.env'
- No credentials in tracked files: grep for password=, secret=, api_key=, token= in non-.env tracked files
- .gitignore exists and includes: .env*, node_modules/, .claude/settings.local.json
- .gitignore has !.env.example exception

**Git Hygiene:**
- No uncommitted changes on main/master
- No stale branches (no commits in 30+ days): git -C [repo] for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/
- Remote is set and reachable
- Local is not behind remote (fetch first if needed)

**DOE Compliance:**
- .claude/CLAUDE.md exists
- Root CLAUDE.md exists
- Engram exists in .claude/engrams/ for this repo name

**File Hygiene:**
- No build artifacts tracked (.next/, dist/, build/, coverage/)
- No large binary files tracked (>1MB)
- node_modules not tracked

Return format:

AUDIT_TABLE:
| Repo | Security | Git | DOE | Files | Issues |
|------|----------|-----|-----|-------|--------|
(one row per repo, status: OK/WARN/FAIL)

DETAILS:
[repo]: [WARN/FAIL] [category]: [specific issue]
(one line per issue, no extra text)

SUMMARY: [N] repos scanned, [M] issues found ([X] FAIL, [Y] WARN)
```

### Step 3: Present Results

Take the subagent's returned table and present it to the user. Include:
- The full audit table
- Issue details grouped by severity (FAIL first, then WARN)
- Summary line

Status values: OK, WARN, FAIL
- FAIL = security risk or broken state (needs immediate action)
- WARN = hygiene issue (should fix soon)
- OK = clean

### Step 4: Offer Fixes

For each issue, suggest a fix:
"Want me to fix any of these? Pick by number, or 'all safe' for non-destructive fixes."

Fixes run in the MASTER context (targeted edits, not bulk reads).

Non-destructive fixes (safe to auto-apply):
- Add entries to .gitignore
- Create missing CLAUDE.md from template
- Create missing engram from template

Destructive fixes (ask first):
- Delete stale branches
- Remove tracked files that should be gitignored

## Important
- Data gathering runs in a subagent to protect master context.
- Fixes run in master (small, targeted operations).
- Security checks are best-effort pattern matching, not a full security audit.
- Skip repos that don't have a local clone.
- Run git commands with -C flag to avoid changing working directory.
