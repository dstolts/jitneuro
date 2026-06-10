---
type: skill
name: install
description: One-shot install of the JitNeuro framework on a machine. Trigger phrases include "install jitneuro", "set up jitneuro", "bootstrap jitneuro", "jitneuro first time setup", "wire jitneuro into Claude Code". Use on a fresh machine or after pulling a new JitNeuro release to copy the commands, rules, hooks, cognition layer, and horizon templates into the chosen .claude/ scope and register the Claude Code hooks.
purpose: 'One-shot bootstrap of the JitNeuro framework on a machine: runs install.sh / install.ps1 to copy templates into the chosen .claude/ scope, register Claude Code hooks in settings.local.json, scaffold the url-resolver, and print the next-steps primer. Read this when setting up JitNeuro on a fresh machine or after pulling a new release.'
tags: [skill, install, bootstrap, setup, jitneuro]
scope: public
departments: [all]
# leak_allow below: the public repo owner appears in the canonical clone URL -- intentional public info, not a private-identity leak
leak_allow: ["dstolts"]
owner_role: cos
read_when: When setting up JitNeuro on a fresh machine or after pulling a new release to copy templates into a .claude/ scope and register hooks.
last_evaluated: 2026-06-10
---

# Install JitNeuro (Bootstrap a Machine)

Brings a machine to a state where JitNeuro slash commands, rules, cognition layer,
hooks, and horizon templates are installed into a chosen `.claude/` scope, the
Claude Code hooks are registered, and the framework is ready to use.

JitNeuro is a standalone framework. It works with NO external knowledge catalog.
If your organization keeps a separate shared knowledge catalog repo, the installer
can record where to find it (optional) -- but a standalone install is the default
and is fully functional on its own.

## What this skill does (high level)

The installer (`install.sh` on macOS/Linux/Git-Bash, `install.ps1` on Windows
PowerShell) copies the contents of the repo's `templates/` tree into a target
`.claude/` directory and wires up Claude Code hooks. It:

1. Picks an install scope (workspace / project / user -- see below)
2. Detects whether this is a fresh install or an upgrade (reads the version from `jitneuro.json`)
3. Copies the slash commands (`templates/commands/*.md`) into `.claude/commands/`
4. Copies the framework rules (`templates/rules/*.md`) into `.claude/rules/`, respecting any `(DISABLED)` marker and preserving local edits
5. Copies the cognition layer (`templates/cognition/`: personas, friction-detection, anti-patterns, decision models) and seeds `owner-persona.md` from the example
6. Copies the helper scripts (`templates/scripts/*.sh`) and the local session dashboard (`templates/dashboard/`)
7. Copies the hook scripts (`templates/hooks/*.sh`) into `.claude/hooks/`
8. Seeds example `bundles/`, `engrams/`, and the `horizon/` strategic-context templates (only if those dirs are empty -- never overwrites your filled-in content)
9. Copies `jitneuro.json` and optionally records a shared-knowledge-catalog location
10. Registers the JitNeuro hooks in `.claude/settings.local.json` (merging with any existing hooks, never clobbering yours)
11. Scaffolds `~/.claude/url-resolver.md` (machine-specific repo-name -> local-path map; optional)
12. Records an upgrade-safe framework manifest (`.jitneuro-manifest.tsv`) so future upgrades prune only framework files and never touch your own files
13. Prints the next-steps block (restart Claude Code, run `/verify`, populate horizon, run `/onboard`)

## Install scopes

The installer takes ONE positional mode argument. Pick based on how broadly the
commands should be available:

| Mode | Target | Use when |
|---|---|---|
| `workspace` | parent directory's `.claude/` | You keep many repos under one folder and want shared commands + context across all of them |
| `project` | current directory's `.claude/` (default) | You want JitNeuro in a single repo only |
| `user` | `~/.claude/` | You want JitNeuro available in every project on the machine |

In `workspace` mode the installer also scans the parent folder for git repos and
reports which ones still need `/onboard` (CLAUDE.md / brainstem / engram).

## Cross-platform contract

- macOS / Linux: run `./install.sh [mode]`
- Windows with PowerShell: run `.\install.ps1 -Mode [mode]`
- Windows hooks require bash. `install.ps1` auto-detects Git for Windows bash and
  warns if it is missing (commands work without bash; hooks do not). Install Git
  for Windows from https://git-scm.com/downloads/win if hooks are needed.

Both installers are idempotent and safe to re-run. They never require admin
rights and never depend on Python, Node, or a package manager.

## Procedure

### 1. Prerequisites

Required:
- `git` (to clone the JitNeuro repo)
- A POSIX shell (`bash`) on macOS/Linux, OR PowerShell + Git-for-Windows bash on Windows

Recommended (improves the hook-merge step but not required):
- `jq` on macOS/Linux -- lets `install.sh` merge JitNeuro hooks into an existing
  `settings.local.json` without clobbering your own hooks. Without `jq`, an
  existing settings file is left untouched and you add the hooks block manually.

No Python, no Node, no PyYAML, no submodules are needed.

