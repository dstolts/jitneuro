# Claude Code Feature Requests (Created / Upvoted)
**Last Updated:** 2026-03-28

All items on this list have been upvoted. Please do the same.

## Autonomous Execution

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 1 | [#33783](https://github.com/anthropics/claude-code/issues/33783) | /never-stop mode for autonomous execution | Core pain point -- Claude stops between tasks |
| 2 | [#37386](https://github.com/anthropics/claude-code/issues/37386) | Claude walks back correct, user-approved fixes based on self-doubt | Interrupts approved autonomous work |

## Rules Compliance

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 3 | [#28158](https://github.com/anthropics/claude-code/issues/28158) | CLAUDE.md instructions systematically ignored / suspected model substitution | Rules defined, acknowledged, then violated |
| 4 | [#8059](https://github.com/anthropics/claude-code/issues/8059) | Claude violates rules clearly defined in CLAUDE.md (by its own admission) | LOCKED -- cannot upvote |
| 5 | [#12068](https://github.com/anthropics/claude-code/issues/12068) | CLAUDE.md "no auto-commit" rule violated on session resume | Rules lost after context summary/compaction |

## Hooks & Session

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 6 | [#25642](https://github.com/anthropics/claude-code/issues/25642) | Expose session ID as $CLAUDE_SESSION_ID env var | Eliminates JSON parsing in heartbeat hook (we coded around limitation) |
| 7 | [#38390](https://github.com/anthropics/claude-code/issues/38390) | Expose session_id to conversation context | Session ID visible inside conversation, not just hooks |
| 8 | [#28221](https://github.com/anthropics/claude-code/issues/28221) | PostTask hook -- fire when background agent completes | Needed for deploy monitoring + scheduled agent re-spawn |
| 9 | [#34431](https://github.com/anthropics/claude-code/issues/34431) | SessionStart:resume hook payload missing 'cwd' field | Hook payload completeness |

## Context & Compaction

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 10 | [#9796](https://github.com/anthropics/claude-code/issues/9796) | Context compaction erases .claude/project-context.md instructions | CLAUDE.md rules lost after compaction (we coded around limitation) |
| 11 | [#33088](https://github.com/anthropics/claude-code/issues/33088) | PreCompact hook + background compaction | Would enable auto-save before context loss |
| 12 | [#32946](https://github.com/anthropics/claude-code/issues/32946) | Rolling asynchronous compaction | Prevents losing work mid-task |
| 13 | [#17428](https://github.com/anthropics/claude-code/issues/17428) | Enhanced /compact with file-backed summaries | Aligns with our /save checkpoint pattern |
| 14 | [#28389](https://github.com/anthropics/claude-code/issues/28389) | Effective usable context window reduced by infrastructure overhead | Real constraint on CLAUDE.md + rules/ size |

## Task Management

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 15 | [#31103](https://github.com/anthropics/claude-code/issues/31103) | TodoWrite/TaskCreate unrecognized for custom agents | Blocks multi-agent task delegation via Agent SDK |
| 16 | [#32347](https://github.com/anthropics/claude-code/issues/32347) | TaskCreate batch calls display in random order | Task ordering matters for sprint execution |
| 17 | [#23874](https://github.com/anthropics/claude-code/issues/23874) | Task tools disabled in VS Code (isTTY check) | Blocks TaskCreate in VS Code extension |

## Background Agents

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 18 | [#38859](https://github.com/anthropics/claude-code/issues/38859) | Background agents cannot get Bash permissions | Blocks watcher agents from executing bash autonomously |
| 19 | [#36323](https://github.com/anthropics/claude-code/issues/36323) | Background agents lose edits when parent switches branches | Branch safety for background agents during sprints |
| 20 | [#39530](https://github.com/anthropics/claude-code/issues/39530) | Stop hook blocks unrelated parallel sessions | Session isolation for parallel agents (ralph-tui) |

## Memory

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 21 | [#31294](https://github.com/anthropics/claude-code/issues/31294) | Subagents never create or update MEMORY.md | Blocks multi-agent /learn pattern |
| 22 | [#38536](https://github.com/anthropics/claude-code/issues/38536) | Shared team memory for Claude Code | Team-level shared memory for multi-session orchestration |
| 23 | [#38519](https://github.com/anthropics/claude-code/issues/38519) | Project-scoped memory in repository for cross-device sync | In-repo memory for team portability |
| 24 | [#36045](https://github.com/anthropics/claude-code/issues/36045) | Branch-aware auto-memory | Branch-scoped memory for feature branch isolation |

## Enterprise & Governance

| # | Link | Description | Why it matters |
|---|------|-------------|----------------|
| 25 | [#34209](https://github.com/anthropics/claude-code/issues/34209) | Allow projects to exclude inherited .claude/rules/ from parent dirs | Enterprise rule scoping |
| 26 | [#20880](https://github.com/anthropics/claude-code/issues/20880) | Exclude parent CLAUDE.md from auto-loading in subdirectories | Parent/child rule inheritance control |
| 27 | [#39882](https://github.com/anthropics/claude-code/issues/39882) | PreApiCall/PostApiCall hooks for secret exfiltration prevention | Enterprise security -- prevent secrets leaking to API |
| 28 | [#24185](https://github.com/anthropics/claude-code/issues/24185) | Claude reads .env files and hardcodes secrets into inline scripts | Security vulnerability -- secrets in code |
| 29 | [#24317](https://github.com/anthropics/claude-code/issues/24317) | OAuth refresh token race condition with concurrent sessions | Multi-session auth stability (28 upvotes) |
| 30 | [#25148](https://github.com/anthropics/claude-code/issues/25148) | Enable Agent Teams on all plans | Team agent features shouldn't be plan-gated |
| 31 | [#18550](https://github.com/anthropics/claude-code/issues/18550) | Automatic cost tracking and reporting | Enterprise cost visibility |
| 32 | [#21051](https://github.com/anthropics/claude-code/issues/21051) | Display message timestamps in CLI | Audit trail / session timing visibility |

## Bugs

| # | Link | Description | Status |
|---|------|-------------|--------|
| 33 | [#4686](https://github.com/anthropics/claude-code/issues/4686) | Copy/paste extra formatting chars | LOCKED |
