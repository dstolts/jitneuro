# JitNeuro: Endless Memory for Claude Code

**Status: v0.1.0 -- Core framework complete, ready for testing**
**Website:** [jitneuro.ai](https://jitneuro.ai)

A framework for managing short-term and long-term memory in Claude Code sessions,
inspired by neural network architecture. Stop losing context. Stop reloading everything.
Load only what you need, when you need it.

## The Problem

Claude Code loads CLAUDE.md files at session start and keeps everything in a fixed-size
context window. As conversations grow, older context gets compressed or lost. You can't
selectively unload context, and `/clear` wipes everything. There's no middle ground.

**Result:** Long sessions degrade. Task switching wastes tokens reloading irrelevant context.
Critical instructions get compressed away. You manually type reload commands after every `/clear`.

## The Solution

JitNeuro adds a memory management layer using Claude Code's existing primitives:
- **Context Bundles** -- modular knowledge files loaded on-demand (like neural network layers)
- **Context Manifest** -- tracks what's available and what's active (like an attention mechanism)
- **Session State** -- checkpoint/load across `/clear` cycles (like working memory)
- **Routing Weights** -- learned patterns for which bundles to co-activate (in MEMORY.md)
- **Orchestrator** -- automated context routing via subagents (no manual typing)

## Architecture

```
LONG-TERM MEMORY (disk -- survives all sessions)
  |-- MEMORY.md            learned patterns + routing weights
  |-- bundles/             domain knowledge, loaded on-demand
  |-- context files        project/repo deep context
  |-- specs + decisions    procedural + episodic memory

WORKING MEMORY (context window -- limited capacity)
  |-- CLAUDE.md            core rules (always loaded, minimal)
  |-- active bundles       task-relevant knowledge only
  |-- conversation         immediate reasoning chain

SHORT-TERM MEMORY (checkpoint files -- survives /clear)
  |-- session-state.md     task, modified files, next steps
  |-- active bundles list  what's currently "hot"
  |-- pending decisions    unresolved items carrying forward
```

### Neural Network Mapping

| Neural Network      | JitNeuro Equivalent                           |
|---------------------|-----------------------------------------------------|
| Weights             | MEMORY.md (learned routing patterns)                |
| Layers              | Context bundles (domain-specific knowledge)         |
| Attention heads     | Rules with path scoping (activate per file type)    |
| Working memory      | Context window (limited, actively managed)          |
| Long-term memory    | Disk files (specs, context, decisions)              |
| Activation function | Manifest routing (which bundles to load)            |
| Backpropagation     | User corrections -> MEMORY.md updates               |
| Dropout             | /clear (intentional forgetting)                     |
| Checkpointing       | session-state.md (save/restore)                     |
| Transfer learning   | Cross-project context files                         |

## How It Works

### The Context Cycle

```
SESSION START
  |-- CLAUDE.md loads (brainstem -- always, kept minimal)
  |-- MEMORY.md loads (routing weights -- first 200 lines)
  |-- Check session-state.md (any prior state to resume?)
  |
  |-- User gives a task
  |-- Orchestrator reads manifest, picks bundles
  |-- Launches agent with ONLY those bundles
  |-- Agent works in isolated context, returns summary
  |-- Main context stays thin
  |
  |-- CONTEXT GETTING FULL (or switching tasks)
  |   |-- Checkpoint: save state to session-state.md
  |   |-- /clear: flush working memory
  |   |-- Resume: reload only what's needed for next task
  |
  |-- END OF SESSION
      |-- Update MEMORY.md with new routing patterns
      |-- Update session-state.md with status
      |-- Next session picks up cleanly
```

### Automated (No Manual Typing)

The key insight: **subagents ARE automated clear/reload.** Each agent launch:
- Gets a fresh context window (automatic /clear)
- Receives only the bundles it needs (selective reload)
- Returns a compressed summary (automatic /compact)

The main conversation becomes a thin orchestrator that never fills up.

### Conversation Logging (Optional)

Toggle-based session logging that records every user prompt and response summary
to a daily log file in `.logs/`. Useful for audit trails, session handoffs, and
reviewing what happened in long sessions.

```
convlog on FirstMover    <-- enable with session name
convlog off                        <-- disable
convlog status                     <-- check current state
```

When enabled, the **first action** on every user message is appending the prompt
to the log -- before any other work. After the work completes, a response summary
is appended. This guarantees no prompt is lost, even if context is cleared or
the session crashes mid-task.

Log files are one-per-day, append-only, stored in `.logs/` (gitignored by default):
```
.logs/20260309-143022-FirstMover.md
```

See [conversation-log.md](templates/commands/conversation-log.md) for full spec.

## File Structure

Commands can be installed at three levels. Choose the one that fits your setup:

```
~/.claude/commands/              <-- USER-LEVEL: available everywhere on this machine

workspace-root/                  <-- MULTI-REPO (recommended for shared workflows)
  |-- .claude/
  |   |-- commands/              <-- available to all repos launched from this directory
  |   |   |-- save.md
  |   |   |-- load.md
  |   |   |-- sessions.md
  |   |   |-- orchestrate.md
  |   |   |-- conversation-log.md
  |   |-- bundles/               <-- shared context bundles
  |   |-- context-manifest.md    <-- bundle index + routing
  |   |-- session-state/         <-- session checkpoints
  |-- repo-a/
  |-- repo-b/

your-project/                    <-- PROJECT-LEVEL: single repo only
  |-- .claude/
  |   |-- CLAUDE.md              <-- minimal brainstem (30-40 lines)
  |   |-- commands/              <-- project-specific commands (override workspace)
  |   |-- bundles/               <-- project-specific context bundles
  |   |-- rules/                 <-- path-scoped rules (optional)
  |-- .logs/                     <-- conversation logs (gitignored)
  |-- MEMORY.md routing weights  <-- in your memory directory
```

Claude Code merges commands from all three levels. More specific scopes take priority.

## Quick Start

1. Copy the template files into your project (see [Setup Guide](docs/setup-guide.md))
2. Slim your CLAUDE.md to brainstem using `templates/CLAUDE-brainstem.md`
3. Create bundles for your domains in `.claude/bundles/`
4. Update `.claude/context-manifest.md` with your bundles
5. Add routing weights to your MEMORY.md
6. Use `/save` before `/clear`, `/load` after
7. Or let the orchestrator handle it automatically via subagents

## Files

| File | Status | Description |
|------|--------|-------------|
| `templates/context-manifest.md` | DONE | Bundle index + routing weights + session state |
| `templates/bundles/example.md` | DONE | Example bundle template with guidelines |
| `templates/commands/save.md` | DONE | Save state before /clear |
| `templates/commands/load.md` | DONE | Reload state after /clear |
| `templates/commands/orchestrate.md` | DONE | Auto-route tasks to agents with bundles |
| `templates/commands/sessions.md` | DONE | Session management (list, show, clean) |
| `templates/commands/conversation-log.md` | DONE | Toggle-based session logging to .logs/ |
| `templates/CLAUDE-brainstem.md` | DONE | Minimal CLAUDE.md template (30-40 lines) |
| `templates/session-state.md` | DONE | Session checkpoint template |
| `templates/rules/scoped-rule-example.md` | DONE | Path-scoped rule with frontmatter |
| `examples/multi-repo-sprint.md` | DONE | Multi-repo sprint with context switching |
| `examples/solo-developer.md` | DONE | Solo dev managing 3 projects in one session |
| `templates/gitignore-additions.txt` | DONE | .gitignore entries for logs + session state |
| `docs/setup-guide.md` | DONE | Step-by-step setup with troubleshooting |

## Key Concepts

### Context Bundles
Self-contained knowledge files (50-80 lines max) covering one domain. Examples:
- `deploy.md` -- deployment pipeline, container commands, environments
- `api-design.md` -- API conventions, auth patterns, error handling
- `sprint.md` -- sprint protocol, task format, commit conventions

Bundles live in `.claude/bundles/` and are loaded **only when needed** by the
orchestrator or manually via "Read .claude/bundles/X.md".

### Routing Weights
Patterns in MEMORY.md that map task types to bundle combinations:
```
- Deploy tasks -> bundles: [deploy, infra]
- API work -> bundles: [api-design, testing]
- Sprint execution -> bundles: [sprint, cross-repo]
```
These improve over time as the system learns which bundles co-activate.

### Conversation Logging
Optional toggle that records every prompt and response to a daily log file:
- **Prompt-first:** User prompt is logged BEFORE any work starts (no data loss)
- **Response-after:** Concise summary appended after work completes
- **Daily files:** One file per day, append-only, sequential prompt numbering
- **Survives /clear:** Logs are on disk, not in context. Resume picks up logging state.
- **Gitignored by default:** `.logs/` excluded from commits (may contain sensitive prompts)

### Compact Instructions
A section in CLAUDE.md that controls what auto-compaction preserves:
```markdown
# Compact Instructions
When compacting, always preserve:
- Active bundle list
- Modified file paths
- Current task and status
- Pending decisions
```
This fires automatically when context fills -- no user action needed.

## Claude Code Primitives Used

| Primitive | How JitNeuro Uses It |
|-----------|---------------------------|
| CLAUDE.md | Minimal brainstem + compact instructions |
| MEMORY.md | Routing weights + learned patterns |
| /clear | Flush working memory (context window) |
| /compact | Controlled compression with focus instructions |
| /context | Monitor context usage |
| /memory | Verify loaded files |
| Subagents | Isolated context windows with selective bundle loading |
| .claude/rules/ | Path-scoped rules that only load when relevant |
| Custom Commands | On-demand workflow loading (/save, /load, /sessions, convlog) |
| Hooks | Automatic triggers (pre-compact, session start) |
| .logs/ | Conversation log files (prompt-first, response-after pattern) |

## Lineage

JitNeuro didn't appear overnight. It's the result of a year of iteration on AI memory management:

| When | What | Limitation |
|------|------|------------|
| Mid-2025 | `/SaveAI` + `/LoadAI` in TaskManager | Single session, single repo, everything loaded at once |
| Late 2025 | DOE Framework v01-v03 | Rules, workflows, inference -- but flat MEMORY.md hit 200-line ceiling |
| Early 2026 | DOE v04 (Knowledge Hierarchy) | 5-layer architecture designed but implemented as one file |
| March 2026 | **JitNeuro** | Bundles, routing weights, /save + /load, multi-session, cross-repo, orchestrator |

Each version solved a real problem. Each hit a new wall. JitNeuro is what happens
when you stop theorizing about AI memory and start managing 16 repos across 6
concurrent sessions every day.

## License

MIT

## Author

Dan Stolts - [jitai.co](https://jitai.co) | [jitneuro.ai](https://jitneuro.ai)
