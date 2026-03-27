# Learn

Evaluate the current session for knowledge worth persisting to long-term memory.
This is JitNeuro's backpropagation -- the system improves itself over time.

## Arguments
- `/learn` -- full evaluation (health check + session learnings + team queue if TeamApprover)
- `/learn q` -- quick mode: skip health check, focus on learnings only (session scan + Hub.md check still run)
- `/learn --team` -- team-only: skip personal learnings, show team lessons queue + team health (TeamApprover only)

Quick mode skips: stale session flags, archive/delete recommendations, session count warnings, team queue. Use when you know sessions are fine and just want to capture learnings fast.

## When to Use
- Before ending a session (especially productive ones)
- Before `/save` if the session produced new insights
- After a correction ("that's wrong" / "not how it works")
- After discovering something new about a project's architecture
- At sprint boundaries when conventions or patterns changed

## What It Evaluates

The /learn command scans the current session for 5 categories:

### 1. Routing Weight Updates (MEMORY.md)
Did Claude load the wrong bundle? Did the user have to manually specify context?
- "I had to tell Claude to read the deploy bundle" -> add trigger word
- New task pattern emerged that doesn't map to any bundle -> add routing entry

### 2. Bundle Updates (.claude/bundles/)
Is any bundle stale, missing information, or too large?
- New convention established this session -> add to relevant bundle
- Bundle was loaded but didn't have what Claude needed -> update content
- Bundle over 280 lines -> suggest split

### 3. Engram Updates (.claude/engrams/)
Did the session reveal new facts about a project's identity or architecture?
- New key file discovered (route, config, migration)
- Tech stack change (new dependency, version bump, new service)
- Architecture pattern changed (new microservice, renamed routes)
- Integration added or removed

Why "engrams": In neuroscience, an engram is the physical trace a memory leaves
in the brain -- the compressed representation of an experience. Each project's
context file is exactly that: not the codebase itself, but the compressed knowledge
about it, strengthened each time /learn updates it.

### 4. New Knowledge (MEMORY.md or new bundle)
Did the session produce cross-project facts that belong in long-term memory?
- New integration between repos
- Infrastructure change (new VM, new port, new service)
- Business decision that affects multiple projects

### 5. Corrections
Did the user correct Claude on something it stated from memory?
- Wrong fact in MEMORY.md -> fix at source
- Outdated info in a bundle -> update
- Missing project in engrams -> create

## Instructions

When invoked as `/learn`:

### Phase 1: Gather (master + 2 agents in PARALLEL)

Three things happen simultaneously:

**Master (needs conversation context, skip if `/learn --team`):**
Scan the session for each of the 5 categories above.
Look at: user corrections, bundle loads, manual context requests,
new discoveries, architecture changes, decisions made.
Produce a raw findings list (one line per finding).
If `.jitneuro/` exists, classify each finding as TEAM or PERSONAL:
- TEAM: conventions, quality gates, architecture decisions, testing rules (benefits all devs)
- PERSONAL: editor preferences, workflow habits, personal shortcuts (only benefits you)

**Health Agent (background, skip if `/learn q`):**
Dispatch a background agent to run `/health` (quick mode). Agent returns the health table. Master includes health findings in the Phase 2 table if any issues found. If all healthy, no health rows in the output.

**Agent A (background, no conversation needed):**
Dispatch a background agent with this prompt:
```
Read Hub.md for the active session. Extract ## Lessons Learned entries.
Read all memory/*.md filenames + frontmatter type fields (NOT full content).
Read ~/.claude/rules/ filenames (NOT full content).
For each Hub.md lesson:
  - Check if memory/ already has a file covering this topic -> mark DUPLICATE
  - Check if rules/ already has a rule covering this -> mark DUPLICATE
  - Check if the lesson is universal (applies to any project) -> mark PROMOTE
Return: clean list of NEW lessons (not duplicated), with classification.
Return all findings. Do not truncate or limit -- every lesson matters.
```

Agent A runs even in `/learn q` (quick mode) -- Hub.md lessons must always be checked. Quick mode only skips the health check (Step 0).

**Team Agent (background, only if `.jitneuro/` exists AND not `/learn q`):**
Dispatch a background agent with this prompt:
```
Read .jitneuro/TEAM.md to determine team members and roles.
Get current username: git config user.name
Determine if this user is a TeamApprover (or if TEAM.md is missing = everyone is approver).

If TeamApprover:
  Read all .jitneuro/users/*/lessons.md files.
  Collect PENDING lessons from all users.
  For each pending lesson:
    - Check if .jitneuro/rules/ already has a rule covering this -> mark DUPLICATE
    - If not duplicate, include in the team queue
  Read .jitneuro/users/*/active-work.md timestamps for active dev status.
  Count .jitneuro/rules/ files and check for conflicts.
  Count .jitneuro/engrams/ files and check line counts.
  Check for stale lessons (pending > 7 days).

Return:
  TEAM_ROLE: <role from TEAM.md or "approver (no TEAM.md)">
  IS_APPROVER: true/false
  TEAM_QUEUE: list of pending lessons (author, date, content)
  TEAM_HEALTH: rules count, engram stats, active devs, stale lessons, conflicts
```

