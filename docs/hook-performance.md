# Hook Performance Analysis

Benchmarked on Windows Server 2022 with Git Bash (MSYS2). Linux/macOS will be faster due to native fork costs being lower than MSYS2's POSIX emulation layer.

## Benchmark Results

| Hook | Fires On | Avg Time | Disk Writes | Concern? |
|------|----------|----------|-------------|----------|
| heartbeat.sh | EVERY tool call | ~290ms | 1 (touch) | Low -- spread across minutes |
| branch-protection.sh | Every Bash call | ~770ms | 1 (log) | Low -- only Bash calls |
| pre-agent-register.sh | Agent spawn only | ~750ms | 3 (mkdir, 2 JSON) | None -- rare event |
| post-agent-complete.sh | Agent return only | ~510ms | 1 (sed) | None -- rare event |
| session-start-write-id.sh | Session start | ~300ms | 1 (heartbeat file) | None -- once per session |
| session-start-post-clear.sh | Session start | ~400ms | 0 (stdout only) | None -- once per session |
| session-end-autosave.sh | Session end | ~300ms | 1 (autosave file) | None -- once per session |
| pre-compact-save.sh | Before compact | ~200ms | 1 (save file) | None -- rare event |

## Session Cost Estimate

Typical 200-tool-call session:
- ~200 heartbeat fires: **~58s** wall time (spread across the full session)
- ~80 Bash calls + branch-protection: **~62s** wall time
- ~5 Agent spawns + completions: **~6s** wall time
- **Total: ~126s (~2 min)** of hook overhead across the entire session

This is wall time, not blocking time. Hooks run in sub-second bursts between tool calls. The user never waits -- Claude Code fires the hook, it completes in <1s, then the next tool runs.

## Should You Be Concerned?

**No.** Here's why:

1. **Non-blocking.** Hooks run between tool calls, not during them. A 290ms heartbeat between two 5-second file reads is invisible.

2. **CPU is trivial.** Each hook is bash grep/touch/mkdir -- no computation. CPU usage is dominated by process fork overhead on Windows (MSYS2), not actual work.

3. **Memory is negligible.** Each hook runs as a short-lived bash process (~5MB RSS), exits immediately. No persistent memory allocation.

4. **Disk I/O is minimal.** heartbeat.sh touches one file (mtime update, no data written). pre-agent-register.sh writes ~200 bytes of JSON. These are metadata operations, not bulk writes.

5. **The value is high.** Live session tracking, agent monitoring, branch protection, and auto-save provide real-time visibility and safety. A 2-minute overhead across a multi-hour session is excellent ROI.

6. **Linux/macOS is faster.** The 290ms heartbeat is inflated by MSYS2's POSIX emulation. On native Linux, expect ~50-80ms. macOS ~80-120ms.

## Optimization Opportunities (Future)

If performance becomes a concern on low-powered machines:

1. **heartbeat.sh: Replace grep pipeline with bash builtins** -- The 5-fork grep chain to parse session_id could be replaced with bash string manipulation (0 forks), cutting heartbeat time to ~100ms on Windows.

2. **branch-protection.sh: Early exit for non-git commands** -- 80% of Bash calls aren't git commands but still pay the full grep cascade. Adding `echo "$COMMAND" | grep -qiE '^\s*git\s' || exit 0` early would skip them.

3. **branch-protection.sh: Remove debug log write** -- Writing to /tmp on every Bash call is unnecessary in production.

## How to Disable Dashboard Hooks

If you don't use the dashboard, you can disable the tracking hooks without affecting session management or branch protection.

### Selective Disable (dashboard tracking only)

Remove these entries from `.claude/settings.local.json`:

| Hook | Entry to Remove | What It Does |
|------|----------------|-------------|
| heartbeat.sh | PostToolUse (matcher: "") | Session liveness tracking |
| pre-agent-register.sh | PreToolUse (matcher: "Agent") | Agent spawn tracking |
| post-agent-complete.sh | PostToolUse (matcher: "Agent") | Agent completion tracking |

