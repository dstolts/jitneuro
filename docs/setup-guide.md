# Setup Guide

Get JitNeuro running in your project in 10 minutes.

## Prerequisites
- Claude Code installed and working
- An existing project with `.claude/` directory
- Basic familiarity with CLAUDE.md and MEMORY.md
- Bash available (Git Bash on Windows, native on Linux/Mac)

## Automated Install (Recommended)

The install scripts handle everything: commands, hooks, config, settings.

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Pick your install level:
./install.sh user        # global -- commands available in ALL repos (recommended)
./install.sh workspace   # parent directory only (see note below)
./install.sh project     # current repo only

# Windows (PowerShell)
.\install.ps1 -Mode user
```

**Which mode should I use?**

Claude Code resolves slash commands from exactly two locations:
1. **User level:** `~/.claude/commands/` -- always loaded, every project
2. **Project level:** `<git-root>/.claude/commands/` -- loaded for that repo only

There is no parent-directory traversal. **Workspace mode** installs commands to a parent
folder's `.claude/commands/`, but those commands are only visible when Claude Code is
launched directly from that parent folder -- not from any child repo under it.

| Mode | When to use |
|------|-------------|
| **user** | You work inside individual repos (recommended for most setups) |
| **workspace** | You always launch Claude Code from the workspace root folder |
| **project** | You only want JitNeuro in one specific repo |

If you previously installed in workspace mode and commands are missing from child repos,
re-run the installer with `user` mode to fix it.

The installer:
- Copies all commands to `.claude/commands/`
- Installs the full rule library to `.claude/rules/` (skips any rule whose first line is marked `(DISABLED)`; updates only changed rules)
- Copies the cognition layer (personas, decision models) to `.claude/cognition/`
- Seeds strategic-context templates into `.claude/horizon/` (only when empty -- never overwrites a filled-in horizon)
- Copies hook scripts to `.claude/hooks/`, including a **SessionStart master-orchestrator identity hook** and a **PreCompact save + reload-directive hook**
- Creates or merges hooks config into `settings.local.json` (re-install preserves your own added hooks and dedups JitNeuro's)
- Installs `jitneuro.json` (version, hook settings, protected branches)
- Backs up existing commands that differ from source
- Scans workspace for repos needing onboarding (workspace mode)
- Detects bash on Windows (checks Git Bash, Scoop, Chocolatey paths)

After install:
1. **Close and reopen Claude Code** (commands load at session start only)
2. Run `/verify` to confirm all components are GREEN
3. Run `/onboard <repo>` to set up context for your projects
4. **Populate your horizon** (optional, ~5 min): tell Claude `"populate my horizon files"` or open `.claude/horizon/POPULATE-HORIZON.md`. Claude interviews you one topic at a time and fills in vision, mission, goals, operating rhythm, and your owner profile so every session aligns to your goals.

### Install Scenarios

| Scenario | What to Do |
|----------|-----------|
| Fresh install, no repos | Run installer. Create bundles + engrams after. |
| Fresh install, existing repos | Run installer in workspace mode. Run `/onboard` for each repo. |
| Multi-machine sync | Clone repos, run installer. `/onboard` detects existing context from git. |
| Upgrade from older version | Re-run installer for EVERY scope where commands exist (see "Update ALL Installed Scopes" below). |
| Existing commands you want to keep | Installer backs up differing commands to `.backup/` before overwrite. |
| Commands loading old version | Stale copy at another scope is overriding. Check user + workspace + project levels. |

### Upgrading: Update ALL Installed Scopes

**This is the #1 install gotcha.** Claude Code loads commands from multiple scopes and the most specific scope wins:

```
User level:      ~/.claude/commands/         (always loaded)
Project level:   <repo>/.claude/commands/    (loaded for that repo)
Workspace level: <parent>/.claude/commands/  (loaded when launched from parent)
```

If you installed commands at **user level** AND **workspace level**, upgrading only one leaves the other stale. The stale copy overrides the updated one depending on where you launch Claude Code.

**Easiest upgrade: Ask Claude Code to do it.**

Just tell Claude Code:
```
> "Pull the latest jitneuro repo and install updates to all scopes where commands exist"
```

Claude Code will:
1. Pull the latest templates from your jitneuro repo
2. Detect which scopes have JitNeuro commands installed
3. Copy updated templates to all of them
4. Report what changed

This is the recommended approach -- let the AI handle the file operations. You focus on reviewing what changed, not running shell commands.

**Manual upgrade (if you prefer):**
```bash
./install.sh user        # updates ~/.claude/commands/
./install.sh workspace   # updates <workspace>/.claude/commands/
```

**Checking where commands are installed:**
```
> "Show me which scopes have JitNeuro commands installed and whether any are stale"
```
Or manually:
```bash
ls ~/.claude/commands/*.md           # user level
ls <workspace>/.claude/commands/*.md # workspace level
ls .claude/commands/*.md             # project level (from inside a repo)
```

**Symptoms of stale commands at another scope:**
- `/health` runs the old version (missing subagent dispatch, wrong thresholds)
- `/save` doesn't sync Hub.md (the new mandatory step)
- `/learn` doesn't dispatch health check to subagent
- Commands show outdated formatting or missing sections

**Prevention:** Pick ONE scope (user mode recommended) and remove commands from other scopes. Claude Code merges scopes, but maintaining one source is simpler.

### Windows Notes

- Hooks require bash. The PowerShell installer detects Git Bash automatically.
- WSL is detected but explicitly **not supported** for hooks (path resolution issues).
- If bash is not found, install continues -- commands work, hooks won't fire.
- PowerShell 5.1 and 7+ both supported. On a re-install, PS 7+ does a per-event hook merge (preserves your custom hooks, dedups JitNeuro's); PS 5.1 backs up `settings.local.json` to `.bak` and replaces the hooks block (re-add any custom hooks after).

## Upgrades Are Safe (Framework vs Your Files)

JitNeuro keeps a clean line between the **framework's files** and **yours**, so upgrading never clobbers your work.

- On install, JitNeuro writes a manifest at `.claude/.jitneuro-manifest.tsv` listing every framework-owned file (path + checksum).
- **To upgrade:** `git pull` in your jitneuro clone, then re-run `./install.sh <mode>` (or `install.ps1`). The installer:
  - Updates framework files that changed.
  - Removes framework files dropped in the new version (only if you hadn't edited them).
  - **Backs up** any framework rule you edited to `.claude/.jitneuro-backup/` before updating it -- your version is never silently lost.
  - **Never touches files that aren't in the manifest** -- your own rules, bundles, engrams, filled-in horizon, and owner-persona are yours and stay untouched.

In short: put your customizations in your own files (add new rules to `.claude/rules/`, fill in `.claude/horizon/`, create bundles/engrams). Don't hand-edit a shipped framework rule unless you mean to fork it -- if you do, your edit is preserved in `.jitneuro-backup/` on the next upgrade.

## Single-User vs Team

**Single user:** `install.sh user` once. Done. Everything under `~/.claude/` is yours.

**Team (several developers sharing a repo):** each developer runs `install.sh user` on their own machine -- no coordination needed (each `~/.claude/` is isolated). Commit the **shared** pieces to the repo (`.claude/CLAUDE.md`, `.claude/jitneuro.json`, `.claude/rules/`) and gitignore the **per-developer** pieces so they never collide. Add the block from `templates/gitignore-additions.txt` to your repo's `.gitignore` -- it covers `.claude/settings.local.json`, `.claude/horizon/`, `.claude/cognition/`, and session state. Team-shared learning (a shared vision, shared bundles) is a manual opt-in today: commit those files deliberately.

## Manual Install

If the install script doesn't fit your needs, ask Claude Code to do it:

```
> "Copy all JitNeuro command templates from templates/commands/ to .claude/commands/,
   hook scripts to .claude/hooks/, jitneuro.json to .claude/, and set up
   settings.local.json with the hook configuration. Install at [user/workspace/project] scope."
```

Claude Code will create directories, copy files, set permissions, and configure hooks in one pass.

**Understanding scopes** (Claude Code merges all levels, most specific wins):
- **User:** `~/.claude/commands/` -- all projects on this machine (recommended)
- **Project:** `<repo>/.claude/commands/` -- single repo only
- **Workspace:** `<workspace>/.claude/commands/` -- only works when launched from workspace root

**Config customization** -- after install, ask Claude Code:
```
> "Show me jitneuro.json and explain what I can customize"
```

Key options: `preCompactBehavior` (block vs warn), `autosave` (true/false), `protectedBranches`.

<details>
<summary>Shell commands (if you prefer manual)</summary>

```bash
# Step 1: Copy commands
mkdir -p .claude/commands && cp templates/commands/*.md .claude/commands/

# Step 2: Copy hooks
mkdir -p .claude/hooks && cp templates/hooks/*.sh .claude/hooks/ && chmod +x .claude/hooks/*.sh

# Step 3: Copy config
cp templates/jitneuro.json .claude/jitneuro.json

# Step 4: Configure hooks in settings.local.json (see jitneuro.json hookEvents for reference)
```
</details>

**IMPORTANT:** Close and reopen Claude Code after setup.

## Post-Install Configuration

The fastest way to configure JitNeuro is to tell Claude Code what you need. It already has the templates and knows the patterns.

### Create Your Brainstem

```
> "Create a brainstem CLAUDE.md for this repo using the CLAUDE-brainstem.md template.
   Keep it under 40 lines. Move deployment, API, and testing instructions to bundles."
```

Claude Code will read the template, extract domain-specific content from your existing CLAUDE.md, create bundles for each domain, and slim down CLAUDE.md to core rules only.

**Goal:** 30-40 lines max. Only rules that apply to every single task. Everything else lives in bundles.

### Create Your First Bundle

```
> "Create a bundle for [your domain] based on the example template.
   I'll tell you what to include."
```

Claude Code will copy the template, rename it, and walk you through what to add. Keep under 180 lines. Include: key files, commands, conventions, gotchas. Exclude: anything Claude can infer from reading the code.

### Register Bundles with the Canonical Router

Routing lives in `jit-knowledge/INDEX.md` -- the single source of truth for all task-keyword to bundle mappings. To make a new bundle load automatically:

1. Open a PR to `dstolts/jit-knowledge` adding a route line to `INDEX.md`:
   `- <trigger phrase>  -> [your-bundle-name]`
2. Once merged, your consuming system picks it up on the next `jit-knowledge` submodule pull.

For local-only routes (experimental, not recommended long-term), ask Claude Code:
```
> "Add a temporary routing entry for my-bundle to .jitneuro/engrams/context.md
   and note it should be promoted to jit-knowledge/INDEX.md via PR."
```

Do NOT add routing entries to `context-manifest.md` or `MEMORY.md`; those surfaces no longer carry routing tables.

### Add Compact Instructions to CLAUDE.md

```
> "Add compact instructions to my CLAUDE.md so session state is preserved during compaction"
```

This tells Claude Code what to keep when context gets compressed: active bundles, modified file paths, current task, pending decisions.

### Test the Cycle

1. Start a Claude Code session
2. Work on something until context builds up
3. Run `/save test-session`
4. Run `/clear`
5. Run `/load test-session`
6. Verify: correct bundles loaded, task state restored, no unnecessary context

## Usage Patterns

### Manual (Simple)
```
You: "Work on the deploy pipeline"
Claude: [reads manifest, loads deploy bundle, works]
You: "Switch to API bug"
You: /save deploy-work
You: /clear
You: /load deploy-work -- switching to API debugging
Claude: [loads api + testing bundles, continues]
```

### Automated (Orchestrator)
```
You: "Deploy the API and update the frontend"
Claude: [reads manifest]
  -> Agent 1: [deploy bundle] deploy API
  -> Agent 2: [frontend bundle] update frontend
  -> Returns: summaries only, main context stays thin
```

## Best Practice: Rule of Lowest Context

**Store rules at the lowest level possible, closest to where they apply.**

| Content | Where It Belongs | Why |
|---------|-----------------|-----|
| Trust zones, commit rules, approval workflow | CLAUDE.md (brainstem) | Universal |
| Schema naming, migration rules | `.claude/rules/schema.md` scoped to `schema/**` | Only for schema files |
| API error format, auth patterns | `.claude/rules/api.md` scoped to `src/api/**` | Only for API code |
| Test conventions, coverage | `.claude/rules/tests.md` scoped to `tests/**` | Only for test files |
| Domain knowledge | `.claude/bundles/` | Loaded on demand |
| Project architecture, key files | `.claude/engrams/` | Loaded on demand per project |

See [concepts.md](concepts.md) for detailed explanation with examples.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Commands not recognized | Restart Claude Code. Verify `.claude/commands/` has .md files. |
| Commands work at workspace root but not in repos | Installed in workspace mode. Re-run installer with `user` mode. |
| Hooks not firing | Run `/verify` to check hooks config and script paths. |
| "bash not found" on Windows | Install Git for Windows. Installer detects paths automatically. |
| settings.local.json parse error | Installer skips merge on parse failure. Fix JSON and re-run. |
| Claude ignores bundle content | Bundle too long (over 180 lines) or conflicting with CLAUDE.md. |
| Wrong bundles loaded | Open a PR to jit-knowledge/INDEX.md to add or correct the route mapping. |
| Context still fills up | Use agents more aggressively, save/clear more often. |
| /load loads stale state | Check session date with `/sessions`. |
| Interrupted install | No `jitneuro.json` in `.claude/` = incomplete. Re-run installer. |

| Why .claude/ not .jitneuro/? | Claude Code only looks in `.claude/` for commands, hooks, and rules. If JitNeuro used its own folder, nothing would load. See [technical-overview.md](technical-overview.md) for details. In v1.0, `.jitneuro/` will be the team-shared folder (committed to git) while `.claude/` stays personal. |

For enterprise deployment and security considerations, see [enterprise-security.md](enterprise-security.md).
