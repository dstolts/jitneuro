---
type: rule
scope: public
departments: [all]
purpose: RCA decision workflow for all failure types (code bugs, process failures, behavioral errors) -- ensures root cause is identified before any fix is applied; skipping produces symptom patches that recur.
read_when: When friction detection fires and the user rejects an initial fix, when repeated failures occur in the same area, or when the user explicitly requests root cause analysis.
last_evaluated: 2026-06-03
---

# Decision Model: Root Cause Analysis

When debugging or fixing issues, follow this workflow. Never patch symptoms.
Applies to ALL failures -- code bugs, process failures, communication mistakes, behavioral errors.

## Triggers

- User explicitly asks for root cause analysis
- Friction detection fires AND user rejects the initial fix
- Repeated failures in the same area

## Process (Code Bugs)

1. Research and fully understand the issue, flow, and requirements
2. Check server logs first when diagnosing or validating
3. Evaluate if the current approach is solid, low maintenance, stable -- if not, review architecture
4. Execute changes
5. Real test to validate request/response payloads (no mocks)
6. Update all affected surfaces to send the correct request, receive the correct response, display properly
7. Repeat for next problem

## Process (Behavioral / Communication Failures)

1. STOP. Do not fix anything yet.
2. What did the user expect vs what happened?
3. What did the assistant actually do? (re-read the exact exchange, not from memory)
4. Where in the chain did it go wrong?
5. Is there a rule or anti-pattern that should have prevented this? If yes, why did it not fire? If no, what is missing?
6. State the root cause in one sentence. Confirm with user.
7. Only after user accepts the analysis: update anti-patterns immediately.

## Rules

- Never skip, disable, or bypass functionality to "fix" the problem
- Trace the problem to its origin before writing code
- Show all pertinent requests/responses in logs or console
- Never update rules or anti-patterns until analysis is complete and user-accepted
- Premature fixes with wrong root causes create wrong rules
