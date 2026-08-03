# JitNeuro

<!-- jit-knowledge-managed:block:begin claude-agents-bridge-v1 -->
<!-- jit-knowledge-managed:base sha256:31f55f5ef9c2a43867e1341f3fdb2d95c9facacb4f485f4b0655e555ca27e21c -->
## jit-knowledge Bootstrap

This managed block is inserted by the jit-knowledge installer. Claude Code
should use `AGENTS.md` as the canonical, tool-agnostic bootstrap surface:

`/Users/danstolts/Code/jitneuro/AGENTS.md`

Before substantive work:

1. Read `/Users/danstolts/Code/jitneuro/AGENTS.md`.
2. Read `/Users/danstolts/Code\AGENTS.md` when present.
3. Read the active hub's `agent-inbox.md`, `agent-goals.md`, `agent-permissions.md`,
   `questions.md`, and `Hub.md` when present.
4. Read `.agents\context.md` when present.
5. Follow the jit-knowledge bootstrap chain and repo-local context named by
   `AGENTS.md`.

If this file contains substantial reusable rules or durable project knowledge,
evaluate whether that content should move to KnowledgeRoot, `.agents\context.md`,
or repo `.knowledge` instead of remaining embedded in `CLAUDE.md`.

Continuation and questions:

- Apply `<KnowledgeRoot>\rules\agent-goals.md` and
  `<KnowledgeRoot>\rules\multi-agent-repo-coordination.md` and
  `<KnowledgeRoot>\rules\session-working-tree-context.md` and
  `<KnowledgeRoot>\rules\autonomous-execution.md` and
  `<KnowledgeRoot>\rules\session-guardrail.md` after bootstrap.
- Verify the current working directory against the active hub/session state's
  working-tree context before mutating files or dispatching workers.
- Discover the configured Intercom surface (DB/API tracker, deterministic
  scripts, watcher config, or file-backed `agent-inbox.md` spool).
- Read the active hub's `agent-inbox.md`, `agent-goals.md`, and
  `agent-permissions.md` files.
- For approved backlog-clearing work, set a Claude `/goal` to clear the
  executable repo or repo-group lane.
- Use `/loop` for cadence-based polling such as PR, CI, or deploy checks.
- Put Owner questions in the active hub's `questions.md` file
  (`.hub\questions.md` or `.HUB\questions.md`) and open that file when a
  question is added.
<!-- jit-knowledge-managed:block:end claude-agents-bridge-v1 -->
JIT memory management framework for Claude Code -- persistent context across sessions via bundles, engrams, routing weights, and slash commands.

## Status
- **Phase:** Active Development
- **Version:** v0.5.0
- **Repo:** https://github.com/dstolts/jitneuro

## Tech Stack
- **Language:** Markdown, Bash, PowerShell
- **Framework:** Claude Code slash commands + hooks
- **Runtime:** Claude Code CLI

## Key Paths
| Path | Purpose |
|------|---------|
| templates/commands/ | Slash command templates (22 files: 17 commands + 5 shortcuts) |
| templates/hooks/ | Hook script templates (10 hook scripts) |
| templates/engrams/ | Engram templates + examples |
| templates/rules/ | Path-scoped rule templates |
| templates/CLAUDE-brainstem.md | CLAUDE.md template for new repos |
| docs/ | Setup guide, commands reference, hooks guide, holistic review, enterprise isolation, master session |
| install.sh / install.ps1 | Installation scripts (workspace/project/user modes) |

## Key Components
- 17 commands: help, session, sessions, divergent, learn, health, gitstatus, diff, enterprise, audit, bundle, onboard, orchestrate, conversation-log, test-tools, schedule, verify
- 5 shortcuts: save, load, pulse, status, dashboard (delegate to session/sessions based on preference)
- 10 hook scripts / 9 hook events: PreCompact save, SessionStart (write-id, post-clear, recovery, scheduled-agents), PreToolUse (branch-protection, pre-agent-register), PostToolUse (heartbeat, post-agent-complete), SessionEnd auto-save
- Engram system: per-project deep context files (50-150 lines each)
- Bundle system: domain knowledge files loaded on-demand via routing weights
- Context manifest: bundle index and routing weight definitions

## Notes
- This is a documentation/template project -- no compiled code
- Install scripts copy templates to target locations
- Workspace mode: shared context across repos. Project mode: isolated per-repo.
- All commands are markdown files that Claude Code loads as slash command prompts
