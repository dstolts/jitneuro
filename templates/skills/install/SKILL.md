---
type: skill
name: install
description: One-shot install of jit-knowledge on a consuming machine. Trigger phrases include "install jit-knowledge", "set up jit-knowledge", "bootstrap jit-knowledge", "jit-knowledge first time setup", "wire jit-knowledge into Claude Code". Use on a fresh machine or after a major reinstall to put jit-knowledge in its canonical location, install per-component dependencies, register the load rule with Claude Code, and prime the session with the horizon docs.
purpose: 'One-shot bootstrap of jit-knowledge on a new consuming machine: clones the repo, installs dependencies, drops the Claude Code load rule, and prints the mandatory horizon-doc reading primer. Read this when setting up jit-knowledge on a fresh machine or after a major reinstall.'
tags: [skill, install, bootstrap, setup, jit-knowledge]
scope: public
departments: [all]
leak_allow: ["Code/jit-knowledge", "Code\jit-knowledge", "C:\Users", "C:/Users"]
owner_role: cos
read_when: When setting up jit-knowledge on a fresh machine or after a major reinstall to clone the repo, install dependencies, and register hooks.
last_evaluated: 2026-06-03
---

# Install jit-knowledge (Bootstrap a Consuming Machine)

Brings a new machine to a state where jit-knowledge skills, charters, engrams, playbooks, workflows, and patterns are discoverable + the foundational horizon context (vision + mission + personal-constitution-simplified) is loaded at session start.

## What this skill does (high level)

1. Verifies prerequisites (git, gh, node, python, bash)
2. Clones jit-knowledge to the canonical local path (or refreshes an existing clone)
3. Installs per-component node dependencies (gtm-gate, ux-narration-agent, visual-review-agent each have a `package.json`)
4. Installs Python dependency PyYAML (used by `scripts/rebuild-index.py` + `scripts/rebuild-manifest.py`)
5. Drops the `jit-knowledge-load.md` rule into the consuming user's `~/.claude/rules/` (idempotent)
5a. Drops the `hub-guardrail.md` rule (no-secrets-in-Hub.md + gitignore-scope) into `~/.claude/rules/` (idempotent; mirrors step 5)
5b. Materializes the gitignored `.claude/CLAUDE.md` from `templates/claude-repo-local/CLAUDE.md` inside the jit-knowledge clone
5d. Wires the in-repo `hooks/pre-push` hook via `git config core.hooksPath hooks` (mechanical enforcement of `rules/worktree-discipline.md` -- refuses pushes from main clone on non-default branches; worktrees pass through unblocked)
5c. Installs `templates/claude-hooks/session-start-master-orchestrator-rule.sh` to `~/.claude/hooks/jit-knowledge-session-start.sh` and registers it under `hooks.SessionStart` in `~/.claude/settings.json` (idempotent -- always overwrites the hook file; skips settings registration if already present)
5e. Installs `templates/claude-hooks/pre-compact-knowledge-rebootstrap.sh` to `~/.claude/hooks/jit-knowledge-pre-compact.sh` and registers it under `hooks.PreCompact` in `~/.claude/settings.json` (idempotent; mirrors 5c pattern). Fires on Claude Code's PreCompact event and injects a post-compact directive instructing the session to invoke `/knowledge` as its first action so the bootstrap chain + TodoWrite are re-anchored from durable state (Hub.md + session-state) after context compaction. Origin: 2026-05-28 -- post-compact loss of in-conversation TodoWrite + bootstrap discipline drift.
5f. Resolves and logs canonical placeholders (`<CodeBasePath>`, `<jit-knowledge-root>`) per `governance/path-conventions.md` section 3a, and prints the install-time artifact registry (below) so Owner sees exactly which docs / scripts / hooks now point at which real paths.
6. Updates `~/.claude/workspace.json` to record both `jit_knowledge_root` (this clone) AND `codeBasePath` (the workspace code root that `<CodeBasePath>` placeholder resolves to). Derives `codeBasePath` from the parent dir of `JIT_KNOWLEDGE_ROOT` unless env `CODE_BASE_PATH` is set. Idempotent (skips write if both values already match).
7. Runs the manifest refresh once to validate INDEX.md is current
8. Prints a "post-install" block that names the foundational reads to do next:
   - `horizon/vision.md` (auto-loads `mission.md` + `personal-constitution-simplified.md` per its footer)
   - `horizon/business-strategies.md`
   - `horizon/goals-2026.md` (and the active quarter file, e.g. `goals-2026-q2.md`)
   - `horizon/decision-routing.md`
   - `horizon/operating-rhythm.md`

