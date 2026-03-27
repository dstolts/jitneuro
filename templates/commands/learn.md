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
- Bundle over 180 lines -> suggest split

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

### Step 0: Memory System Health Check

Run `/health` (quick mode) inline. This is 3-5 file reads, under 10 seconds, no subagent needed.

If quick health finds CRITICAL or FAIL issues, recommend `/health --deep` for full diagnosis.

Skip this step entirely if `/learn q` (quick mode).

Run the quick health checks inline (see /health command for the 5 checks). Present the table. If CRITICAL or FAIL, recommend `/health --deep`.

Then proceed to Step 0.5 in the master context.

### Step 0.5: Read Hub.md Lessons (runs in master)

Before scanning session context, read durable lessons from Hub.md:

1. Find the current session's Hub.md (resolve from session state).
2. Read the `## Lessons Learned` section if it exists.
3. Parse each `- [type] description` line into a candidate list.
4. These candidates came from real-time capture during work (see rules/lessons-capture.md).
   They survive crashes and context compaction -- this is the rescue path.
5. Hold this list for merge with session scan in Step 1.

If no Hub.md exists or no `## Lessons Learned` section is found, skip -- proceed to Step 1.
If lessons exist from a PREVIOUS session (context was lost), process them -- they were rescued.

### Step 1: Scan Session for Learnings (runs in master)

This step needs the current session context, so it stays in master.

Scan the session for each of the 5 categories above.
Look at: user corrections, bundle loads, manual context requests,
new discoveries, architecture changes, decisions made.

Merge with Hub.md candidates from Step 0.5:
- Deduplicate: if a Hub.md lesson matches a session-scanned learning, keep one copy.
- Hub.md lessons the session scan missed (lost context) are rescued and included.
- Combined list feeds into Step 1b classification.

### Step 1b: Classification Check (prevent misplacement)

For each learning found in Step 1, before proposing where to save it, check:

1. **Duplicate check:** Grep `~/.claude/rules/` for the same guidance. If a rule already covers it, skip -- do not save a duplicate to memory.
2. **Promotion check:** If the learning is a universal behavioral instruction ("always X", "never Y", applies regardless of project or context), recommend saving to `rules/` instead of `memory/`. Flag in the table as Type: `Promote`.
3. **Publishable check:** If the learning is a universal pattern any Claude Code user would benefit from (not owner-specific), flag as Type: `Publish` and recommend submitting as a jitneuro feature request. See docs/feedback-classification.md for the decision criteria.
4. **Existing memory check:** Grep `memory/` for overlapping feedback files. If an existing feedback_* file covers the same topic, update it rather than creating a new file.

### Step 2: Build Proposed Changes Table (runs in master)

Session learnings ONLY. Health issues are handled by /health (runs separately as agent).
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

### Step 3: Present for Approval (runs in master)

- "These are the session learnings. Approve all, or pick by number?"
- Do NOT write anything until approved.

### Step 4: Execute Approved Changes (runs in master)

- Update files as approved
- For `Publish` items: create GitHub issue on the jitneuro repo with `gh issue create` (only after explicit approval)
- Re-count lines after changes to confirm limits are respected
- **Clear Hub.md lessons:** After all approved changes are written, replace the
  `## Lessons Learned` section in Hub.md with a processed marker:
  ```markdown
  ## Lessons Learned
  (Processed by /learn on YYYY-MM-DD)
  ```
  This prevents re-processing on the next /learn run. New lessons captured after
  this point will append below the marker, starting a fresh cycle.
- Report what was written and where

### Step 5: If Nothing Found

- "Memory system healthy. No learnings to persist from this session."

## Important
- **Health check (Step 0) runs in a subagent.** Learning evaluation (Steps 1-4) runs in master because it needs session context.
- NEVER write without user approval. Present the table first.
- Health check runs EVERY time, even if session had no learnings.
- MEMORY.md hard limit: 200 lines. Lines beyond 200 are silently truncated.
- Bundle soft limit: 180 lines. Report if over, do NOT auto-trim.
- Engram soft limit: 150 lines. Longer engrams waste context on low-value detail.
- Session state soft limit: 10 active files.
- This command reads and proposes. It does not modify code files, only memory/context files.
- After executing changes, re-read modified files to verify limits are respected.
