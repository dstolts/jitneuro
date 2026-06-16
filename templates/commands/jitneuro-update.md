# JitNeuro Update

Update the installed JitNeuro framework to the latest version: pull the JitNeuro clone,
re-run the installer (idempotent + version-aware), refresh the knowledge catalog, and verify.
This is the turnkey `/jitneuro-update` -- read it and run it; it just happens.

## When to Use
- After a new JitNeuro release, to refresh commands / rules / hooks / dashboard
- On a second machine, to bring it current with the latest framework + knowledge
- When installed commands or hooks have drifted from the shipped templates
- As the routine "bring me up to date" action

## What It Does
Re-running the installer IS the update path -- version-aware and idempotent. It backs up any
framework file you edited, installs new/changed files, prunes ones the new version dropped
(sha-guarded), and preserves your own files + your configured knowledgeRoot. Full contract:
`skills/update/SKILL.md`.

## Instructions

When invoked as `/jitneuro-update`:

### Step 1: Resolve the JitNeuro clone
- Resolve the clone path: `JITNEURO_HOME` env -> `jitneuro.json` location -> the directory the
  framework was installed from. If it cannot be resolved, ask the user for the clone path.

### Step 2: Pull latest
- `cd <jitneuro-clone>`
- `git checkout main` (or the release tag the user pins)
- `git pull --ff-only`
- Note the previous version -> new version from `jitneuro.json`.

### Step 3: Re-run the installer in the SAME scope
- Detect the existing install scope (project / workspace / user). If unsure, run `/verify` first --
  it reports the install path.
- Windows PowerShell: `powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Mode <scope>`
- macOS / Linux / Git-Bash: `bash scripts/install.sh <scope>`

### Step 4: Refresh the knowledge catalog (if configured)
- If a shared knowledge catalog (knowledgeRoot) clone is configured, pull it too so the catalog is
  current: `cd <knowledgeRoot>` then `git pull --ff-only`.

### Step 5: Restart + verify
- Tell the user to restart the tool (slash commands + hooks load at session start).
- After restart, run `/verify` to confirm components + hook events are healthy.

### Step 6: Report
- Report: version old -> new, what changed (commands / rules / hooks updated, files pruned),
  knowledgeRoot, and any framework files that were backed up because the user had edited them.

## Important
- Idempotent + safe to re-run; never requires admin; no Python / Node dependency.
- The installer NEVER overwrites the user's own files or a populated horizon / bundles / engrams dir.
- A `(DISABLED)` first-line marker on a rule is respected (skipped, not restored).
- Restart is mandatory -- an in-flight session will not see new commands / hooks until reopened.
- This is the framework update only. To populate a repo's `.knowledge/` after updating, use the
  repo-knowledge-adoption playbook.
