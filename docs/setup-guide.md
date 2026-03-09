# Setup Guide

Get JitNeuro running in your project in 10 minutes.

## Prerequisites
- Claude Code installed and working
- An existing project with `.claude/` directory
- Basic familiarity with CLAUDE.md and MEMORY.md

## Important: Skills vs Commands

Claude Code registers custom slash commands from `.claude/commands/`, **not** `.claude/skills/`.
Files placed in `.claude/skills/` will not be recognized as slash commands.

**Correct path:** `.claude/commands/<name>.md` -> invoked as `/<name>`
**Three scopes:**
- **Project commands:** `<repo-root>/.claude/commands/` -- available in that single repo
- **Multi-repo commands:** `<workspace-root>/.claude/commands/` -- available to all repos under that workspace (e.g., `D:\Code\.claude\commands\` covers all 16 repos launched from D:\Code)
- **User commands:** `~/.claude/commands/` -- available globally in all projects on the machine

Claude Code walks up the directory tree looking for `.claude/commands/` directories.
Commands found at any level are merged -- more specific scopes take priority.

**Recommended install level:**
- Single-repo tools -> project-level
- Multi-repo workflows (JitNeuro /save, /load, /sessions) -> workspace-level
- Personal utilities you want everywhere -> user-level

## Step 1: Copy Template Files

Copy the template directory structure into your project:

```bash
# From your project root
mkdir -p .claude/bundles .claude/commands .claude/rules

# Copy templates (adjust source path)
cp templates/context-manifest.md .claude/context-manifest.md
mkdir -p .claude/session-state

# Copy all 15 commands
for cmd in save load learn sessions orchestrate conversation-log \
           health enterprise status dashboard audit bundle onboard diff gitstatus; do
  cp "templates/commands/$cmd.md" ".claude/commands/$cmd.md"
done
```

**For multi-repo installation** (recommended -- covers all repos in your workspace):

```bash
# Linux/Mac -- workspace root (e.g., ~/Code/)
mkdir -p ~/Code/.claude/commands
cp templates/commands/*.md ~/Code/.claude/commands/

# Windows (PowerShell) -- workspace root (e.g., D:\Code\)
mkdir -Force "D:\Code\.claude\commands"
Copy-Item templates\commands\*.md "D:\Code\.claude\commands\"
```

**For user-level installation** (available on the entire machine, any project):

```bash
# Linux/Mac
mkdir -p ~/.claude/commands
cp templates/commands/*.md ~/.claude/commands/

# Windows (PowerShell)
mkdir -Force "$env:USERPROFILE\.claude\commands"
Copy-Item templates\commands\*.md "$env:USERPROFILE\.claude\commands\"
```

All 15 commands: /save, /load, /learn, /sessions, /orchestrate, /conversation-log,
/health, /enterprise, /status, /dashboard, /audit, /bundle, /onboard, /diff, /gitstatus.

After copying, verify with `/load` -- it should be recognized as a slash command.

**IMPORTANT: You MUST close and reopen Claude Code after installing commands.**
Claude Code scans `.claude/commands/` directories at session start only. An existing
session will NOT see newly added commands. This is a hard requirement -- there is no
way to reload commands without restarting the session.

### Choosing Your Install Level

Claude Code walks **up** the directory tree from your current working directory, merging
`.claude/commands/` directories at every level. More specific scopes take priority.

```
~/.claude/commands/              <-- User-level: every project on this machine
  |
D:\Code\.claude\commands\        <-- Workspace-level: all repos under D:\Code\
  |
D:\Code\my-repo\.claude\commands\ <-- Project-level: this repo only
```

**Multi-repo (workspace-level) is recommended for JitNeuro commands** because /save, /load,
and /sessions manage state across repos. Install once at your workspace root and every repo
launched from that directory inherits them automatically.

| Scenario | Install Level | Path |
|----------|--------------|------|
| You work in one repo | Project | `<repo>/.claude/commands/` |
| You work across multiple repos from one workspace | Workspace | `<workspace>/.claude/commands/` |
| You want JitNeuro everywhere on the machine | User | `~/.claude/commands/` |
| You want both shared + repo-specific commands | Workspace + Project | Both paths, project overrides |

## Step 2: Create Your Brainstem

Replace or slim down your existing CLAUDE.md using `CLAUDE-brainstem.md` as a template.

**Goal:** 30-40 lines max. Only rules that apply to every single task.

**Move everything else to bundles:**
- Deployment instructions -> `.claude/bundles/deploy.md`
- API conventions -> `.claude/bundles/api.md`
- Sprint/task protocol -> `.claude/bundles/sprint.md`
- Testing strategy -> `.claude/bundles/testing.md`

## Step 3: Create Your First Bundle

Copy `templates/bundles/example.md` and fill in your domain:

```bash
cp templates/bundles/example.md .claude/bundles/deploy.md
```

Edit with your actual deployment context. Keep under 80 lines.
Include: key files, commands, conventions, gotchas.
Exclude: anything Claude can infer from reading the code.

## Step 4: Update the Manifest

Edit `.claude/context-manifest.md`:

1. Add your bundles to the "Available Bundles" table
2. Add routing weights for your common task types
3. Verify the "Always Load" section matches your setup

## Step 5: Add Routing Weights to MEMORY.md

In your MEMORY.md (auto-memory), add a routing section:

```markdown
## JitNeuro Routing Weights
- Deploy tasks -> bundles: [deploy]
- API work -> bundles: [api, testing]
- Sprint execution -> bundles: [sprint]
- Bug investigation -> bundles: [api, testing, deploy]
```

These improve over time as you correct Claude's bundle selections.

## Step 6: Add Compact Instructions to CLAUDE.md

Add this section to your brainstem CLAUDE.md:

```markdown
## Compact Instructions
When compacting, always preserve:
- Active bundle list from session-state.md
- All modified file paths with line numbers
- Current task name and status
- Pending decisions awaiting user input
```

## Step 7: Test the Cycle

1. Start a Claude Code session
2. Work on something until context builds up
3. Run `/save test-session`
4. Run `/clear`
5. Run `/load test-session`
6. Verify: correct bundles loaded, task state restored, no unnecessary context

## Step 8: Install Hooks

JitNeuro includes 4 hooks that integrate with Claude Code's hook system to protect your
work and enforce guardrails automatically.

### The 4 Hooks

**1. PreCompact Save Prompt (pre-compact-save.sh)**
Fires before context compaction. Warns you that compaction is about to happen and asks
if you want to run /save first. Without this, compaction can silently discard session
state that you have not checkpointed. Configurable as "warn" (default) or "block" mode.

**2. Post-Compact Context Recovery (session-start-recovery.sh)**
Fires after compaction completes. Reads the most recent session-state file from
`.claude/session-state/` and re-injects it into Claude's context window so you do not
lose track of what you were working on. If no session state exists, it exits silently.

**3. Branch Protection (branch-protection.sh)**
Fires before every Bash tool invocation (PreToolUse on Bash). Scans the command for
RED zone git operations and blocks them with exit code 2:
- `git push ... main` or `master` -- blocks push to protected branches
- `git push --force` -- blocks force push to any branch
- `git branch -D` -- blocks force-delete of branches
- `git reset --hard` -- blocks destructive reset

**4. Session End Auto-Save (session-end-autosave.sh)**
Fires when the session terminates. Writes a minimal breadcrumb file (`_autosave.md`) to
`.claude/session-state/` recording the session end time, duration, reason, and working
directory. This is NOT a full /save -- it is a safety net so the next session can detect
that work was happening. Use /save for proper checkpoints.

### Copy Hook Files

```bash
# From your project root (or workspace root for multi-repo)
mkdir -p .claude/hooks
cp templates/hooks/*.sh .claude/hooks/
cp templates/hooks/jitneuro-hooks.json .claude/hooks/

# Make hooks executable (required on Linux/Mac, recommended on Windows Git Bash)
chmod +x .claude/hooks/*.sh
```

### Configure settings.local.json

Claude Code reads hook definitions from `.claude/settings.local.json` in your project
or workspace root. Add the hooks block to register all 4 hooks:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-compact-save.sh"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start-recovery.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/branch-protection.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-end-autosave.sh"
          }
        ]
      }
    ]
  }
}
```

If you already have a `settings.local.json`, merge the `hooks` key into it. Do not
overwrite existing settings.

**Scope note:** Place `settings.local.json` at the same level as your `.claude/` directory:
- Workspace-level: `D:\Code\settings.local.json` (covers all repos)
- Project-level: `<repo-root>/settings.local.json` (single repo)

### Hook Config: jitneuro-hooks.json

The file `.claude/hooks/jitneuro-hooks.json` controls hook behavior:

```json
{
  "preCompactBehavior": "warn",
  "_options": {
    "warn": "Message injected into context, compaction proceeds. Claude asks user about /save.",
    "block": "Compaction blocked (exit 2). User must respond before compaction can proceed."
  }
}
```

- **warn** (default): Claude receives a message reminding it to offer /save, but compaction
  proceeds immediately. Good for most workflows -- low friction, but you might miss the prompt
  if you are not watching.
- **block**: Compaction is halted (exit code 2) until you explicitly respond. Use this if you
  have lost session state to surprise compactions before. More disruptive but safer.

To change: edit the `preCompactBehavior` value in `jitneuro-hooks.json`. No restart required.

### Hooks Troubleshooting (Windows)

| Problem | Cause | Fix |
|---------|-------|-----|
| Hook not firing | `bash` not on PATH | Install Git for Windows (includes Git Bash). Verify: `where bash` in PowerShell should return a path. |
| "Permission denied" on .sh file | File not executable | Run `chmod +x .claude/hooks/*.sh` from Git Bash. Or: `git update-index --chmod=+x .claude/hooks/*.sh` |
| "jq: command not found" in hooks | jq not installed | JitNeuro hooks use grep-based JSON parsing to avoid this dependency. If you customize hooks to use jq, install it: `winget install jqlang.jq` |
| Hook runs but branch protection does not block | grep not matching | Verify the hook is registered under PreToolUse with matcher "Bash" (case-sensitive). Check that `settings.local.json` is valid JSON (no trailing commas). |
| "stat: invalid option" | GNU vs BSD stat | The session-start-recovery hook tries both `stat -c` (GNU/Linux) and `stat -f` (BSD/Mac). On Windows Git Bash, GNU stat is typical. If neither works, the timestamp is skipped gracefully. |
| Hooks work in Git Bash but not in Claude Code | Shell mismatch | Claude Code uses its own shell. Ensure the `command` values in settings.local.json start with `bash` (not `sh` or `./`). Use forward slashes in paths. |

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

### Long Session
```
[work for a while...]
/compact keep only: current task status, modified files, active bundles
[continue with compressed context...]
[work more...]
/save my-task
/clear
/load my-task
[fresh context with only what's needed]
```

## Tips

- **Start small:** One or two bundles. Add more as you discover natural domain boundaries.
- **Bundle size:** If a bundle exceeds 80 lines, split it. If under 20, merge with related domain.
- **Routing weights:** Don't pre-optimize. Let patterns emerge from actual usage, then codify.
- **Save often:** Before task switches, before risky operations, at natural breakpoints.
- **Trust the orchestrator:** Let it use agents. Don't manually load bundles into main context.

## Best Practice: Rule of Lowest Context

The single most important principle in JitNeuro: **store rules at the lowest level possible,
closest to where they apply.** Don't duplicate -- reference.

### What Goes Where

| Content | Where It Belongs | Why |
|---------|-----------------|-----|
| Trust zones, commit rules, approval workflow | CLAUDE.md (brainstem) | Universal -- applies to every task |
| Schema naming conventions, migration rules | `.claude/rules/schema.md` scoped to `schema/**` | Only relevant when editing schema files |
| API error format, auth patterns, rate limits | `.claude/rules/api.md` scoped to `src/api/**` | Only relevant when editing API code |
| Test conventions, coverage thresholds | `.claude/rules/tests.md` scoped to `tests/**` | Only relevant when writing tests |
| Deployment checklist, container commands | `.claude/rules/deployment.md` scoped to `deploy/**`, `Dockerfile`, `.github/workflows/**` | Only relevant when deploying |
| Domain knowledge (how deploys work, sprint protocol) | `.claude/bundles/deploy.md`, `.claude/bundles/sprint.md` | Loaded on demand by orchestrator |
| Project-specific architecture, key files, gotchas | `.claude/engrams/repo.md` | Loaded on demand per project |
| Routing weights, project index | MEMORY.md | Always loaded but kept under 200 lines |

### Example: Deployment Rules

Your deployment checklist, container commands, and environment configs don't belong in
CLAUDE.md. Put them in `.claude/rules/deployment.md` scoped to `deploy/**`, `Dockerfile`,
and workflow files. They load automatically when Claude touches those files and cost zero
tokens otherwise.

```markdown
---
description: Deployment rules and container conventions
globs:
  - deploy/**
  - Dockerfile
  - docker-compose*.yml
  - .github/workflows/**
---

## Deployment Rules
- Always use multi-stage Docker builds
- Tag images with git SHA, not "latest"
- Run smoke test after deploy: curl /health
- Never deploy on Friday without explicit approval
```

Compare this to stuffing the same rules in CLAUDE.md: they load every session, consume
tokens during API debugging, get compressed away during long sessions, and still miss
the file-path scoping that makes them fire at the right time.

### The Payoff

A 500-line CLAUDE.md loads everything, every session, whether relevant or not. With
Rule of Lowest Context:

- **CLAUDE.md** stays at 30-40 lines (brainstem only)
- **Rules** load automatically and only when needed (zero cost otherwise)
- **Bundles** load on demand via routing weights
- **Engrams** load on demand per project

This is how one developer manages 16+ repos without context bloat. The deep knowledge
is always there -- it just loads just in time, not all the time.

### Anti-Pattern: Rule Duplication

Don't put schema rules in CLAUDE.md AND in `.claude/rules/schema.md`. Define them once
in the scoped rule file, then reference from the brainstem if needed:

```markdown
## Rules
Schema conventions: see .claude/rules/schema.md
API patterns: see .claude/rules/api.md
```

The brainstem points to where the knowledge lives. It doesn't duplicate it.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Claude ignores bundle content | Bundle too long (over 80 lines) or conflicting with CLAUDE.md |
| Wrong bundles loaded | Update routing weights in manifest/MEMORY.md |
| Context still fills up | Use agents more aggressively, save/clear more often |
| /load loads stale state | Check session date, run `sessions stale` to review |
| Commands not recognized | Verify .claude/commands/ directory has the .md files (not .claude/skills/). Restart session. |
