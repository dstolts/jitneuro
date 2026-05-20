# Daily Improvement Scout Charter (WS7)

**Scheduled:** Daily (every 1440 minutes via jitneuro.json scheduledAgents)
**Model:** Haiku for all steps by default; optional Gemma pre-filter (config flag, OFF by default)
**Enabled by default:** false -- enable in jitneuro.json when external source monitoring is desired

## Purpose

Watch Anthropic best practices, release notes, and curated skill libraries for improvement
opportunities relevant to the master-orchestrator system. A single Haiku Scout subagent
owns the whole run -- it fetches, classifies, validates, and persists. The master dispatches
it once and reads the digest; the master is never inside the per-item loop.

External signals from this scout join internal LEARNING: signals in the same /learn queue.
One loop, two intake sources.

## Source List

Sources are defined in `sources.json` (sibling file). The charter reads that file at run
start, so sources can be added or removed without editing this charter.

## Queue File

Survivors are appended to:
  `.claude/session-state/improvement-opportunities.md`

Format per entry (one entry block per survivor):
```
---
timestamp: <ISO-8601>
source: <source name from sources.json>
source_url: <url>
finding: <one-sentence description of the finding>
category: <one of: technique | model | tool | cost | skill | deprecation | other>
content_hash: <first 80 chars of finding, normalized: lowercase, whitespace collapsed>
status: queued
---
```

The master triages this queue on its own cadence via /learn. The scout never interrupts.

## Agent Prompt

When invoked as a scheduled agent or manually, execute this sequence:

---

### STEP 0 -- Skip-if-no-change check

```bash
LAST_RUN_FILE="$HOME/.claude/session-state/.scout-last-run"
SOURCES_FILE="$(dirname "$0")/sources.json"
NOW=$(date +%s)
LAST_RUN=0
[ -f "$LAST_RUN_FILE" ] && LAST_RUN=$(cat "$LAST_RUN_FILE" 2>/dev/null | tr -d '[:space:]')
SOURCES_MTIME=$(stat -c %Y "$SOURCES_FILE" 2>/dev/null || stat -f %m "$SOURCES_FILE" 2>/dev/null || echo 0)
# If last run was within 23 hours AND sources.json has not changed since last run, skip.
ELAPSED=$((NOW - LAST_RUN))
if [ "$ELAPSED" -lt 82800 ] && [ "$SOURCES_MTIME" -le "$LAST_RUN" ]; then
  echo "SKIP: last run was ${ELAPSED}s ago (< 23h) and sources unchanged. Exiting."
  exit 0
fi
```

If skip condition fires, return STATUS: SKIP with message "Last run was less than 23h ago and sources unchanged."

### STEP 1 -- Read source list

Read `sources.json` from the charter's sibling directory. Parse the array of source objects.
Each source has: `name`, `url`, `description`, `fetch_type` (one of: rss | webpage | github_releases).

If sources.json cannot be read, abort with STATUS: BLOCKED and message "sources.json not found or unreadable."

### STEP 2 -- Fetch and summarize each source (Haiku, sequential, one source at a time)

For each source in the list:

1. Fetch the URL using the WebFetch tool (or Bash curl with a 10-second timeout).
2. Extract the most recent entries (last 7 days for feeds; last page for release notes; first 50 lines for static pages).
3. For each entry, produce a candidate record:
   - `source`: source name
   - `source_url`: entry URL or parent URL
   - `raw_text`: first 300 chars of the entry text (truncated)
   - `candidate_hash`: first 80 chars of raw_text normalized (lowercase, collapse whitespace)

4. Write all candidates from this source to the scratch file:
   `.claude/session-state/.scout-scratch-<ISO-date>.json`
   Append-mode (one JSON object per line, ndjson format).

Token ceiling: stop fetching additional entries for a source once total raw_text accumulated
for that source exceeds 8,000 chars. Log a `truncated: true` flag on the source.

On fetch failure (network error, 404, timeout): log `{ "source": "<name>", "error": "<msg>", "skipped": true }` to scratch file. Continue to next source. Do NOT abort the run.

### STEP 3 -- Dedup and classify (Haiku by default; optional Gemma pre-filter)

Read all candidate records from the scratch file.

