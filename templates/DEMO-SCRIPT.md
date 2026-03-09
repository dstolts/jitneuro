# JitNeuro Demo Walkthrough

A step-by-step walkthrough for demonstrating JitNeuro to your team or
recording a video. Each scene is a self-contained demo you can run live.

---

## Scene 1: The Problem

Show Claude Code hitting its limits:
- Start a long session, get deep into a task
- Watch context get compressed -- Claude forgets conventions you set earlier
- Run `/clear` to switch tasks -- everything is gone
- Spend time re-explaining your codebase

This is the daily reality for anyone managing multiple repos with Claude Code.

---

## Scene 2: Install (30 seconds)

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
./install.sh workspace    # or .\install.ps1 -Mode workspace
```

Close and reopen Claude Code. Commands load at session start.

---

## Scene 3: /status and /health

```
/status     # shows current branch, dirty files, loaded bundles
/health     # audits the memory system -- line counts, staleness, missing engrams
```

These give you immediate visibility into where you are and whether the
memory system is healthy.

---

## Scene 4: /save and /load -- Surviving /clear

The core workflow:

```
# Working on a task...
/save auth-api-refactor    # checkpoint to disk

/clear                     # context is gone

/load auth-api-refactor    # everything is back
```

After load, Claude knows your task, modified files, next steps, and which
bundles to reload. No re-explaining.

---

## Scene 5: /gitstatus -- Multi-Repo Visibility

```
/gitstatus
```

One command shows every repo: current branch, dirty files, commits
ahead/behind between local, uat, and main. Flags issues like dirty
files on main or diverged branches.

---

## Scene 6: Hooks -- Automatic Safety Nets

Four hooks fire automatically:

1. **Pre-compact save** -- prompts you to /save before context compaction
2. **Post-compact recovery** -- re-injects session state after compaction
3. **Branch protection** -- blocks push to main, force push, hard reset
4. **Session-end auto-save** -- writes a breadcrumb when session terminates

Demo the branch protection hook by asking Claude to push to main -- it
gets blocked with an explanation.

---

## Scene 7: /learn -- The System Improves

```
/learn
```

Evaluates the session for knowledge worth persisting. Corrections become
permanent. New routing patterns get added to weights. Memory health check
included. Nothing is written without your approval.

---

## Scene 8: Wrap-Up

Show the architecture:
- Brainstem CLAUDE.md (30-40 lines, always loaded)
- Bundles (domain knowledge, loaded on demand)
- Engrams (per-project context, updated by /learn)
- Routing weights (in MEMORY.md, learned over time)

Total cost: ~3-4% of context window for the full infrastructure.

---

## Pre-Recording Checklist

- [ ] Claude Code running with JitNeuro installed
- [ ] At least 2-3 repos with real uncommitted work (for /gitstatus demo)
- [ ] A named session saved for /load demo
- [ ] Terminal font large enough for video (16-18pt)
- [ ] Screen resolution set (1920x1080 recommended)
- [ ] No sensitive data visible (.env files, API keys, passwords)
- [ ] Test each command once before recording
- [ ] Hooks registered in settings.local.json
