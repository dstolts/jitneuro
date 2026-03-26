# Handoff: Add "Verify Before Presenting" to DOE Spec + JitNeuro Docs

**Created:** 2026-03-26
**Owner:** (project owner)
**For:** JitNeuro team
**Status:** Ready for execution

## Background

During the blog-style-review session (60+ hours, Jan-Mar 2026), a critical pattern failure was identified: Claude repeatedly asked Owner to "check" or "refresh" pages without verifying the output first. This wasted significant Owner time debugging work that should have been AI-verified before presentation.

The rule now exists as a private guardrail (`~/.claude/rules/verify-before-presenting.md`) but has NOT been added to the published DOE Framework Spec or the open-source JitNeuro docs. These two tasks close that gap so all adopters benefit.

## Rule Text (canonical)

```
# Verify Before Presenting

NEVER tell Owner to check, refresh, or look at something until you have verified it yourself first.

## Before presenting ANY work to Owner:
1. Make the change
2. Verify it works by checking the actual output yourself (fetch page, read image, test API, curl endpoint)
3. If verification fails, fix it and re-verify -- do NOT present broken work
4. If you can't verify (no access to the page/system), say so explicitly -- don't disguise it as "check this for me"
5. If you've failed 2+ times on the same issue, STOP and investigate root cause before trying again -- don't keep guessing

## Before scaling ANY change to multiple items:
1. Fix ONE item
2. Verify ONE item yourself
3. Present ONE item to Owner for approval
4. Only after Owner approves, scale to all

## When something breaks:
1. Investigate first -- read the actual code, CSS, theme, rendering pipeline
2. Understand WHY before attempting a fix
3. Never guess-and-push

Owner is not your debugger. Owner reviews finished work, not work-in-progress.
```

---

## Task 1: Add to DOE Framework Spec

**File:** `D:\Code\Automation\Projects\Orchestration\DOE-Framework-Spec-04.md`

**Where:** Section "WHAT CLAUDE.md BECOMES" -- quality standards list (around line 349).

**Insert after:** Item 3 ("Quality: ASCII only, fix root cause, test before commit, tsc --noEmit")

**What to add:** A new numbered item:
```
4. Verify before presenting: Never present work to Owner without self-verifying first. Fix ONE, verify ONE, present ONE, then scale.
```

Renumber subsequent items (current 4-6 become 5-7).

**Why here:** This section defines what every repo's CLAUDE.md should contain. Adding it here makes it a standard quality gate for all DOE-managed projects.

---

## Task 2: Add to JitNeuro Docs

Two insertion points:

### 2a. New doc: `docs/verify-before-presenting.md`

Create a new best-practices doc in `D:\Code\jitneuro\docs\`. No existing best-practices.md file exists, so this becomes the first standalone best-practice doc.

**Content:** Use the canonical rule text above, with these modifications for open-source:
- Replace any instance of "Dan" with "Owner" (per jitneuro contribution guidelines)
- Add a "## Origin" section explaining the pattern failure that motivated the rule
- Add a "## Integration" section explaining where to place this rule in a new adopter's setup (`~/.claude/rules/` or repo `.claude/CLAUDE.md`)

### 2b. Reference in `docs/holistic-review.md`

**File:** `D:\Code\jitneuro\docs\holistic-review.md`

**Where:** After the "## Output Format" header (line 85), before "### Preview Output (Pre-Execution)" (line 89).

**What to add:**
```
> **Gate 0 -- Verify Before Presenting:** Before showing ANY output to Owner,
> self-verify it works. See [verify-before-presenting.md](verify-before-presenting.md)
> for the full rule. This gate applies before both pre-execution and post-execution reviews.
```

**Why here:** The holistic review doc defines the quality gates. This rule is a pre-gate that applies before all others.

### 2c. Reference in `.claude/CLAUDE.md` Quality Standards

**File:** `D:\Code\jitneuro\.claude\CLAUDE.md`

**Where:** Quality Standards section (after line 23).

**What to add:**
```
- Verify before presenting (never show Owner unverified work -- see docs/verify-before-presenting.md)
```

---

## Naming Reminder

JitNeuro is open source. All content must use "Owner" -- never "Dan" or any personal name. Grep for "Dan" before committing.

---

## Acceptance Criteria

- [ ] DOE-Framework-Spec-04.md has "Verify before presenting" as a quality standard item
- [ ] `jitneuro/docs/verify-before-presenting.md` exists with full rule + origin + integration guidance
- [ ] `jitneuro/docs/holistic-review.md` references the new doc as Gate 0
- [ ] `jitneuro/.claude/CLAUDE.md` Quality Standards references the rule
- [ ] No instances of "Dan" in any modified jitneuro files
- [ ] PR created on feature branch (not main)
