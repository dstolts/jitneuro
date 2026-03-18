# AFK Pattern -- Autonomous Task Execution

## What It Is

When the user signals they're stepping away ("AFK", "keep going", "I'll be back",
"work through the list"), Claude switches to autonomous execution mode: it works
through the task list without stopping for confirmation on GREEN/YELLOW zone actions.

This is one of JitNeuro's most powerful patterns. It turns Claude from an interactive
assistant into an autonomous worker that maximizes output while the user is away.

## How It Works

1. **User signals AFK** -- any phrase indicating they're stepping away
2. **Claude checks the task list** -- TodoWrite, session state pending items, or explicit list
3. **For each task:**
   - GREEN zone action? Execute immediately, move to next.
   - YELLOW zone action? Execute, log what was done for review.
   - RED zone action? Skip, flag for user, move to next GREEN/YELLOW task.
   - Blocked? Skip, document the blocker, move to next.
   - Need user input? Skip, document the question, move to next.
4. **When all tasks are done or all remaining are blocked/RED:** Stop and summarize.
5. **User returns:** Claude presents a summary of what was done, what's blocked, what needs approval.

## Trust Zone Integration

AFK mode respects the same trust zones as interactive mode:

| Zone | AFK Behavior |
|------|-------------|
| GREEN | Execute freely, log results |
| YELLOW | Execute, flag in summary for user review |
| RED | NEVER execute autonomously -- skip and flag |

This is critical. AFK mode does NOT elevate trust. Pushing to main is still RED
even if the user said "do everything." The trust zone system protects against
autonomous actions the user didn't intend to authorize.

## AFK Handoff Checklist

Before going AFK, the user should ensure:
- [ ] Task list is clear and ordered (TodoWrite or explicit list)
- [ ] Feature branch is checked out (not main)
- [ ] No RED zone actions are in the critical path
- [ ] Session state is saved (/save) in case of context compaction

After returning:
- [ ] Review the summary of completed work
- [ ] Approve any YELLOW zone actions that were flagged
- [ ] Address any blocked items or RED zone requests
- [ ] Run /save to checkpoint the new state

## Trigger Phrases

These phrases (or similar) activate AFK mode:
- "AFK" / "I'll be back" / "stepping away"
- "Keep going" / "keep working" / "work through the list"
- "Don't stop" / "don't wait for me"
- "Execute all" / "run the plan" / "you can proceed with everything"

## What AFK Mode Is NOT

- It is NOT permission to skip quality gates (tests still run, criteria still checked)
- It is NOT permission to escalate trust zones (RED stays RED)
- It is NOT permission to make architectural decisions without the plan being approved first
- It is NOT infinite -- if context compaction fires, Claude should /save and stop

## Example Flow

```
User: "Here's the task list. I'm AFK for 30 minutes, work through it."

Claude:
1. [DONE] Fix the login validation bug (GREEN -- code change + test)
2. [DONE] Update API docs for /auth endpoint (GREEN -- docs)
3. [DONE] Add rate limiting to /signup (YELLOW -- new middleware, flagged for review)
4. [SKIPPED] Push to main (RED -- needs your approval)
5. [BLOCKED] Deploy to production (blocked by #4)
6. [DONE] Update CHANGELOG.md (GREEN -- docs)

Summary: 4 completed, 1 skipped (RED), 1 blocked.
Waiting on: push to main approval (#4), then deploy (#5).
```

## Relationship to FR-105 (Autonomous Orchestration)

AFK mode is the interactive version of what FR-105 will formalize. Today, AFK works
within a single session -- the user says "go" and Claude works until done. FR-105
extends this to scheduled and event-driven sessions where no human is present at all.

The trust zone model, task list pattern, and RED zone guardrails are the same in both.
AFK mode is the proving ground for the autonomous orchestration architecture.
