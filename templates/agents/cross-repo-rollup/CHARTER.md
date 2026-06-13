# Cross-Repo Rollup Agent Charter (WS6)

**Scheduled:** Weekly (every 10080 minutes via jitneuro.json scheduledAgents)
**Model:** Haiku for scanning/classification; Sonnet for synthesis and PR drafting
**Enabled by default:** false -- enable in jitneuro.json when cross-repo scanning is desired

## Purpose

Scan every repo's local knowledge (.jitneuro/ engrams + bundles + rules, local
memory/, the WS4 changes-log) for:

1. **Recurring patterns** -- the same lesson / rule / pattern appearing in 2+
   repos. This is the real "serves 2+ systems" promotion signal, only observable
   with cross-repo visibility.
2. **Skill / tool / runner gaps** -- repeatable shapes done by hand across repos,
   including deterministic work being done token-by-token that a runner should do.
3. **Stale knowledge** -- superseded, duplicate, or contradicted entries flagged
   for retirement. The loop prunes, not only adds.

Proposes shared catalog promotions in BATCH (one PR with N artifacts). Applies
prompt caching for the stable reference context. Uses idempotency via content
hash to skip already-promoted or already-proposed items.

## Agent Prompt

When invoked as a scheduled agent or manually, execute this sequence:

---

### STEP 0 -- Skip-if-no-change check

```bash
# Check if anything changed since last run
LAST_RUN_FILE="$CLAUDE_DIR/session-state/.cross-repo-rollup-last-run"
LAST_RUN=0
[ -f "$LAST_RUN_FILE" ] && LAST_RUN=$(cat "$LAST_RUN_FILE" 2>/dev/null | tr -d '[:space:]')
NOW=$(date +%s)
# Check changes-log mtime
CHANGES_LOG="$CLAUDE_DIR/session-state/improvement-changes.log.md"
LESSONS_PENDING="$CLAUDE_DIR/session-state/lessons-pending.md"
CHANGED=0
for f in "$CHANGES_LOG" "$LESSONS_PENDING"; do
  if [ -f "$f" ]; then
    MTIME=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)
    [ "$MTIME" -gt "$LAST_RUN" ] && CHANGED=1
  fi
done
if [ "$CHANGED" -eq 0 ]; then
  echo "SKIP: no changes since last run ($LAST_RUN). Exiting."
  exit 0
fi
```

If nothing changed, return STATUS: SKIP with message "No changes since last run."

### STEP 1 -- Discover repos

Read `.claude/session-state/` for active sessions and their repo paths.
Read `MEMORY.md` for the repo index (project list).
Build a list of repo root paths to scan. Cap at 20 repos per run to avoid
memory exhaustion (per context-safety.md -- max 25 files per response).

### STEP 2 -- Scan per-repo knowledge (Haiku agents, parallel, max 10 concurrent)

For each repo in the list, dispatch a Haiku subagent:

```
You are scanning <repo-path> for recurring knowledge patterns.

Read these locations (skip if missing):
  <repo-path>/.jitneuro/rules/*.md  (filenames + first 20 lines each)
  <repo-path>/.jitneuro/engrams/*.md  (filenames + frontmatter)
  <repo-path>/.jitneuro/bundles/*.md  (filenames + first 10 lines each)

For each file found:
1. Extract a content hash: first 200 chars normalized (strip whitespace)
2. Record: { repo, path, type, title, content_hash, first_line }

Return as JSON array. No prose. Max 50 items.
```

Also scan the WS4 changes-log:
```
Read .claude/session-state/improvement-changes.log.md
Parse each line (format: <timestamp> | <type> | <summary> | <destination> | <session>)
Collect unique summaries grouped by destination prefix.
Return: { log_entries: N, unique_destinations: [...], recurring_summaries: [...] }
```

