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
- TodoWrite lists (volatile, per-instance)

This is why Hub.md matters -- it's the durable record that persists across all instances.

### Session Isolation (heartbeats/)

JitNeuro supports multiple simultaneous sessions via per-instance heartbeat tracking. Each Claude Code instance gets a unique session ID (injected into its context by the SessionStart hook), and its current session name is stored in `heartbeats/<session-id>` inside the session-state directory. The heartbeat file's mtime is updated on every tool call by the PostToolUse heartbeat hook, enabling the dashboard to show real-time liveness.

This means:
- Terminal 1 can be on session "sprint-api" (heartbeats/abc-123)
- Terminal 2 can be on session "sprint-frontend" (heartbeats/def-456)
- Terminal 3 can be on session "master-planning" (heartbeats/ghi-789)
- They don't overwrite each other -- each instance has its own heartbeat file
- The dashboard shows all active sessions with last-seen timestamps

## Multi-Session Patterns

### Pattern 1: Master + Ralph (Basic Sprint)

```
Terminal 1 (Master):               Terminal 2 (Ralph):
  cd ~/Code                          cd ~/Code/my-api
  claude                             ralph-tui run --headless --force
  > /load sprint-plan
  > "review ralph progress"
  > /learn
  > /save
```

Master plans and reviews. Ralph executes. One human, two AI sessions.

### Pattern 2: Master + Parallel Ralph (Multi-Repo Sprint)

```
Terminal 1 (Master):     Terminal 2 (Ralph API):    Terminal 3 (Ralph FE):
  cd ~/Code                cd ~/Code/backend          cd ~/Code/frontend
  claude                   ralph-tui run              ralph-tui run
  > /orchestrate           (API stories)              (FE stories, after API done)
  > watch progress
  > /learn after both done
```

Master orchestrates. Two ralph instances execute independent story groups. Dashboard shows both.

### Pattern 3: Master + Ralph + Dev Server (Full Stack)

```
Terminal 1 (Master):     Terminal 2 (Ralph):     Terminal 3 (Dev Server):
  cd ~/Code                cd ~/Code/my-api        cd ~/Code/my-api
  claude                   ralph-tui run           npm run dev
  > plan next sprint                               (API running on :3000)
  > review results
```

Dev server runs so ralph can test against real endpoints. Master plans the next sprint while ralph executes the current one.

### Pattern 4: Research + Execution (Pipeline)

```
Terminal 1 (Master):                    Terminal 2 (Ralph):
  cd ~/Code                               (waiting)
  claude
  > "analyze auth patterns across repos"
  > (subagents scan codebase)
  > "write PRD for auth consolidation"
  > (PRD written, approved)
  > "hand off to ralph"                   ralph-tui run --headless
  > /learn                                (executing stories)
  > /save
```

Research phase uses subagents (fast, read-heavy). Execution phase uses ralph (thorough, test-heavy). Clean handoff via PRD.

## Tips and Tricks

### Docked Master Window
Run the master session in its own separate window, docked to one side of your monitor. Run the split code/ralph sessions in a second window filling the rest. This gives master full monitor height -- you see more context, scroll less, and the master session is always visible while you watch ralph execute.

**Option A: Docked windows (master gets full height)**
Master in its own window (`Win+Left`), everything else in a second window (`Win+Right`) with splits.
```
Window 1 (docked left):     Window 2 (docked right):
+-------------------+       +------------+------------+
|                   |       |  RALPH 1   |  RALPH 2   |
|  MASTER SESSION   |       |            |            |
|  (full height,    |       +------------+------------+
|   full context    |       |  DEV SVR   |  MISC      |
|   visibility)     |       |            |            |
+-------------------+       +------------+------------+
```

**Option B: Single window, 2x2 grid**
All four panes in one window. Less screen real estate per pane but everything in one place.
```
+---------------+---------------+
|  MASTER       |  RALPH 1      |
|               |               |
+---------------+---------------+
|  RALPH 2      |  DEV SERVER   |
|               |               |
+---------------+---------------+
```

**Option C: Single window, 3-column**
Good when you need more ralph sessions than dev servers.
```
+----------+----------+----------+
|          |          |          |
|  MASTER  |  RALPH 1 |  RALPH 2 |
|          |          |          |
+----------+----------+----------+
```

