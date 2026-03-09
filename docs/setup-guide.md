# Setup Guide

Get JitNeuro running in your project in 10 minutes.

## Prerequisites
- Claude Code installed and working
- An existing project with `.claude/` directory
- Basic familiarity with CLAUDE.md and MEMORY.md

## Step 1: Copy Template Files

Copy the template directory structure into your project:

```bash
# From your project root
mkdir -p .claude/bundles .claude/skills .claude/rules

# Copy templates (adjust source path)
cp templates/context-manifest.md .claude/context-manifest.md
mkdir -p .claude/session-state
cp templates/skills/checkpoint.md .claude/skills/checkpoint.md
cp templates/skills/resume.md .claude/skills/resume.md
cp templates/skills/orchestrate.md .claude/skills/orchestrate.md
```

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
3. Say: "Run /checkpoint"
4. Run `/clear`
5. Say: "Run /resume"
6. Verify: correct bundles loaded, task state restored, no unnecessary context

## Usage Patterns

### Manual (Simple)
```
You: "Work on the deploy pipeline"
Claude: [reads manifest, loads deploy bundle, works]
You: "Switch to API bug"
You: /checkpoint
You: /clear
You: /resume -- switching to API debugging
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
/checkpoint
/clear
/resume
[fresh context with only what's needed]
```

## Tips

- **Start small:** One or two bundles. Add more as you discover natural domain boundaries.
- **Bundle size:** If a bundle exceeds 80 lines, split it. If under 20, merge with related domain.
- **Routing weights:** Don't pre-optimize. Let patterns emerge from actual usage, then codify.
- **Checkpoint often:** Before task switches, before risky operations, at natural breakpoints.
- **Trust the orchestrator:** Let it use agents. Don't manually load bundles into main context.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Claude ignores bundle content | Bundle too long (over 80 lines) or conflicting with CLAUDE.md |
| Wrong bundles loaded | Update routing weights in manifest/MEMORY.md |
| Context still fills up | Use agents more aggressively, checkpoint/clear more often |
| /resume loads stale state | Check session date, run `sessions stale` to review |
| Skills not recognized | Verify .claude/skills/ directory exists and files are .md |
