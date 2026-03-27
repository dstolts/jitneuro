# Scheduled Agent Interrupts (MANDATORY)

Scheduled agents are user-configured timer agents that periodically return instructions to master. They exist because master forgets housekeeping during deep work. Their interrupts are mandatory.

## When a background scheduled agent returns

1. **STOP current work immediately** -- mid-sentence, mid-tool, mid-plan. Do not finish the current thought first.
2. **Read the INSTRUCTION** from the agent's return message.
3. **Execute the instruction FIRST**, before resuming any previous work:
   - `INSTRUCTION: /save` -- run /save now
   - `INSTRUCTION: /health` -- run /health now
   - `INSTRUCTION: UPDATE_HUB` -- sync TodoWrite state to Hub.md now. Read TaskList, compare to Hub.md, update Hub.md to match current task status.
   - `INSTRUCTION: ASK_USER <message>` -- surface the message to the user immediately
   - `INSTRUCTION: RESUME_TASKS` -- read TaskList, pick next pending task, execute it
   - `INSTRUCTION: SURFACE_QUESTIONS` -- display the pending questions queue NOW
   - `INSTRUCTION: NONE` -- no action needed this cycle, just re-spawn
   - `INSTRUCTION: <any slash command>` -- run that command now
   - `REMINDER:` lines -- execute alongside the main instruction (e.g., always surface pending questions)
4. **Re-spawn the timer agent** with the same config (unless user ran `/schedule stop <name>` or the agent's `enabled` is false in jitneuro.json).
5. **Resume previous work** where you left off.

## Why this rule exists

Master gets tunnel vision during deep coding. It deprioritizes housekeeping (saving, status updates, Hub.md) when focused on implementation. Scheduled agents are the interrupt mechanism that forces discipline. If master delays or ignores the instruction, the entire system fails.

## Priority order

```
User input > Scheduled agent interrupt > Current task
```

Treat a scheduled agent return the same way you treat a new user message arriving mid-work: handle it NOW.

## Trust model

Scheduled agents are defined in the user's jitneuro.json config. They are trusted. Execute their instructions without asking for confirmation. The user already approved these when they configured them.

## Re-spawn protocol

After executing the instruction, immediately spawn a fresh background timer agent with the same name, interval, and prompt from the scheduledAgents config. The agent is one-shot by design -- each instance sleeps once, returns once, dies. Master re-spawns create the loop.

Do NOT re-spawn if:
- User explicitly ran `/schedule stop <name>`
- The agent's `enabled` field is false in jitneuro.json
- The session is ending
