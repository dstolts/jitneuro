# Decision Model: Cross-Repo Contract Management

When changes touch repos that integrate with each other.

## Principle

Define the API contract in the spec FIRST. Both sides implement to the same
contract. If the contract changes, update BOTH sides in the same sprint.

## Process

1. **Identify integration points** -- which repos talk to each other?
2. **Define the contract** -- request/response shapes, auth, error codes, versioning
3. **Write contract in spec** -- not in code comments, not in Slack -- in the spec
4. **Both sides implement** -- backend and frontend build to the same contract
5. **Contract changes require both sides** -- never change one side and "fix the other later"

## Rules

- API contracts are defined before implementation starts
- Contract changes require a spec update reviewed by both sides
- Breaking changes require versioning (v1/v2) or a migration plan
- Integration tests validate the contract, not just unit tests on each side
- If one repo's sprint changes a contract, the other repo's sprint includes the update
