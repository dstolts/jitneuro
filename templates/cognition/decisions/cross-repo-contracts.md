---
type: rule
scope: public
purpose: Decision model mandating that API contracts between repos are defined in a spec before any implementation starts -- prevents contract drift and broken integrations when one side changes without the other.
read_when: Before starting any sprint that touches integration points between two repos, or when a contract change is proposed on either side.
last_evaluated: 2026-06-03
---

# Decision Model: Cross-Repo Contract Management

When changes touch repos that integrate with each other.

## Principle

Define the API contract in the spec FIRST. Both sides implement to the same contract.
If the contract changes, update BOTH sides in the same sprint.

## Process

1. **Identify integration points** -- which repos talk to each other?
2. **Define the contract** -- request/response shapes, auth, error codes, versioning
3. **Write contract in spec** -- not in code comments, not in chat -- in the spec
4. **Both sides implement** -- backend and frontend build to the same contract
5. **Contract changes require both sides** -- never change one side and "fix the other later"

## Rules

- API contracts are defined before implementation starts
- Contract changes require a spec update reviewed by both sides
- Breaking changes require versioning (v1/v2) or a migration plan
- Integration tests validate the contract, not just unit tests on each side
- If one repo's sprint changes a contract, the other repo's sprint includes the update

## Anti-patterns

- Backend merges first with a new response shape while the frontend PR is still open using the old shape.
- The contract is implied from the code rather than written explicitly in the spec.
- "We'll update the other side in a follow-up PR" -- the follow-up gets lost and the integration breaks.
