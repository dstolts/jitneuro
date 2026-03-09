# JitNeuro Quickstart

**JIT = Just In Time.** JitNeuro loads context just in time -- not all the time.

Get up and running in 5 minutes.

## Quick Start

1. Clone or copy `templates/` into your workspace `.claude/` directory
2. Edit MEMORY.md with your project index and business context
3. Create bundles in `.claude/bundles/` for your domain knowledge
4. Set routing weights in `.claude/context-manifest.md`
5. Install hooks in `.claude/settings.local.json` (see Hooks section)
6. **Close and reopen Claude Code.** Commands are only discovered at session start.
7. Try `/status` to verify everything loaded.

**Windows note:** Hooks require bash (Git Bash or WSL). For full functionality
at scale, WSL (Windows Subsystem for Linux) is recommended. Core slash commands
work on any platform without WSL.

---

## Why JitNeuro

JitNeuro lets you talk to your AI with full context and understanding -- every
session, every time. No more re-explaining your codebase, your conventions,
your decisions. The AI remembers because the framework manages what it knows
and when it knows it. This is a game-changer in productivity. The creator
manages 16+ repos solo and is 3x more productive alone than when running a
15-person dev team -- because the AI never loses context.

---

## Commands (15)

All commands live in `.claude/commands/` and are available as `/command` in any
session launched from the workspace root.

### Memory

| Command | Purpose |
|---------|---------|
| `/save <name>` | Checkpoint session state before /clear or context loss |
| `/load <name>` | Restore session state after /clear or new session |
| `/learn` | Evaluate session for long-term knowledge + memory health check |
| `/health` | Audit memory health -- staleness, size, orphaned refs |

### Governance

| Command | Purpose |
|---------|---------|
| `/enterprise` | Enterprise isolation -- tenant boundaries, access rules |
| `/audit` | Audit trail -- review logged actions, compliance check |

### Git

| Command | Purpose |
|---------|---------|
| `/gitstatus` | Multi-repo git status across workspace |
| `/diff` | Multi-repo diff view across workspace |

### Context

| Command | Purpose |
|---------|---------|
| `/bundle` | Load, inspect, or manage domain bundles |
| `/orchestrate` | Auto-route tasks to agents with the right bundles |
| `/status` | Show current session state -- loaded bundles, active task |
| `/dashboard` | High-level workspace overview -- repos, sprints, health |

### Setup

| Command | Purpose |
|---------|---------|
| `/onboard` | Guided setup for new repos or new team members |
| `/sessions` | List, inspect, or clean saved session checkpoints |
| `convlog` | Toggle conversation logging to .logs/ |

---

## Hooks (4)

Hooks fire automatically on Claude Code events. Configure them in
`.claude/settings.local.json`. See `templates/hooks/README.md` for full
installation instructions.

| Hook | Event | What It Does |
|------|-------|--------------|
| PreCompact Save Prompt | PreCompact | Warns you to /save before context compaction compresses your session |
| Post-Compact Context Recovery | SessionStart (compact) | Re-injects the most recent session state after compaction so Claude picks up where it left off |
| Branch Protection | PreToolUse (Bash) | Blocks RED zone git operations: push to main, force push, force delete, hard reset |
| Session End Auto-Save | SessionEnd | Writes a minimal breadcrumb when a session terminates (safety net, not a full /save) |

---

## What Gets Deployed

Your workspace gets this structure:

```
.claude/
  bundles/           Domain knowledge files (loaded on demand)
  commands/          15 slash commands (see table above)
  hooks/             4 event hooks (see table above)
  engrams/           Per-project deep context (updated by /learn)
  session-state/     Session checkpoints (created by /save)
  context-manifest.md   Routing weights + bundle index
```

MEMORY.md stays small (under 100 lines). All detail lives in bundles and engrams.

---

## Testing the System

### Test 1: Routing Weights

Start a new session from your workspace root. Try prompts and watch which
bundle Claude loads:

```
"What's the AIBM pricing?"
```
Expected: Claude reads bundles/aibm.md, answers from the bundle.

```
"What port does AIFieldSupport-App run on?"
```
Expected: Claude reads bundles/infrastructure.md, answers correctly.

**Pass criteria:** Claude loads the right bundle without being told which one.
If it doesn't, tune the routing weights in MEMORY.md.

### Test 2: Save / Clear / Resume

1. Do some work (or just have a contextual conversation)
2. Run `/save test-session`
3. Verify the file: `cat .claude/session-state/test-session.md`
4. Run `/clear` -- context is gone
5. Run `/load test-session`

**Pass criteria:** After load, Claude knows what you were doing and continues.

### Test 3: Sessions List

After creating saves, run `/sessions`. Expected: table of all session files
with age, task, repos.

### Test 4: Hook Verification

- Trigger compaction (large conversation) -- PreCompact hook should prompt /save
- After compaction, context recovery hook should re-inject session state
- Try `git push origin main` -- branch protection should block it
- End a session -- check `.claude/session-state/_autosave.md` for breadcrumb

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Claude doesn't load a bundle | Check routing weights in MEMORY.md -- does the trigger word match? |
| /save too short (<20 lines) | Work more before saving -- Claude needs context to summarize |
| /save too long (>80 lines) | Target is 30-60 lines -- Claude should summarize, not replay |
| /load loads wrong bundles | Check the session file -- are the right bundles listed? |
| Commands not recognized | Verify .claude/commands/ has the .md files. Restart session. |
| Hooks not firing | Check .claude/settings.local.json -- paths must be absolute |

---

## After Testing

1. Clean up test sessions: `/sessions clean` or delete .claude/session-state/*.md
2. Push to GitHub (RED zone -- ask for permission)
3. Record demo using these test scenarios as the script