**3a. Dedup against existing queue**

Read the queue file: `.claude/session-state/improvement-opportunities.md`
Extract all existing `content_hash:` values into a set.
For each candidate: compute its candidate_hash. If the hash already exists in the queue,
mark `duplicate: true` and skip.

**3b. Classify each non-duplicate candidate**

For each non-duplicate candidate, produce a classification:

Prompt template (Haiku):
```
INPUT:
  Source: <source name>
  Text: <raw_text (first 300 chars)>

TASK:
  Classify this finding as relevant or not relevant to an AI orchestration system
  using Claude Code. Relevant = introduces a new technique, model, tool, cost pattern,
  or deprecation that the system should know about. Not relevant = general news,
  non-Claude topics, marketing content, or already-known patterns.

OUTPUT:
  JSON object: { "relevant": true|false, "category": "<technique|model|tool|cost|skill|deprecation|other>", "finding": "<one sentence summary>" }

FAILURE-MODE:
  If you cannot determine relevance, output: { "relevant": false, "category": "other", "finding": "UNSURE" }
```

**3c. Optional Gemma pre-filter (only if `gemmaPreFilter: true` in config)**

If the Gemma flag is enabled, route each candidate through Gemma BEFORE the Haiku classify step.
Gemma is a pure stateless pre-filter; it never writes files and never holds state between calls.

Rules for Gemma calls (ALL must be followed):
- ONE candidate per call. Each call is fully independent.
- Use the structured INPUT/TASK/OUTPUT/FAILURE-MODE contract exactly as specified in
  `~/.claude/rules/local-inference-tier.md`.
- The Scout validates the JSON response schema before accepting it.
- On any unparseable response OR a response where `"finding": "UNSURE"`: fall back to Haiku
  for that candidate (do not retry Gemma for the same item).
- Track consecutive Gemma failures (network unreachable, unparseable, UNSURE):
  3 consecutive failures -> disable Gemma for the remainder of the run, log the disable event,
  fall back to Haiku for all remaining candidates.
- Ollama unreachable: immediately fall back to Haiku, log the event, do not attempt Gemma again
  this run.
- Gemma result: if `"relevant": false` with high confidence, skip the Haiku call (pre-filtered).
  If `"relevant": true` or confidence is not high: pass to Haiku for final classification.

This flag exists for high-volume growth scenarios, not day-one use. The cost saving at
~20-40 findings/day is ~$0.01-0.05/day -- Haiku-only is simpler and the recommended default.

### STEP 4 -- Write survivors to queue

For each candidate where classification returned `relevant: true` and `duplicate: false`:

Append an entry block to `.claude/session-state/improvement-opportunities.md`:

```
---
timestamp: <ISO-8601 UTC>
source: <source name>
source_url: <source_url>
finding: <finding from classification>
category: <category from classification>
content_hash: <candidate_hash>
status: queued
---
```

If the queue file does not exist, create it with a header:
```
# Improvement Opportunities Queue (WS7)
# Managed by: daily-improvement-scout
# Consumed by: /learn (master triage, owner-gated)
# Format: one entry block per survivor. Append-only; /learn marks status: reviewed.
```

Count of new entries written: N_written.

### STEP 5 -- Append changes-log entry

Write one line to `.claude/session-state/improvement-changes.log.md`:
```
<ISO-timestamp> | Scout | Queued <N_written> new findings, <N_skipped> duplicates, <N_irrelevant> irrelevant, <N_errors> source errors | .claude/session-state/improvement-opportunities.md | daily-improvement-scout
```

If improvement-changes.log.md does not exist, create it with:
```
# Improvement Changes Log (WS4/WS7/WS8)
# Append-only. One line per change event. Machine-readable: fields delimited by ' | '.
```

### STEP 6 -- Update last-run marker and clean scratch file

```bash
date +%s > "$HOME/.claude/session-state/.scout-last-run"
# Remove scratch file (raw findings are now in the queue; scratch is temporary)
rm -f "$HOME/.claude/session-state/.scout-scratch-<ISO-date>.json" 2>/dev/null || true
```

### RETURN FORMAT

