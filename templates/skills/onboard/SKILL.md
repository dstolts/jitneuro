---
type: skill
purpose: Bootstrap a new repo into the DOE/JitNeuro framework with automated assessment, file generation, and verification; skipping means the repo lacks the CLAUDE.md, engram, and trust-zone guardrails the framework requires.
read_when: When adding a new repository to the JitNeuro framework and it lacks CLAUDE.md, engram, or jitneuro scaffolding.
tags: [onboard, bootstrap, doe, jitneuro, repo-setup, automation]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /onboard <repo>

Bootstrap a new repo into the DOE/JitNeuro framework.

## Steps

**Step 1: Assess current state**

Check the repo for:
- Existing CLAUDE.md / AGENTS.md
- Existing .claude/ folder
- Existing .jitneuro/ folder
- Existing engram in workspace .claude/engrams/
- Git remote URL (to derive repo name)
- Primary language and framework
- Test setup

**Step 2: Analyze via subagent**

Dispatch a subagent to:
- Read key files (package.json, README, main entry point)
- Identify tech stack, key paths, conventions
- Draft engram content based on findings

**Step 3: Generate files**

Propose creating:
- `.claude/CLAUDE.md` -- project passport (tech stack, key paths, notes)
- `.claude/` folder with commands symlinked or copied from workspace
- Engram at workspace `.claude/engrams/<repo>-context.md`
- `.jitneuro/jitneuro.json` -- repo config (team, scheduled agents)

**Step 4: Present for approval**

Show all proposed files and their content before writing. User must confirm.

**Step 5: Execute**

Write approved files. Never overwrite existing files without explicit confirmation.

**Step 6: Verify**

Run `/verify` to confirm installation is working.

## What onboard does NOT do

Does not modify existing code. Does not commit. Does not push. Framework files only.
