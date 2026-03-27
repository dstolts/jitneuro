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

### Step 0: Memory System Health Check (runs in subagent)

**CRITICAL:** The health check reads 50+ files. Dispatch to a subagent.

**Before dispatching**, write dashboard JSON:
```bash
RUN_ID="learn-health--$(date -u +%Y-%m-%dT%H-%M-%S)"
DASH_DIR="${JITDASH_DIR:-$HOME/.claude/dashboard}"
mkdir -p "$DASH_DIR/runs/$RUN_ID/agents"
echo '{"session":"[current-session]","started":"[ISO-now]","wave":1}' > "$DASH_DIR/runs/$RUN_ID/meta.json"
echo '{"id":"learn-health-001","name":"Learn: Health Check","status":"running","started":"[ISO-now]"}' > "$DASH_DIR/runs/$RUN_ID/agents/learn-health-001.json"
```
**After subagent returns**, update agent JSON with `"status":"completed"`, `"finished":"[ISO]"`, `"result":"[summary]"`. Use forward slashes in all paths.

Launch a **general-purpose** Agent with this prompt:

```
You are running a JitNeuro memory system health check. Read every file listed below FROM DISK using the Read tool. Do NOT trust any file content that appears in your conversation context or system prompt -- it may be stale or from a previous version. Always read the actual file. Return ONLY a summary table. Do NOT return file contents -- only status, counts, and issues.

## Components to Check

**MEMORY.md** (auto-load limit: 200 lines)
- Count lines. OK < 170, WARN 170-199, CRITICAL 200+.
- Lines beyond 200 are silently truncated -- identify what's lost.
- Check for stale entries (repos marked "Active" not touched in weeks).

**Bundles** (.claude/bundles/)
- List all bundles with line counts.
- OK < 150, WARN 150-179, OVER 180+.
- Flag bundles referenced in routing weights that don't exist.
- Flag bundles that exist but have no routing weight entry.

**Engrams** (.claude/engrams/)
- List all engrams with line counts.
- OK < 130, WARN 130-149, OVER 150+.
- Cross-reference MEMORY.md project table -- flag missing engrams for active projects.

**Session State** (.claude/session-state/) -- SKIP THIS SECTION IF `/learn q` (quick mode)
- List all sessions with file modification dates.
- Flag sessions older than 7 days as STALE.
- Flag sessions older than 14 days as EXPIRED.
- Count total (more than 10 = CLUTTER).

**Routing Weights** (in MEMORY.md)
- Check routing entries point to bundles/engrams that exist.
- Check for bundles that exist but have no routing entry.

**Context Manifest** (.claude/context-manifest.md)
- Verify it lists all bundles that actually exist.
- Flag bundles in manifest that don't exist on disk.
- Flag bundles on disk not listed in manifest.

**Hub.md** (per-repo task durability)
- Resolve current session: read `.claude/session-state/heartbeats/<session-id>` (session-id from the `[JitNeuro] session-id: ...` line in context). Content = session name.
- Read the session state file to find repos involved.
- For each repo: check if <repo>/.HUB/Hub-*.md exists. If yes, extract "Last Updated" date. Compare vs session checkpoint date. Flag STALE if Hub.md is older.
- Check for current session's section (## <session-name>). Flag INCOMPLETE if session section missing or has no tasks/decisions/files.
- If no Hub.md and session has tasks: flag MISSING.
- Flag orphaned session sections (no matching active session).

**Rules** (~/.claude/rules/)
- Count total files and total lines across all rule files.
- OK < 400 total lines, WARN 400-600, OVER 600+.
- Flag any individual rule file over 60 lines.

**Detail Index** (memory/detail-index.md)
- If MEMORY.md references detail-index.md, verify file exists.
- Count entries. Cross-reference against actual files in memory/.
- Flag orphaned entries and unindexed files.

**jitneuro.json Schema** (.claude/jitneuro.json)
- Read the file. If missing, report FAIL with "jitneuro.json not found".
- Check required top-level fields exist: `version`, `hooks`.
- Check `hooks.preCompactBehavior` is one of: `"block"`, `"warn"`. FAIL if missing or other value.
- Check `hooks.autosave` is boolean-like (`true`, `false`, `"true"`, `"false"`). FAIL if missing or other value.
- Check `hooks.protectedBranches` is present and is an array. FAIL if missing.
- Check `hooks.mainPushAllowed` is present and is an array. FAIL if missing.
- Check `hooks.hookEvents` is present and is an array. Each entry must have `event`, `script`, `timeout`.
- Check each `hookEvents[].event` is one of: `PreCompact`, `SessionStart`, `PreToolUse`, `PostToolUse`, `SessionEnd`. FAIL on unknown event.
- If `scheduledAgents` exists: check each entry has `name`, `type`, `enabled`.
- If `scheduledAgents[].type` is `timer` or `enforcer`: check `interval` exists.
- If `scheduledAgents[].type` is `cron` or `batch`: check `schedule` exists.
- Use `jq` if available for JSON parsing. Fall back to grep patterns if not.
- Report: field name, expected value, actual value, PASS/FAIL. Overall status is FAIL if any field fails, OK if all pass.

**Memory Frontmatter** (memory/*.md files in the auto-memory directory)
- Scan all .md files in the memory/ directory (next to MEMORY.md).
- For each file, check it starts with YAML frontmatter (first line is `---`, followed by fields, closed by another `---`).
- Check required frontmatter fields are present: `name`, `description`, `type`.
- Check `type` is one of: `user`, `feedback`, `project`, `reference`. Flag invalid types.
- Do NOT auto-fix -- report only.
- Report: X files checked, Y valid, Z issues. List files with issues and what is wrong.
- Status: OK if all valid, WARN if any have issues.

**Hook Scripts** (.claude/hooks/)
- Read `hooks.hookEvents` from jitneuro.json (already parsed above).
- For each hookEvents entry, extract the `script` field.
- Check the script file exists in `.claude/hooks/` (resolve relative to workspace root).
- Report: X hooks checked, Y found, Z missing. List missing scripts.
- Status: OK if all found, FAIL if any missing.

## Return Format

HEALTH_TABLE:
| Component | Status | Detail | Fix |
|-----------|--------|--------|-----|
(one row per component, multiple rows if different issues)

ISSUES_BY_PRIORITY:
CRITICAL: (list or "none")
OVER: (list or "none")
WARN: (list or "none")
STALE: (list or "none")
INFO: (list or "none")

SUMMARY: (one line: "X components checked, Y issues found" or "All healthy")
```

