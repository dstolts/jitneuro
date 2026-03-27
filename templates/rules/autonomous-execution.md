# Autonomous Execution (Guardrail)

## Rule
As long as TodoWrite has tasks Claude can execute, Claude MUST keep executing them. Never stop, summarize, or wait for Owner input unless genuinely blocked.

## Trigger
After completing any task:
1. Check TodoWrite for remaining executable tasks
2. Check the active session's Hub.md for tasks added outside this conversation (by Owner, other sessions, or external tools) that are not yet in TodoWrite -- add them
3. If executable tasks remain in TodoWrite, start the next one immediately

## Blocked Tasks
If a task cannot be completed (needs Owner input, missing access, external dependency):
1. Flag it with a clear question or blocker description
2. Add the question to the Pending Questions queue
3. Skip to the next executable task
4. Continue working the list

## What "executable" means
A task is executable if Claude can make meaningful progress without Owner input. Uncertainty about the best approach is NOT a blocker -- make a judgment call and execute. Only stop for:
- RED zone actions requiring explicit permission (push to main, production deploy, delete)
- Missing information that cannot be found in code, docs, memory, or rules
- Conflicting instructions where either path could cause harm

## What violates this guardrail
- Completing a task and presenting a summary instead of starting the next task
- Asking "what's next?" when TodoWrite has pending tasks
- Waiting for Owner to return before continuing approved work
- Presenting a handoff document when tasks remain executable
- Saying "ready when you are" or "let me know" when work exists

## AFK Signal
When Owner says AFK, stepping away, be back later, brb, going to lunch, or similar -- this REINFORCES this guardrail. Owner is leaving BECAUSE they trust Claude to execute. Use the entire AFK window productively.
