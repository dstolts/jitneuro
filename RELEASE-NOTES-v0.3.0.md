# JitNeuro v0.3.0 Release Notes

**Release Date:** 2026-03-23
**Previous Version:** v0.2.0

## Overview

v0.3.0 is a major feature release focused on multi-agent orchestration, live session tracking, and memory system hardening. The session identity system was rewritten from scratch to support multiple concurrent Claude Code instances, and a real-time dashboard now tracks agent spawns and completions.

---

## New Features

### Heartbeat Session Tracking (Breaking Change)

Replaced the `.current` / `.current.d/` / `.session-id` session identity cascade with a single `heartbeats/` directory.

**How it works:**
- One file per active Claude Code instance: `session-state/heartbeats/<claude-session-id>`
- File content = JitNeuro session name (or "none" if no session loaded)
- File mtime = last activity timestamp (touched by PostToolUse hook)
- SessionStart creates the file; SessionEnd deletes it

**Why:** The old system had a single-writer bug -- two Claude Code terminals would overwrite each other's `.current` file. The cascade logic (4-step resolution) was fragile and hard to debug. The heartbeat model gives each instance its own independent file with zero conflicts.

**Migration:** Automatic. The install script creates `heartbeats/` and no longer creates `.current.d/`. Old files (`.current`, `.current.d/`, `.session-id`) are not auto-deleted but are ignored.

### Agent Tracking Dashboard

Real-time monitoring of subagent spawns via the dashboard at `http://localhost:9847`.

**How it works:**
- `PreToolUse(Agent)` hook registers each spawned agent as "running" in `dashboard/runs/<session>/agents/`
- `PostToolUse(Agent)` hook marks the agent as "completed" when it returns
- Dashboard polls `/api/status` every 2 seconds and displays agent lifecycle
- Each agent entry shows: name, status (running/completed), start time, finish time, duration

**Architecture decision:** Originally designed for subagent self-registration (subagent reads breadcrumb on its SessionStart, self-registers, marks itself complete on SessionEnd). Discovery during live testing revealed that Claude Code subagents do NOT fire their own SessionStart/SessionEnd hooks -- they run as tasks within the master process, not separate processes. The design was pivoted to master-side registration via PreToolUse/PostToolUse hooks, which is simpler and proven working.

### Clear Session Recovery

When a context clear occurs (`/clear`), the SessionStart hook now echoes:
```
You were working on session: <session-name>
To reload it: /load <session-name>
```
This appears before the session list, making it trivial to reload the active session after a clear.

### Dashboard Features

- **Session hierarchy:** Sessions group their agents (runs > agents)
- **Day grouping:** Sessions grouped by date
- **Archive checkbox:** Toggle visibility of archived sessions
- **Completed checkbox:** Toggle visibility of completed agents
- **Popout window:** Open dashboard in a standalone browser window
- **ACTIVE badge:** Green indicator for sessions with recent heartbeats
- **Timer freeze:** Agent timers stop updating once marked completed
- **Smart age display:** Human-readable "3s ago", "2m ago", "1h ago"
- **Auto-archive:** Server archives completed runs after configurable TTL (30s interval)
- **Windows path normalization:** Backslash-to-forward-slash fix for JSON parsing

### Memory System Hardening

- **5 remediation strategies** for when memory exceeds line limits
- **Workspace splitting** guidance for large memory files
- **Feedback classification:** Personal vs publishable feedback separation
- **Component limits** defined with OK/WARN/OVER thresholds for MEMORY.md, Bundles, Engrams, Sessions

### Command Updates

- **/session close** -- explicitly close a session (removes heartbeat, updates checkpoint)
- **/learn q** -- quick mode for fast evaluations
- **/pulse** shortcut -- delegates to /session pulse
- **Subagent dispatch** -- /health, /audit, /gitstatus, /learn, /onboard can spawn subagents
- **Dashboard JSON writing** -- instructions added to all subagent-capable commands
- **Previous Claude Session ID** -- save/load now tracks session-id chain across restarts

### Session-Scoped Hub.md Sections

Multiple sessions working in the same repo now get their own sections in Hub.md:

```markdown
## AIFieldSupport-HE (sync)
- [ ] Fix sync retry logic
- [x] Add timeout handling (2026-03-23)

## AIFS-marine-analysis
- [ ] Marine scoring criteria update
```

