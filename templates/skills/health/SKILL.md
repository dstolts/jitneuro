---
type: skill
purpose: Standalone memory system diagnostic reporting line counts, stale sessions, and missing engrams.
tags: [health, memory, diagnostic, sessions, engrams, bundles]
scope: public
departments: [all]
status: canonical
read_when: When diagnosing memory system bloat, stale sessions, or oversized engrams and bundles.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /health

Standalone memory system diagnostic. Checks component sizes and surfaces warnings.

## Modes

### Quick mode (default)
5 reads. Reports status for each component without deep analysis:
1. MEMORY.md line count
2. Active session count (from sessions.json)
3. Engram count + size summary
4. Bundle count + size summary
5. Stale session count (sessions older than 7 days)

### Deep mode: `/health deep`
50+ reads. Dispatches subagent to scan all components and produce detailed report.

## Size thresholds

| Component | OK | WARN | CRITICAL |
|-----------|-----|------|----------|
| MEMORY.md | < 170 lines | 170-199 | 200+ |
| Bundles | < 230 lines each | 230-279 | 280+ |
| Engrams | < 230 lines each | 230-279 | 280+ |
| Active sessions | < 10 | -- | 10+ |
| Session age | < 7 days | 7-14 days (stale) | 14+ days (expired) |

## Output format

```
MEMORY HEALTH CHECK
===================
MEMORY.md:    142 lines [OK]
Sessions:     3 active, 1 stale [WARN]
Engrams:      12 files (avg 98 lines) [OK]
Bundles:      8 files (1 over limit: tech-stack.md 285 lines) [WARN]

Action needed:
  - Archive stale session: jitai-sprint (14 days old)
  - Split bundle: tech-stack.md (285 lines)
```

## What this does NOT do

Does not modify any files. Read-only diagnostic.
