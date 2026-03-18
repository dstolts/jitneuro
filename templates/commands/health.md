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

### Step 1: Read and Measure All Components

Read these files and count actual lines:

**MEMORY.md** (auto-load limit: 200 lines)
- Count lines. OK < 170, WARN 170-199, CRITICAL 200+.
- Lines beyond 200 are silently truncated -- identify what's lost.
- Check for stale entries (repos marked "Active" not touched in weeks).
- Check for duplicates (same fact in MEMORY.md and a bundle).

**Bundles** (.claude/bundles/)
- List all bundles with line counts.
- OK < 70, WARN 70-79, OVER 80+.
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

### Step 2: Present Health Table

```
Memory System Health:
| Component | Status | Detail | Fix |
|-----------|--------|--------|-----|
| MEMORY.md | OK (91/200) | | |
| Bundles | OK (5 files, all under 70) | | |
| Engrams | WARN | auth-api at 142/150 | Trim History section |
| Sessions | STALE | deploy-fix (5d old) | Delete or /load to resume |
| Routing | OK | All routes resolve | |
| Manifest | MISS | blog.md not listed | Add to context-manifest.md |
```

Status values: OK, WARN, MISS, STALE, EXPIRED, OVER, CRITICAL, CLUTTER

### Step 3: Summarize

- If all OK: "Memory system healthy. No action needed."
- If issues found: List recommended fixes, grouped by priority (CRITICAL > OVER > WARN > STALE).
- Ask: "Want me to fix these? All, or pick by number?"

### Step 4: Execute Approved Fixes

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

After fixes, re-read modified files to verify limits are respected.

## Important
- This is READ-ONLY by default. Only modifies files after explicit approval.
- Does NOT evaluate session learnings (that's /learn's job).
- Does NOT modify code files, only memory/context files.
- Fast: should complete in under 30 seconds.