## Artifacts that need `<CodeBasePath>` at install time

These artifacts reference `<CodeBasePath>` (the per-machine workspace code
root, per `governance/path-conventions.md` section 3a) in their body. At
install time, the install script resolves `<CodeBasePath>` for this machine
and logs the value so Owner can verify substitution will land at the right
place when these artifacts are consumed.

Resolution chain for `<CodeBasePath>` (first match wins):
1. env `CODE_BASE_PATH`
2. `~/.claude/workspace.json` `codeBasePath` key
3. Default: `$HOME/Code` (POSIX) / `%USERPROFILE%\Code` (Windows)

### Registry (kept in sync with artifacts on every merge)

| Artifact | Where `<CodeBasePath>` appears | Notes |
|---|---|---|
| `rules/worktree-discipline.md` | Worktree path convention `<CodeBasePath>/_worktrees/<repo>-<branch-slug>/` | Doc; consumer substitutes on read |
| `skills/worktree-new/SKILL.md` | Default target path | Slash command; resolves at invocation time |
| `skills/worktree-remove/SKILL.md` | Target path for removal | Slash command; resolves at invocation time |
| `skills/worktree-status/SKILL.md` | Per-worktree path display | Slash command; resolves at invocation time |
| `skills/session-close/SKILL.md` | Hub.md + session-state file paths | Slash command; resolves at invocation time |
| `workflows/pre-push-hook-worktree-discipline.md` | Error message refusal text refers to worktree path | Doc; the actual hook (`hooks/pre-push`) prints the path it expects -- text uses `<CodeBasePath>` substitution by the install script when generating the hook, or by the hook itself at runtime via env-var fallback |
| `workflows/nightly-pull-jit-knowledge.md` | Task scheduler script + log file path | Doc + scheduled-task spec; consumer substitutes |
| `hooks/pre-push` | Error message text (only -- the logic uses `$GIT_DIR` directly) | The hook script may EMBED the substituted path at install time so error messages show real paths; or use a runtime fallback. See "Hook path substitution" below. |

### Hook path substitution

For executable scripts (like `hooks/pre-push`), the recommended pattern is:

1. Script reads env `CODE_BASE_PATH` at runtime
2. Falls back to the OS-appropriate default
3. Composes user-facing messages using the resolved value

This avoids template-rewriting the hook at install time (cleaner versioning;
the hook on disk matches the hook in the repo). When the install script
substitutes, it logs the resolved value -- it does NOT modify the on-disk
hook content.

### When the registry must be updated

Every PR that introduces a new artifact referencing `<CodeBasePath>` in its
body MUST add a row to this registry table in the same PR. Reviewers check
this before approving.

---

## Cross-platform contract

The install script works on:
- macOS (system bash + zsh)
- Windows with Git Bash
- Linux (bash)

It does NOT use Windows-only commands (no `mklink`, no `Set-ExecutionPolicy`, no PowerShell-specific syntax). It uses POSIX bash throughout.

## Command adapter sync contract

This installer registers the load rule and repo-local Claude stub. It does not
make copied skills authoritative.

For skills, prefer direct discovery of `<jit-knowledge-root>/skills/`. If a
future adapter installs commands into a runtime-local command or skill
directory, those commands must either be thin wrappers that read the canonical
skill from `<jit-knowledge-root>/skills/<name>/SKILL.md`, or generated files with
source metadata recording the jit-knowledge path and tag/SHA.

Re-run install or the future adapter sync after every jit-knowledge pin bump.
Generated, unmodified adapters may be refreshed. Locally edited adapters must
produce a warning and require manual review. A copied command without source
metadata is stale and non-authoritative.

