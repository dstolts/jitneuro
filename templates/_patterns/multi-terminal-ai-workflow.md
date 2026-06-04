---
type: pattern
purpose: MUST be read by any developer or agent operator setting up a multi-session AI sprint environment before launching parallel master + execution + dev-server sessions -- because running all sessions in a single terminal causes context accumulation in the master session, prevents real-time cross-session failure visibility, and eliminates the isolated context budget that makes execution sessions reliable; skipping this layout produces a degraded master session that plans, executes, and accumulates context simultaneously.
read_when: Before setting up a multi-session AI sprint environment with parallel master, execution, and dev-server terminals.
tags: [terminals, sessions, workflow, parallelism]
scope: public
status: canonical
last_evaluated: 2026-06-03
---

# Terminal Best Practices for Multi-Session AI Development

Most developers use one terminal, one session, one task at a time. AI-assisted development changes this fundamentally. Running multiple Claude Code sessions in parallel -- a master session for planning, ralph sessions for execution, and API servers for testing -- is the difference between working WITH AI and working THROUGH AI.

This guide covers terminal setup, multi-session patterns, and capabilities many developers don't know exist.

## The Multi-Terminal Layout

The recommended layout for sprint execution:

```
Option A: All in one window (split terminals, same row)
+---------------+---------------+---------------+---------------+
|               |               |               |               |
|  MASTER       |  RALPH 1      |  RALPH 2      |  DEV SERVER   |
|  (plan,       |  (repo A      |  (repo B      |  (local API   |
|   review,     |   stories)    |   stories)    |   for testing)|
|   /learn)     |               |               |               |
|               |               |               |               |
+---------------+---------------+---------------+---------------+

Option B: Two windows (recommended -- master gets full height)
Window 1 (docked left):     Window 2 (docked right, split):
+-------------------+       +------------+------------+
|                   |       |            |            |
|  MASTER SESSION   |       |  RALPH 1   |  RALPH 2   |
|  (full height,    |       |  (repo A)  |  (repo B)  |
|   full context    |       |            |            |
|   visibility)     |       +------------+------------+
|                   |       |  DEV SERVER             |
|                   |       |  (or 3rd split)         |
+-------------------+       +-------------------------+
```

Option B is preferred. Master gets full monitor height for context visibility. Use `Win+Left` and `Win+Right` to dock windows.

### Why This Layout Matters

- **Master session** stays lean -- it plans, reviews, and captures knowledge. Never runs heavy execution.
- **Ralph sessions** run headless with full context budgets. Each story gets a fresh context -- no accumulation.
- **API/dev server** running locally means ralph can test against real endpoints, not mocks.
- **You can watch progress** across all sessions simultaneously. Spot failures as they happen.

## Terminal Multiplexers

### Windows Terminal (Built-in, Recommended on Windows)

Windows Terminal supports split panes, tabs, and profiles natively.

**Split pane shortcuts:**
- `Alt+Shift+=` -- split right (side-by-side)
- `Alt+Shift+-` -- split down (stacked)
- `Alt+Shift+D` -- split current pane (auto-detects best direction)
- `Alt+Arrow` -- navigate between panes
- `Alt+Shift+Arrow` -- resize panes
- `Ctrl+Shift+W` -- close pane

The key insight: you can split an already-split pane. This is how you get grids, not just rows.

**Create a 2x2 grid (4 panes):**
```
1. Open Windows Terminal (this is pane 1: top-left)
2. Alt+Shift+= (split right -- now top-left | top-right)
3. Click top-left, Alt+Shift+- (split down -- now top-left has bottom-left below it)
4. Click top-right, Alt+Shift+- (split down -- now top-right has bottom-right below it)
```

**Create ralph + dev server layout (3 panes):**
```
1. Open terminal (Ralph 1)
2. Alt+Shift+= (split right -- Ralph 1 | Ralph 2)
3. Click Ralph 1, Alt+Shift+- (split down -- Dev Server appears below Ralph 1)

Result:
+------------+------------+
|  RALPH 1   |            |
|            |  RALPH 2   |
+------------+            |
|  DEV       |            |
|  SERVER    |            |
+------------+------------+
```

