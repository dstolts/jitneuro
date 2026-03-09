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
cp templates/commands/save.md .claude/commands/save.md
cp templates/commands/load.md .claude/commands/load.md
cp templates/commands/orchestrate.md .claude/commands/orchestrate.md
cp templates/commands/sessions.md .claude/commands/sessions.md
cp templates/commands/conversation-log.md .claude/commands/conversation-log.md
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

After copying, verify with `/load` -- it should be recognized as a slash command.

**Note:** New or renamed commands require a fresh Claude Code session to be recognized.
Claude Code scans `.claude/commands/` directories at session start, not during the session.

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

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Claude ignores bundle content | Bundle too long (over 80 lines) or conflicting with CLAUDE.md |
| Wrong bundles loaded | Update routing weights in manifest/MEMORY.md |
| Context still fills up | Use agents more aggressively, save/clear more often |
| /load loads stale state | Check session date, run `sessions stale` to review |
| Commands not recognized | Verify .claude/commands/ directory has the .md files (not .claude/skills/). Restart session. |
