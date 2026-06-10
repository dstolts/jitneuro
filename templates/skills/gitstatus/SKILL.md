---
type: skill
purpose: Cross-repo git comparison showing local vs uat vs main status, dirty files, and ahead/behind counts.
tags: [git, gitstatus, cross-repo, status, subagent]
scope: public
departments: [engineering]
status: canonical
read_when: When checking git status across multiple repos to identify dirty, ahead, or behind states before a cross-repo sprint or sync.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /gitstatus

Cross-repo git status comparison. Dispatches a subagent for multi-repo analysis.

## Operations

### Default: all repos
Scan all repos listed in workspace MEMORY.md or engrams for git status.

### Filtered mode
- `dirty` -- show only repos with uncommitted changes
- `behind` -- show only repos where local is behind remote
- `unpushed` -- show only repos with commits not yet pushed

## Per-repo checks

For each repo:
1. `git status --short` -- uncommitted changes
2. `git rev-list --left-right --count origin/main...HEAD` -- commits ahead/behind main
3. `git rev-list --left-right --count origin/uat...HEAD` -- commits ahead/behind uat (if uat exists)
4. Current branch name
5. Last commit message + timestamp

## Output format

```
REPO STATUS (N repos checked)

[repo-name] [branch]
  Local: X uncommitted changes
  vs main: +A ahead / -B behind
  vs uat:  +C ahead / -D behind
  Last: "commit message" (2h ago)
```

Clean repos: shown in summary line only.

## Dispatch pattern

For >5 repos, dispatch a subagent to do the git checks. Returns STATUS: OK with table.
For <=5 repos, run inline.