**Named profiles:** Create profiles in Windows Terminal settings for each session type. Each profile can have a different starting directory, color scheme, and title. This prevents "which terminal is which?" confusion.

### tmux (Linux/Mac/WSL)

tmux is the gold standard for terminal multiplexing. Sessions persist even if you close the terminal window.

**Quick start:**
```bash
tmux new-session -s master
```

**Split panes:**
- `Ctrl+B %` -- split vertically
- `Ctrl+B "` -- split horizontally
- `Ctrl+B Arrow` -- navigate between panes
- `Ctrl+B z` -- zoom current pane (fullscreen toggle)
- `Ctrl+B d` -- detach (session keeps running in background)
- `tmux attach -t master` -- reattach later

**Named windows (tabs within a session):**
```bash
Ctrl+B c          # create new window
Ctrl+B ,          # rename window
Ctrl+B 0-9        # switch to window by number
Ctrl+B w          # list all windows
```

**Create the 4-pane layout in one command:**
```bash
tmux new-session -s sprint \; \
  split-window -h \; \
  split-window -v \; \
  select-pane -t 0 \; \
  split-window -v \; \
  select-pane -t 0
```

**Key tmux advantage:** If your SSH connection drops or terminal crashes, tmux sessions survive. Reattach with `tmux attach`. Ralph keeps running.

### VS Code Terminal

VS Code has built-in split terminals that work well for lighter setups.

- `Ctrl+Shift+`` ` -- open new terminal
- Click the split icon in terminal panel -- split current terminal
- Drag terminals to rearrange
- Right-click terminal tab to rename

Limitation: VS Code terminals die when VS Code restarts. Use tmux or Windows Terminal for long-running ralph sessions.

## Claude Code Terminal Capabilities

### The `!` Prefix (Run Commands in Session)

Type `! <command>` at the Claude Code prompt to run a shell command directly in the session. The output lands in the conversation context, so Claude can see it.

```
> ! git status
> ! npm test
> ! curl localhost:3000/api/health
```

Use this for quick checks without leaving the conversation. Claude sees the output and can act on it.

### Reasoning Effort and Extended Thinking

Claude Code supports different reasoning effort levels that trade speed for depth. Most users don't know these exist.

**Effort levels** (type in the prompt or use `/effort`):
- Default -- normal reasoning, good for most tasks
- `think` or `think harder` -- activates extended thinking, Claude shows its reasoning process
- `ultrathink` -- maximum reasoning depth, best for architecture decisions, complex debugging, multi-step planning

**When to use each:**

| Effort | Use when | Example |
|--------|----------|---------|
| Default | Routine work, simple edits, known patterns | "fix the typo in line 42" |
| think | Non-obvious bugs, design decisions, code review | "why is this test flaking?" |
| ultrathink | Architecture, multi-repo planning, novel problems | "design the auth system for 3 services" |

**In practice:**
```
> ultrathink how should we restructure the database schema for multi-tenant
> think harder about why the deploy monitoring misses Vercel pushes
> (default) update the README with the new install steps
```

Extended thinking uses more tokens (thinking tokens count as output). For routine work, the default is fine. For decisions you'll live with for months, ultrathink pays for itself.

**`/effort` command:** Set the default effort level for the session. Useful when you're entering a planning phase and want every response to think deeper without typing "ultrathink" each time.

### Fast Mode

Toggle with `/fast`. Uses the same Opus model but optimizes for faster output. Good for:
- Bulk file edits where you know exactly what you want
- Simple Q&A where deep reasoning isn't needed
- Rapid iteration on small changes

Not good for: architecture decisions, complex debugging, multi-file refactoring where reasoning quality matters.

### Background Commands

Claude Code can run commands in the background with `run_in_background`. The session continues working while the command runs. You get notified when it completes.

This is how deploy monitoring works -- the push happens, a background subagent monitors the pipeline, and the notification arrives when it finishes.

### Multiple Claude Code Instances

Each terminal pane can run its own independent Claude Code instance. They share:
- The filesystem (same machine)
- Git repos (same branches)
- JitNeuro memory (same MEMORY.md, bundles, engrams)

They do NOT share:
- Conversation context (each has its own)
- Session state (each tracks its own session via `heartbeats/<session-id>`)
