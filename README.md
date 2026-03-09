# JitNeuro: JIT Memory Management for Claude Code

> This started because reloading context after every /clear got old.
> If it helps you, share what you learn.

**Status: v0.1.1 -- 15 commands, 4 hooks, install scripts**
**GitHub:** [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)

**JIT = Just In Time.** A framework for managing short-term and long-term memory
in Claude Code sessions, inspired by neural network architecture. Stop losing context.
Stop reloading everything. Load only what you need, when you need it -- just in time.

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

## Architecture

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

### Neural Network Mapping

| Neural Network      | JitNeuro Equivalent                           |
|---------------------|-----------------------------------------------------|
| Weights             | MEMORY.md (learned routing patterns)                |
| Layers              | Context bundles (domain-specific knowledge)         |
| Attention heads     | Rules with path scoping (activate per file type)    |
| Working memory      | Context window (limited, actively managed)          |
| Long-term memory    | Disk files (specs, context, decisions)              |
| Activation function | Manifest routing (which bundles to load)            |
| Long-term potentiation | Engrams (project context, strengthened by /learn)  |
| Backpropagation     | /learn (session evaluation -> memory updates)        |
| Dropout             | /clear (intentional forgetting)                     |
| Checkpointing       | session-state.md (save/restore)                     |
| Transfer learning   | Cross-project engrams                               |

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
  |-- END OF SESSION (or before /save)
      |-- /learn: evaluate session for long-term knowledge
      |-- Update MEMORY.md, bundles, engrams (with approval)
      |-- /save: checkpoint short-term state
      |-- Next session picks up cleanly
```

### Automated (No Manual Typing)

The core mechanism: **subagents ARE automated clear/reload.** Subagents run inside
your current Claude Code session (via the Agent tool) -- not separate sessions.
Each agent launch:
- Gets its own isolated context window (automatic /clear)
- Receives only the bundles it needs (selective reload)
- Returns a compressed summary (automatic /compact)

The main conversation becomes a thin orchestrator that never fills up.
You just open Claude Code and work. The framework handles memory behind the scenes.

### Conversation Logging (Optional)

Toggle-based session logging that records every user prompt and response summary
to a daily log file in `.logs/`. Useful for audit trails, session handoffs, and
reviewing what happened in long sessions.

```
convlog on my-project    <-- enable with session name
convlog off                        <-- disable
convlog status                     <-- check current state
```

When enabled, the **first action** on every user message is appending the prompt
to the log -- before any other work. After the work completes, a response summary
is appended. This guarantees no prompt is lost, even if context is cleared or
the session crashes mid-task.

Log files are one-per-day, append-only, stored in `.logs/` (gitignored by default):
```
.logs/20260309-143022-my-project.md
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
  |   |   |-- learn.md
  |   |   |-- health.md
  |   |   |-- enterprise.md
  |   |   |-- status.md
  |   |   |-- dashboard.md
  |   |   |-- gitstatus.md
  |   |   |-- diff.md
  |   |   |-- audit.md
  |   |   |-- bundle.md
  |   |   |-- onboard.md
  |   |   |-- sessions.md
  |   |   |-- orchestrate.md
  |   |   |-- conversation-log.md
  |   |-- bundles/               <-- shared context bundles
  |   |-- engrams/               <-- per-project deep context (updated by /learn)
  |   |-- context-manifest.md    <-- bundle index + routing
  |   |-- session-state/         <-- session checkpoints
  |-- repo-a/
  |-- repo-b/

your-project/                    <-- PROJECT-LEVEL: single repo only
  |-- .claude/
  |   |-- CLAUDE.md              <-- minimal brainstem (30-40 lines)
  |   |-- commands/              <-- project-specific commands (override workspace)
  |   |-- bundles/               <-- project-specific context bundles
  |   |-- engrams/               <-- project-specific deep context
  |   |-- rules/                 <-- path-scoped rules (optional)
  |-- .logs/                     <-- conversation logs (gitignored)
  |-- MEMORY.md routing weights  <-- in your memory directory
```

Claude Code merges commands from all three levels. More specific scopes take priority.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Install (pick your level)
./install.sh workspace   # all repos under parent directory
./install.sh project     # current repo only
./install.sh user        # global, all projects

# Windows (PowerShell)
.\install.ps1 -Mode workspace
```

**IMPORTANT: Close and reopen Claude Code after installing.** Slash commands
are only discovered at session start. An existing session will not see new commands.

**Note:** On Windows, some hooks and scripts require bash (Git Bash, WSL, or
Windows Subsystem for Linux). For full functionality at scale, WSL is recommended.
Core commands work on any platform. Hooks require a bash-compatible shell.