**Option D: Single window, ralph + dev server stacked**
Ralph on top, its dev server below. Repeat per repo.
```
+------------+------------+
|  RALPH 1   |  RALPH 2   |
|            |            |
+------------+------------+
|  DEV SVR 1 |  DEV SVR 2 |
|  (:3000)   |  (:5173)   |
+------------+------------+
  Master in separate docked window
```

**Option E: Maximum sessions (3x2 grid)**
For heavy sprints with 3+ repos, API servers, and a dashboard.
```
+----------+----------+----------+
| MASTER   | RALPH 1  | RALPH 2  |
|          |          |          |
+----------+----------+----------+
| RALPH 3  | DEV SVR  | DASHBOARD|
|          | (:3000)  | (:9847)  |
+----------+----------+----------+
```

Mix and match. Use separate windows for anything that needs full height (master). Use splits within a window for things you want to monitor side-by-side (ralph sessions).

### Scroll Lock (tmux)
When Claude writes output while you're scrolled up reading, the terminal auto-jumps to the bottom. This is a terminal behavior, not a Claude Code setting. The fix is tmux copy mode: `Ctrl+B [` freezes your view. Scroll freely. Claude continues writing below but your position doesn't move. Press `q` to snap back to latest output. This works in Git Bash on Windows.

### Name Your Terminals
Every terminal should have a visible name. "PowerShell" x4 is useless. Name them: "Master", "Ralph-API", "Ralph-FE", "DevServer". In Windows Terminal, right-click the tab to rename. In tmux, `Ctrl+B ,`.

### Keep Master Lean
The master session should never run heavy commands directly. Use subagents for bulk reads, ralph for bulk writes. Master plans, reviews, and captures knowledge. If master's context fills up, the whole orchestration capability degrades.

### Watch Ralph Output
Even in headless mode, ralph outputs progress. Glance at it periodically. A stuck ralph (no output for 5+ minutes) usually means it's in a retry loop -- check the iteration logs.

### Use /pulse for Cross-Session Awareness
The `/pulse` command reads shared state (active-work bundle, session state, Hub.md) and reports changes. Run it in the master session to see what ralph sessions have done since your last check.

### Dev Server Ports
If running multiple dev servers, use different ports to avoid conflicts:
```
API:       localhost:3000
Frontend:  localhost:5173
Auth:      localhost:3030
Dashboard: localhost:5178
```

Document ports in the repo's CLAUDE.md so ralph knows where to test.

### CPU and Resource Management

Each Claude Code session is a native process (not Electron). Multiple sessions consume significant resources -- mostly RAM and disk I/O, not CPU. Most active time is spent waiting for API responses, so CPU spikes are brief but memory usage is persistent.

**What each session costs:**
- Claude Code session (idle): ~55MB RAM, near-zero CPU
- Claude Code session (active): ~200-500MB RAM, CPU spikes during tool use and response streaming
- Ralph session (building/testing): same as above PLUS the build process (`tsc`, `npm test`) which can spike a full CPU core
- Dev server (`npm run dev`): ~50-100MB RAM, minimal CPU unless serving requests

**What to expect with multiple sessions:**
- 2-3 sessions: ~1-1.5GB total, comfortable on most machines
- 4-5 sessions: ~2-2.5GB, noticeable if running builds simultaneously
- 6+ sessions: ~3GB+, fans may spin up during concurrent build steps

**Where the real bottlenecks are:**

RAM, not CPU. Each session maintains its context in memory. Long sessions with large contexts consume more. Use `/compact` in sessions that have been running a while, or `/clear` when switching tasks.

Disk I/O, not compute. Multiple sessions reading/writing code, running `npm install`, or building TypeScript simultaneously thrash the disk. SSD is required -- HDDs cannot keep up.

Build collisions. Two repos running `npm install` or `tsc` at the same time compete for CPU and disk. If repos share `node_modules` via symlinks or monorepo hoisting, simultaneous installs can corrupt packages. Stagger builds.

