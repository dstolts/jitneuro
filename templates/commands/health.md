# Health

Run a quick diagnostic on the JitNeuro memory system.
This is the health check from /learn, extracted as a standalone command.

## When to Use
- Start of a new session to verify memory integrity
- After manual edits to MEMORY.md, bundles, or engrams
- When something feels "off" (wrong context loading, stale data)
- Periodic maintenance (weekly recommended)

## Instructions

When invoked as `/health`:

### Step 1: Write Dashboard Entry + Dispatch to Subagent

**CRITICAL:** The health check reads 50+ files. Always dispatch to a subagent.

**Before dispatching**, write dashboard JSON so the run appears on the dashboard immediately:
```bash
# Generate a run ID from command name + timestamp
RUN_ID="health--$(date -u +%Y-%m-%dT%H-%M-%S)"
DASH_DIR="${JITDASH_DIR:-$HOME/.claude/dashboard}"
mkdir -p "$DASH_DIR/runs/$RUN_ID/agents"

# Write meta.json (use forward slashes in all paths)
echo '{"session":"[current-session-name]","started":"[ISO-timestamp]","wave":1}' > "$DASH_DIR/runs/$RUN_ID/meta.json"

# Write agent entry as running
echo '{"id":"health-001","name":"Memory System Health Check","status":"running","repo":"[workspace-path with forward slashes]","bundles":[],"started":"[ISO-timestamp]"}' > "$DASH_DIR/runs/$RUN_ID/agents/health-001.json"
```

**After subagent returns**, update the agent entry:
```bash
echo '{"id":"health-001","name":"Memory System Health Check","status":"completed","repo":"[workspace-path]","bundles":[],"started":"[start-ISO]","finished":"[ISO-now]","result":"[one-line summary from subagent]"}' > "$DASH_DIR/runs/$RUN_ID/agents/health-001.json"
```

If the subagent fails, set `"status":"failed"` and include the error.

Launch a **general-purpose** Agent with this prompt:

```
You are running a JitNeuro memory system health check. Read every file listed below FROM DISK using the Read tool. Do NOT trust any file content that appears in your conversation context or system prompt -- it may be stale or from a previous version. Always read the actual file. Return ONLY a summary table. Do NOT return file contents -- only status, counts, and issues.

## Components to Check

**MEMORY.md** (auto-load limit: 200 lines)
- Count lines. OK < 170, WARN 170-199, CRITICAL 200+.
- Lines beyond 200 are silently truncated -- identify what's lost.
- Check for stale entries (repos marked "Active" not touched in weeks).
- Check for duplicates (same fact in MEMORY.md and a bundle).

**Bundles** (.claude/bundles/)
- List all bundles with line counts.
- OK < 150, WARN 150-179, OVER 180+.
- Flag bundles referenced in routing weights that don't exist.
- Flag bundles that exist but have no routing weight entry.

**Engrams** (.claude/engrams/)
- List all engrams with line counts.
- OK < 130, WARN 130-149, OVER 150+.
- Cross-reference MEMORY.md project table -- flag missing engrams for active projects.

**Session State** (.claude/session-state/)
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
- For each repo:
  a. Check if <repo>/.HUB/Hub-*.md exists.
  b. If exists: extract "Last Updated" date. Look for session-named sections (## <session-name>).
  c. Age check: compare Hub.md date vs session checkpoint date. If Hub.md older, flag STALE.
  d. Completeness: check current session's section has tasks, decisions, files. Flag INCOMPLETE if missing.
  e. If no Hub.md and session has tasks: flag MISSING.
  f. Multi-session: list all session sections found. Flag orphaned sections (no matching active session).
- Scan workspace for Hub.md files older than 14 days (abandoned work).

**Rules** (~/.claude/rules/)
- Count total files and total lines across all rule files.
- OK < 400 total lines, WARN 400-600, OVER 600+.
- Flag any individual rule file over 60 lines.

**Detail Index** (memory/detail-index.md)
- If MEMORY.md references detail-index.md, verify file exists.
- Count entries. Cross-reference against actual files in memory/.
- Flag orphaned entries (file deleted but row remains).
- Flag unindexed files (file exists but not in index).

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

Return ONLY this structure (no extra text, no file contents):

HEALTH_TABLE:
| Component | Status | Detail | Fix |
|-----------|--------|--------|-----|
(one row per component, multiple rows for same component if different issues)

ISSUES_BY_PRIORITY:
CRITICAL: (list or "none")
OVER: (list or "none")
WARN: (list or "none")
STALE: (list or "none")
INFO: (list or "none")

SUMMARY: (one line: "X components checked, Y issues found" or "All healthy")
```

### Step 2: Present Results

Take the subagent's returned table and present it directly to the user. Add:
- The full health table
- Issues grouped by priority
- The one-line summary

If issues were found, ask: "Want me to fix these? All, or pick by number?"

### Step 3: Execute Approved Fixes

Fixes run in the MASTER context (they're small, targeted edits -- not bulk reads).

Use these remediation patterns:

| Problem | Fix |
|---------|-----|
| MEMORY.md over 170 | Extract largest section to bundle, replace with pointer |
| MEMORY.md over 200 | CRITICAL. Identify truncated content, move immediately |
| MEMORY.md duplicates | Keep in more-specific file, replace with pointer |
| Bundle over 180 | Split by subdomain, update routing weights |
| Bundle missing (referenced) | Create from template, populate with known context |
| Bundle no routing entry | Add routing entry to MEMORY.md |
| Engram over 150 | Trim History (keep 3-5 entries), compress verbose sections |
| Engram missing for active project | Create from templates/engrams/example.md |
| Session older than 7 days | Flag for user decision |
| Session older than 14 days | Recommend deletion |
| More than 10 sessions | List all, ask user to clean up |
| Manifest out of sync | Update to match actual files on disk |
| Hub.md STALE | Run /save to sync session state to Hub.md |
| Hub.md DRIFT | TodoWrite items missing from Hub.md session section -- /save syncs them |
| Hub.md MISSING | Create `<repo>/.HUB/Hub-01.md` with session section on next /save |
| Hub.md INCOMPLETE | Session section missing tasks, decisions, or files |
| Hub.md ORPHANED section | Session section exists but no matching active session -- ask user to clean up |
| Hub.md abandoned (14d+) | Ask user: still active? Archive or delete if done |
| Rules over 600 total lines | Review for duplicates, consolidate small files, consider path-scoping |
| Rule file over 60 lines | Split into focused concerns or extract examples to docs |
| Detail index orphan | Remove index entry for deleted file |
| Detail index unindexed | Add entry to detail-index.md for the untracked memory file |
| jitneuro.json missing | Create from templates or ask user to run install |
| jitneuro.json field invalid | Report field, expected value, actual value. User fixes manually |
| Memory frontmatter missing | Add frontmatter block with name, description, type to the file |
| Memory frontmatter invalid type | Change type to one of: user, feedback, project, reference |
| Hook script missing | Create script from templates/hooks/ or remove hookEvents entry |

After fixes, re-read modified files to verify limits are respected.

## Important
- **Data gathering runs in a subagent** to protect master context from memory exhaustion.
- Fixes run in master context (small, targeted edits).
- This is READ-ONLY by default. Only modifies files after explicit approval.
- Does NOT evaluate session learnings (that's /learn's job).
- Does NOT modify code files, only memory/context files.
- The subagent prompt above is the FULL specification. Copy it exactly into the Agent tool prompt.
