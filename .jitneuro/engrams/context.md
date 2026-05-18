---
name: jitneuro
type: engram
domains:
  - jitneuro
  - jitneuro.ai
  - DOE
  - framework
  - JitNeuro
  - directive-orchestration-execution
  - templates
  - cognition
  - bundles-system
  - skills
  - hooks
  - slash-commands
  - open-source-framework
status: production
version: 2026-05-11
repo: dstolts/jitneuro
last-verified: 2026-05-11
owner: dstolts
---

# jitneuro Engram

**Status:** Production
**Last verified:** 2026-05-11

## Identity

JitNeuro is an **open-source AI engineering framework for Claude Code**. It provides structured behaviors (skills, rules, hooks, cognition) that make AI assistants reliable, security-aware, and production-grade.

Purpose: production tool AND enterprise thought leadership. Never optimize for just Owner's team alone -- every design decision must work for any adopter.

- **GitHub:** `dstolts/jitneuro`
- **Local path:** `<local-clone-path>/jitneuro`
- **Domains:** jitneuro.ai (primary), jitneuro.com (redirects to .ai)
- **Current version target:** v0.4.5

## Architecture

### Skills-First Pivot (2026-03-30)

JitNeuro pivoted from "monolithic framework you adopt wholesale" to "composable skills you install individually" using Anthropic's official SKILL.md standard (Dec 2025).

- `.claude/skills/<skill-name>/SKILL.md` replaces `.claude/commands/` as primary behavior mechanism
- Skills use SKILL.md with YAML frontmatter (progressive disclosure, ~100 tokens at startup)
- Commands still work but are legacy -- skills take precedence
- Install all skills by default; users remove what they don't want

### v0.4.5 Scope (ships)

- Skills architecture: `.claude/skills/<skill-name>/SKILL.md`
- Core skills: `strategy`, `divergent`, `rca`, `learn`, `session`, `health`, `review`, `gap`
- Always-on rules: truth-over-speed, scope-guard, trust zones, friction detection, verify-before-presenting
- Cognition layer: personas.md, anti-patterns.md, decisions/
- Hooks: PostToolUse heartbeat, pre-commit branch protection
- Bundles and engrams (personal mode in v0.4.5)
- Simplified install via `install.sh` / `install.ps1`

### Deferred to v2

- `.jitneuro/` shared team folders, TEAM.md, per-user tracking
- `/learn --team` promotion workflow
- machineName, bundle-map.json
- Enterprise docs and dashboard
- External cron launcher

## Key Paths

| Path | Purpose |
|------|---------|
| `templates/commands/` | Slash command templates (16 commands + 5 shortcuts + test-tools) |
| `templates/hooks/` | Hook script templates (4 hooks) |
| `templates/engrams/` | Engram templates + examples |
| `templates/rules/` | Path-scoped rule templates |
| `templates/.github/workflows/` | GH Actions templates (incl. notify-jit-knowledge.yml) |
| `templates/CLAUDE-brainstem.md` | CLAUDE.md template for new repos |
| `docs/` | Setup guide, commands reference, hooks guide |
| `install.sh` / `install.ps1` | Installation scripts (workspace/project/user modes) |

## Core Components

### Skills (`.claude/skills/`)

| Skill | Purpose |
|-------|---------|
| strategy | 3-phase gated workflow: plan -> approve -> execute |
| divergent | FRAME -> DIVERGE -> EVALUATE -> CONVERGE -> EXECUTE reasoning |
| rca | Root cause analysis with owner-gated closure |
| learn | Evaluate session for long-term knowledge persistence |
| session | Session lifecycle: new, save, load, switch, rename |
| health | Memory system diagnostic: line counts, stale sessions, missing engrams |
| review | Code review with holistic evaluation |
| gap | Gap analysis before presenting code changes |

### Always-On Rules (`.claude/rules/`)

Load every session. Never trigger-based -- always active.
Examples: trust zones, security guardrails, friction detection, verify-before-presenting, session-guardrail, autonomous-execution.

### Cognition (`.claude/cognition/`)

- `personas.md` -- specialist personas activated per-request
- `anti-patterns.md` -- learned mistakes to avoid
- `decisions/` -- decision frameworks (RCA, technology selection)

### Bundles (`.claude/bundles/`)

Domain knowledge loaded on demand via routing weights. Personal only in v0.4.5.
Line limit: warn at 230, hard cap at 280.

### Engrams (`.claude/engrams/`)

Per-project deep context updated by `/learn` at sprint completion or on architecture changes.
Line limit: warn at 230, hard cap at 280.

## Key Principles

- **DOE Framework:** Directive Orchestration Execution -- guardrails override goals
- **Reliability-first, security-aware** engineering identity
- **Fail fast over fail silently**
- **Follow existing patterns before inventing new ones**
- **Skills model:** composable, shareable, portable across Anthropic ecosystem
- **Open-source:** use "Owner" in all published docs, never personal names

## Conventions

| Convention | Value |
|---|---|
| File versioning | Name-01.md, Name-02.md (CLAUDE.md exempt; Hub.md never versioned) |
| Hub.md | Never versioned, never deleted, updated in place |
| Output | ASCII only, no emojis, no special characters |
| MEMORY.md line limit | 200 (hard, truncated by Claude Code) |
| Bundle/Engram line limit | 280 (warn at 230) |
| Session tag | `[session: <name> | DIV: <MODE>]` |
| Domain guard | jitneuro.ai primary; jitneuro.com redirects to .ai |

## Integration Points

- **Ghost CMS** -- blog publishing via API
- **GitHub** -- gh CLI, fine-grained PAT auth (expires 2026-07-31)
- **N8N** -- workflow automation (Python requests only -- curl 500s from shell escaping)
- **jit-knowledge** -- canonical shared knowledge repo; this repo is subscribed via `notify-jit-knowledge.yml`

## jit-knowledge Subscription

This repo is subscribed to `dstolts/jit-knowledge`'s `refresh-index` workflow.
Changes under `.jitneuro/{engrams,bundles,rules,cognition}/**` on `main` trigger
`.github/workflows/notify-jit-knowledge.yml` -> `repository_dispatch` -> jit-knowledge regenerates `INDEX.md`.

Token: `JITAI_OPENCLAW_PROD` secret (fine-grained PAT, Contents:write on `dstolts/jit-knowledge` only).

## Agent Execution

Agents run via Paperclip or equivalent dispatch infrastructure:

- Agents run `claude --dangerously-skip-permissions` inside their container
- Agent instructions from `<agents-dir>/<agent-name>/AGENTS.md` (canonical: `jit-knowledge/org/`)
- Create GH issue + `paperclip-dispatch` label + `agent:<role>` -> GitHub Actions dispatch -> agent runner
- Blocked issues: set `status=blocked` via API with numbered Owner action steps

### Agent roster

| Agent | Scope |
|-------|-------|
| Repo agent | Code quality guardian for this repo |
| sys-backend | API/server code changes |
| sys-frontend | Client/UI changes |
| sys-qa | Test suites |
| sys-security | Security audit (advisory only) |
| sys-devops | `.github/workflows/`, infra scripts |
| sys-architect | Architecture decisions |

## Not-this list

- NOT a compiled application -- pure Markdown + shell scripts
- NOT a SaaS product -- installs into user's Claude Code workspace
- NOT owner-specific -- all templates use "Owner" / "user" / "project owner"; never personal names
- NOT a product domain -- jitneuro.ai is the framework's canonical domain
