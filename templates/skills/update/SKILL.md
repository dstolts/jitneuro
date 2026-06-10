---
type: skill
name: update
purpose: 'Update an existing jitneuro install: pull latest changes, re-materialize the load rule + repo-local CLAUDE.md + SessionStart identity hook, and bump submodule consumers to the new pin. MUST be run after any `git pull` on the jitneuro clone so hook files, rules, and manifest stay in sync with the new tree.'
tags: [skill, update, install, bootstrap, jitneuro, sessionstart-hook]
scope: public
departments: [all]
read_when: After running `git pull` on the jitneuro clone or after bumping the `.jitneuro` submodule pin in any consuming repo.
last_evaluated: 2026-06-03
---

# Update jitneuro (Refresh an Existing Install)

Re-running the installer is the update path. No separate migration script needed.

## When to use

- After `git pull` on the jitneuro clone (template files may have changed)
- After bumping the `.jitneuro` submodule pin in a consuming repo
- After the knowledge catalog repo tags a new release and your pin advances
- Whenever `~/.claude/hooks/jitneuro-session-start.sh` or `~/.claude/rules/jitneuro-load.md` drifts from the shipped template

## Procedure

### 1. Pull latest changes

```bash
cd "$JITNEURO_KNOWLEDGE_ROOT"   # e.g. <CodeBasePath>\jitneuro
git pull --ff-only
```

Or fetch + checkout a specific tag per `governance/PIN-POLICY.md`:

```bash
git fetch --tags
git checkout v1.4
```

### 2. Re-run the installer

```bash
bash scripts/install.sh
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

`scripts/install.sh` is idempotent. Re-running it:

- Refreshes the jitneuro clone (step 2 -- already done in step 1 if you pulled manually, but safe to re-run)
- Installs any new per-component node dependencies (step 3)
- Ensures PyYAML is current (step 4)
- Updates `~/.claude/rules/jitneuro-load.md` if the shipped template has changed and the local file matches the previous shipped version; warns and preserves local edits if the file diverged (step 5)
- Re-materializes `.claude/CLAUDE.md` inside the clone (step 5b)
- **Overwrites** `~/.claude/hooks/jitneuro-session-start.sh` with the repo-canonical version and re-registers it in `~/.claude/settings.json` if not already present (step 5c) -- hook files are always overwritten because the repo copy is canonical
- Updates `workspace.json` with `jitneuro_knowledge_root` if the file exists (step 6)
- Validates INDEX.md is current; warns if a manifest refresh is needed (step 7)
- Prints the foundational read primer (step 8)

### 3. Bump submodule consumers (if applicable)

For any downstream repo that consumes jitneuro as a `.knowledge/` submodule, bump the pin per `governance/PIN-POLICY.md`:

```bash
cd <consuming-repo>
git -C .jitneuro checkout <new-tag-or-sha>
git add .jitneuro
git commit -m "chore(jitneuro): bump pin to <new-tag>"
```

After bumping, re-run the consuming repo's own install or adapter-sync if it materializes local rule/hook copies from the submodule.

## What install.sh will NOT overwrite

- `~/.claude/rules/jitneuro-load.md` if the local copy diverges from the shipped template (preserved with a WARN; merge manually)
- `.claude/CLAUDE.md` inside the clone if the local copy diverges from `templates/claude-repo-local/CLAUDE.md` (same WARN + preserve behavior)

The hook file (`~/.claude/hooks/jitneuro-session-start.sh`) IS always overwritten because it is a mechanical artifact that must match the repo version exactly. If you have made local edits to the hook, re-apply them after the update or upstream them to jitneuro via a PR.

## Related

- `scripts/install.sh` -- the idempotent installer; the implementation of this procedure
- `scripts/install.ps1` -- Windows entry point that delegates to install.sh via Git Bash
- `skills/install/SKILL.md` -- one-shot bootstrap (first-time install); full contract for each install step
- `governance/PIN-POLICY.md` -- pinning and version bump cadence for consuming systems
- `skills/update-index/SKILL.md` -- refresh INDEX.md after adding or changing artifacts
- `templates/claude-hooks/session-start-master-orchestrator-rule.sh` -- the hook file re-installed by step 5c
- `rules/interactive-master-orchestrator.md` -- the identity rule the hook injects at session start
