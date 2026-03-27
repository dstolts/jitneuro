# .jitneuro/ -- Team Knowledge Directory

This directory contains team-shared knowledge for AI-assisted development.
Everything here is committed to git and shared across the team.

## Structure

```
.jitneuro/
  rules/              -- Team-approved rules (loaded for everyone)
  engrams/            -- Project context files (deep knowledge per project area)
  bundles/            -- Domain knowledge (loaded on-demand via routing weights)
  cognition/          -- Team personas, decision frameworks
  users/              -- Per-developer spaces (auto-created)
    <username>/
      active-work.md  -- Current task, branch, blockers (auto by /save)
      lessons.md      -- /learn output, team promotion staging
      rules/          -- Personal repo-level rules (loaded for this user only)
      afk-log.md      -- Autonomous execution records (auto by session tracking)
  TEAM.md             -- Member list, roles, TeamApprover flags
  context-manifest.md -- Team routing weights for on-demand bundle loading
  jitneuro.json       -- Repo-level scheduled agents (optional)
```

## What Gets Loaded

**Team context (everyone):**
1. `rules/` -- all files loaded every session
2. `engrams/` -- loaded on demand or by routing weights
3. `bundles/` -- loaded on demand via context-manifest.md
4. `cognition/` -- personas and decision frameworks
5. `context-manifest.md` -- routing weight definitions

**Personal context (you only):**
- `users/<YOUR_USERNAME>/rules/` -- your repo-level preferences
- `.claude/` (gitignored) -- session state, local config, credentials

**Not loaded for you:**
- `users/<OTHER_PEOPLE>/rules/` -- their personal preferences
- `users/<OTHER_PEOPLE>/lessons.md` -- visible in git for review, not loaded

## Progressive Enhancement

| Mode | Setup | Behavior |
|------|-------|----------|
| Solo | No .jitneuro/ | Current v0.x behavior, nothing changes |
| Small team | .jitneuro/ without TEAM.md | Everyone is TeamApprover |
| Full team | .jitneuro/ with TEAM.md | Roles, lesson queue, promotion flow |
| Enterprise | + CODEOWNERS on .jitneuro/rules/ | Branch protection on team rules |

## Getting Started

Run `/onboard --team` in your repo to create this structure.
