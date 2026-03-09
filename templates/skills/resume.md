# Resume

Restore working state after a context reset (/clear).
This reloads short-term memory saved by the /checkpoint skill.

## When to Use
- Immediately after `/clear` to continue previous work
- At session start when picking up from a previous session
- After accidental context loss

## Instructions

When invoked, perform these steps:

1. Read `.claude/session-state.md`
   - If it doesn't exist, report: "No checkpoint found. Starting fresh."
   - If it exists, continue to step 2.

2. Read the active bundles listed in session-state.md:
   - For each bundle listed, read `.claude/bundles/[bundle-name].md`
   - Do NOT load bundles that aren't listed (context conservation)

3. Read `.claude/context-manifest.md` for the full bundle index
   - This provides awareness of available bundles without loading them all

4. Report to the user:
   ```
   Resumed from checkpoint ([checkpoint date])
   Task: [current task]
   Loaded bundles: [list]
   Available bundles: [list of unloaded]
   Next steps:
   1. [from session-state]
   2. [from session-state]
   ```

5. Continue working from where the checkpoint left off.

## Important
- Load ONLY the bundles listed in session-state.md
- If the user wants different bundles, they can request them explicitly
- Do NOT re-read files that aren't needed for the current task
- Keep the main context thin -- use agents for heavy work
- If session-state.md is stale (more than a day old), mention it to the user
