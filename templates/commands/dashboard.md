# Dashboard

Aggregate all NEEDS DAN items, pending approvals, and blockers into one
prioritized view. Single triage list so Dan can make decisions in one pass.

## When to Use
- Start of day to see what needs attention
- When switching contexts to find the highest-priority item
- Before a planning session to review open items
- When Dan asks "what needs my attention"

## Instructions

When invoked as `/dashboard`:

### Step 1: Gather Sources

Read these files (in parallel where possible):

1. `.claude/bundles/active-work.md` -- NEEDS DAN section + current sprints
2. `.claude/session-state/` -- all session files, check for stale/pending items
3. Scan for `.HUB/Hub.md` or `.HUB/*.md` files in active repos:
   - D:\Code\Automation\.HUB\
   - D:\Code\AIFieldSupport-API\.HUB\
   - D:\Code\jitai\.HUB\
   - D:\Code\FirstMover\.HUB\ (if exists)
   - Check any other repos listed in active-work that might have hub files

### Step 2: Categorize Items

Group all found items into categories:

| Category | Priority | Description |
|----------|----------|-------------|
| BLOCKED | Highest | Items that cannot proceed without Dan's input |
| APPROVAL | High | Plans, PRs, pushes waiting for Dan's go-ahead |
| DECISION | Medium | Choices Dan needs to make (architecture, priority, scope) |
| REVIEW | Medium | Work completed that needs Dan's eyes |
| INFO | Low | Status updates Dan should know about |

### Step 3: Present Dashboard

```
== Dashboard == [date]

BLOCKED (cannot proceed):
  1. [item] -- [source file] -- [what's needed]

APPROVAL NEEDED:
  2. [item] -- [source file] -- [what to approve]
  3. [item] -- [source file] -- [what to approve]

DECISIONS:
  4. [item] -- [source file] -- [options]

REVIEW:
  5. [item] -- [source file] -- [what to review]

INFO:
  - [status update]
  - [status update]

Active sprints: [count]
Open sessions: [count] ([stale count] stale)
Total items: [count]
```

### Step 4: Offer Quick Actions

After presenting the dashboard:
"Pick a number to focus on, or 'all' to work through the list."

If Dan picks a number, load the relevant context (bundle, session, hub file)
and present the specific item with enough detail to make a decision.

## Important
- This is READ-ONLY. Never modifies any files.
- Present items in priority order (BLOCKED first).
- Include source file paths so Dan can find the original context.
- Keep descriptions to one line each -- detail on demand.
- If no items found: "Dashboard clear. No items need your attention."
- Hub files may not exist for all repos -- skip gracefully.
