# [Project Name]

<!--
  BRAINSTEM TEMPLATE

  This is a minimal CLAUDE.md template designed for JitNeuro.
  Target: 30-40 lines. Only include what Claude MUST know at all times.
  Everything else goes in bundles, rules, or commands.

  Replace bracketed content with your project specifics.
-->

## Identity
[One line: what this project is and does]

## Critical Rules
<!-- Only rules that apply to EVERY task, regardless of domain -->
- [Rule 1: e.g., never push to main without approval]
- [Rule 2: e.g., run tests before committing]
- [Rule 3: e.g., ASCII only in all output]

## Context Loading
- Bundles: `.claude/bundles/` (loaded on-demand by orchestrator)
- Manifest: `.claude/context-manifest.md` (bundle index + routing)
- Session state: `.claude/session-state/` (one file per named session)
- Memory: Check MEMORY.md routing weights for task-to-bundle mapping

## Compact Instructions
When compacting, always preserve:
- Active bundle list from session-state.md
- All modified file paths with line numbers
- Current task name and status
- Pending decisions awaiting user input
- Critical rules from this file
Drop: exploratory reads, verbose tool outputs, completed subtask details

## Conversation Logging
When conversation_log is "on" in session-state.md:
- FIRST action on every user message: append their prompt to the log file
- If previous entry has no Response line, write that response FIRST
- After completing work, append response summary to current entry
- See `.claude/commands/conversation-log.md` for full protocol
- Toggle: `convlog on <session-name>` / `convlog off` / `convlog status`

## Key Paths
<!-- Only paths Claude needs constantly. Domain paths go in bundles. -->
| Path | Purpose |
|------|---------|
| `.claude/context-manifest.md` | Bundle index and routing |
| `.claude/session-state/` | Session checkpoints (one per task) |
| `.claude/bundles/` | Context bundles directory |
| `.logs/` | Conversation logs (when enabled) |