Each session reads/writes only its own section. No conflicts when sync, marine analysis, and automotive analysis all work in the same repo simultaneously. Commands updated: session.md (save), health.md, learn.md, pending-questions.md, Cursor rules.

### Subagent Communication Protocol

New rule (`rules/subagent-communication.md`) enforcing structured returns from all subagents:

- **STATUS line** (first line): OK, BLOCKED, or PARTIAL
- **FILES_CHANGED**: paths to created/modified files
- **SUMMARY_DOC**: reference to detailed output (master reads only if needed)
- **Result**: under 15 lines

Orchestration shifted from step-driven ("exact file paths, what to look for") to outcome-driven ("define WHAT, guardrails define HOW"). Matches Ralph story patterns.

### Hook Performance Analysis

New doc (`docs/hook-performance.md`) with benchmarks, race condition audit, and safety proofs:

- **Benchmarks:** heartbeat ~290ms, branch-protection ~770ms per call (Windows/MSYS2; Linux ~3x faster)
- **Session cost:** ~2 min across 200 tool calls -- non-blocking, invisible to user
- **Race conditions:** All analyzed, no data corruption risks. Parallel 5-agent spawns stress-tested.
- **Hook recursion:** Impossible -- hooks are bash scripts, not Claude Code tool calls
- **Conclusion:** No performance concerns. Value (live tracking, safety) far exceeds cost.

### Documentation Overhaul

- **AI-first patterns** -- setup guide, environment config, memory maintenance, customization guide all lead with "ask Claude Code to do it" instead of shell commands
- **Context-loss language corrected** -- "forces a session reset and recovery cycle" not "all progress is lost"
- **Open-source sanitization** -- all D:\Code\ hardcoded paths replaced with generic placeholders

### Infrastructure

- **Deploy monitoring rule** -- auto-detect CI/CD after any `git push`, spawn background subagent, ASCII box results
- **Pending questions queue** -- track unanswered questions, surface at end of every response
- **Context safety rule** -- batch file analysis to 25 max, use subagents for bulk reads (prevents JS heap crash)
- **Testing method rule** -- every test result must state the method used (curl, npm test, code review, etc.)
- **Environment setup docs** -- Windows, macOS, Linux env var configuration (JITDASH_DIR, JITDASH_SESSIONS)
- **FR-106: Modular component setup** -- feature request for install/uninstall by feature (community feedback requested)

---

