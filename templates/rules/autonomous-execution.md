---
type: rule
purpose: Binding execution-continuity rule for every agent running an approved multi-step task list; load at session start and at every task-completion boundary so agents continue to the next executable task instead of stopping for summaries, AFK pauses, or per-task reapproval.
read_when: At session start for every master agent, and at every task-completion boundary while working an approved task list.
tags: [autonomous-execution, task-management, afk-signal, anti-stall, agent-behavior]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---

# Autonomous Execution (Guardrail)

## Rule
As long as the approved task list has tasks that can be executed, keep executing
them. Never stop, summarize, or wait for input unless genuinely blocked.

Approval to execute a plan, PR, remediation list, Hub.md queue, or TodoWrite
list is approval to keep working that executable list until it is complete or
blocked. Do not ask for fresh permission between items on the same approved
list.

## Trigger
After completing any task:
1. Check the task list for remaining executable tasks
2. Check the active session's Hub.md for tasks added outside this conversation that are not yet in the task list -- add them
3. If executable tasks remain, start the next one immediately

## Blocked Tasks
If a task cannot be completed (needs human input, missing access, external dependency):
1. Flag it with a clear question or blocker description
2. Add the question to the Pending Questions queue
3. Skip to the next executable task
4. Continue working the list

## What "executable" means
A task is executable if meaningful progress can be made without human input. Uncertainty about the best approach is NOT a blocker -- make a judgment call and execute. Only stop for:
- RED zone actions requiring explicit permission (push to main, production deploy, delete)
- Missing information that cannot be found in code, docs, memory, or rules
- Conflicting instructions where either path could cause harm

## What violates this guardrail
- Completing a task and presenting a summary instead of starting the next task
- Asking "what's next?" when the task list has pending tasks
- Waiting for a human to return before continuing approved work
- Presenting a handoff document when tasks remain executable
- Saying "ready when you are" or "let me know" when work exists
- Treating approval workflow as a requirement to ask again after every task in
  an already-approved list

## AFK Signal
When someone says AFK, stepping away, be back later, brb, going to lunch, or similar -- this REINFORCES this guardrail. They are leaving BECAUSE they trust the agent to execute. Use the entire AFK window productively.

### Trigger phrases

Any of the following (or close variants) activate AFK behavior:
- "AFK", "be back later", "brb", "I'll be back", "stepping away", "going to lunch"
- "Keep going", "keep working", "work through the list", "don't stop", "don't wait for me"
- "Execute all", "run the plan", "proceed with everything"

### Trust-zone behavior under AFK

AFK does NOT elevate trust. Apply the same trust-zone rules as interactive mode:

| Zone | Behavior under AFK |
|---|---|
| GREEN | Execute freely, log results |
| YELLOW | Execute, flag in summary for review on return |
| RED | NEVER execute autonomously -- skip, flag for explicit approval |

### What AFK Mode Is NOT

- NOT permission to skip quality gates (tests still run, criteria still checked)
- NOT permission to elevate trust zones (RED stays RED -- push-to-main still requires explicit human approval per the trust-zone rule)
- NOT permission to make architectural decisions when the plan was not pre-approved
- NOT infinite -- if context compaction fires, save state and continue per PreCompact hook

### Ending AFK requires an explicit return signal

A reply from the human DURING an AFK window does NOT end AFK. They may have popped in for a
moment without coming back for good -- a one-off question, a quick correction, or a single
answer is not a return signal. Answer or act on it, then CONTINUE the AFK loop.

AFK ends ONLY when the human gives an explicit back-for-good signal, such as:
- "back", "I'm back", "I'm here", "returning"
- "let's discuss", "let's strategize", "strategy", "let's plan", "let's review this together"
- any instruction that only makes sense if they are staying present

When in doubt, assume the human is still away: keep executing the approved list, surface what
needs them, and do not stop the loop or present a wrap-up on a brief interjection.

### AFK handoff checklist (for the human, before stepping away)

Optional discipline but reduces friction on return:
- Task list is ordered and clear (TodoWrite or explicit list)
- Feature branch is checked out (not main)
- No RED-zone actions are critical-path
- Session state has been saved if context is near compaction

## Relationship To Approval Workflow

`approval-workflow.md` controls when work may start. This rule controls what
happens after work is approved. Once approval exists, continue through the
approved executable list without per-task reapproval. Stop only for RED-zone
actions, missing information that cannot be discovered, harmful instruction
conflicts, or exhaustion of all executable work.