## Procedure

### 1. Prerequisites

Required:
- `git` (clone)
- `bash` (run install.sh)
- Python 3.11+ (manifest scripts)
- `pip install pyyaml` (manifest dep)

Recommended:
- `gh` CLI authenticated to the JIT AI org (so `rebuild-index.py` can refresh the engram routing region from subscribed repos)
- `node` 20+ + `npm` (for the gtm-gate / ux-narration-agent / visual-review-agent components)

If anything is missing, surface a one-line warning per missing tool. Do not block the install on optional tools -- only block on the required set.

### 2. Clone or refresh

Default canonical path:
- macOS / Linux: `$HOME/Code/jit-knowledge`
- Windows: `$USERPROFILE/Code/jit-knowledge` (e.g., `C:\Users\<you>\Code\jit-knowledge`)

```
JIT_KNOWLEDGE_ROOT="${JIT_KNOWLEDGE_ROOT:-$HOME/Code/jit-knowledge}"
if [ -d "$JIT_KNOWLEDGE_ROOT/.git" ]; then
  cd "$JIT_KNOWLEDGE_ROOT" && git fetch --tags && git pull --ff-only
else
  git clone https://github.com/<your-org>/jit-knowledge.git "$JIT_KNOWLEDGE_ROOT"
fi
```

If pin-to-tag is desired (per `governance/PIN-POLICY.md`), check out the tag:

```
git -C "$JIT_KNOWLEDGE_ROOT" checkout v1.3   # whatever the consuming system pins
```

### 3. Install component dependencies

Walk each component that ships a `package.json`:

```
for d in playbooks/gtm-gate playbooks/ux-narration-agent playbooks/visual-review-agent; do
  if [ -f "$JIT_KNOWLEDGE_ROOT/$d/package.json" ]; then
    (cd "$JIT_KNOWLEDGE_ROOT/$d" && npm install --no-fund --no-audit)
  fi
done
```

### 4. Install Python deps

```
pip install --user pyyaml
```

(or `pip3` depending on the platform)

### 5. Drop the Claude Code load rule (user) + repo-local stub + SessionStart hook

**User rule:** Source `templates/rules/jit-knowledge-load.md` (shipped with this repo).
Target `~/.claude/rules/jit-knowledge-load.md` (per-user rules dir).

**Repo-local (jit-knowledge clone only):** Source `templates/claude-repo-local/CLAUDE.md`.
Target `<jit-knowledge-root>/.claude/CLAUDE.md`. The `jit-knowledge` repo gitignores `.claude/` so nothing here is committed; `scripts/install.sh` materializes the stub idempotently.

```
USER_RULES_DIR="$HOME/.claude/rules"
mkdir -p "$USER_RULES_DIR"
SRC="$JIT_KNOWLEDGE_ROOT/templates/rules/jit-knowledge-load.md"
DST="$USER_RULES_DIR/jit-knowledge-load.md"
if [ -f "$DST" ]; then
  if ! diff -q "$SRC" "$DST" >/dev/null 2>&1; then
    echo "WARN: $DST exists and differs from template. Manual review needed (do NOT auto-overwrite local edits)."
  fi
else
  cp "$SRC" "$DST"
  echo "Installed: $DST"
fi
```

**Repo-local stub (same idempotency rules as the user rule):**

```
LOCAL_DIR="$JIT_KNOWLEDGE_ROOT/.claude"
mkdir -p "$LOCAL_DIR"
SRC2="$JIT_KNOWLEDGE_ROOT/templates/claude-repo-local/CLAUDE.md"
DST2="$LOCAL_DIR/CLAUDE.md"
if [ -f "$DST2" ]; then
  if ! diff -q "$SRC2" "$DST2" >/dev/null 2>&1; then
    echo "WARN: $DST2 exists and differs from template. Manual review needed."
  fi
else
  cp "$SRC2" "$DST2"
  echo "Installed: $DST2"
fi
```

Idempotent: running install twice either copies once or warns on local divergence; never overwrites an Owner-edited rule silently.

**SessionStart hook (5c):**