And the WS5 lessons-pending file:
```
Read .claude/session-state/lessons-pending.md
Extract lesson lines (non-header, non-empty).
For each lesson, produce a content hash (first 100 chars normalized).
Return: { lesson_count: N, lessons: [{hash, text, session, timestamp}] }
```

### STEP 3 -- Cross-repo pattern detection (Sonnet, single call)

Aggregate all subagent returns. Build the cross-repo knowledge inventory.

For each knowledge item:
1. Compute content hash (already in subagent output)
2. Check against `.claude/session-state/.rollup-promoted-hashes.txt` (append-only list of hashes already promoted or proposed) -- skip if present (IDEMPOTENCY)
3. Group items by semantic similarity: items with near-identical title / first-line across 2+ repos are RECURRING PATTERN candidates
4. Items that appear in the changes-log summary with 3+ occurrences are SKILL GAP candidates
5. Items where the content is contradicted by a newer item in the same repo are STALE candidates

Classify each candidate:
- PROMOTE: recurring pattern in 2+ repos, not already in the shared knowledge catalog
- SKILL_GAP: deterministic work done repeatedly that should be a runner/script
- STALE: outdated entry that should be retired
- SKIP: already promoted / already proposed / below threshold

### STEP 4 -- Propose shared catalog promotions (batch PR)

For PROMOTE candidates:

