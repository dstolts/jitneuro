# /afk -- Arm/disarm autonomous continuation (work the queue unattended)

Arms the autonomous-continuation Stop hook (`hooks/stop-continue-queue.sh`) so the
session keeps working the `.HUB/Hub.md` ACTIVE TODO queue without stopping after each
task. Use it when you step away and want the agent to keep executing the backlog.

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

Resolve the flag path: `<project>/.sessions/autonomous-mode.flag`
(`<project>` = `$CLAUDE_PROJECT_DIR`, else the repo root).

- **on / (no arg):** ensure `.HUB/Hub.md` exists and its `## ACTIVE TODO` reflects the
  current task list (mirror TodoWrite first). Then write the flag, scoped to this
  session: `echo "on:<session_id>" > <flag>`. Confirm: "Autonomous mode ARMED -- I will
  work the Hub.md queue until it is empty or every remaining task is blocked. Disarm
  with /afk off."
- **off:** `rm -f <flag>`. Confirm: "Autonomous mode OFF -- back to normal stop-after-turn."
- **status:** report whether the flag exists and its contents.

When the owner signals AFK in plain language ("AFK", "stepping away", "be back later",
"keep going while I'm gone"), arm autonomous mode the same way, and disarm it when they
return.

## Safety

- **Safe by default:** with no flag, sessions stop normally. This command is the only
  thing that arms it (besides the owner setting the flag directly).
- **Runaway guard:** the hook stops itself after `JITNEURO_MAX_CONTINUE` (default 50)
  consecutive turns with no queue progress, and never blocks when the queue is empty or
  all remaining tasks are marked blocked / awaiting-owner.
- **Long unattended runs:** Claude Code caps consecutive Stop-hook blocks (default 8).
  For long queues, raise it: set `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` (e.g., `999`) in your
  environment or the `env` block of `settings.local.json`.
- **Keep Hub.md current:** the hook reads `.HUB/Hub.md` `## ACTIVE TODO`. Mirror
  TodoWrite to Hub.md as you work, or the hook cannot see progress.

## Requires

- `hooks/stop-continue-queue.sh` installed and registered on the `Stop` event
  (both done by `install.sh`).