Install `templates/claude-hooks/session-start-master-orchestrator-rule.sh` to `~/.claude/hooks/jit-knowledge-session-start.sh`. Always overwrite -- the repo copy is canonical. Register a `SessionStart` entry in `~/.claude/settings.json` pointing at the hook (on Windows Git Bash, use `bash "<hookpath>"`; on POSIX, the path directly). Skip registration if the command is already present.

```
HOOKS_DIR="$HOME/.claude/hooks"
mkdir -p "$HOOKS_DIR"
cp "$JIT_KNOWLEDGE_ROOT/templates/claude-hooks/session-start-master-orchestrator-rule.sh" \
   "$HOOKS_DIR/jit-knowledge-session-start.sh"
chmod +x "$HOOKS_DIR/jit-knowledge-session-start.sh"
# python3 heredoc registers in settings.json (idempotent)
```

When the hook fires at SessionStart, it resolves `<jit-knowledge-root>`, reads `rules/interactive-master-orchestrator.md`, and injects the binding identity rule into the session context window before any tool runs. Origin: 2026-05-19 RCA -- the identity rule was documented but never mechanically reached context; the session ran as a generic coding agent the whole session.

**PreCompact hook (5e):**

Install `templates/claude-hooks/pre-compact-knowledge-rebootstrap.sh` to `~/.claude/hooks/jit-knowledge-pre-compact.sh`. Always overwrite -- the repo copy is canonical. Register a `PreCompact` entry in `~/.claude/settings.json` pointing at the hook. Skip registration if the command is already present.

```
HOOKS_DIR="$HOME/.claude/hooks"
mkdir -p "$HOOKS_DIR"
cp "$JIT_KNOWLEDGE_ROOT/templates/claude-hooks/pre-compact-knowledge-rebootstrap.sh" \
   "$HOOKS_DIR/jit-knowledge-pre-compact.sh"
chmod +x "$HOOKS_DIR/jit-knowledge-pre-compact.sh"
# python3 heredoc registers in settings.json under hooks.PreCompact (idempotent)
```

When the hook fires at PreCompact (just before Claude Code compresses the conversation), it prints a directive into the compacted context instructing the post-compact session to invoke `/knowledge` as its FIRST action. `/knowledge` then re-reads the bootstrap chain, prints the Mandatory Session Preflight, refreshes TodoWrite from `Hub.md` + active session-state, and auto-resumes the next executable task. Net effect: compaction does not lose session continuity -- the in-conversation TodoWrite is rebuilt from durable state on the very next response. Origin: 2026-05-28 -- post-compact loss of in-conversation TodoWrite + observed bootstrap drift across sessions.

### 6. Record the path in workspace.json (optional)

If `~/.claude/workspace.json` exists and the consuming system uses it for path resolution, set `jit_knowledge_root`:

```
WORKSPACE_JSON="$HOME/.claude/workspace.json"
if [ -f "$WORKSPACE_JSON" ]; then
  python -c "
import json, sys
p = '$WORKSPACE_JSON'
with open(p) as f: d = json.load(f)
d['jit_knowledge_root'] = '$JIT_KNOWLEDGE_ROOT'
with open(p, 'w') as f: json.dump(d, f, indent=2)
print('Updated workspace.json: jit_knowledge_root = $JIT_KNOWLEDGE_ROOT')
"
fi
```

### 7. Validate INDEX.md is current

```
cd "$JIT_KNOWLEDGE_ROOT"
python scripts/rebuild-manifest.py --check
```

If exit-non-zero, run `python scripts/rebuild-manifest.py` and (if changes appear) open a PR per `skills/update-index/SKILL.md`. Install does NOT auto-commit; it surfaces the diff for Owner review.

### 8. Foundational read primer (post-install)

The install script prints, and the operator must complete BEFORE doing real work:

