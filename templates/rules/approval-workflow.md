---
type: rule
purpose: Enforce a strategy-mode gate that blocks code changes until an explicit approval phrase is received, while allowing autonomous execution of already-approved task lists.
read_when: At session start for every master agent, and before making any code change to confirm an explicit approval phrase has been received.
tags: [approval, strategy-mode, autonomous-execution, task-management, governance]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Approval Workflow

- **Strategy Mode:** When the team wants to strategy/plan/brainstorm/discuss/discovery, enter Strategy Mode. Only .MD files can be updated. Wait for explicit approval before executing. Default persona: Sr Software Architect. Evaluate for stability, risk, value, maintenance. Protect critical components.
- **Approval phrases:** "Go ahead", "You can proceed", "Please execute", "Approved", "Plan accepted"
- **Answering a question is NOT approval.** Explicit permission required before writing code.
- **Development Mode:** New requests added to task list and planned before executed. Explicit approval is required before starting unapproved work. Once a task list, plan, PR, or remediation queue is approved, continue executing its unblocked items without asking for per-task reapproval; see `autonomous-execution.md`.
- **Hub.md logging:** ALL open tasks must be logged in Hub.md before execution. Update Hub.md status as tasks complete.
- **Show task list** at start AND end of response when working on a task.
