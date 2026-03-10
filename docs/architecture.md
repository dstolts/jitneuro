# JitNeuro Architecture

## Memory Architecture

```
LONG-TERM MEMORY (disk -- survives all sessions)
  |-- MEMORY.md            learned patterns + routing weights
  |-- bundles/             domain knowledge, loaded on-demand
  |-- engrams/             per-project deep context (updated by /learn)
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

## Neural Network Mapping

| Neural Network      | JitNeuro Equivalent                                |
|---------------------|----------------------------------------------------|
| Weights             | MEMORY.md (learned routing patterns)               |
| Layers              | Context bundles (domain-specific knowledge)        |
| Attention heads     | Rules with path scoping (activate per file type)   |
| Working memory      | Context window (limited, actively managed)         |
| Long-term memory    | Disk files (specs, context, decisions)             |
| Activation function | Manifest routing (which bundles to load)           |
| Long-term potentiation | Engrams (project context, strengthened by /learn) |
| Backpropagation     | /learn (session evaluation -> memory updates)      |
| Dropout             | /clear (intentional forgetting)                    |
| Checkpointing       | session-state.md (save/restore)                    |
| Transfer learning   | Cross-project engrams                              |

## The Context Cycle

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
  |-- END OF SESSION (or before /save)
      |-- /learn: evaluate session for long-term knowledge
      |-- Update MEMORY.md, bundles, engrams (with approval)
      |-- /save: checkpoint short-term state
      |-- Next session picks up cleanly
```

## How Subagents Enable Automation

The core mechanism: **subagents ARE automated clear/reload.** Subagents run inside
your current Claude Code session (via the Agent tool) -- not separate sessions.
Each agent launch:
- Gets its own isolated context window (automatic /clear)
- Receives only the bundles it needs (selective reload)
- Returns a compressed summary (automatic /compact)

The main conversation becomes a thin orchestrator that never fills up.
You just open Claude Code and work. The framework handles memory behind the scenes.

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
| Custom Commands | 15+ commands: memory, governance, git, context, setup |
| Hooks | PreCompact save, session recovery, branch protection, auto-save |
| .logs/ | Conversation log files (prompt-first, response-after pattern) |

## Lineage

| When | What | Limitation |
|------|------|------------|
| Early-Mid 2025 | Massive CLAUDE.md files + manual context saves | 500+ line CLAUDE.md loaded every session. Context management was the job, not the work. |
| Mid-2025 | `/SaveAI` + `/LoadAI` in TaskManager | Single session, single repo, everything loaded at once |
| Late 2025 | DOE Framework v01-v03 | Rules, workflows, inference -- but flat MEMORY.md hit 200-line ceiling |
| Early 2026 | DOE v04 (Knowledge Hierarchy) | 5-layer architecture designed but implemented as one file |
| March 2026 | **JitNeuro** | Bundles, routing weights, /save + /load, multi-session, cross-repo, orchestrator |
