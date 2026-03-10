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
- **Guardrails override goals.** If a task conflicts with a guardrail, the guardrail wins. Never bypass a guardrail to complete a task. Surface the conflict and ask the project owner.
- [Rule 1: e.g., never push to main without approval]
- [Rule 2: e.g., run tests before committing]
- [Rule 3: e.g., ASCII only in all output]

## JitNeuro Mode
<!-- Choose ONE mode. Delete the other. -->

<!-- OPTION A: SINGLE-REPO MODE (enterprise / isolated)
     All JitNeuro files stay inside this repo. No cross-repo access.
     Install with: ./install.sh project -->
JitNeuro is scoped to THIS REPO only.
- Read/write: `.claude/` within this repo
- Read/write: MEMORY.md auto-memory
- DO NOT read or write files outside this repository
- DO NOT access parent workspace .claude/ directories

<!-- OPTION B: MULTI-REPO MODE (solo dev / small team)
     Shared JitNeuro at workspace level. Cross-repo visibility.
     Install with: ./install.sh workspace -->
<!--
From any repo, Claude has full read/write access to:
- `[workspace]/.claude/bundles/` -- shared domain knowledge
- `[workspace]/.claude/engrams/` -- shared project context
- `[workspace]/.claude/session-state/` -- shared session checkpoints
- `[workspace]/.claude/context-manifest.md` -- bundle index and routing
- MEMORY.md auto-memory (routing weights, project index)
-->

## Context Loading
- Bundles: `.claude/bundles/` (loaded on-demand by orchestrator)
- Engrams: `.claude/engrams/` (per-project context, loaded per task)
- Manifest: `.claude/context-manifest.md` (bundle index + routing)
- Session state: `.claude/session-state/` (one file per named session)
- Memory: Check MEMORY.md routing weights for task-to-bundle mapping

## Compact Instructions
When compacting, always preserve:
- Active bundle list from session-state.md
- All modified file paths with line numbers
- Full task list with status (all known tasks, not just current)
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
| `.claude/bundles/` | Domain knowledge bundles |
| `.claude/engrams/` | Per-project deep context |
| `.logs/` | Conversation logs (when enabled) |
