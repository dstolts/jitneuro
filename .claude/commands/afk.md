---
type: template
purpose: '/afk slash command template: arms/disarms the autonomous-continuation Stop hook (stop-continue-queue.sh) so a Claude Code session keeps working the .HUB/Hub.md ACTIVE TODO queue unattended. Install this file to ~/.claude/commands/ on any consuming machine (scripts/install.sh step 5h does this automatically).'
tags: [template, afk, autonomous-continuation, stop-hook, claude-code, slash-command]
scope: public
read_when: When installing or invoking the /afk command, or when wiring the autonomous-continuation Stop hook on a consuming machine.
last_evaluated: 2026-06-06
---

# /afk -- Arm/disarm autonomous continuation (work the queue unattended)

Arms the autonomous-continuation Stop hook (`stop-continue-queue.sh`, installed to
`~/.claude/hooks/` by the installer) so the session keeps working the
`.HUB/Hub.md` ACTIVE TODO queue without stopping after each task. Use it when you step
away and want the agent to keep executing the backlog.

It works because the Stop hook fires in the harness when the model tries to yield, and
re-injects "continue the queue" while executable tasks remain. A soft "keep going"
instruction cannot do this; the model still stops. The hook makes it mechanical.

## Usage

```
/afk            arm   -- keep working the queue until it is empty or fully blocked
/afk on         arm
/afk off        disarm -- return to normal (stop after each turn)
/afk status     report whether autonomous mode is on
```

## What Claude does when invoked

Flag path (project-scoped; resolve `<project>` to the current session's workspace root,
i.e. `$CLAUDE_PROJECT_DIR` or the directory Claude Code was launched from):

`<project>/.sessions/autonomous-mode.flag`

Use the Bash tool with forward slashes. Create `session-state/` with `mkdir -p` if missing.

- **on / (no arg):** mirror the current TodoWrite list into `.HUB/Hub.md` `## ACTIVE TODO`
  first (the hook reads Hub.md, not TodoWrite), then write the flag scoped to this session:
  `echo "on:<session_id>" > <flag>`. Confirm: "Autonomous mode ARMED -- I will work the
  Hub.md queue until it is empty or every remaining task is blocked. Disarm with /afk off."
- **off:** `rm -f <flag>`. Confirm: "Autonomous mode OFF -- back to normal stop-after-turn."
- **status:** report whether the flag exists and its contents.

When the owner signals AFK in plain language ("AFK", "stepping away", "be back later",
"keep going while I'm gone"), arm autonomous mode the same way, and disarm it when they
return.

## Safety

- **Safe by default:** with no flag, sessions stop normally.
- **Takes effect at session start:** the Stop hook is loaded when a session starts. After
  a fresh install/registration, start a new session for it to be active.
- **Runaway guard:** the hook gives up after 50 consecutive no-progress turns
  (override with env `JITNEURO_MAX_CONTINUE`); progress resets the counter.
- **Blocked-task discipline:** tasks marked blocked/awaiting/needs-owner/RED-zone in
  Hub.md are excluded from the executable count; when only blocked tasks remain the
  hook allows the stop.
