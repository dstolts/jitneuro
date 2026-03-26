# Technical Overview

Detailed technical reference for JitNeuro internals. For the quick version, see the [README](../README.md).

## The Problem

Claude Code loads CLAUDE.md files at session start and keeps everything in a fixed-size
context window. As conversations grow, older context gets compressed or lost. You can't
selectively unload context, and `/clear` wipes everything. There's no middle ground.

**Result:** Long sessions degrade. Task switching wastes tokens reloading irrelevant context.
Critical instructions get compressed away. You manually type reload commands after every `/clear`.

## The Solution

JitNeuro adds a memory management layer using Claude Code's existing primitives:
- **Context Bundles** -- modular knowledge files loaded on-demand (like neural network layers)
- **Engrams** -- per-project deep context, strengthened over time by /learn (like long-term potentiation)
- **Context Manifest** -- tracks what's available and what's active (like an attention mechanism)
- **Session State** -- save/load across `/clear` cycles (like working memory)
- **Routing Weights** -- learned patterns for which bundles to co-activate (in MEMORY.md)
- **Orchestrator** -- automated context routing via subagents (no manual typing)
- **/learn** -- backpropagation: evaluate sessions and persist learnings to long-term memory
- **Holistic Review** -- 4-persona pre/post execution gates for enterprise-grade code quality

For deeper explanation of these concepts, see [concepts.md](concepts.md).
For architecture diagrams and the neural network mapping, see [architecture.md](architecture.md).

## Architecture

```
LONG-TERM MEMORY (disk -- survives all sessions)
  |-- MEMORY.md            learned patterns + routing weights
  |-- bundles/             domain knowledge, loaded on-demand
  |-- engrams/             per-project deep context (updated by /learn)

WORKING MEMORY (context window -- limited capacity)
  |-- CLAUDE.md            core rules (always loaded, minimal)
  |-- active bundles       task-relevant knowledge only

SHORT-TERM MEMORY (checkpoint files -- survives /clear)
  |-- session-state.md     task, modified files, next steps
```

## File Structure

```
workspace-root/
  |-- .claude/
  |   |-- commands/           slash commands (installed by JitNeuro)
  |   |-- bundles/            domain knowledge, loaded on-demand
  |   |-- engrams/            per-project deep context
  |   |-- cognition/          personas, decisions, anti-patterns, friction detection
  |   |-- scripts/            deterministic bash scripts (dashboard, sessions)
  |   |-- hooks/              hook scripts (6 lifecycle hooks)
  |   |-- rules/              path-scoped rules (optional)
  |   |-- session-state/      session checkpoints
  |   |-- context-manifest.md bundle index + routing
  |   |-- jitneuro.json       version, hooks config, settings
  |   |-- settings.local.json Claude Code hooks configuration
  |-- repo-a/
  |-- repo-b/
```

Commands can be installed at three levels (user, workspace, project).
Claude Code merges all levels; more specific scopes take priority.

**Important:** Claude Code only resolves commands from the **user** level (`~/.claude/commands/`)
and the **project** level (`<git-root>/.claude/commands/`). It does NOT walk up parent directories.
Workspace mode installs to a parent `.claude/` folder, which is only visible when Claude Code is
launched directly from that parent folder -- not from any child repo. If you work inside individual
repos, use **user** mode so commands are available everywhere.

## What's Included