**WSL2 performance note:** If running Claude Code in WSL2, keep your code on the Linux filesystem (ext4), not on Windows mounts (`/mnt/c/`). The Windows 9P filesystem bridge has a ~9x performance penalty. WSL2 on ext4 achieves ~87% of bare-metal performance.

**Mitigation strategies:**

Stagger ralph launches. Don't start 3 ralph instances simultaneously. Launch one, wait for it to settle into its first story, then launch the next. This spreads the context-loading and initial build spikes.

Close finished sessions. A paused Claude Code session still holds memory. Close the terminal pane when ralph finishes.

Use `/compact` proactively. Long-running master sessions accumulate context. Run `/compact` periodically or between major tasks.

Reduce MCP server overhead. Each configured MCP server adds tool definitions to every session's context, even when idle. Disable unused servers with `/mcp` to save tokens and memory.

Monitor with Task Manager. `Ctrl+Shift+Esc` on Windows. Sort by memory. If total Claude-related memory exceeds 50% of system RAM, reduce parallel sessions.

**Hardware guidelines:**
- 16GB RAM: comfortable with 3-4 concurrent sessions
- 32GB RAM: comfortable with 6-8 concurrent sessions
- SSD required: HDDs cannot handle parallel session I/O
- CPU cores: diminishing returns beyond 4 -- sessions spend most time waiting for API, not computing

**Relevant environment variables:**
- `MAX_THINKING_TOKENS=8000` -- limit extended thinking to reduce token consumption per response
- `ENABLE_TOOL_SEARCH=auto:5` -- defer MCP tool loading when tools exceed 5% of context (reduces per-session overhead)

**The MemoryExhaustion crash:** Claude Code can crash with `MemoryExhaustion` if a single session accumulates too much context in one response (reading 50+ files at once). This is per-session heap exhaustion, not system RAM. The fix is subagent batching (see rules/context-safety.md), not reducing session count.

### VS Code vs External Terminals

VS Code's integrated terminal runs on Electron (Chromium + Node.js) and has significant overhead compared to native terminals.

**Performance comparison:**
| Terminal | Memory per instance | CPU on heavy output | Idle overhead |
|----------|-------------------|--------------------|----|
| Windows Terminal | ~50-100MB | ~0-2% | Near zero |
| tmux (Git Bash) | ~30-50MB | Near zero | Near zero |
| VS Code terminal | ~150-250MB | Can spike to 100% of a core | ~55MB |

VS Code terminals share a renderer process. Heavy output in one terminal (build logs, test results) can slow ALL terminals in VS Code. The integrated terminal can spike to 100% CPU utilization on 1,600+ line outputs that take <1 second in Windows Terminal.

**Recommendation for multi-session AI workflows:**
- Use VS Code for your editor and 1-2 lightweight terminals (master session, quick commands)
- Run ralph sessions and dev servers in Windows Terminal or tmux OUTSIDE VS Code
- This keeps VS Code responsive while heavy work runs in native terminals

**VS Code terminal settings for better performance:**
```json
{
  "terminal.integrated.scrollback": 500,
  "terminal.integrated.gpuAcceleration": "off",
  "terminal.integrated.copyOnSelection": true,
  "terminal.integrated.enableMultiLinePasteWarning": false,
  "terminal.integrated.splitCwd": "workspaceRoot"
}
```

- `scrollback: 500` -- reduces buffer memory (default 1000 eats RAM on long sessions)
- `gpuAcceleration: off` -- reduces rendering overhead if experiencing high CPU
- `copyOnSelection: true` -- select text to auto-copy (helps with the scroll-jump problem)
- `splitCwd: workspaceRoot` -- split terminals start in the right directory

### Pre-Flight Checklist
Before launching a multi-session sprint:
1. `/health` in master -- verify memory system is clean
2. `git status` in each repo -- verify clean working directories
3. Dev servers running if ralph needs them for testing
4. PRD approved and reviewed via holistic review
5. Feature branches created (never sprint on main)
6. Hub.md current for each repo involved

### Post-Sprint Checklist
After ralph finishes:
1. Holistic review (US-HER) in master session
2. `/learn` to capture new patterns and architecture changes
3. `/save` to checkpoint (which syncs Hub.md)
4. Push to uat for staging validation
5. Deploy monitoring confirms pipeline success
6. Owner reviews and merges to main
