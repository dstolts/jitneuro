# Save

Save current working state before a context reset (/clear or /compact).
This preserves short-term memory so it can be restored by the /load skill.

## When to Use
- Before `/clear` when switching tasks
- Before `/clear` when context is getting full
- Before `/compact` as insurance against aggressive compression
- At logical breakpoints (feature complete, sprint boundary)
- Before any destructive context operation

## How It Works
Checkpoint writes to DISK (`.claude/session-state/<name>.md`), which survives
both `/clear` and `/compact`. After `/clear`, use `/load <name>` to reload.
After `/compact`, the session file serves as a safety net -- if compaction
dropped something important, the full state is still on disk.

```
/save blog-comments-api    <-- saves to disk
/clear                           <-- wipes context (disk untouched)
/load blog-comments-api        <-- reads from disk, reloads bundles
```

## Instructions

When invoked as `/save <session-name>`:

1. **Determine session name:**
   - If user provided a name, use it (lowercase, hyphens, task-descriptive)
   - If no name provided, suggest one based on current work and ASK to confirm
   - Name should describe the TASK, not the repo (cross-repo sessions are normal)
   - Good: `firstmover-stripe-checkout`, `blog-comments-api`, `aibm-dealer-research`
   - Bad: `jitai`, `session1`, `work`
   - **Multiple tasks in session:** If the session touched more than one distinct task,
     ask ONE question: "This session touched [task A] and [task B]. Save as one
     checkpoint or separate?" Then create accordingly.

2. **Gather current session state:**
   - What task am I working on?
   - Which repos are involved? (cross-repo is common)
   - Which bundles are currently loaded/active?
   - What files have been modified this session?
   - What decisions were made that haven't been persisted?
   - What are the immediate next steps?
   - Any key findings or discoveries worth preserving?

3. **Write state to `.claude/session-state/<session-name>.md`:**
   - Create `.claude/session-state/` directory if it doesn't exist
   ```markdown
   # Session: <session-name>
   **Checkpointed:** [current date/time]

   ## Current Task
   [task name and brief status]

   ## Repos Involved
   - [repo path] -- [what's happening here]

   ## Active Bundles
   - [bundle1.md] -- [why it's loaded]
   - [bundle2.md] -- [why it's loaded]

   ## Modified Files
   - [repo/file:line] -- [what changed]

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

4. **Confirm to user:**
   - "Checkpoint saved to .claude/session-state/<session-name>.md"
   - List repos involved and current task
   - "Safe to /clear. Use `/load <session-name>` to reload."

## Size Guidance
- Target: 30-60 lines. Enough to fully resume, not a session transcript.
- Under 30 lines: probably missing something (decisions? findings? file paths?)
- Over 80 lines: too verbose. Summarize, don't replay.
- Claude decides what matters based on the actual session. No rigid rules.

## Important
- Do NOT update MEMORY.md, bundles, or engrams during save (that's /learn's job)
- Do NOT modify any code files
- If the session file already exists, UPDATE it (preserve history of previous checkpoints as context)
- Session names are cross-repo by design -- one task may touch multiple repos
- After saving, suggest: "Run `/learn` first if you want to persist any learnings from this session."