## Architecture Decisions

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| Session identity | heartbeats/<session-id> | .current + .current.d/ cascade | Single-writer bug eliminated; each instance independent |
| Agent tracking | Master-side PreToolUse/PostToolUse | Subagent self-registration via breadcrumbs | Subagents don't fire SessionStart/SessionEnd hooks |
| Heartbeat trigger | PostToolUse (all tools) | Notification, UserPromptSubmit | PostToolUse fires during active work, catches long autonomous runs |
| Dashboard architecture | HTTP server + polling | WebSocket | Zero-dependency; polling at 2s is sufficient for human monitoring |
| Archive strategy | In-place flag in JSON | File move to .archive/ | Simpler, fewer filesystem operations |
| Install scope | workspace + project + user modes | Single mode | Different teams have different needs; workspace covers multi-repo |
| Hub.md multi-session | Session-named sections (## name) | Separate Hub files per session | One file = full picture, humans can scan easily |
| Orchestration model | Outcome-driven (WHAT not HOW) | Step-driven prompts | Matches Ralph story pattern; guardrails constrain approach |
| Subagent returns | STATUS + FILES_CHANGED + SUMMARY_DOC | Unstructured text | Master stays thin; only digs into detail when needed |
| Hook file locking | No locking | flock | Scripts are fast (<1s), all races are benign; locking adds deadlock risk |

---

## Breaking Changes

- **heartbeats/ replaces .current.d/** -- Any external tooling that reads `.current` or `.current.d/` for session detection must switch to scanning `heartbeats/`. The dashboard server.js already does this.
- **Install scripts create heartbeats/ instead of .current.d/** -- Fresh installs will not have `.current.d/` at all.
- **PostToolUse hook required** -- The heartbeat (session liveness) depends on a PostToolUse hook firing after every tool call. Without it, the dashboard cannot detect active sessions. The install script auto-configures this.

---

## Hook Inventory (9 hooks)

| Hook | Event | Matcher | Purpose | Timeout |
|------|-------|---------|---------|---------|
| pre-compact-save.sh | PreCompact | (all) | Save session state before compaction | 10s |
| session-start-write-id.sh | SessionStart | (all) | Create heartbeat, inject session-id into context | 10s |
| session-start-post-clear.sh | SessionStart | (all) | Show session list + reload hint after clear | 10s |
| session-start-recovery.sh | SessionStart | compact | Recover session state after compaction | 10s |
| branch-protection.sh | PreToolUse | Bash | Block pushes to protected branches | 10s |
| pre-agent-register.sh | PreToolUse | Agent | Register spawned agent as "running" in dashboard | 5s |
| heartbeat.sh | PostToolUse | (all) | Touch heartbeat file for liveness tracking | 5s |
| post-agent-complete.sh | PostToolUse | Agent | Mark agent as "completed" in dashboard | 5s |
| session-end-autosave.sh | SessionEnd | (all) | Clean up heartbeat, write autosave breadcrumb | 10s |

---

## File Manifest

### New Files (v0.3.0)
- templates/hooks/heartbeat.sh
- templates/hooks/pre-agent-register.sh
- templates/hooks/post-agent-complete.sh
- templates/dashboard/server.js
- templates/dashboard/dashboard.html
- templates/dashboard/bin/jitdash.cmd, jitdash.ps1, jitdash.sh
- templates/scripts/dashboard.sh, sessions.sh
- templates/rules/subagent-communication.md
- templates/rules/testing-method.md
- templates/rules/code-reuse.md, context-safety.md, deploy-monitoring.md
- templates/rules/pending-questions.md, proactive-quality.md, security-guardrails.md
- templates/memory/README.md, detail-index.md
- docs/hook-performance.md
- docs/environment-setup.md
- docs/deploy-monitoring-reference.md
- docs/feedback-classification.md
- docs/memory-maintenance.md
- docs/multi-agent-orchestration-01.md
- docs/terminal-best-practices.md
- RELEASE-NOTES-v0.3.0.md
- FEATURE-REQUESTS.md (FR-106 added)

### Modified Files
- templates/hooks/session-start-write-id.sh -- heartbeat creation, removed subagent self-registration
- templates/hooks/session-start-post-clear.sh -- heartbeat-based session detection, clear reload hint
- templates/hooks/session-end-autosave.sh -- heartbeat cleanup, removed subagent self-completion
- templates/commands/session.md -- heartbeat, session-scoped Hub.md sections, session isolation rule
- templates/commands/sessions.md -- heartbeat scan for active detection
- templates/commands/health.md -- session sections, orphaned section detection
- templates/commands/learn.md -- session sections, quick mode
- templates/commands/orchestrate.md -- outcome-driven prompts, subagent return format
- templates/cursor/rules/jitneuro-intents.mdc -- session-scoped Hub.md sections
- templates/jitneuro.json -- added 3 new hook events (heartbeat, pre-agent, post-agent)
- install.sh -- heartbeats/ dir, dashboard install, 3 new hook configs
- install.ps1 -- heartbeats/ dir, dashboard install, 3 new hook configs
- docs/setup-guide.md -- AI-first patterns, manual install in collapsible sections
- docs/customization-guide.md -- AI-first persona/anti-pattern customization
- docs/ralph-integration.md -- /pulse monitoring, generic paths
- CLAUDE.md -- version bump

---

## Upgrade Instructions

**Easiest:** Ask Claude Code:
```
> "Pull the latest jitneuro repo and install updates to all scopes where commands exist"
```

**Manual:**
1. Pull latest jitneuro repo
2. Run `./install.sh workspace` (or `.\install.ps1 -Mode workspace` on Windows)
3. Restart Claude Code (hooks load at session start)
4. Run `/verify` to confirm installation
5. Run `/health` to check memory system status

The installer will:
- Back up existing commands to `commands/.backup/`
- Create `session-state/heartbeats/` directory
- Create `dashboard/runs/` directory
- Install all 9 hooks
- Configure PostToolUse and PreToolUse(Agent) hooks in settings.local.json
- Install dashboard server and HTML

Old `.current.d/` directories and `.session-id` files can be safely deleted after upgrade.
