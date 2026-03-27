# Lessons Capture (Real-Time to Hub.md)

When a correction, new pattern, preference, or discovery is identified during work,
append one line to the current session's Hub.md under a `## Lessons Learned` section.

## Trigger

Any of these events during normal work:
- Owner corrects a behavior or assumption
- A new convention or pattern is established
- A cross-project fact is discovered
- A routing weight, bundle, or engram gap is identified
- An anti-pattern is flagged by friction detection

## Action

Append one line to Hub.md immediately. No separate step, no user prompt.

```markdown
## Lessons Learned
- [type] one-line description with enough context for /learn to process later
```

**Types:** `feedback` (correction/preference), `project` (architecture/convention),
`user` (workflow/habit), `reference` (external fact/integration).

## Rules

1. Capture inline -- do not stop work or ask permission to log a lesson.
2. One line per lesson. If it needs more, /learn will expand when it processes.
3. If `## Lessons Learned` section does not exist in Hub.md, create it.
4. If no Hub.md exists for the session, create the section in the fallback
   location: `.claude/session-state/lessons.md`.
5. Do not duplicate -- grep the section before appending.
6. /learn reads this section, deduplicates against session scan, persists to
   the correct long-term location, then clears it with a processed marker.
7. Between /learn runs, lessons accumulate. They survive crashes and compaction.
