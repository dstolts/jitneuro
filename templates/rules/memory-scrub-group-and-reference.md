---
type: rule
purpose: Standard process for scrubbing a memory manifest (MEMORY.md or any index loaded into context each session) that exceeds its load cap -- move the stale cluster into a grouped archive file and leave a one-line reference pointer; never delete durable knowledge and never inline-compress backing detail into the manifest.
read_when: When any session-loaded manifest (MEMORY.md or equivalent) approaches or exceeds its byte or line cap -- skipping causes the runtime to silently truncate the newest entries, losing the most current knowledge.
tags: [memory, scrub, archive, manifest, group-and-reference, recursive-improvement]
scope: public
last_evaluated: 2026-06-03
---

# Memory Scrub: Group-and-Reference (Standard Process)

## Rule

When a memory manifest file (e.g. `MEMORY.md`, or any index loaded into context each session) approaches or exceeds its HARD load cap, scrub it by **group-and-reference**:

1. Identify the lowest-frequency cluster of entries -- typically an older dated arc (a past launch, a finished build phase, a superseded initiative).
2. Create a grouped archive file alongside the manifest: `memory_archive_<topic-or-date>.md`. Give it a short header (what it contains, the date it was grouped, when a session should load it). MOVE the cluster's entries into it verbatim.
3. In the manifest, REPLACE the moved cluster with a SINGLE one-line reference pointer (a callout naming the archive file + when to load it).
4. Verify the manifest is back under the cap. The archived detail remains full-fidelity and discoverable via its pointer + grep.

## The cap is BYTES first, lines second

Claude Code truncates an over-cap manifest by **total byte size** (observed load cap ~24.4KB) as well as by **line count** (~200 lines). Whichever limit is hit first triggers truncation, and truncation drops the BOTTOM of the file -- usually the NEWEST entries.

A manifest can be UNDER the 200-line cap and still be truncated because its bytes are over the limit. This happens when index entries have grown into multi-sentence summaries. Two complementary moves bring it back under:

- **Group-and-reference** older/low-frequency clusters into `memory_archive_*.md` (removes whole entries).
- **Tighten over-long index hooks** back to a single short line. For an INDEX/manifest, each entry is a POINTER whose full detail already lives in the backing `memory_*.md` file it links to; restoring a bloated entry to a one-line hook loses nothing. (This is NOT the inline-compress violation below -- that violation is about compressing detail that has NO backing file.)

## Why

- The load cap truncates the BOTTOM of the file -- usually the NEWEST entries. An over-cap manifest silently drops the most recent learnings. Scrubbing older/lower-frequency clusters protects new knowledge.
- Group-and-reference loses nothing: archived clusters stay complete and grep-able; the manifest stays thin and fully loadable.
- This is the manifest -> category-file -> detail-file architecture applied to time/topic clusters.

## What violates this rule

- DELETING stale entries (loses durable knowledge).
- INLINE-COMPRESSING detail that has no backing file into terse fragments inside the manifest (degrades content, not recoverable to full fidelity). Note: shortening an index hook whose detail lives in a linked backing file is NOT this violation -- it is the intended thin-manifest form.
- Letting the manifest sit over the cap (newest entries silently truncated).

## Reference example

2026-06-01: `MEMORY.md` was 199 lines but 40.4KB -- under the line cap yet far over the ~24.4KB byte cap, so the harness was truncating the newest entries. The ~30-entry 2026-04 launch-hardening + content/Viral-pipeline cluster was moved to `memory_archive_2026_04_launch_and_content.md` with a one-line pointer, and over-long multi-sentence index hooks were tightened back to one-line pointers (detail intact in each backing `memory_*.md`); the manifest returned under cap and the newest directives loaded again.

## Cross-references

- Memory-architecture spec (manifest -> category-file -> detail-file pattern; per-component line caps).
- `recursive-improvement` / `/learn` process (this is the scrub step of memory maintenance).
- `rules/wip-drafts-lifecycle.md` (this rule was promoted from WIP-Drafts).

_Origin: Owner directive 2026-06-01 (a multi-agent E2E session); promoted to canonical 2026-06-01 (Knowledge session) after Owner noted the process should already have been a rule._
