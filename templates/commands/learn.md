# Learn

Evaluate the current session for knowledge worth persisting to long-term memory.
This is JitNeuro's backpropagation -- the system improves itself over time.

## Arguments
- `/learn` -- full evaluation (health check + session learnings)
- `/learn q` -- quick mode: skip session/archive cleanup recommendations, focus on learnings only

Quick mode skips: stale session flags, archive/delete recommendations, session count warnings. Use when you know sessions are fine and just want to capture learnings fast.

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

### Phase 1: Gather (master + agent in PARALLEL)

Two things happen simultaneously:

**Master (needs conversation context):**
Scan the session for each of the 5 categories above.
Look at: user corrections, bundle loads, manual context requests,
new discoveries, architecture changes, decisions made.
Produce a raw findings list (one line per finding).

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
Keep under 15 lines.
```

Skip Phase 1 Agent A if `/learn q` (quick mode -- session scan only, no Hub.md check).

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

### If Nothing Found

- "No learnings to persist from this session."

## Token Budget

| Phase | Who | Token cost | Why |
|-------|-----|-----------|-----|
| 1 (scan session) | Master | Medium | Must read conversation context |
| 1 (Hub.md + dedup) | Agent A | Low | File reads only, returns 15 lines |
| 2 (merge + present) | Master | Low | Combine two lists, display table |
| 3 (write files) | Agent B | Low | File writes, returns file list |

Master never reads memory/ files, Hub.md, or rules/ directly. Agents handle all file I/O.

## Important
- Phase 1 runs in PARALLEL (master scans conversation while agent reads Hub.md)
- NEVER write without user approval. Present the table first.
- Health runs separately via /health (as agent). /learn does not run health.
- MEMORY.md hard limit: 200 lines. Lines beyond 200 are silently truncated.
- Bundle soft limit: 280 lines. Report if over, do NOT auto-trim. Offer to trim, default no.
- Engram soft limit: 180 lines. Report if over, do NOT auto-trim. Offer to trim, default no.
- This command reads and proposes. It does not modify code files, only memory/context files.
