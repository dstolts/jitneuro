# User Story: /reload Command

**Created:** 2026-03-27
**Priority:** 80/100
**Status:** Ready for execution
**Handoff:** Agent-ready

## Desired State

User says `/reload` and gets a fresh context window with all project knowledge intact. No conversation history bloat, no stale context, full engrams/bundles/routing loaded.

## User Value

Long sessions degrade. Context fills with old tool outputs, completed subtask details, and stale reasoning. `/reload` is the "restart without losing knowledge" button. Owner doesn't have to remember the save/clear/load sequence or worry about losing state.

## Objectives

1. One command to refresh context
2. Project knowledge survives (engrams, bundles, routing, rules)
3. Session state survives (tasks, decisions, next steps)
4. Conversation history is intentionally dropped (that's the point)

## How It Works

### Interactive Mode (user is present)

```
User: /reload

Claude:
  1. Scans conversation for learn candidates (corrections, patterns, discoveries)
  2. Writes any found to Hub.md ## Lessons Learned section (crash-safe staging)
  3. Runs /save (checkpoint session + sync Hub.md)
  4. Displays:
     ```
     Session state captured and reloading.
     Type /clear to refresh -- context loads automatically after clear.
     Or close this terminal -- safe to, nothing will be lost.
     ```
  5. User types /clear (same terminal, SessionStart auto-loads)
     OR user closes terminal and opens new one (SessionStart auto-loads)
     OR external launcher handles it (zero user action, see External Mode)

  Note: Claude cannot trigger /clear programmatically (see #51).
  Until Anthropic adds that capability, the user types /clear.

  Future: VS Code extension that opens a new Claude Code terminal in the same
  workspace (not a new window). Requires VS Code extension API:
  `vscode.window.createTerminal({cwd, shellPath: 'claude'})`. See FR below.
  4. SessionStart hook fires, detects saved session
  5. Claude loads: CLAUDE.md, engrams, bundles (via routing weights), rules
  6. Claude reads session state file for pickup instructions
  7. Claude displays: "Reloaded. Session: <name>. Ready to continue."
```

### External Mode (cron/unattended)

```
/reload --external

Claude:
  1. Runs /save
  2. Writes a reload marker: .claude/state/reload-pending.md
     Content: session name, timestamp, reason
  3. External launcher (jitneuro-cron.sh) detects marker
  4. Launcher spawns new Claude instance:
     claude --print --prompt "Load project context from .claude/. Read .claude/state/reload-pending.md for session to resume. Execute pending tasks from Hub.md."
  5. New instance loads fresh, reads marker, resumes work
  6. Removes marker after loading
```

## Acceptance Criteria

### AC-1: /reload command template
- [ ] Create templates/commands/reload.md
- [ ] Steps: /save, display /clear instruction, set reload flag for SessionStart
- [ ] After /clear, SessionStart hook reads reload flag and auto-loads project context
- [ ] Display pickup summary: session name, pending tasks, repos involved

### AC-2: SessionStart hook integration
- [ ] Check for .claude/state/reload-pending.md on session start
- [ ] If found: auto-load engrams, bundles, routing weights, session state
- [ ] Display: "Reloaded from /reload. Session: <name>."
- [ ] Remove the pending marker after load

### AC-3: External reload mode
- [ ] /reload --external writes marker file for launcher pickup
- [ ] jitneuro-cron.sh checks for reload-pending.md on each cycle
- [ ] If found: spawn fresh Claude with project context prompt
- [ ] New instance reads marker, loads context, executes Hub.md tasks

### AC-4: What loads vs what doesn't
- [ ] LOADS: CLAUDE.md, engrams (relevant to session repos), bundles (via routing weights), rules, session state file, Hub.md
- [ ] DOES NOT LOAD: old conversation history, previous tool outputs, completed subtask details
- [ ] This is the point -- fresh context with durable knowledge

### AC-5: Learn candidates captured before clear
- [ ] Before /save, scan conversation for learn candidates (corrections, patterns, new knowledge)
- [ ] Write any found to Hub.md ## Lessons Learned section
- [ ] These survive /clear and get processed by /learn in the next session
- [ ] If no candidates found, skip (no empty Lessons Learned section)

### AC-6: Safety
- [ ] /save MUST complete before /clear instruction is shown
- [ ] If /save fails, abort and explain why
- [ ] Never auto-clear -- always require user to type /clear (destructive action)
- [ ] Hub.md must be synced before clearing

## Context Loading After Reload

```
Fresh context budget after /reload:

1. CLAUDE.md + rules/              ~2-4% context
2. Engrams for session repos       ~2-3% per repo
3. Bundles via routing weights     ~2-5% per bundle loaded
4. Session state file              ~1%
5. Hub.md for session repos        ~1% per repo
                                   ─────────────
                                   ~10-15% used

Remaining: ~85-90% available for new work
```

Compare to end-of-session (pre-reload): ~70-80% consumed by conversation history.

## Test Plan

1. Work for 30+ minutes, accumulating context
2. Run /reload
3. Verify /save completes (Hub.md synced)
4. Run /clear
5. Verify SessionStart loads project context automatically
6. Verify: correct session name, pending tasks visible, can continue work
7. Verify: old conversation details are gone (that's the goal)