Then:
1. Slim your CLAUDE.md to brainstem using `templates/CLAUDE-brainstem.md`
2. Create bundles for your domains in `.claude/bundles/`
3. Create engrams for your projects in `.claude/engrams/`
4. Add routing weights to your MEMORY.md
5. Start a new Claude Code session (commands load at session start)
6. Use `/save` before `/clear`, `/load` after, `/learn` to persist knowledge

See [Setup Guide](docs/setup-guide.md) for detailed walkthrough.

## What's Included

- **15 slash commands** in `templates/commands/` -- memory, governance, git, context, setup
- **4 hooks** in `templates/hooks/` -- pre-compact save, session recovery, branch protection, auto-save
- **5 rule templates** in `templates/rules/` -- schema, tests, coverage, deployment, components
- **Templates** -- brainstem CLAUDE.md, bundle example, engram example, session-state, context manifest
- **Examples** in `examples/` -- multi-repo sprint, solo developer workflow
- **Docs** in `docs/` -- setup guide, commands reference, hooks guide, holistic review, enterprise isolation
- **Install scripts** -- `install.sh` (bash) and `install.ps1` (PowerShell) for workspace/project/user modes

## Key Concepts

### Context Bundles
Self-contained knowledge files (50-80 lines max) covering one domain. Examples:
- `deploy.md` -- deployment pipeline, container commands, environments
- `api-design.md` -- API conventions, auth patterns, error handling
- `sprint.md` -- sprint protocol, task format, commit conventions

Bundles live in `.claude/bundles/` and are loaded **only when needed** by the
orchestrator or manually via "Read .claude/bundles/X.md".

### Engrams
Per-project deep context files. One file per project or repository.

In neuroscience, an engram is the physical trace a memory leaves in the brain --
the compressed representation of an experience. Each project's engram is exactly
that: not the codebase itself, but the compressed knowledge about it.

Engrams live in `.claude/engrams/` and are updated by `/learn`:
- `my-api.md` -- tech stack, key files, architecture, integrations, gotchas
- `my-frontend.md` -- framework setup, build config, deploy pipeline, known issues

