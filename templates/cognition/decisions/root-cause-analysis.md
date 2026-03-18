# Decision Model: Root Cause Analysis

When debugging or fixing issues, follow this workflow. Never patch symptoms.
Applies to ALL failures -- code bugs, process failures, communication mistakes, behavioral errors.

## Triggers

- User explicitly asks for root cause analysis
- Friction detection fires AND user rejects the initial fix
- Repeated failures in the same area

## Process (Code Bugs)

1. Research and fully understand issues, flow, and requirements
2. Check server logs first when diagnosing or validating
3. Evaluate if current approach is solid, low maintenance, stable -- if not, review architecture
4. Execute changes on API
5. Real test of API to validate request/response payloads (no mockups)
6. Update frontend to send proper request, receive proper response, display properly
7. Repeat for next problem

## Process (Behavioral / Communication Failures)

1. STOP. Do not fix anything yet.
2. What did the user expect vs what happened?
3. What did the assistant actually do? (re-read the exact exchange, not from memory)
4. Where in the chain did it go wrong?
5. Is there a rule or anti-pattern that should have prevented this? If yes, why didn't it fire? If no, what's missing?
6. State the root cause in one sentence. Confirm with user.
7. Only after user accepts the analysis: update anti-patterns immediately.

## Rules

- Ask user which branch before making changes
- Execute API and frontend simultaneously when both are involved
- Never skip, disable, or bypass functionality to "fix" the problem
- Trace the problem to its origin before writing code
- Show all pertinent requests/responses on console
- Never update rules or anti-patterns until analysis is complete and user-accepted
- Premature fixes with wrong root causes create wrong rules
