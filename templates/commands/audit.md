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

### Step 2: Run Checks

For each repo, run these checks:

**Security:**
- [ ] .env files not tracked in git (`git ls-files | grep -i '\.env'`)
- [ ] No credentials in tracked files (grep for common patterns: password=, secret=, api_key=, token= in non-.env files)
- [ ] .gitignore exists and includes: .env*, node_modules/, .claude/settings.local.json
- [ ] .gitignore has exception for .env.example (`!.env.example`) so example configs can be tracked

**Git Hygiene:**
- [ ] No uncommitted changes on main/master
- [ ] No stale branches (branches with no commits in 30+ days)
- [ ] Remote is set and reachable
- [ ] Local is not behind remote

**DOE Compliance:**
- [ ] .claude/CLAUDE.md exists (project passport)
- [ ] Root CLAUDE.md exists (project identity)
- [ ] Engram exists in `.claude/engrams/` for this repo
- [ ] If TypeScript: tsconfig.json exists

**File Hygiene:**
- [ ] No build artifacts tracked (.next/, dist/, build/, coverage/)
- [ ] No large binary files tracked (>1MB)
- [ ] node_modules not tracked

### Step 3: Present Results

```
== Audit Report == [date]

| Repo | Security | Git | DOE | Files | Issues |
|------|----------|-----|-----|-------|--------|
| my-app | WARN | OK | OK | WARN | 2 |
| my-api | OK | WARN | OK | OK | 1 |
| my-tools | OK | OK | OK | OK | 0 |

Details:
  my-app:
    [WARN] Security: .next/ build artifacts tracked in git
    [WARN] Files: .next/ in git history (needs .gitignore update)
  my-api:
    [WARN] Git: 3 stale branches (>30 days): feature/old-thing, test/spike, hotfix/legacy

Total: 12 repos scanned, 3 issues found
```

Status values: OK, WARN, FAIL
- FAIL = security risk or broken state (needs immediate action)
- WARN = hygiene issue (should fix soon)
- OK = clean

### Step 4: Offer Fixes

For each issue, suggest a fix:
"Want me to fix any of these? Pick by number, or 'all safe' for non-destructive fixes."

Non-destructive fixes (safe to auto-apply):
- Add entries to .gitignore
- Create missing CLAUDE.md from template
- Create missing engram from template

Destructive fixes (ask first):
- Delete stale branches
- Remove tracked files that should be gitignored

## Important
- This is primarily READ-ONLY. Only modifies files with explicit approval.
- Security checks are best-effort pattern matching, not a full security audit.
- Skip repos that don't have a local clone (e.g., docs-only or archived).
- Run git commands with -C flag to avoid changing working directory.
- Large repos: limit file scanning to avoid long waits.
