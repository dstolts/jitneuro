---
type: skill
purpose: Scan repos for hygiene issues including .env leaks, stale branches, git hygiene, DOE compliance, and file hygiene.
tags: [audit, hygiene, git, env-leaks, doe-compliance, subagent]
scope: public
departments: [engineering]
status: canonical
read_when: When running the /audit command against a repo to scan for hygiene issues, env leaks, stale branches, or DOE compliance gaps.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /audit [repo]

Scan a repo for hygiene issues. Dispatches a subagent to inspect and report.

## Steps

**Step 1: Parse arguments**
- If `[repo]` is provided, resolve the path
- If not provided, use the current repo (git root)

**Step 2: Dispatch subagent**

Prompt the subagent to inspect the repo for:

1. **.env leaks** -- any .env, .env.local, .env.production files NOT in .gitignore; any committed files containing API_KEY=, SECRET=, PASSWORD=, TOKEN= patterns
2. **Stale branches** -- local branches with no commits in 30+ days; remote branches merged but not deleted
3. **Git hygiene** -- large files (>5MB) committed; binary files tracked; node_modules or build artifacts tracked
4. **DOE compliance** -- missing CLAUDE.md at repo root; missing .claude/ folder; missing engram in workspace .knowledge/engrams/
5. **File hygiene** -- TODO/FIXME comments in production code; console.log in production code; hardcoded localhost URLs; unused imports (TypeScript)

**Step 3: Present report**

Format findings by severity:
- CRITICAL: .env committed, API keys exposed
- HIGH: missing DOE compliance files, large binary tracked
- MEDIUM: stale branches, missing gitignore entries
- LOW: code hygiene issues, TODO comments

**Step 4: Offer remediation**

For each finding, offer the specific command or action to fix it. Never auto-remediate without user confirmation.

## Return format

```
AUDIT COMPLETE: [repo-name]
Critical: N | High: N | Medium: N | Low: N

[findings list]
```
