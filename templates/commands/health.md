# Health

Memory system diagnostic. Two modes: quick (default, safe for /save) and deep (on-demand).

## Modes

- `/health` -- quick check. 3-5 file reads, under 10 seconds. Always runs as a subagent.
- `/health --deep` -- full scan. 50+ file reads. Always runs as a subagent.

Health is not context-dependent -- it reads files on disk, not conversation state. Always dispatch to a subagent so master keeps working. Agent returns results; master displays them.

## Quick Health (`/health`)

Launch a background **general-purpose** Agent with this prompt:

```
You are running a JitNeuro quick health check. Read these 5 things and return a table.

1. Read MEMORY.md (the auto-memory file). Count lines. OK < 170, WARN 170-199, CRITICAL 200+.
2. Count .md files in .claude/session-state/ (exclude archive/, heartbeats/, .preferences, README.md, _autosave.md). OK < 10, WARN 10+. Check file dates -- flag any >7 days as STALE.
3. Count .md files in .claude/bundles/. Report count only.
4. Count .md files in .claude/engrams/. Report count only.
5. Read .claude/jitneuro.json. Check it exists and has a version field.

Return EXACTLY this format:
QUICK_HEALTH:
| Component | Status | Detail |
|-----------|--------|--------|
| MEMORY.md | OK/WARN/CRITICAL | X/200 lines |
| Sessions | OK/WARN | X sessions, Y stale |
| Bundles | OK | X bundles |
| Engrams | OK | X engrams |
| jitneuro.json | OK/FAIL | vX.X.X or missing |

SUMMARY: X components checked, Y issues
```

When the agent returns, display the table. If any CRITICAL or FAIL: recommend `/health --deep` for details.

## Deep Health (`/health --deep`)

**CRITICAL:** Reads 50+ files. Always dispatch to a subagent.

### Dashboard Entry

Before dispatching, write dashboard JSON:
```bash
RUN_ID="health--$(date -u +%Y-%m-%dT%H-%M-%S)"
DASH_DIR="${JITDASH_DIR:-$HOME/.claude/dashboard}"
mkdir -p "$DASH_DIR/runs/$RUN_ID/agents"
echo '{"session":"[current-session-name]","started":"[ISO-timestamp]","wave":1}' > "$DASH_DIR/runs/$RUN_ID/meta.json"
echo '{"id":"health-001","name":"Memory System Health Check","status":"running","repo":"[workspace-path with forward slashes]","bundles":[],"started":"[ISO-timestamp]"}' > "$DASH_DIR/runs/$RUN_ID/agents/health-001.json"
```

After subagent returns, update agent entry with `"status":"completed"` and result summary.

### Subagent Prompt

Launch a **general-purpose** Agent with this prompt:

```
You are running a JitNeuro deep health check. Read every file listed below FROM DISK using the Read tool. Do NOT trust any file content in your conversation context -- it may be stale. Return ONLY a summary table.

## Components to Check

**MEMORY.md** (auto-load limit: 200 lines)
- Count lines. OK < 170, WARN 170-199, CRITICAL 200+.
- Lines beyond 200 are silently truncated -- identify what's lost.
- Check for stale entries (repos marked "Active" not touched in weeks).
- Check for duplicates (same fact in MEMORY.md and a bundle).

**Bundles** (.claude/bundles/)
- List all bundles with line counts.
- OK < 230, WARN 230-279, OVER 280+. Soft limit -- report only, do not auto-trim.
- Flag bundles referenced in routing weights that don't exist.
- Flag bundles that exist but have no routing weight entry.

**Engrams** (.claude/engrams/)
- List all engrams with line counts.
- OK < 150, WARN 150-179, OVER 180+. Soft limit -- report only, do not auto-trim.
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
- Resolve current session from heartbeats.
- Read session state to find repos involved.
- For each repo: check Hub.md exists, check staleness, check session section completeness.
- Flag: STALE (older than session checkpoint), MISSING (no Hub.md + tasks exist), INCOMPLETE (session section missing tasks/decisions).

**Rules** (~/.claude/rules/)
- Count total files and total lines across all rule files.
- OK < 400 total lines, WARN 400-600, OVER 600+.
- Flag any individual rule file over 60 lines.

**Detail Index** (memory/detail-index.md)
- If exists, count entries. Cross-reference against actual files in memory/.
- Flag orphaned entries and unindexed files.

**jitneuro.json Schema** (.claude/jitneuro.json)
- Check required fields: version, hooks.
- Validate: preCompactBehavior (block/warn), autosave (boolean), protectedBranches (array), hookEvents (array with event/script/timeout).
- If scheduledAgents exists: validate per-type required fields.

**Memory Frontmatter** (memory/*.md files)
- Check each file has YAML frontmatter with name, description, type.
- Check type is one of: user, feedback, project, reference.

**Hook Scripts** (.claude/hooks/)
- For each hookEvents entry, check script file exists.

**Team Knowledge** (.jitneuro/) -- SKIP if .jitneuro/ does not exist
- Check .jitneuro/TEAM.md exists and has at least one member
- Count team rules (.jitneuro/rules/) with line counts
- Count team engrams (.jitneuro/engrams/) with line counts
- Count team bundles (.jitneuro/bundles/) with line counts
- List users in .jitneuro/users/ -- check each has active-work.md
- Check for stale lessons (pending > 7 days in any users/*/lessons.md)
- Check .jitneuro/context-manifest.md exists and references existing bundles
- If .jitneuro/jitneuro.json exists, validate schema matches personal jitneuro.json format
- Flag conflicts: same rule name in .jitneuro/rules/ and .claude/rules/

## Return Format

HEALTH_TABLE:
| Component | Status | Detail | Fix |
|-----------|--------|--------|-----|
(one row per component)

ISSUES_BY_PRIORITY:
CRITICAL: (list or "none")
OVER: (list or "none")
WARN: (list or "none")
STALE: (list or "none")
INFO: (list or "none")

SUMMARY: (one line: "X components checked, Y issues found" or "All healthy")
```

### Present Results

Display the subagent's table. If issues found, ask: "Want me to fix these? All, or pick by number?"

### Execute Approved Fixes

Fixes run in master context (small, targeted edits).

| Problem | Fix |
|---------|-----|
| MEMORY.md over 170 | Extract largest section to bundle, replace with pointer |
| MEMORY.md over 200 | CRITICAL. Identify truncated content, move immediately |
| Bundle over 280 | Soft limit. Report only. Offer to trim, default no. |
| Bundle missing (referenced) | Create from template |
| Engram over 180 | Soft limit. Report only. Offer to trim, default no. |
| Engram missing for active project | Create from template |
| Session older than 7 days | Flag for user decision |
| More than 10 sessions | List all, ask user to clean up |
| Manifest out of sync | Update to match actual files |
| Hub.md STALE | Run /save to sync |
| Hub.md MISSING | Create on next /save |
| Rules over 600 total | Review for duplicates, consolidate |
| jitneuro.json field invalid | Report field + expected value |
| Memory frontmatter missing | Add frontmatter block |
| Hook script missing | Create from template or remove hookEvents entry |

## Important
- **Quick mode** is the default. Fast, lightweight, safe for automated use.
- **Deep mode** requires `--deep` flag. Dispatched to subagent to protect master context.
- Both are READ-ONLY by default. Only modify files after explicit approval.
- Does NOT evaluate session learnings (that's /learn's job).
