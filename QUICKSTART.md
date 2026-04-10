# JitNeuro Quickstart

Get up and running in 4 steps.

## Prerequisites

- **Claude Code** (CLI, desktop app, or web) — latest version recommended
  - Requires slash command support (available in all current Claude Code versions)
  - Hooks require settings.json configuration (available in all current Claude Code versions)
- **Bash** for hook scripts (macOS/Linux native; Windows needs Git Bash — installer auto-detects)

## 1. Clone and Install

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Pick your install level:
./install.sh user        # global -- commands available in ALL repos (recommended)
./install.sh workspace   # parent directory -- only works when launched from there
./install.sh project     # current repo only

# Windows (PowerShell)
.\install.ps1 -Mode user
```

The installer automatically:
- Copies all commands and hook scripts
- Configures hooks in settings.local.json (no manual JSON editing)
- Backs up any existing commands that differ
- Scans your workspace for repos needing onboarding (workspace mode)
- Detects bash on Windows (Git Bash paths)

## 2. Restart Claude Code

Close and reopen Claude Code. Slash commands are only discovered at session start.

## 3. Verify

```
/verify              # checks all 9 components, reports GREEN/YELLOW/RED
```

If everything is GREEN, you're done. If anything is YELLOW or RED, `/verify`
tells you exactly what to fix.

## 4. Try It

```
/status          # where am I? what's loaded?
/health          # is my memory system healthy?
/save my-task    # checkpoint before /clear
/load my-task    # pick up where you left off
/sessions        # list all saved sessions
```

That's it. You now have 15+ commands, 4 hooks, and a memory management layer.

---

## What You Get

**Commands** -- `/save`, `/load`, `/learn`, `/health`, `/verify`, `/sessions`, `/status`,
`/dashboard`, `/enterprise`, `/audit`, `/gitstatus`, `/diff`, `/bundle`,
`/orchestrate`, `/onboard`, `convlog`

**Hooks** -- pre-compact save prompt, post-compact recovery, branch protection,
session-end auto-save

**Config** -- `jitneuro.json` with version, hook settings, protected branches

**Templates** -- brainstem CLAUDE.md, bundle/engram examples, scoped rules

See [commands reference](docs/commands-reference.md) for details on each command.

---

## 5. Make It Yours

JitNeuro ships with opinionated defaults. Review and modify everything to match your engineering style.

See the [Customization Guide](docs/customization-guide.md) for a walkthrough of what to review.

**Quick version:**

1. **Review Cognitive Identity** -- `.claude/CLAUDE-brainstem.md` has 10 engineering principles. Keep what fits, change what doesn't.
2. **Review Personas** -- `.claude/cognition/personas.md` has 16 expert roles. Adjust biases, add domain-specific checks, remove roles that don't apply.
3. **Create your Owner Persona** -- copy `.claude/cognition/owner-persona.example.md` to `.claude/cognition/owner-persona.md` and add your business context (revenue targets, compliance requirements, decision style).
4. **Review Anti-Patterns** -- `.claude/cognition/anti-patterns.md` ships with seed entries. Add your own, remove any that don't apply. Over time, `/learn` proposes new entries from your corrections.
5. **Review Decision Models** -- `.claude/cognition/decisions/` has structured frameworks. Add models for decisions you make repeatedly.

## Next Steps (Optional)

Once commands are working and customized, set up the full memory system:

1. **Slim your CLAUDE.md** -- use `templates/CLAUDE-brainstem.md` as a starting point (30-40 lines max)
2. **Onboard repos** -- run `/onboard <repo>` to generate context for your projects
3. **Create bundles** -- add domain knowledge files to `.claude/bundles/`
4. **Set routing weights** -- add trigger patterns to your MEMORY.md

See [Setup Guide](docs/setup-guide.md) for a detailed walkthrough.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Commands not recognized | Restart Claude Code. Verify `.claude/commands/` has .md files. |
| Commands work at parent but not in repos | Installed in workspace mode. Re-run with `user` mode. |
| Hooks not firing | Run `/verify` -- check hooks config and hook paths. |
| "bash not found" on Windows | Install Git for Windows. Installer detects Git Bash automatically. |
| settings.local.json parse error | Installer skips merge if file can't be parsed. Fix JSON syntax and re-run. |
| /verify shows RED for hooks config | Re-run install script to auto-configure. |
| Wrong bundle loads | Tune routing weights in MEMORY.md -- does the trigger word match? |
| /save too short | Work more before saving -- Claude needs context to summarize. |
| Interrupted install | No jitneuro.json = incomplete. Re-run installer. |

**Windows note:** Hooks require bash (Git Bash). WSL is detected but not supported for hooks.
Core commands work on any platform.
