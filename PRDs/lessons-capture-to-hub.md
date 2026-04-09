# User Story: Capture Learn Candidates to Hub.md in Real-Time

**Created:** 2026-03-27
**Priority:** 85/100
**Status:** Ready for execution
**Handoff:** Agent-ready

## Problem

/learn runs at the END of a session. If the session crashes, context compacts unexpectedly, or the user forgets to run /learn, all lessons from that session are lost. The learnings existed in conversation context -- which is volatile.

Today's session is a perfect example: 10 learnings identified, but if context had reset before /learn ran, all 10 would have been gone.

## Solution

As learn candidates are identified during the session, write them immediately to Hub.md under a `## Lessons Learned` section. This is durable -- it survives /clear, crashes, and compaction. When /learn runs, it reads this section, processes the candidates, persists them to the right locations (rules/, memory/, engrams/), and clears the section.

## How It Works

### During the session (real-time capture)

When Claude identifies something worth persisting (correction, new pattern, preference, discovery), append it to Hub.md immediately:

```markdown
## Lessons Learned
- [feedback] CONVERGE step should allow merging approaches, not just picking one winner
- [feedback] /learn is day 1 core command, more important than /status
- [project] jitneuro v0.4.0 shipped: /divergent, /help, scheduled agents, sub-orchestrator
- [feedback] Smart agents should self-loop, only return to master when action needed
```

One line per candidate. Type prefix in brackets. Enough context to process later.

### When /learn runs

1. Read Hub.md `## Lessons Learned` section
2. Use these as ADDITIONAL input alongside the session scan (Step 1 of /learn)
3. Candidates from Hub.md that were already captured by the session scan = deduplicate
4. Candidates from Hub.md that the session scan missed (because context was lost) = rescued
5. After /learn completes and changes are approved, clear the `## Lessons Learned` section from Hub.md
6. Leave a marker: `## Lessons Learned\n(Processed by /learn on 2026-03-27)`

### When context resets WITHOUT /learn

The lessons stay in Hub.md. Next session loads Hub.md, sees unprocesed lessons, and either:
- /learn processes them (user runs /learn)
- They remain visible as a reminder until addressed

## Acceptance Criteria

### AC-1: Real-time capture rule
- [ ] Create rule `~/.claude/rules/lessons-capture.md` (or add to existing rule)
- [ ] Rule: when a correction, new pattern, or discovery is identified during work, append one line to Hub.md `## Lessons Learned` section
- [ ] Capture happens inline with normal work -- no separate step, no user prompt
- [ ] Each entry: `- [type] one-line description` where type is feedback, project, user, reference

### AC-2: /learn integration
- [ ] Update learn.md Step 1 to also read Hub.md `## Lessons Learned`
- [ ] Deduplicate against session scan results
- [ ] After approved changes are written, clear the section (leave processed marker)
- [ ] If /learn finds lessons in Hub.md from a PREVIOUS session (context was lost), process them -- this is the rescue path

### AC-3: Housekeeper integration
- [ ] The housekeeper agent (from watcher-agent-architecture PRD) should include lessons capture in its Hub.md sync
- [ ] If learn candidates exist in conversation context but NOT yet in Hub.md, the housekeeper writes them during its UPDATE_HUB cycle

### AC-4: /save integration
- [ ] /save already syncs Hub.md. Lessons Learned section persists naturally.
- [ ] Verify: lessons survive /save -> /clear -> /load cycle

## Example Flow

```
1. User corrects Claude: "don't mock the database"
2. Claude fixes behavior AND appends to Hub.md:
   ## Lessons Learned
   - [feedback] Integration tests must hit real DB, not mocks (prior incident: mock/prod divergence)
3. Work continues for 2 hours
4. User runs /learn
5. /learn reads Hub.md lessons + scans session
6. Proposes: create feedback_no_db_mocks.md
7. User approves
8. /learn writes the file, clears Hub.md lessons section
```

```
CRASH SCENARIO:
1. User corrects Claude: "always use UTC"
2. Claude appends to Hub.md: - [feedback] Always use UTC timestamps
3. Context compacts unexpectedly
4. Session recovers, loads Hub.md
5. Lesson is still there -- not lost
6. User runs /learn, lesson is processed
```

## Notes
- This is a lightweight append operation -- one line to Hub.md. Zero overhead.
- The Lessons Learned section is a staging area, not permanent storage. /learn moves items to their proper locations.
- If Hub.md doesn't exist yet for the session, this is another reason to create it early (or the lesson goes to a fallback location like `.claude/session-state/lessons.md`).
