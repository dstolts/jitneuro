# JitNeuro Quickstart

Get up and running in 3 steps.

## 1. Clone and Install

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Pick your install level:
./install.sh workspace   # all repos under parent directory (recommended)
./install.sh project     # current repo only
./install.sh user        # global, all projects on this machine

# Windows (PowerShell)
.\install.ps1 -Mode workspace
```

## 2. Restart Claude Code

Close and reopen Claude Code. Slash commands are only discovered at session start.

## 3. Try It

```
/status          # where am I? what's loaded?
/health          # is my memory system healthy?
/save my-task    # checkpoint before /clear
/load my-task    # pick up where you left off
/sessions        # list all saved sessions
```

That's it. You now have 15 commands, 4 hooks, and a memory management layer.

---

## What You Get

**15 Commands** -- `/save`, `/load`, `/learn`, `/health`, `/sessions`, `/status`,
`/dashboard`, `/enterprise`, `/audit`, `/gitstatus`, `/diff`, `/bundle`,
`/orchestrate`, `/onboard`, `convlog`

**4 Hooks** -- pre-compact save prompt, post-compact recovery, branch protection,
session-end auto-save

**Templates** -- brainstem CLAUDE.md, bundle/engram examples, scoped rules

See [commands reference](docs/commands-reference.md) for details on each command.

---

## Next Steps (Optional)

Once commands are working, you can set up the full memory system:

1. **Slim your CLAUDE.md** -- use `templates/CLAUDE-brainstem.md` as a starting point (30-40 lines max)
2. **Create bundles** -- add domain knowledge files to `.claude/bundles/` (see `templates/bundles/example.md`)
3. **Create engrams** -- add per-project context to `.claude/engrams/` (see `templates/engrams/example.md`)
4. **Set routing weights** -- add trigger patterns to your MEMORY.md so the orchestrator auto-loads the right bundles

See [Setup Guide](docs/setup-guide.md) for a detailed walkthrough.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Commands not recognized | Verify `.claude/commands/` has the .md files. Restart Claude Code. |
| Hooks not firing | Check `.claude/settings.local.json` -- paths must be absolute. |
| Wrong bundle loads | Tune routing weights in MEMORY.md -- does the trigger word match? |
| /save too short | Work more before saving -- Claude needs context to summarize. |

**Windows note:** Hooks require bash (Git Bash or WSL). Core commands work on any platform.
