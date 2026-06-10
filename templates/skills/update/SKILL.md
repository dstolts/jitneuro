---
type: skill
name: update
purpose: 'Update an existing JitNeuro install: pull the latest release and re-run install.sh / install.ps1. The installer is version-aware and idempotent -- it upgrades framework files, prunes ones the new version dropped, backs up any framework file you edited, and never touches your own files. MUST be re-run after pulling a new JitNeuro release so commands, rules, hooks, and the dashboard stay in sync.'
tags: [skill, update, upgrade, install, jitneuro]
scope: public
departments: [all]
read_when: After pulling a new JitNeuro release, or whenever installed commands / hooks drift from the shipped templates and need re-syncing.
last_evaluated: 2026-06-10
---

# Update JitNeuro (Refresh an Existing Install)

Re-running the installer IS the update path. There is no separate migration
script. The installer detects the previously installed version, performs a safe
upgrade, and prints what changed.

## When to use

- After `git pull` on your JitNeuro clone (a new release may have changed commands, rules, hooks, or the dashboard)
- After the JitNeuro repo publishes a new version and you want it
- Whenever an installed command, rule, or hook script drifts from the shipped template and you want to re-sync
- To change the install scope or reconfigure the shared-knowledge-catalog location

## Procedure

### 1. Pull the latest JitNeuro

```bash
cd jitneuro
git pull --ff-only
```

Or check out a specific tag if you pin to releases:

```bash
git fetch --tags
git checkout v0.5.0
```

### 2. Re-run the installer in the SAME scope you installed before

macOS / Linux / Git-Bash:

```bash
./install.sh project      # or workspace / user -- match your original install
```

Windows PowerShell:

```powershell
.\install.ps1 -Mode project
```

The mode must match the scope you originally installed (`project`, `workspace`,
or `user`); otherwise you install a second copy in a different `.claude/`. Run
`/verify` first if you are unsure which scope holds your install -- it reports
the install path.

### 3. What a re-run does (idempotent, upgrade-safe)

The installer reads the version from the installed `jitneuro.json`, compares it
to the new version, and prints `Fresh install`, `Re-installing ... (same
version)`, or `Upgrading: vOLD -> vNEW`. Then it:

- Backs up any command that differs to `commands/.backup/` before overwriting
- Installs new and changed commands, rules, cognition files, scripts, dashboard files, and hook scripts
- Respects a `(DISABLED)` marker on the first line of any installed rule -- skips it instead of restoring it
- Preserves YOUR edits: if you changed a framework rule since the last install, your copy is saved to `.jitneuro-backup/rules/` before the new version lands
- Seeds `horizon/`, `bundles/`, and `engrams/` ONLY if those dirs are empty -- never overwrites your filled-in strategic context, bundles, or engrams
- Re-merges the JitNeuro hook block into `settings.local.json`, preserving any hooks you added
- Preserves the previously configured `knowledgeRoot` unless you pass `--reconfigure` / `-Reconfigure`
- Updates the framework manifest (`.jitneuro-manifest.tsv`) and PRUNES framework files the new version dropped -- but only if you did not edit them (sha-guarded); edited now-removed files are KEPT with a notice
- Files NOT in the manifest are YOURS and are never touched

### 4. Reconfigure the knowledge catalog (optional)

To change where JitNeuro looks for a shared knowledge catalog, re-run with the
reconfigure flag:

```bash
./install.sh project --reconfigure
```

```powershell
.\install.ps1 -Mode project -Reconfigure
```

Or set the `KNOWLEDGE_ROOT` env var before running to override per-machine
without editing config. Standalone (no catalog) remains the default.

### 5. Restart and verify

```
1. CLOSE AND REOPEN Claude Code (commands and hooks load at session start)
2. Run /verify to confirm all components and hook events are healthy
```

The restart is mandatory after every update -- Claude Code loads slash commands
and hooks at session start, so an in-flight session will not see the new
versions until it is reopened.

## What the installer will NOT overwrite

- Your own files (anything not in `.jitneuro-manifest.tsv`)
- A populated `horizon/`, `bundles/`, or `engrams/` directory
- `cognition/owner-persona.md` once you have customized it (seeded only on first install)
- A rule whose first line carries the `(DISABLED)` marker
- A framework rule you edited (it is backed up to `.jitneuro-backup/rules/` before the new version is applied)
- An existing `~/.claude/url-resolver.md`

## QA Gates

Reject or revise the update if any of these are true:

- The installer was re-run in a different scope than the original install, creating a duplicate `.claude/` (run `/verify` to confirm the install path first)
- A user-edited framework rule was overwritten with no backup in `.jitneuro-backup/rules/`
- A populated `horizon/`, `bundles/`, or `engrams/` directory was wiped (those are seeded only when empty)
- The operator skipped the mandatory Claude Code restart after updating
- The update was assumed to require a submodule pin bump, PyYAML, or a separate manifest-rebuild script (none are used -- re-running the installer is the whole update)

## Related

- `install.sh` -- the idempotent POSIX installer that also performs upgrades
- `install.ps1` -- the Windows PowerShell installer
- `skills/install/SKILL.md` -- first-time install; full contract for each install step
- `templates/commands/verify.md` -- the `/verify` post-update health check
- `templates/hooks/` -- the hook scripts re-installed on every run
