# Orchestrate

Route tasks to subagents with the right context bundles. Subagents run inside
your current Claude Code session (using the Agent tool) -- they are NOT separate
sessions. Each subagent gets its own isolated context window, works with only the
bundles it needs, and returns a compressed summary to your main conversation.

No manual /clear or reload needed. No new sessions to open.

## When to Use
- Any task that can be delegated to a subagent
- When working on multiple domains in one session
- When context is getting heavy and you want to keep the main conversation thin
- When parallel execution would be faster

## Instructions

When a task is received:

1. **Classify the task** -- determine which domain(s) it touches:
   - Read `.claude/context-manifest.md` for available bundles
   - Check routing weights in the manifest (or MEMORY.md) for known patterns
   - If no routing weight exists, infer from the task description

2. **Decide execution strategy:**

   a. **Single agent** -- task touches one domain:
      - Launch agent with prompt:
        "Read [bundle path(s)]. Then: [task description]"
      - Agent works in isolated context with only relevant bundles

   b. **Parallel agents** -- task touches independent domains:
      - Launch multiple agents simultaneously
      - Each gets its own bundle(s)
      - Results merge back into main context as summaries

   c. **Sequential agents** -- task has dependencies:
      - Launch agent 1, get result
      - Feed result into agent 2's prompt with its own bundles
      - Chain continues until complete

   d. **Main context** -- task is simple or needs conversation history:
      - Load bundle directly into main context (only if small and essential)
      - Use for tasks that need back-and-forth with the user

3. **Launch agent(s)** with outcome-driven prompts:
   ```
   Context:
   - [path/to/bundle1.md]
   - [path/to/bundle2.md]

   Outcome: [what should be true when you're done -- not how to get there]
   Scope: [which files/modules are in play]
   Guardrails: Follow all rules in .claude/rules/. Key constraints: [any specific ones]

   Return format:
   - First line: STATUS: OK, BLOCKED, or PARTIAL
   - List any files created or modified (full paths)
   - If you write a detailed report, include its path as SUMMARY_DOC
   - Keep the result under 15 lines
   ```
   The agent decides HOW to achieve the outcome. Guardrails (no new tech, reuse components,
   fix root cause, etc.) constrain the approach without micromanaging implementation.

4. **Process results:**
   - Read status line first (OK / BLOCKED / PARTIAL)
   - Collect file paths from FILES_CHANGED for commit/PR scope
   - Only read SUMMARY_DOC if you need detail beyond the status and file list
   - If BLOCKED: answer the question and re-dispatch via SendMessage
   - Update session-state.md with results
   - If new routing patterns discovered, note for MEMORY.md update
   - Report to user: what was done, files changed, what's next

5. **Update routing weights** if a new pattern emerged:
   - "Task type X needed bundles [A, B] -- adding to routing weights"
   - Update context-manifest.md or MEMORY.md at session end

## Routing Decision Table

| Signal | Strategy |
|--------|----------|
| Task mentions specific files/domain | Load that domain's bundle |
| Task is exploratory/research | Agent with broad context, return summary |
| Task is implementation | Agent with specific bundle + file paths |
| Task needs user input mid-way | Main context with minimal bundle |
| Task is multi-repo | Parallel agents, one per repo |
| Unknown domain | Read manifest, infer, launch agent |

## Important
- Main context should stay THIN -- summaries only
- Never load all bundles into main context "just in case"
- When in doubt, use an agent (isolated context is always safer)
- Failed agent? Retry with additional bundles, not more main context
- Update routing weights after discovering new co-activation patterns
