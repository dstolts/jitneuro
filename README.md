# JitNeuro: JIT Memory Management for Claude Code

> This started because reloading context after every /clear got old.
> If it helps you, share what you learn.

**Status: v0.1.3 -- 12 commands, 5 shortcuts, 4 hooks, install scripts**
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

For deeper explanation of these concepts, see [docs/concepts.md](docs/concepts.md).
For architecture diagrams and the neural network mapping, see [docs/architecture.md](docs/architecture.md).

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

## Quick Start

```bash
# Clone the repo
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Install (pick your level)
./install.sh workspace   # parent directory -- only works when launched from there
./install.sh project     # current repo only
./install.sh user        # global -- commands available in ALL repos (recommended)

# Windows (PowerShell)
.\install.ps1 -Mode user
```

**Close and reopen Claude Code after installing.** Commands load at session start.

Then:
1. Run `/verify` to confirm installation
2. Slim your CLAUDE.md using `templates/CLAUDE-brainstem.md`
3. Create bundles for your domains in `.claude/bundles/`
4. Run `/onboard <repo>` to set up context for your repos
5. Use `/save` before `/clear`, `/load` after, `/learn` to persist knowledge

See [Setup Guide](docs/setup-guide.md) for detailed walkthrough.

## File Structure

```
workspace-root/
  |-- .claude/
  |   |-- commands/           slash commands (installed by JitNeuro)
  |   |-- bundles/            domain knowledge, loaded on-demand
  |   |-- engrams/            per-project deep context
  |   |-- hooks/              hook scripts
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

- **12 commands + 5 shortcuts** -- session (/session, /sessions), memory (/learn, /health, /bundle), governance (/enterprise, /audit), git (/gitstatus, /diff), setup (/onboard, /orchestrate, convlog, /verify). Shortcuts: /save, /load, /pulse, /status, /dashboard
- **4 hooks** -- pre-compact save, session recovery, branch protection, auto-save
- **5 rule templates** -- schema, tests, coverage, deployment, components
- **Templates** -- brainstem CLAUDE.md, bundle example, engram example, context manifest
- **Install scripts** -- `install.sh` (bash) and `install.ps1` (PowerShell)
- **Docs** -- [setup guide](docs/setup-guide.md), [commands reference](docs/commands-reference.md), [hooks guide](docs/hooks-guide.md), [concepts](docs/concepts.md), [architecture](docs/architecture.md), [enterprise security](docs/enterprise-security.md)

## Roadmap

### v0.1.3 (Current) -- Session Management
Consolidated session lifecycle: /session (current) and /sessions (all).
Subcommands: new, save, load, pulse, switch, rename, dashboard.
Numbered session lists, .current tracking, shortcut preference system,
session tag rule for cross-terminal awareness.

### v0.1.2 -- Memory Layer
Bundles, engrams, routing weights, /save, /load, /learn, /health, /enterprise,
orchestrator, session management, install scripts with auto-configuration.

### Phase 2 -- Decision Frameworks (The Brain)
Phase 1 solves memory (what to know). Phase 2 adds structured decision-making
patterns -- teaching Claude not just your project context, but your preferences
and workflows. The foundation for this already exists in /learn, which
evaluates sessions and persists patterns to long-term memory. Phase 2 extends
this into a full cognitive layer:

- **Decision Models** -- structured frameworks for how to decide, not what to do
- **Prediction Rules** -- anticipate what the user wants next
- **Anti-Patterns** -- learned constraints from corrections
- **Persona Weights** -- which expert voice for which task type
- **Governance Rules Engine** -- structured config for branching, trust zones, deploy gates

Note: The author's production instance runs hundreds of additional capabilities
built on this framework that are not yet in the open-source release. The memory
and neuro network layers are straightforward to package. The cognitive layer --
"how to think like me" -- requires more abstraction work to generalize for
distribution. These capabilities will be pushed as they are packaged.

See [FEATURE-REQUESTS.md](FEATURE-REQUESTS.md) for detailed Phase 2 design.

## Disclaimer

JitNeuro is an independent open-source project. It is not affiliated with, endorsed by,
or officially connected to Anthropic, Claude, or Claude Code. "Claude Code" is a product
of Anthropic, PBC. JitNeuro uses Claude Code's publicly documented features and does not
modify or extend the Claude Code application itself.

This software is provided as-is, without warranty. See [LICENSE](LICENSE) for details.

## License

MIT -- see [LICENSE](LICENSE).

## Author

Dan Stolts - [jitai.co](https://jitai.co) | [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)
