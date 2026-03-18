# Learn

Evaluate the current session for knowledge worth persisting to long-term memory.
This is JitNeuro's backpropagation -- the system improves itself over time.

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

Before evaluating session learnings, audit the memory system itself.
Read these files and measure actual line counts:

**MEMORY.md** (auto-load limit: 200 lines)
- Read MEMORY.md. Count lines.
- WARN at 170+ lines (approaching limit, plan extraction)
- CRITICAL at 190+ lines (must extract before next session)
- If over 200: lines beyond 200 are NOT loaded. Identify what's being truncated.
- Check for stale entries (projects marked "Active" that haven't been touched in weeks)
- Check for duplicates (same fact in MEMORY.md and a bundle)

**Bundles** (.claude/bundles/)
- List all bundles. Count lines in each.
- WARN at 150+ lines (approaching 180-line max)
- Flag any bundle over 180 lines -> suggest split
- Flag bundles not loaded in current session that routing weights say should have been
- Check for bundles referenced in routing weights that don't exist

**Engrams** (.claude/engrams/)
- List all engrams. Count lines in each.
- WARN at 130+ lines (approaching 150-line max)
- Flag any engram over 150 lines -> suggest trimming stale content
- Check for projects active in this session that have no engram -> suggest creating one
- Check for engrams referencing outdated tech/versions

**Session State** (.claude/session-state/)
- List all session files with ages
- Flag sessions older than 7 days as stale
- Flag sessions older than 14 days -> suggest archiving or deleting
- Count total sessions (more than 10 active = clutter)

**Routing Weights** (in MEMORY.md)
- Check if any task in this session required manual bundle loading (missed route)
- Check for routing entries that point to bundles/engrams that don't exist
- Check for bundles that exist but have no routing entry

Present health check as:
```
Memory System Health:
| Component | Status | Detail |
|-----------|--------|--------|
| MEMORY.md | OK (89/200 lines) | |
| Bundles | WARN | blog.md at 155/180 lines |
| Engrams | OK (3 files, all under 150) | |
| Sessions | WARN | 2 stale (>7 days) |
| Routing | MISS | No route for "stripe" tasks |
```

When presenting the health table, include the **Fix** column with the recommended action.
Use these remediation patterns:

```
Memory System Health:
| Component | Status | Detail | Fix |
|-----------|--------|--------|-----|
| MEMORY.md | WARN (174/200) | Approaching limit | Extract largest section to bundle or engram |
| Bundles | WARN | blog.md 76/80 | Split into blog-workflow.md + blog-content.md |
| Engrams | MISS | No engram for auth-api | Create from templates/engrams/example.md |
| Sessions | STALE | deploy-fix (5d old) | Delete if done, or /load to resume |
| Routing | MISS | No route for "stripe" | Add to MEMORY.md routing weights |
```

**Remediation Reference** (for Claude to follow when executing fixes):

| Problem | Fix Pattern |
|---------|-------------|
| MEMORY.md over 170 lines | Find the largest non-routing section. Extract to a bundle (domain knowledge) or engram (project-specific). Replace in MEMORY.md with one-line pointer: `Detail: memory/[topic].md` or `See bundle: [name].md` |
| MEMORY.md over 200 lines | CRITICAL. Identify what's being truncated (lines 201+). Move truncated content to appropriate file immediately. Then apply 170+ fix to create headroom. |
| MEMORY.md has duplicates | Keep the canonical copy in the more specific file (bundle > MEMORY.md). Replace duplicate in MEMORY.md with pointer. |
| MEMORY.md has stale entries | Verify with user before removing. Mark as "UNVERIFIED" if unsure, delete if confirmed stale. |
| Bundle over 180 lines | Split by subdomain. Example: `deploy.md` -> `deploy-pipeline.md` + `deploy-environments.md`. Update routing weights to reference both. |
| Bundle missing content | Add the missing information. If it pushes over 180 lines, split first. |
| Bundle referenced but missing | Create from `templates/bundles/example.md`. Populate with known context from session. |
| Engram over 150 lines | Trim History section (keep last 3-5 entries). Move Gotchas to a bundle if they're domain-general. Compress verbose sections. |
| Engram missing for active project | Create from `templates/engrams/example.md`. Populate with: tech stack, key files, architecture, integrations discovered this session. |
| Engram has outdated info | Update specific fields. Don't rewrite the whole file -- surgical edits only. |
| Session state older than 7 days | Flag as stale in output. User decides: delete, resume, or keep. |
| Session state older than 14 days | Recommend deletion. If task is still relevant, suggest creating a fresh save. |
| More than 10 active sessions | List all with ages. Ask user to clean up completed tasks. |
| Routing weight miss | Add new routing entry to MEMORY.md. Format: `- [trigger words] -> [bundle list]` |
| Routing weight points to missing bundle | Either create the bundle or remove the routing entry. |
| Bundle exists with no routing entry | Add routing entry, or confirm the bundle is only loaded manually/by orchestrator. |

### Step 1: Scan Session for Learnings

Scan the session for each of the 5 categories above.
Look at: user corrections, bundle loads, manual context requests,
new discoveries, architecture changes, decisions made.

### Step 2: Build Proposed Changes Table

Combine health check findings AND session learnings into one table:
```
Proposed Updates:
| # | Type | File | Change | Fix |
|---|------|------|--------|-----|
| 1 | Health | MEMORY.md | Extract deploy detail (174/200 lines) | Move to memory/deploy-workflow.md, replace with pointer |
| 2 | Health | stale-task.md | Stale session (5 days old) | Delete or /load to resume |
| 3 | Learn | MEMORY.md | Add "payments" -> [integrations] | Add routing entry |
| 4 | Learn | deploy.md | Add rollback flag v2 | Append to Conventions section |
| 5 | Learn | auth-api.md | Add /auth/refresh route | Append to Key Files table |
| 6 | Fix | MEMORY.md | Port 3002 is wrong, should be 3003 | Update line 47 |
```

### Step 3: Present for Approval

- "These are the health findings and learnings. Approve all, or pick by number?"
- Do NOT write anything until approved.

### Step 4: Execute Approved Changes

- Update files as approved
- Re-count lines after changes to confirm limits are respected
- Report what was written and where

### Step 5: If Nothing Found

- "Memory system healthy. No learnings to persist from this session."

## Important
- NEVER write without user approval. Present the table first.
- Health check runs EVERY time, even if session had no learnings.
- MEMORY.md hard limit: 200 lines. Lines beyond 200 are silently truncated by Claude Code.
- Bundle hard limit: 180 lines. Longer bundles get ignored or partially read.
- Engram soft limit: 150 lines. Longer engrams waste context on low-value detail.
- Session state soft limit: 10 active files. More than that is clutter.
- This command reads and proposes. It does not modify code files, only memory/context files.
- After executing changes, re-read modified files to verify line counts are within limits.