If `/learn --team`: only run Team Agent + Health Agent (skip Master scan and Agent A).

### Phase 2: Merge + Present (master only)

When Agent A returns, merge:
- Master's session findings + Agent A's Hub.md results
- Deduplicate: if both found the same lesson, keep one copy
- Hub.md lessons the session scan missed (lost context) = rescued

Build the table:
```
Proposed Updates:
| # | Type | File | Change |
|---|------|------|--------|
| 1 | Learn | MEMORY.md | Add "payments" -> [integrations] routing |
| 2 | Learn | deploy.md | Add rollback flag v2 to conventions |
| 3 | Promote | rules/new-rule.md | Universal instruction found |
| 4 | Publish | (github issue) | Universal pattern for jitneuro |
| 5 | Fix | MEMORY.md | Port 3002 is wrong, should be 3003 |
```

Present: "These are the session learnings. Approve all, or pick by number?"
Do NOT write anything until approved.

**Team output (if `.jitneuro/` exists and Team Agent returned):**

For any user (TeamApprover or not), TEAM-classified findings are shown with scope:
```
| # | Scope | Target | Change |
|---|-------|--------|--------|
| 1 | TEAM (Rec) | .jitneuro/users/<you>/lessons.md | No DB mocking in tests |
| 2 | PERSONAL | .jitneuro/users/<you>/rules/prefs.md | Prefer small PRs |
| 3 | Learn | MEMORY.md | Add routing weight |
```
TEAM items write to YOUR lessons.md (staging area). PERSONAL items write to YOUR rules/.

For TeamApprovers, also show:
```
== Team Lessons Queue ==
| # | Author | Date | Proposed Rule |
|---|--------|------|---------------|
| T1 | dev03 | 2026-03-27 | No DB mocking in integration tests |
| T2 | dev02 | 2026-03-26 | Always use UTC timestamps |

Promote to team? (all / pick by # / skip)

== Team Health ==
| Component | Status | Detail |
|-----------|--------|--------|
| Team rules (12) | OK | No conflicts |
| Team engrams (3) | WARN | api-context.md 160 lines (cap 150) |
| Active devs (3) | OK | dev01: active, dev02: AFK 2h, dev03: active |
| Stale lessons | INFO | 2 lessons >7 days without review |
| Conflicts | OK | No file overlap between active branches |
```

Team health runs automatically when reviewing team lessons. No extra cost.

### Phase 3: Write (agent, after approval)

Dispatch Agent B with the approved list:
```
Write these approved lessons to the specified files:
[approved items list with target files and content]

After writing all files:
- Clear Hub.md ## Lessons Learned section, replace with:
  ## Lessons Learned
  (Processed by /learn on YYYY-MM-DD)
- Return: FILES_CHANGED list + count
```

Master receives confirmation. Reports what was written and where.

**Team writes (if `.jitneuro/` exists):**

For TEAM-scoped lessons (any user):
- Write to `.jitneuro/users/<username>/lessons.md` under `## Pending`
- Include date and one-line description

For PERSONAL-scoped lessons (any user):
- Write to `.jitneuro/users/<username>/rules/<topic>.md`

For promotions (TeamApprover approved T# items):
- Read the lesson from the author's `users/<author>/lessons.md`
- Write to `.jitneuro/rules/<topic>.md` as a team rule
- Move the lesson from `## Pending` to `## Promoted` in the author's lessons.md
- Add: `-> .jitneuro/rules/<topic>.md` after the lesson text

For rejections (TeamApprover rejects T# items):
- Move the lesson from `## Pending` to `## Rejected` in the author's lessons.md
- Add the rejection reason

All team file writes go to Agent B alongside personal writes.

### If Nothing Found

- "No learnings to persist from this session."

## Token Budget

| Phase | Who | Token cost | Why |
|-------|-----|-----------|-----|
| 1 (scan session) | Master | Medium | Must read conversation context |
| 1 (Hub.md + dedup) | Agent A | Low | File reads only, returns findings list |
| 1 (health check) | Health Agent | Low | 5 file reads, returns table (skipped in -q) |
| 1 (team queue) | Team Agent | Low | File reads only, returns queue + health (skipped in -q) |
| 2 (merge + present) | Master | Low | Combine lists, display table |
| 3 (write files) | Agent B | Low | File writes, returns file list |

Master never reads memory/ files, Hub.md, rules/, or team files directly. Agents handle all file I/O.

## Important
- Phase 1 runs in PARALLEL (master scans conversation while agents read Hub.md + team files)
- NEVER write without user approval. Present the table first.
- Health runs separately via /health (as agent). /learn does not run health.
- MEMORY.md hard limit: 200 lines. Lines beyond 200 are silently truncated.
- Bundle soft limit: 280 lines. Report if over, do NOT auto-trim. Offer to trim, default no.
- Engram soft limit: 180 lines. Report if over, do NOT auto-trim. Offer to trim, default no.
- This command reads and proposes. It does not modify code files, only memory/context files.
- Team features are additive: no .jitneuro/ = solo mode, identical to v0.x behavior.
- `/learn --team` is TeamApprover-only. If user is not a TeamApprover, say so and suggest `/learn` instead.
- Team lesson promotion requires explicit approval per item (promote T1, promote all, skip).
