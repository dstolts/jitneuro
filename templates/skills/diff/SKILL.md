---
type: skill
purpose: Show git diff since last push or main divergence for the current or specified repo.
tags: [git, diff, code-review, read-only]
scope: public
status: canonical
graduation_target: skills/diff/SKILL.md
read_when: When reviewing what changed in a repo since the last push or main divergence before a PR or code review.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /diff [repo]

Show what changed since last push or main divergence. READ-ONLY operation.

## Steps

**Step 1: Resolve repo**
- If `[repo]` provided: cd to that repo path
- Otherwise: use current git root

**Step 2: Detect comparison base**

Try in order:
1. `git diff @{push}` -- changes since last push to remote
2. `git diff origin/main...HEAD` -- changes from main divergence
3. `git diff HEAD~1` -- fallback: last commit

**Step 3: Display diff**

Show:
- Files changed (count + list)
- Additions / deletions summary
- Full diff content (or truncated if >200 lines with offer to show more)

**Step 4: Surface observations**

After showing the diff, note:
- Any files that appear unintentionally changed
- Large diffs that might warrant splitting into multiple PRs
- Test files vs source files ratio

## Format

```
DIFF: [repo-name] vs [base]
Files: N changed (+A/-D lines)

[diff output]
```

## What this does NOT do

Does not modify any files. Does not create PRs. Read-only diagnostic.
