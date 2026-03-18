# JitNeuro

JIT memory management framework for Claude Code -- persistent context across sessions via bundles, engrams, routing weights, and slash commands.

## Status
- **Phase:** Active Development
- **Version:** v0.1.5
- **Repo:** https://github.com/dstolts/jitneuro

## Tech Stack
- **Language:** Markdown, Bash, PowerShell
- **Framework:** Claude Code slash commands + hooks
- **Runtime:** Claude Code CLI

## Key Paths
| Path | Purpose |
|------|---------|
| templates/commands/ | Slash command templates (17 files: 12 commands + 5 shortcuts) |
| templates/hooks/ | Hook script templates (4 hooks) |
| templates/engrams/ | Engram templates + examples |
| templates/rules/ | Path-scoped rule templates |
| templates/CLAUDE-brainstem.md | CLAUDE.md template for new repos |
| docs/ | Setup guide, commands reference, hooks guide, holistic review, enterprise isolation, master session |
| install.sh / install.ps1 | Installation scripts (workspace/project/user modes) |

## Key Components
- 12 commands: session, sessions, learn, health, gitstatus, diff, enterprise, audit, bundle, onboard, orchestrate, conversation-log
- 5 shortcuts: save, load, pulse, status, dashboard (delegate to session/sessions based on preference)
- 4 hooks: PreCompact save, SessionStart recovery, Branch protection, SessionEnd auto-save
- Engram system: per-project deep context files (50-150 lines each)
- Bundle system: domain knowledge files loaded on-demand via routing weights
- Context manifest: bundle index and routing weight definitions

## Notes
- This is a documentation/template project -- no compiled code
- Install scripts copy templates to target locations
- Workspace mode: shared context across repos. Project mode: isolated per-repo.
- All commands are markdown files that Claude Code loads as slash command prompts