Bundles and engrams are orthogonal:
- **Bundles** cut across projects by domain ("how to deploy")
- **Engrams** cut across domains by project ("everything about this repo")

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
- Full task list with status (all known tasks, not just current)
- Pending decisions
```
This fires automatically when context fills -- no user action needed.

### Rule of Lowest Context

The most important design principle in JitNeuro: **store context at the lowest level possible.**

Don't put everything in CLAUDE.md. A 500-line CLAUDE.md loads every session, wastes tokens on irrelevant rules, and gets compressed away. Instead, push rules down to where they apply:

```
CLAUDE.md (brainstem, 30-40 lines)    -- universal rules only
  .claude/rules/schema.md              -- loads only for schema/**
  .claude/rules/api.md                 -- loads only for src/api/**
  .claude/rules/tests.md               -- loads only for tests/**
  .claude/rules/deployment.md          -- loads only for deploy/**, Dockerfile, .github/workflows/**
  .claude/bundles/deploy.md            -- loads on demand by orchestrator
  .claude/engrams/repo.md              -- loads on demand per project
  MEMORY.md                            -- routing weights (first 200 lines)
```

Each level only loads when relevant:
- **Rules** load automatically when Claude touches matching file paths (zero cost when not needed)
- **Bundles** load on demand when routing weights match the task
- **Engrams** load on demand when working on a specific project
- **CLAUDE.md** loads every session (keep it minimal)

This pattern scales across many repos without context bloat. Each repo has a 30-line brainstem. The deep knowledge lives in scoped rules, bundles, and engrams -- loaded just in time, not all the time.

**Example: Layered Test Coverage**

Rules can layer -- a global default in CLAUDE.md, overridden per project:

```
Global CLAUDE.md:        "Tests required. Minimum 60% line coverage."
Payment API rules/:      80% min, 90% target, 95% for auth/payment paths
Marketing site rules/:   40% min, 60% target, branch coverage not required
Scripts repo:            (no override -- uses global 60% default)
```

The payment API gets strict rules that load only when touching test files.
The marketing site gets relaxed rules. Scripts inherit the global default.
No project pays the token cost for another project's coverage rules.

See `templates/rules/test-coverage.md` for a ready-to-use template with
configurable thresholds per project.

## Context Budget

JitNeuro is designed to be lightweight. Here's what it actually costs:

### Always Loaded (every session)

| File | Lines | Est. Tokens | Purpose |
|------|-------|-------------|---------|
| CLAUDE.md (global) | ~50-140 | ~400-1,100 | Core rules, trust zones |
| CLAUDE.md (project) | ~30-50 | ~250-400 | Project identity, key paths |
| MEMORY.md | ~90-200 | ~700-1,600 | Routing weights, project index |
| **Total brainstem** | **~170-390** | **~1,350-3,100** | |

That's roughly **1-2% of a 200K context window**. The rest is your conversation and code.

### On-Demand (loaded only when needed)

| Category | Typical Load | Lines | Est. Tokens |
|----------|-------------|-------|-------------|
| 1 command (/save, /load, etc.) | Per invocation | ~65-185 | ~500-1,500 |
| 1-2 bundles | Per task routing | ~30-80 each | ~250-650 each |
| 1 engram | Per project | ~50-150 | ~400-1,200 |

A typical working session adds **~1-2%** more for on-demand context.

### Total: ~3-4% of context for full JitNeuro infrastructure

Compare this to the alternative: a monolithic CLAUDE.md that grows to 500+ lines,
loads everything every session, can't be selectively unloaded, and still misses
project-specific context. That approach easily consumes 5-10%+ and scales worse
as projects grow.

### Size Limits (enforced by /learn)

| Component | Limit | Why |
|-----------|-------|-----|
| MEMORY.md | 200 lines (hard) | Claude Code truncates beyond 200 -- content silently lost |
| Bundles | 80 lines each | Longer bundles get skimmed or partially read |
| Engrams | 150 lines each | Diminishing returns -- trim stale content |
| CLAUDE.md | 30-40 lines | Loaded every session -- keep minimal |
| Session state | 30-60 lines | Checkpoint, not transcript |

The `/learn` command monitors these limits and flags violations before they cause problems.

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
| Custom Commands | 15 commands: memory (/save, /load, /learn, /health), governance (/enterprise, /audit), git (/gitstatus, /diff), context (/bundle, /orchestrate, /status, /dashboard), setup (/onboard, /sessions, convlog) |
| Hooks | PreCompact save prompt, automatic triggers (pre-compact, session start) |
| .logs/ | Conversation log files (prompt-first, response-after pattern) |

## Lineage

Here's how this evolved:

| When | What | Limitation |
|------|------|------------|
| Early-Mid 2025 | Massive CLAUDE.md files + manual context saves | 500+ line CLAUDE.md loaded every session. Constant "save this to a .md file" then "read that .md file back." Context management was the job, not the work. |
| Mid-2025 | `/SaveAI` + `/LoadAI` in TaskManager | Single session, single repo, everything loaded at once |
| Late 2025 | DOE Framework v01-v03 | Rules, workflows, inference -- but flat MEMORY.md hit 200-line ceiling |
| Early 2026 | DOE v04 (Knowledge Hierarchy) | 5-layer architecture designed but implemented as one file |
| March 2026 | **JitNeuro** | Bundles, routing weights, /save + /load, multi-session, cross-repo, orchestrator |

Each version solved a real problem and hit a new wall.

## Roadmap

### v0.1.1 (Current) -- Memory Layer
Bundles, engrams, routing weights, /save, /load, /learn, /health, /enterprise,
orchestrator, session management, enterprise isolation, install scripts.

### Phase 2 -- Decision Frameworks
Phase 1 solves memory (what to know). Phase 2 adds structured decision-making
patterns -- teaching Claude not just your project context, but your preferences
and workflows. Extends the current guardrails (trust zones, approval workflows) into:

- **Decision Models** -- structured frameworks Claude applies at decision points
  (not "what to do" but "how to decide what to do")
- **Prediction Rules** -- anticipate what the user wants next based on observed
  sequences across sessions
- **Anti-Patterns** -- learned constraints from corrections, stronger than routing
  weights, with severity levels and context scoping
- **Persona Weights** -- which expert voice for which task type, with tunable
  decision bias and vocabulary
- **Governance Rules Engine** -- externalize branching policies, trust zones,
  merge rules, and deployment gates into structured config (FR-013)

Phase 2 extends /learn to capture cognitive patterns: overridden recommendations
become decision model updates, repeated sequences become prediction rules,
corrections become anti-patterns.

See [FEATURE-REQUESTS.md](FEATURE-REQUESTS.md) for detailed Phase 2 design (FR-100 through FR-104).

## Disclaimer

JitNeuro is an independent open-source project. It is not affiliated with, endorsed by,
or officially connected to Anthropic, Claude, or Claude Code. "Claude Code" is a product
of Anthropic, PBC. JitNeuro uses Claude Code's publicly documented features (CLAUDE.md,
MEMORY.md, custom commands, subagents) and does not modify or extend the Claude Code
application itself.

This software is provided as-is, without warranty. See [LICENSE](LICENSE) for details.

## License

MIT -- see [LICENSE](LICENSE).

## Author

Dan Stolts - [jitai.co](https://jitai.co) | [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)
