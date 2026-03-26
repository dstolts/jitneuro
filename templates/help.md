# JitNeuro Quick Reference

## Getting Started
```
/save              save current session
/load              restore a session
/learn             persist what Claude learned this session
/status            where am I, what's dirty, what's next
```
That's it for day 1. Everything else activates when you need it.

## All Commands

### Session Management
```
/session                   current session status + repos + next steps
/session new <name>        start a fresh session
/session save <name>       checkpoint to disk (shortcut: /save)
/session load <name|#>     restore from disk (shortcut: /load)
/session pulse             check what changed in other sessions
/session switch <name|#>   save current + load another
/session rename <name>     rename current session
/session close             mark session done
/session dashboard         blockers for THIS session
/sessions                  list ALL sessions + NEEDS OWNER summary
/sessions stale            sessions older than 7 days
/sessions clean            delete stale sessions
/sessions archive <#>      move to archive
```

### Memory + Learning
```
/learn                     evaluate session, persist patterns to long-term memory
/health                    memory system diagnostic (line counts, stale, missing)
/bundle <name>             load a specific context bundle on demand
```

### Reasoning
```
/divergent                 show current divergent thinking mode
/divergent auto            smart routing (default)
/divergent always          force multi-path evaluation
/divergent never           force serial (first-fit)
/divergent repo <mode>     set at repo level
/divergent workspace <mode> set at workspace level
```

### Governance
```
/enterprise                trust zones, approval workflow, review gates
/audit [repo]              scan for .env leaks, stale branches, missing engrams
```

### Git
```
/gitstatus                 cross-repo comparison (local vs uat vs main)
/diff [repo]               changes since last push or main divergence
```

### Setup + Maintenance
```
/onboard <repo>            bootstrap a new repo into JitNeuro
/orchestrate               auto-route tasks to agents with bundles
/conversation-log          toggle session logging to .logs/
/verify                    confirm all components are GREEN
/test-tools                smoke-test all tools and MCP servers
```

### Automation
```
/schedule                  list scheduled agents
/schedule start <name>     spawn a timer agent
/schedule stop <name>      stop re-spawning
/schedule add <name> <interval> <instruction>
/schedule remove <name>
```

## Key Features (activate by need)

| Feature | How to activate | What it does |
|---------|----------------|--------------|
| Auto-save | "save my work every 30 min" | Timer agent checkpoints your session |
| Hub.md sync | "keep Hub.md updated" | Enforcer agent syncs task state |
| Divergent thinking | /divergent always | Multi-path evaluation on every response |
| Sub-orchestrators | "score all 77 blog posts" | Rolling worker pool manages batch ops |
| Nightly automation | "audit repos every night at 2am" | Cron agent runs unattended |
| Rules on the fly | "never push to main on Fridays" | /learn persists it as a guardrail |
| Content quality | "blog posts need FAQ + CTA" | /learn creates a content quality gate |
| Branch protection | (active from install) | Hooks block push to main/master |
| Session recovery | (active from install) | PreCompact hook saves before context loss |

## Session Tag

Every response ends with: `[session: <name> | DIV: <MODE>]`
- Session name = what you're working on
- DIV mode = AUTO, ALWAYS, or NEVER (divergent thinking)

## Docs (reference, not prerequisites)

All docs: https://github.com/dstolts/jitneuro/tree/main/docs

| Start here | For depth |
|-----------|-----------|
| philosophy.md | Why JitNeuro works the way it does |
| setup-guide.md | Installation + troubleshooting |
| commands-reference.md | Full command details |
| configuration-reference.md | Every config file and setting |
| scheduled-agents.md | Timer, enforcer, cron, batch agents |
| sub-orchestrator-pattern.md | Managing 30+ tasks at scale |

## "I Wish..." -> JitNeuro Already Does That

| What you say | What to do |
|-------------|-----------|
| "I wish this would auto-save" | `/schedule add autosave 30 /save` |
| "I keep forgetting to update Hub.md" | `/schedule add hub-sync 15 UPDATE_HUB` |
| "Can we save before context resets?" | Already active -- PreCompact hook |
| "I want Claude to remember this rule" | Say the rule, then run `/learn` |
| "Show me what I'm working on" | `/status` or `/sessions` |
| "What changed since last push?" | `/diff` or `/gitstatus` |
| "I need to work across multiple repos" | `/session new <name>` -- sessions are cross-repo |
| "Can Claude evaluate multiple approaches?" | `/divergent always` |
| "I need to score 50 blog posts" | Describe the task -- Claude uses sub-orchestrator pattern |
| "Run an audit every night" | `/schedule add nightly-audit ...` with cron schedule |
| "I don't want anyone pushing to main" | Already active -- branch protection hook |
| "What tools do we have?" | `/help` (this file) |
| "How do I set up a new repo?" | `/onboard <repo>` |
| "Claude keeps forgetting my preferences" | Run `/learn` after each session -- it persists patterns |
| "I want a style guide for content" | State your preferences, `/learn` persists them as rules |
| "Check if everything is healthy" | `/health` |
| "Test all my tools and MCP servers" | `/test-tools` |
