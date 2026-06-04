---
type: rule
purpose: Mandate a graduated backoff when API calls return 5xx errors so agents do not hammer an unstable service, burn budget, or mask the real failure.
read_when: Before implementing any API retry logic, or immediately when an API call or subagent dispatch returns a 5xx error.
tags: [api, backoff, error-handling, retry-policy, resilience]
scope: public
last_evaluated: 2026-06-03
---
# API Error Backoff (5xx Responses)

When an API call or subagent dispatch returns a 5xx server error, wait before retrying.
Do not hammer the API through an error wave -- it burns budget for no output and may
make instability worse.

## When It Fires

Typical pattern: call dispatched -> returns in seconds with a server error + 0 useful output
-> same error on immediate retry. This indicates a transient service issue, not a bug in
the request.

## Backoff Policy

- **1st 5xx:** retry once after ~60 seconds (transient hiccup likely)
- **2nd consecutive 5xx on same call:** wait ~5 minutes before 3rd attempt. Check the
  service's status page for an API-wide incident.
- **3rd consecutive 5xx:** pause the dispatch, notify the requester, wait for direction
  or status-page confirmation. Do NOT auto-retry a 4th time within 30 minutes.

## What to Do During Backoff

- Keep prior work intact. Do not roll back state because a dispatch failed to produce output.
- If other independent work can proceed via a different service or call, do that in parallel.
- Report the situation in one line: "API 5xx x2 -- pausing dispatch for N minutes before retry."

## What Violates This Rule

- Immediate re-dispatch after a 5xx within 10 seconds
- Retrying more than 3 times in quick succession
- Silently burning budget on retries without reporting the situation
- Rolling back completed work because a follow-up call failed

## Related

- `runaway-process-prevention.md` -- caps on retry loops and API loop scripts
