---
type: rule
purpose: BINDING for every master/orchestrator agent -- when Owner grants class-level authorization (e.g., "merge to uat is greenlit"), execute each ready instance immediately without pausing for per-instance confirmation; skipping means re-introducing the synchronous approval loop Owner deliberately exited, stalling AFK execution windows.
trigger: Owner issues a class-level authorization phrase (e.g., "merge to uat", "no budget cap this sprint", "kill node for local testing") and the precondition (CI green, tests passing) is met for a specific instance
read_when: When the Owner issues a class-level authorization phrase and you are deciding whether each individual instance requires fresh confirmation before proceeding.
tags: [autonomous-execution, authorization, afw, owner-delegation, class-auth]
scope: public
departments: [all]
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_act_on_greenlit_authority.md) -- Knowledge session 2026-06-01
---

# Act on Class Authorization

## Rule

When Owner has authorized an action class (e.g., "merge to uat is greenlit",
"no budget cap for this run", "kill node for local testing"), each individual
instance of that action does NOT require a fresh ping or wait.

If the action class is greenlit AND the instance's prerequisite (CI green, tests
passing, build complete) is met: execute immediately. Do not pause to report and wait.

Still do NOT extend the authorization beyond its class:
- "merge to uat" is greenlit -> do NOT also merge to main
- "no budget cap this sprint" -> does not authorize production deploys
- Scope matches exactly what Owner stated; everything outside that scope stays at
  the normal zone level (YELLOW/RED)

## Why

Owner issues class-level authorization to reduce coordination overhead, especially
during AFK windows. Pausing on each individual instance after the class is greenlit
creates exactly the friction Owner was eliminating. It forces Owner back into a
synchronous loop Owner had deliberately exited.

Origin incident (2026-05-15 streaming-contract AFK run): Owner greenlit merge-to-uat.
Master stated "Waiting on CI for #176. When it returns green, I'll merge it" -- pausing
for Owner after CI cleared. Owner correction: "you should not have waited for me, you
are green for merge to uat."

The pattern: "Waiting on CI" is correct. "Waiting on Owner after CI clears" is the
violation.

## What violates this rule

- Saying "PR #N is green, merging -- let me know if you'd prefer otherwise" and waiting.
- Adding a "confirm before merge" step for each PR after class authorization is live.
- Treating every individual action as if no authorization had been given.
- Failing to execute an authorized action because Owner is AFK.

## Origin

Owner correction 2026-05-15. Related: `autonomous-execution.md`,
`dont-kill-productive-agents.md`, `iterate-until-success.md`.