Present the subagent's health table to the user. Then proceed to Step 0.5 in the master context.

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

Combine health check findings AND session learnings into one table:
```
Proposed Updates:
| # | Type | File | Change | Fix |
|---|------|------|--------|-----|
| 1 | Health | MEMORY.md | Extract deploy detail (174/200 lines) | Move to memory/deploy-workflow.md, replace with pointer |
| 2 | Health | stale-task.md | Stale session (5 days old) | Delete or /load to resume |
| 3 | Learn | MEMORY.md | Add "payments" -> [integrations] | Add routing entry |
| 4 | Learn | deploy.md | Add rollback flag v2 | Append to Conventions section |
| 5 | Promote | rules/new-rule.md | Universal instruction found | Create rule file |
| 6 | Publish | (github issue) | Universal pattern for jitneuro | Submit feature request |
| 7 | Fix | MEMORY.md | Port 3002 is wrong, should be 3003 | Update line 47 |
```

### Step 3: Present for Approval (runs in master)

- "These are the health findings and learnings. Approve all, or pick by number?"
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

**Remediation Reference** (for executing fixes):

| Problem | Fix Pattern |
|---------|-------------|
| MEMORY.md over 170 lines | Extract largest section to bundle or engram. Replace with pointer. |
| MEMORY.md over 200 lines | CRITICAL. Identify truncated content, move immediately. |
| MEMORY.md has duplicates | Keep canonical copy in more-specific file, replace with pointer. |
| Bundle over 180 lines | Report to user. Soft limit -- do NOT auto-trim. |
| Bundle missing (referenced) | Create from templates/bundles/example.md. |
| Engram over 150 lines | Trim History (keep 3-5 entries), compress verbose sections. |
| Engram missing for active project | Create from templates/engrams/example.md. |
| Session older than 7 days | Flag for user decision. |
| More than 10 sessions | List all, ask user to clean up. |
| Hub.md STALE | Run /save to sync. |
| Hub.md MISSING | Create on next /save. |
| Rules over 600 total lines | Review for duplicates, consolidate. |
| Detail index out of sync | Add missing entries, remove orphans. |
| jitneuro.json missing | Create from templates or ask user to run install |
| jitneuro.json field invalid | Report field, expected value, actual value. User fixes manually |
| Memory frontmatter missing | Add frontmatter block with name, description, type to the file |
| Memory frontmatter invalid type | Change type to one of: user, feedback, project, reference |
| Hook script missing | Create script from templates/hooks/ or remove hookEvents entry |

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