```
============================================================
jit-knowledge installed at: $JIT_KNOWLEDGE_ROOT

NEXT: load the foundational horizon context. In your Claude
Code session, read these files in order:

  1. horizon/vision.md
       -- auto-loads mission.md + personal-constitution-simplified.md
          per its footer (mandatory)
  2. horizon/business-strategies.md
       -- per-venture plans + 2026 priority frame
  3. horizon/goals-2026.md AND the current quarter file
       (e.g. goals-2026-q2.md)
       -- annual + quarterly milestones
  4. horizon/decision-routing.md
       -- T1 / T2 / T3 trust ratchet; ANY-of-3 escalation
  5. horizon/operating-rhythm.md
       -- daily cadence; brief formats
  6. INDEX.md
       -- the capability manifest

  Optional but high value:
  -  horizon/risk-register.md
  -  horizon/metrics-config.md
  -  horizon/product-launch-pipeline.md

These are READ-ONLY at this point. They prime the session with
Owner's vision + operating model. Skipping them produces work
that conflicts with anchors / counter-horizons / hard lines.
============================================================
```

The vision.md footer encodes a self-load rule -- when an AI session reads vision.md, it MUST also read mission.md + personal-constitution-simplified.md silently. Honor that rule; do not stop at vision.md.

## QA Gates

Reject or revise the output if any of these are true:

- The SessionStart hook was not installed to `~/.claude/hooks/jit-knowledge-session-start.sh` AND not registered under `hooks.SessionStart` in `~/.claude/settings.json` -- both must be present for mechanical identity loading to function
- The PreCompact hook was not installed to `~/.claude/hooks/jit-knowledge-pre-compact.sh` AND not registered under `hooks.PreCompact` in `~/.claude/settings.json` -- both must be present for the post-compact `/knowledge` re-anchor to fire
- The skill silently overwrote an existing `~/.claude/rules/jit-knowledge-load.md` that diverged from the shipped template (per-machine rules may be intentionally edited; never destroy local state)
- The skill ran `npm install` without checking for `package.json` first (would error out on directories that have no node component)
- The skill failed cross-platform: used `mklink`, `Set-ExecutionPolicy`, or any Windows-only or macOS-only command outside the documented contract
- The skill skipped the Foundational Read Primer block (the install is incomplete without it -- the consuming session needs the horizon context loaded BEFORE doing work)
- The skill assumed a hard-coded clone path instead of honoring `JIT_KNOWLEDGE_ROOT` env override + per-OS default
- The skill ran the engram refresh (`rebuild-index.py`) without `gh` auth and committed `status: missing` placeholders -- network failures are diagnostic warnings, not regressions to commit
- The skill auto-committed an INDEX.md diff without surfacing it for Owner review (manifest changes are PR-gated per governance)

## Required Tooling

- `git`, `bash`, Python 3.11+, `pip` (required)
- `gh` CLI, `node` + `npm` (recommended; install proceeds without them but logs WARN)

## After This Skill Completes

The consuming machine has:
- jit-knowledge cloned at the canonical path
- Per-component node dependencies installed
- PyYAML installed
- The Claude Code load rule registered in `~/.claude/rules/`
- The SessionStart identity hook installed at `~/.claude/hooks/jit-knowledge-session-start.sh` and registered in `~/.claude/settings.json`
- The PreCompact re-bootstrap hook installed at `~/.claude/hooks/jit-knowledge-pre-compact.sh` and registered under `hooks.PreCompact` in `~/.claude/settings.json`
- (Optional) workspace.json updated with `jit_knowledge_root`
- A clean INDEX.md (or a surfaced diff for Owner review)

The operator's NEXT action is to read the horizon docs in their Claude Code session per the post-install primer.

## Related

- `scripts/install.sh` -- the implementation of the procedure above (POSIX)
- `scripts/install.ps1` -- Windows entry that runs `install.sh` via Git Bash and sets `JIT_KNOWLEDGE_ROOT` to the current clone
- `templates/rules/jit-knowledge-load.md` -- the shipped Claude Code load rule
- `governance/PIN-POLICY.md` -- pinning tags vs floating on main
- `governance/SYNC-MECHANISMS.md` -- the formal integration spec (declarative imports, skill discovery, charter discovery)
- `skills/update-index/SKILL.md` -- when adding new artifacts; refreshes INDEX.md
- `horizon/vision.md` -- the canonical vision; mandatory read after install
- `README.md` -- one-page summary including these install steps
