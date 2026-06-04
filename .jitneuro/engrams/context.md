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
version: v0.5.0
repo: dstolts/jitneuro
---

# jitneuro Engram

**Status:** Production

This file is also a worked EXAMPLE of an engram -- per-project deep context an
adopter would keep under `.jitneuro/engrams/` (team-shared) or `.claude/engrams/`
(personal). Use it as a model for your own.

## Identity

JitNeuro is an **open-source AI engineering framework for Claude Code**. It provides
structured behaviors (skills, rules, hooks, cognition) that make AI assistants
reliable, security-aware, and production-grade.

Design principle: every decision must work for ANY adopter, not just the author's
own setup.

- **GitHub:** `dstolts/jitneuro`
- **Local checkout:** resolve through the current workspace clone or configured runtime root; never assume a specific machine's absolute path.
- **Domains:** jitneuro.ai (primary), jitneuro.com (redirects to .ai)
- **Current version:** v0.5.0

## Architecture

### Skills-first

Behavior is composable: install the pieces you want, remove what you don't.

- `.claude/skills/<skill-name>/SKILL.md` is the primary behavior mechanism (SKILL.md with YAML frontmatter, progressive disclosure)
- `.claude/commands/` still work but are legacy; skills take precedence
- Install the set by default; users disable what they don't want

### What ships

- Skills architecture: `.claude/skills/<skill-name>/SKILL.md`
- Always-on rules: trust zones, friction detection, verify-before-presenting, scope guards
- Cognition layer: personas.md, anti-patterns.md, decisions/
- Hooks: SessionStart identity injection, PostToolUse heartbeat, PreCompact save + reload directive, branch protection
- Horizon: vision / mission / goals / operating-rhythm / owner-profile templates + a guided interview
- Bundles and engrams (on-demand domain + project context)
- Cross-platform install via `install.sh` / `install.ps1`

### Roadmap (later)

- Shared team folders (`.jitneuro/`), team-promotion workflow
- Enterprise docs and dashboard

## Key Paths

| Path | Purpose |
|------|---------|
| `templates/commands/` | Slash command templates |
| `templates/skills/` | Skill templates (SKILL.md) |
| `templates/hooks/` | Hook script templates |
| `templates/rules/` | Behavioral rule templates |
| `templates/horizon/` | Strategic-context templates + POPULATE-HORIZON interview |
| `templates/cognition/` | Personas, anti-patterns, decision models |
| `templates/engrams/` | Engram templates + examples |
| `templates/CLAUDE-brainstem.md` | CLAUDE.md template for new repos |
| `docs/` | Setup guide, commands reference, hooks guide |
| `install.sh` / `install.ps1` | Installation scripts (workspace/project/user modes) |

## Core Components

### Skills (`.claude/skills/`)

Composable behaviors. Examples: a gated strategy/plan workflow, divergent-thinking
reasoning, root-cause analysis, session save/load, memory health, code review,
gap analysis.

### Always-On Rules (`.claude/rules/`)

Load every session -- always active, not trigger-based. Trust zones, security
guardrails, friction detection, verify-before-presenting, autonomous execution.

### Cognition (`.claude/cognition/`)

- `personas.md` -- specialist personas activated per-request
- `anti-patterns.md` -- learned mistakes to avoid (built by /learn)
- `decisions/` -- decision frameworks (RCA, technology selection)

### Bundles + Engrams

Domain knowledge (bundles) and per-project deep context (engrams), loaded on demand.

## Key Principles

- **DOE Framework:** Directive Orchestration Execution -- guardrails override goals
- **Reliability-first, security-aware** engineering identity
- **Fail fast over fail silently**
- **Follow existing patterns before inventing new ones**
- **Composable + portable** across the Anthropic ecosystem
- **Open-source:** use "Owner" / "user" in published docs, never personal names

## Conventions

| Convention | Value |
|---|---|
| File versioning | Name-01.md, Name-02.md (CLAUDE.md exempt; Hub.md never versioned) |
| Hub.md | Never versioned, never deleted, updated in place |
| Output | ASCII only, no emojis, no special characters |
| Session tag | `[session: <name> \| DIV: <MODE>]` |

## Not-this list

- NOT a compiled application -- pure Markdown + shell scripts
- NOT a SaaS product -- installs into the user's Claude Code workspace
- NOT owner-specific -- all templates use "Owner" / "user" / "project owner"; never personal names