1. Draft the artifact content (rules/patterns/playbooks format per the shared catalog's conventions)
2. Assign a content hash to each draft
3. Append hashes to `.claude/session-state/.rollup-promoted-hashes.txt` (prevents duplicate PRs)
4. Write draft artifacts to a staging directory:
   `.claude/session-state/rollup-staging/<YYYY-MM-DD>/`
5. Generate a promotion proposal document:
   `.claude/session-state/rollup-staging/<YYYY-MM-DD>/PROPOSAL.md`

PROPOSAL.md format:
```
# Cross-Repo Rollup Proposal (WS6)
**Generated:** <ISO timestamp>
**Run covers:** <N repos>, <N log entries>, <N lessons>
**Candidates:** <N PROMOTE>, <N SKILL_GAP>, <N STALE>

## Promotions (<N>)

### <artifact-title>
- Source repos: <list>
- Proposed destination: <KnowledgeRoot>/<path>
- Evidence: seen in <repo1>/.jitneuro/rules/<file>, <repo2>/.jitneuro/rules/<file>
- Draft: rollup-staging/<date>/<filename>.md

## Skill Gaps (<N>)
- <description>: <occurrences> times in changes-log, manual work detected in <repos>
  Recommended: new skill or runner at <proposed path>

## Stale Entries (<N>)
- <repo>/.jitneuro/<path>: contradicted by <newer entry>. Recommend retirement.

## Skipped (<N>)
- <N> items already promoted/proposed (hash match)
- <N> items below threshold (< 2 repos)
```

6. Write a one-line entry to `.claude/session-state/improvement-changes.log.md`:
   `<ISO-timestamp> | Rollup | Proposed <N> promotions, <N> skill gaps, <N> stale | rollup-staging/<date>/PROPOSAL.md | cross-repo-rollup`

### STEP 5 -- Open shared catalog PR (if PROMOTE candidates exist)

**Only if the owner has authorized automated PRs in jitneuro.json `rollupAutoPR: true`.**
By default: write staging artifacts and proposal doc only. Owner opens the PR manually.

If authorized:
1. Ensure the knowledge catalog local clone is up to date (`git pull origin main`)
2. Create branch: `chore/rollup-<YYYY-MM-DD>`
3. Copy staging artifacts to correct catalog paths
4. Run the catalog's manifest rebuild script once for the full batch
5. Commit with standard format:
   ```
   chore(rollup): cross-repo pattern promotions <YYYY-MM-DD>

   ## What
   Promote <N> recurring patterns from per-repo .jitneuro/ to the shared knowledge catalog.

   ## Why
   WS6 cross-repo rollup detected these patterns in 2+ repos, meeting the
   catalog's promotion criteria "serves 2+ systems" threshold.

   ## Risk
   Knowledge-only changes. No code. Easily reverted if any pattern is wrong.

   ## Test plan
   - [x] manifest rebuild ran clean (method: direct script execution)
   - [x] all promoted artifacts have valid frontmatter (method: grep type: field)
   - [ ] Owner reviews PROPOSAL.md and approves each promotion

   ## Follow-ups
   - Review STALE entries from PROPOSAL.md
   - Consider SKILL_GAP items as new skill candidates
   ```
6. Open PR to the knowledge catalog targeting its main branch. Title: `chore(rollup): cross-repo pattern promotions <date>`
7. Add link to PROPOSAL.md in PR description

### STEP 6 -- Update last-run marker

```bash
date +%s > "$LAST_RUN_FILE"
```

### RETURN FORMAT

```
STATUS: OK
TOKENS: in=X out=X model=haiku+sonnet
FILES_CHANGED:
  - .claude/session-state/.rollup-promoted-hashes.txt (appended)
  - .claude/session-state/rollup-staging/<date>/PROPOSAL.md (created)
  - .claude/session-state/rollup-staging/<date>/<artifact>.md (created, one per promotion)
  - .claude/session-state/improvement-changes.log.md (appended)
  - .claude/session-state/.cross-repo-rollup-last-run (updated)
SUMMARY_DOC: .claude/session-state/rollup-staging/<date>/PROPOSAL.md
RESULT:
Scanned <N> repos. Found <N> PROMOTE, <N> SKILL_GAP, <N> STALE candidates.
<N> items skipped (already promoted).
Proposal: .claude/session-state/rollup-staging/<date>/PROPOSAL.md
PR: <url or "not created -- rollupAutoPR is false">
```

---

## Workflow Optimizations Applied (per spec)

- **Prompt caching:** The current-capabilities reference list (knowledge catalog INDEX.md)
  is passed with `ttl: "1h"` cache_control to reduce cost on repeated weekly runs.
- **Idempotency:** Every item carries a stable content hash. The promoted-hashes file
  is checked before acting -- no duplicate PRs, no duplicate staging files.
- **Skip-if-no-change:** Step 0 checks file mtimes against last-run marker. Zero cost
  on quiet weeks.
- **Batch the leaves:** Per-repo scanning uses parallel Haiku subagents (max 10
  concurrent per context-safety.md limits). Sonnet handles only the synthesis step.
- **One manifest rebuild:** `scripts/rebuild-manifest.py` runs once per batch PR,
  not once per artifact.

## Config Flags (in jitneuro.json scheduledAgents entry)

```json
{
  "name": "cross-repo-rollup",
  "interval": 10080,
  "enabled": false,
  "rollupAutoPR": false,
  "maxRepos": 20,
  "promoteThreshold": 2
}
```

- `rollupAutoPR`: false = write staging + proposal only, owner opens PR manually.
  true = agent opens the PR automatically (requires write access to the knowledge catalog).
- `maxRepos`: cap on repos scanned per run (memory safety, default 20).
- `promoteThreshold`: minimum number of repos a pattern must appear in to qualify
  for promotion (default 2 = "serves 2+ systems" per the catalog's promotion criteria).

## Output Locations

| File | Purpose |
|---|---|
| `.claude/session-state/improvement-changes.log.md` | WS4 changes-log (also used by WS8 dashboard) |
| `.claude/session-state/lessons-pending.md` | WS5 durable lessons from SessionEnd flush |
| `.claude/session-state/.rollup-promoted-hashes.txt` | idempotency registry (append-only) |
| `.claude/session-state/.cross-repo-rollup-last-run` | Unix timestamp of last successful run |
| `.claude/session-state/rollup-staging/<date>/PROPOSAL.md` | Promotion proposal for Owner review |
| `.claude/session-state/rollup-staging/<date>/<artifact>.md` | Staged promotion artifacts |