### 2. Clone (or pull) the JitNeuro repo

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
# or, to update an existing clone:
# git -C jitneuro pull --ff-only
```

### 3. Run the installer from the repo root

macOS / Linux / Git-Bash:

```bash
./install.sh project      # single repo (default)
./install.sh workspace    # parent folder, all repos underneath
./install.sh user         # ~/.claude, all projects on the machine
```

Windows PowerShell:

```powershell
.\install.ps1 -Mode project
.\install.ps1 -Mode workspace
.\install.ps1 -Mode user
```

The installer must be run from the JitNeuro repo root (it looks for `templates/`
relative to itself). It prints each component as it installs and finishes with a
summary and next-steps block.

### 4. Configure the shared knowledge catalog (optional)

On an interactive run the installer asks where to find a shared knowledge catalog:

```
Where should JitNeuro find your shared knowledge catalog?
  1) A separate repo / folder elsewhere (recommended -- most common)
  2) In this repo, in a .knowledge/ folder
  3) Personal: ~/.claude/.knowledge
  4) None -- run standalone (no shared catalog)   <-- default
```

Choose `4` for a standalone install (fully functional). If you maintain a shared
catalog, point to it; the choice is saved as `knowledgeRoot` in the installed
`jitneuro.json`. At runtime the resolution order is: `KNOWLEDGE_ROOT` env var ->
`~/.claude/url-resolver.md` map -> the saved `knowledgeRoot` -> a local
`.knowledge/` folder -> standalone. To set or override non-interactively, export
`KNOWLEDGE_ROOT` (POSIX) or set the `KNOWLEDGE_ROOT` env var (Windows) and re-run
with `--reconfigure` / `-Reconfigure`.

### 5. Hook registration

The installer writes the JitNeuro hook block into `.claude/settings.local.json`.
The shipped hook scripts (in `templates/hooks/`, copied to `.claude/hooks/`) cover
these Claude Code events:

- `SessionStart` -- session identity, write session id, post-clear refresh, compact recovery, scheduled-agent spawn
- `PreCompact` -- save state before context compaction
- `PreToolUse` -- branch-protection (Bash), pre-agent registration (Agent)
- `PostToolUse` -- heartbeat, post-agent completion
- `Stop` -- autonomous-continuation queue (powers `/afk`)
- `SessionEnd` -- autosave (and lessons flush)

Each hook `command` value is a bare script path. Never prefix it with `bash` or
`bash.exe` -- that breaks every hook (see `rules/claude-code-hook-deployment.md`).
The installer already writes these correctly; the rule documents the constraint
for anyone editing the config by hand.

If a `settings.local.json` already exists, the installer merges JitNeuro's hooks
in and preserves any hooks you added yourself. If the merge tool is unavailable,
it leaves your file untouched and tells you to add the block manually.

### 6. Next steps (printed by the installer)

```
JitNeuro vX.Y.Z installed to: <target>/.claude

Next steps:
  1. CLOSE AND REOPEN Claude Code (commands load at session start)
  2. Run /verify to confirm everything is working
  3. Populate your horizon: tell Claude "populate my horizon files"
     (or open <target>/.claude/horizon/POPULATE-HORIZON.md)
  4. Run /onboard <repo> to set up context for your repos
  5. Create bundles for your domains in <target>/.claude/bundles/
  6. (optional) Edit ~/.claude/url-resolver.md to map repo names to local paths

*** You MUST restart Claude Code for slash commands to take effect. ***
```

Restarting Claude Code is mandatory -- slash commands and hooks are loaded at
session start. After restart, `/verify` confirms commands, hook scripts, hook
config, hook paths, hook events, bundles, engrams, and the url-resolver.

## QA Gates

Reject or revise the install if any of these are true:

- The installer was run from somewhere other than the JitNeuro repo root (it cannot find `templates/` and exits)
- After install, `.claude/settings.local.json` has no JitNeuro hook block AND no merge warning was surfaced (hooks are how session continuity, heartbeat, and `/afk` work)
- The installer silently overwrote a user-edited framework rule instead of backing it up to `.jitneuro-backup/rules/` (per-machine rules may be intentionally edited)
- The installer overwrote a populated `horizon/`, `bundles/`, or `engrams/` directory (those are seeded only when empty)
- A hook `command` in `settings.local.json` was written with a `bash`/`bash.exe` prefix instead of a bare script path
- The operator skipped the mandatory Claude Code restart and reported commands as "not working" before restarting
- The install was assumed to require Python, Node, PyYAML, or a git submodule (none are used)

## Required Tooling

- `git`, `bash` (POSIX) -- required on macOS/Linux/Git-Bash
- PowerShell + Git-for-Windows bash -- required on Windows for hooks
- `jq` -- recommended on macOS/Linux for clean hook merging into an existing settings file

## After This Skill Completes

The machine has:
- JitNeuro commands installed in the chosen `.claude/commands/`
- Framework rules in `.claude/rules/`
- The cognition layer (personas, friction-detection, anti-patterns, decision models) in `.claude/cognition/`
- Hook scripts in `.claude/hooks/` and the hook block registered in `.claude/settings.local.json`
- Helper scripts and the local session dashboard installed
- Example `bundles/`, `engrams/`, and `horizon/` strategic-context templates (seeded only if empty)
- `jitneuro.json` with the chosen knowledge-catalog setting (standalone by default)
- A scaffolded `~/.claude/url-resolver.md`
- An upgrade-safe `.jitneuro-manifest.tsv`

The operator's NEXT action is to restart Claude Code and run `/verify`.

## Related

- `install.sh` -- the POSIX installer (the implementation of the procedure above)
- `install.ps1` -- the Windows PowerShell installer
- `skills/update/SKILL.md` -- re-running the installer to upgrade an existing install
- `templates/commands/verify.md` -- the `/verify` post-install check
- `templates/rules/claude-code-hook-deployment.md` -- the hook-command-format rule the installer obeys
- `templates/horizon/POPULATE-HORIZON.md` -- how to fill in the strategic-context templates after install
- `README.md` / `QUICKSTART.md` -- one-page summary including these install steps
