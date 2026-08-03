---
type: pattern
purpose: Any framework installer or orchestrator configuring AI agent access for an enterprise or multi-team environment MUST consult this before setting write scope -- firing when installing into a shared workspace with distinct team boundaries or compliance requirements -- because omitting isolation lets one team's agent read, influence, or overwrite another team's repo context, violating access controls and creating audit complexity that blocks compliance attestation.
read_when: Before installing or configuring agent access in any shared workspace with distinct team boundaries or compliance requirements.
tags: [enterprise-isolation, multi-repo, team-mode, access-control]
scope: public
departments: [all]
status: canonical
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
source: backport from jitneuro docs/ 2026-05-28
---

# Enterprise Isolation Mode

How to run the framework in strict single-repo mode with no cross-repo access.

## Why Isolation Matters

In enterprise environments:
- Repos belong to different teams with different access controls
- Sensitive data in one repo must not leak into another repo's context
- Compliance requires clear boundaries on what AI can read and write
- Shared state across repos creates audit complexity
- Team A's bundles/engrams should not influence Team B's sessions

## Two Modes

| | Single-Repo (Isolated) | Multi-Repo (Shared) |
|---|---|---|
| Install | `./install.sh project` | `./install.sh workspace` |
| Scope | One repo only | All repos under workspace |
| Bundles | Repo's `.knowledge/bundles/` | Workspace `.knowledge/bundles/` |
| Engrams | Repo's `.knowledge/engrams/` | Workspace `.knowledge/engrams/` |
| Session state | Repo's `.sessions/` | Workspace `.sessions/` |
| Cross-repo | Blocked by CLAUDE.md rule | Enabled by write access grant |
| /save | Saves within repo | Saves at workspace level |
| /learn | Updates repo files only | Updates shared files |
| Best for | Enterprise, compliance, team isolation | Solo dev, small team, multi-repo projects |

## How to Enable Isolation

### 1. Install at project level

```bash
cd your-repo
/path/to/jitneuro/install.sh project
```

This creates `.claude/` inside the repo with all JitNeuro commands, templates,
and directories. Nothing is shared with other repos.

### 2. Configure the brainstem

In your repo's `.claude/CLAUDE.md`, use **Option A** from the brainstem template:

```markdown
## JitNeuro Mode
JitNeuro is scoped to THIS REPO only.
- Read/write: `.claude/` within this repo
- Read/write: MEMORY.md auto-memory
- DO NOT read or write files outside this repository
- DO NOT access parent workspace .claude/ directories
```

This is a hard boundary. Claude will not read or write files outside the repo,
even if a workspace-level `.claude/` exists above it.

### 3. No workspace-level install

Do NOT run `./install.sh workspace`. If a workspace-level `.claude/` already
exists, the brainstem rule above prevents Claude from accessing it.

### 4. Engrams stay local

Each repo has its own engram in `.knowledge/engrams/`. Team A's project context
never appears in Team B's session.

### 5. Session state stays local

Session checkpoints are saved inside the repo. They cannot reference files
in other repos. Cross-repo sessions are not possible in isolated mode.

## What Still Works in Isolated Mode

Everything except cross-repo features:
- /save and /load (scoped to this repo)
- /learn (updates this repo's bundles, engrams; flags new routes for PR to jit-knowledge/INDEX.md)
- /sessions (lists this repo's sessions only)
- /orchestrate (subagents scoped to this repo)
- Conversation logging (.logs/ inside this repo)
- Routing from jit-knowledge/INDEX.md (shared across all users; extensions via PR)
- Compact instructions
- All bundle and engram management

## What Does NOT Work in Isolated Mode

- Cross-repo session state (one session spanning multiple repos)
- Shared bundles (domain knowledge used across repos)
- Shared engrams (project context visible from other repos)
- Master session orchestration (delegating to agents in other repos)
- Cross-repo sprint protocol (API + FE in one session)

These features require multi-repo mode.

## Migration: Isolated to Multi-Repo

If a team later decides to share context:

1. Run `./install.sh workspace` from the parent directory
2. Move shared bundles to workspace `.knowledge/bundles/`
3. Move engrams to workspace `.knowledge/engrams/`
4. Update brainstem to Option B (multi-repo write access grant)
5. Project-level `.claude/commands/` can be removed (workspace commands take over)

Project-level bundles and engrams still work alongside workspace ones --
Claude Code merges all levels, with project-level taking priority.

## Migration: Multi-Repo to Isolated

If a team needs to lock down:

1. Copy any shared bundles into the repo's `.knowledge/bundles/`
2. Copy the repo's engram into `.knowledge/engrams/`
3. Update brainstem to Option A (isolated mode)
4. Delete or ignore workspace-level `.claude/` (the brainstem rule blocks access)

## Per-Team Isolation in a Monorepo

For monorepos where different teams own different directories:

```
monorepo/
  .claude/
    CLAUDE.md          <-- shared brainstem (minimal, team-neutral)
    commands/          <-- shared JitNeuro commands
  team-a/
    .claude/
      bundles/         <-- Team A domain knowledge
      engrams/         <-- Team A project context
      CLAUDE.md        <-- Team A rules (overrides shared)
  team-b/
    .claude/
      bundles/         <-- Team B domain knowledge
      engrams/         <-- Team B project context
      CLAUDE.md        <-- Team B rules (overrides shared)
```

Claude Code merges CLAUDE.md from all levels. Team-level rules override shared
rules. Bundles and engrams at team level are loaded only when working in that
team's directory. This gives shared commands with isolated context.

## Compliance Notes

- MEMORY.md (auto-memory) is always per-user (the agent's local project directory). It is NOT
  shared between users. Each developer has their own MEMORY.md. Routing is shared via jit-knowledge/INDEX.md.
- Session state files may contain summaries of code and decisions. Include
  `.sessions/` in your `.gitignore` if these should not be committed.
- Conversation logs (`.logs/`) may contain user prompts verbatim. Always gitignore.
- Bundles and engrams are documentation, not code. They may be committed to the
  repo for team sharing, or gitignored for individual use.
