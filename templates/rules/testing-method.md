# Testing Method Disclosure

Every test result must state the method used. The method tells the reader how much confidence to put in the result.

## Rule

When reporting test results -- in PRs, checkpoints, status reports, or any output that claims something was "verified" or "tested" -- include the testing method in parentheses after each result line.

## Examples

Good:
```
- [x] API returns 200 (method: curl to live uat endpoint)
- [x] Login flow works (method: npm test -- Jest integration suite)
- [x] No stale files after cleanup (method: ls + grep sweep of target directory)
- [x] Hook fires correctly (method: bash time command, 3 runs with simulated JSON input)
- [x] No security issues (method: code review of all input handling paths)
```

Bad:
```
- [x] API returns 200 (verified)
- [x] Login flow works
- [x] Tested and passing
```

## Why

"Verified" without a method could mean anything from "I read the code" to "I ran it end-to-end in production." The method is the trust signal. A code review catch is different from a live API test which is different from a unit test. Each has different confidence levels and the reader needs to know which one was used.