```
STATUS: OK
TOKENS: in=X out=X model=haiku
FILES_CHANGED:
  - .claude/session-state/improvement-opportunities.md (appended, N new entries)
  - .claude/session-state/improvement-changes.log.md (appended)
  - .claude/session-state/.scout-last-run (updated)
RESULT:
Sources fetched: <N> (<N_errors> errors)
Candidates found: <N_total>
Duplicates skipped: <N_duplicates>
Irrelevant filtered: <N_irrelevant>
New entries queued: <N_written>
Gemma pre-filter: <enabled/disabled> (<N_gemma_used> calls, <N_gemma_fallbacks> fallbacks) [omit if flag is off]
Queue: .claude/session-state/improvement-opportunities.md
```

---

## Cost Caps and Abort Rules

- **Token ceiling per source:** 8,000 chars raw text (see Step 2). Prevents runaway on large feeds.
- **Abort on 3 consecutive source fetch failures:** if 3 sources in a row fail (network / 404 / timeout),
  abort the run, write a partial changes-log entry, return STATUS: PARTIAL.
- **Abort on Gemma 3 consecutive failures:** disable Gemma for the run, fall back to Haiku for remaining
  candidates (do NOT abort the whole run -- Haiku handles it).
- **No retry loops within a single run.** If a fetch fails, log and move on. Retries happen on the
  next scheduled run (24h later).
- **Prompt caching for classification context:** the classification criteria text (TASK block above)
  is stable across all candidates. Cache it with `ttl: "1h"` when submitting batches of candidates
  to Haiku to reduce call cost across the run.

## Workflow Optimizations Applied (per spec)

- **Haiku-only default:** ~$0.001-0.005/run at 20-40 findings/day. Gemma flag exists for scale.
- **Idempotency via content hash:** each finding's first-80-char normalized hash is checked
  against existing queue entries before writing. No duplicate queue entries.
- **Skip-if-no-change:** Step 0 checks elapsed time + sources.json mtime. Zero cost on repeat
  triggers within 23h of a successful run.
- **Prompt caching:** classification criteria text is stable; cache with `ttl: "1h"` across candidates.
- **Scratch file:** raw candidates written to a temp file during processing; removed on clean completion.
  Survives a crash (re-run picks up from scratch if it exists, skipping re-fetch -- future optimization).
- **No master interruption:** the scout appends to the queue; /learn (master-gated, owner-approved)
  triages the queue on its own cadence. The scout never sends an interrupt to the master session.

## Config Flags (in jitneuro.json scheduledAgents entry)

```json
{
  "name": "daily-improvement-scout",
  "interval": 1440,
  "enabled": false,
  "gemmaPreFilter": false,
  "tokenCeilingPerSource": 8000,
  "agent_charter": ".claude/agents/daily-improvement-scout/CHARTER.md",
  "description": "WS7: daily external source scout. Reads sources.json, fetches Anthropic changelog + release notes + blog + cookbook + skill libraries, classifies findings, appends relevant survivors to improvement-opportunities queue."
}
```

- `gemmaPreFilter`: false = Haiku-only (default). true = enable Gemma pre-filter (independent
  single-shot calls only; fallback to Haiku on any failure; 3 consecutive Gemma failures disables
  for the run).
- `tokenCeilingPerSource`: max raw_text chars to accumulate per source before truncating (default 8000).

## Output Locations

| File | Purpose |
|---|---|
| `.claude/session-state/improvement-opportunities.md` | WS7 queue -- survivors appended here; /learn triages |
| `.claude/session-state/improvement-changes.log.md` | WS4/WS7 changes-log (also WS8 dashboard data source) |
| `.claude/session-state/.scout-last-run` | Unix timestamp of last successful run (skip-if-no-change) |
| `.claude/session-state/.scout-scratch-<date>.json` | Temporary per-run scratch (deleted on clean completion) |

## Integration with /learn

The improvement-opportunities queue is the external intake channel for the /learn loop.
When /learn runs, it reads this queue alongside the Hub.md `## Lessons Learned` section.
Entries with `status: queued` are presented in the /learn approval table.
After owner approves or skips, /learn marks the entry `status: reviewed` (approved) or
`status: dismissed` (skipped) -- the queue is never deleted, only updated in place.
