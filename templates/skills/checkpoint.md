# Checkpoint

Save current working state before a context reset (/clear or /compact).
This preserves short-term memory so it can be restored by the /resume skill.

## When to Use
- Before `/clear` when switching tasks
- Before `/clear` when context is getting full
- At logical breakpoints (feature complete, sprint boundary)
- Before any destructive context operation

## Instructions

When invoked, perform these steps:

1. Determine the current session state:
   - What task am I working on?
   - Which bundles are currently loaded/active?
   - What files have been modified this session?
   - What decisions were made that haven't been persisted?
   - What are the immediate next steps?
   - Any key findings or discoveries worth preserving?

2. Write the state to `.claude/session-state.md`:
   ```markdown
   # Session State
   **Checkpointed:** [current date/time]

   ## Current Task
   [task name and brief status]

   ## Active Bundles
   - [bundle1.md] -- [why it's loaded]
   - [bundle2.md] -- [why it's loaded]

   ## Modified Files
   - [file:line] -- [what changed]

   ## Key Decisions
   - [decision and reasoning]

   ## Pending / Unresolved
   - [items awaiting input or follow-up]

   ## Next Steps
   1. [immediate next action]
   2. [following action]

   ## Key Findings
   - [discoveries worth preserving across /clear]
   ```

3. Confirm to the user:
   - "Checkpoint saved to .claude/session-state.md"
   - List active bundles and current task
   - "Safe to /clear. Use /resume to reload."

## Important
- Do NOT update MEMORY.md during checkpoint (that's long-term memory, updated at session end)
- Do NOT modify any code files
- If session-state.md already exists, overwrite it (it's short-term, not versioned)
- Keep the checkpoint concise -- this will be re-read after /clear, so density matters