- **15 commands + 5 shortcuts** -- session (/session, /sessions), reasoning (/divergent), memory (/learn, /health, /bundle), governance (/enterprise, /audit), git (/gitstatus, /diff), setup (/onboard, /orchestrate, convlog, /verify), diagnostics (/test-tools), automation (/schedule). Shortcuts: /save, /load, /pulse, /status, /dashboard
- **Scheduled agents** -- timer agents that interrupt master with housekeeping instructions on a configurable interval. Ships with autosave (30m) and hub-sync (10m) by default.
- **6 hooks** -- pre-compact save, session recovery, post-clear session picker, branch protection, auto-save, session ID tracking
- **16 personas** -- expert roles that evaluate every request (Security Engineer, DBA, Content Strategist, QA, etc.)
- **Friction detection** -- pre-reasoning scan for user correction signals with severity-ordered response
- **4 decision models** -- root cause analysis, API-first design, technology selection, cross-repo contracts
- **10 anti-pattern seeds** -- universal "never do this" patterns learned from real engineering mistakes
- **AFK pattern** -- autonomous task execution when user steps away, respecting trust zones
- **8 rule templates** -- definition of done, trust zones, file versioning, schema, tests, coverage, deployment, components
- **Templates** -- brainstem CLAUDE.md (with Cognitive Identity + Divergent Thinking), bundle/engram examples, owner persona template, context manifest
- **Install scripts** -- `install.sh` (bash) and `install.ps1` (PowerShell)

## Using JitNeuro with Cursor

Cursor doesn't use slash commands. To get **guardrails**, **save**, **load**, and **learn** in Cursor: copy the intent rule so the agent knows what to do when it sees those intents. The agent will **read** CLAUDE.md and MEMORY.md (they change constantly) instead of using copied text.

1. Install JitNeuro as above so your workspace or project has `.claude/` (commands, session-state, bundles, engrams, etc.).
2. Copy the Cursor rule:
   `cp jitneuro/templates/cursor/rules/jitneuro-intents.mdc .cursor/rules/`
   (create `.cursor/rules/` if needed).
3. Use the same `.claude/` layout; the rule tells the agent to read CLAUDE.md and MEMORY.md when needed.

See [templates/cursor/README.md](../templates/cursor/README.md) and [cursor-and-cross-vendor.md](cursor-and-cross-vendor.md) for details. What we ship for Cursor is defined in [cursor-enablement-context.md](cursor-enablement-context.md).

## Roadmap

### v0.4.0 (Current) -- Scheduled Agents, Divergent Thinking, Philosophy-First
- **4 scheduled agent types** -- timer, enforcer, cron, batch with self-looping and shift-based lifespans
- **Divergent thinking toggle** -- /divergent auto/always/never with workspace/repo hierarchy
- **/help command** -- zero-token static quick reference with feature discovery
- **Sub-orchestrator pattern** -- rolling worker pools, write-to-file-return-pointer, executive summaries
- **Business automation examples** -- Stripe monitoring, inbound marketing, support triage
- **Configuration reference** -- single source of truth for all config files
- **README rewrite** -- philosophy-first (why, simple but powerful, Claude learns to think like you)
- **Dan->Owner scrub** -- open-source ready

### v0.2.0 -- Cognition Layer
- 16 personas, friction detection, 4 decision models, 10 anti-pattern seeds
- AFK mode, post-clear session picker, owner persona, customization guide

### v0.1.x -- Memory Layer
Bundles, engrams, routing weights, /save, /load, /learn, /health, /enterprise,
orchestrator, session management, install scripts, branch protection hooks.

### Next
- Complete autonomous orchestration (FR-105) -- cross-session spawn, event-driven triggers
- External cron launcher script (bash + PowerShell)
- Batch task file format and runner
- Context % threshold alerting (FR-016)

See [FEATURE-REQUESTS.md](../FEATURE-REQUESTS.md) for the full roadmap.

## Related Docs

- [Setup Guide](setup-guide.md) -- Detailed installation walkthrough
- [Commands Reference](commands-reference.md) -- All 16 commands + 5 shortcuts
- [Hooks Guide](hooks-guide.md) -- Lifecycle hooks and custom hook development
- [Configuration Reference](configuration-reference.md) -- All config files and settings
- [Scheduled Agents](scheduled-agents.md) -- Timer, enforcer, cron, and batch agents
- [Sub-Orchestrator Pattern](sub-orchestrator-pattern.md) -- Managing 30+ tasks with worker pools
- [Customization Guide](customization-guide.md) -- Personas, rules, cognitive identity
- [Concepts](concepts.md) -- Core concepts explained
- [Architecture](architecture.md) -- Neural network mapping and diagrams
- [Enterprise Security](enterprise-security.md) -- Trust model and hook enforcement