Ask Claude Code:
```
> "Remove the dashboard tracking hooks (heartbeat, pre-agent-register, post-agent-complete)
   from settings.local.json. Keep session management and branch protection hooks."
```

### Full Disable (all hooks)

Remove the entire `"hooks"` section from `.claude/settings.local.json`. Session management commands (/save, /load, /session) still work but lose automatic features:
- No auto-save on exit
- No branch protection
- No context recovery after compaction
- No dashboard tracking

### Re-Enable

Run the installer again or ask Claude Code:
```
> "Re-add the JitNeuro hooks to settings.local.json using the config from jitneuro.json"
```

## Race Conditions

Analyzed all hook combinations for concurrent execution risks. **No data corruption risks exist.** All races produce benign outcomes.

| Scenario | Risk | Worst Case |
|----------|------|------------|
| heartbeat.sh + post-agent-complete.sh (both PostToolUse) | None | Write to different files |
| Two Claude instances, same workspace | Low | Last-writer-wins on _autosave.md |
| Fast sequential Agent spawns | Very Low | Nanosecond timestamp collision -- one agent stuck as "running" in dashboard |
| SessionEnd + last PostToolUse overlap | Low | Zombie heartbeat file (empty, orphaned, harmless) |
| PreToolUse(Agent) + PostToolUse heartbeat | None | Touch does not alter file content |

**No file locking is used or needed.** Scripts are fast (<1s), touch distinct files in most cases, and failure modes are all recoverable. Adding flock would introduce more risk (deadlocks, stale locks) than the races themselves.

### Parallel Agent Spawns (Stress Test)

A common pattern is spawning 5+ research agents simultaneously (find files, search code, explore codebase). This is the heaviest concurrency scenario for the hooks. We analyzed it and **there is nothing to be concerned about:**

- **PreToolUse(Agent) fires 5 times in rapid succession.** Each invocation of pre-agent-register.sh gets a unique nanosecond timestamp (`date +%s%N`). Tested on Windows (100ns granularity): back-to-back calls produce distinct values. 5 parallel spawns get 5 unique IDs.
- **Run directory creation.** All 5 scan for an existing run directory. If none exists, all try to create it. `mkdir -p` is idempotent -- safe regardless of ordering. All 5 write identical `meta.json` content (same session), so even interleaved writes produce correct output.
- **Tracker files.** Each agent gets its own tracker file keyed by `<session-id>-<nanosecond-stamp>`. No collision possible with distinct timestamps.
- **Post-completion.** As agents return, PostToolUse(Agent) fires for each. FIFO ordering (oldest tracker first) means completions generally match the right agent. If agents finish out of order, dashboard labels may swap (agent A shows B's description) -- purely cosmetic, no data loss.
- **Total overhead.** 5 agent spawns add ~4 seconds of hook time total. Each completes in <1s and they run between tool calls, not blocking work.

**Portability note:** The `date +%s%N` nanosecond timestamp falls back to `date +%s` (seconds) on systems where `%N` is unsupported (older macOS/BSD). On those systems, 5 agents spawned within the same second WOULD collide. This is a known limitation -- if you hit it, the worst case is one agent appearing stuck as "running" in the dashboard until manual cleanup.

**Portability note:** The `date +%s%N` nanosecond timestamp in pre-agent-register.sh falls back to `date +%s` (seconds) if `%N` is unsupported. On such systems, two agents spawned within the same second would collide. This is a known limitation on older macOS/BSD systems.

## Hook Recursion

**Hooks cannot call themselves.** Hooks are shell scripts that run outside Claude Code's tool dispatch system. When heartbeat.sh runs `touch` or `grep`, those are native bash operations -- not Claude Code tool calls. The hook dispatcher only fires on Claude Code tool invocations (Read, Write, Bash, Agent, etc.).

The chain is: **Claude tool call -> hook fires -> bash runs -> bash exits -> Claude continues.** The bash execution is invisible to the hook dispatcher. No recursion is possible.

The only way to create hook recursion would be writing a hook that invokes the `claude` CLI itself (spawning a new Claude Code instance). That would start a separate process with its own session-id and hooks -- not recursion, but an independent session. JitNeuro's hooks never do this.
