# Load

Restore working state after a context reset (/clear).
This reloads short-term memory saved by the /save skill.

## When to Use
- Immediately after `/clear` to continue previous work
- At session start when picking up from a previous session
- After accidental context loss

## Instructions

When invoked as `/load <session-name>`:

1. **Determine which session to resume:**
   - If user provided a name: read `.claude/session-state/<session-name>.md`
   - If no name provided: list all files in `.claude/session-state/` with their
     checkpoint dates and current task summaries. Ask user to pick one.
   - If directory doesn't exist or is empty: "No checkpoints found. Starting fresh."

2. **Read the session state file:**
   - Load the full session state
   - Note which repos are involved (cross-repo sessions are normal)
   - Note which bundles were active

3. **Read the active bundles** listed in the session state:
   - For each bundle listed, read `.claude/bundles/[bundle-name].md`
   - Do NOT load bundles that aren't listed (context conservation)

4. **Read `.claude/context-manifest.md`** for the full bundle index
   - This provides awareness of available bundles without loading them all

5. **Report to user:**
   ```
   Loaded: <session-name> (checkpointed [date])
   Task: [current task]
   Repos: [list of repos involved]
   Loaded bundles: [list]
   Available bundles: [list of unloaded]
   Next steps:
   1. [from session-state]
   2. [from session-state]
   ```

6. Continue working from where the checkpoint left off.

## Listing Sessions

When invoked as `/load` with no name, show:

```
Active sessions:
  firstmover-stripe-checkout   (2h ago)  Sprint-FirstMover-Checkout, US-003
  blog-comments-api            (1d ago)  Sprint-BlogComments-001, testing
  aibm-dealer-research         (3d ago)  Dealer script Phase 2 research
Pick one, or start fresh.
```

## Important
- Load ONLY the bundles listed in the session state
- If the user wants different bundles, they can request them explicitly
- Do NOT re-read files that aren't needed for the current task
- Keep the main context thin -- use agents for heavy work
- If session state is stale (more than 3 days old), mention it and ask if still relevant
- Session states are cross-repo -- repos involved are listed explicitly
