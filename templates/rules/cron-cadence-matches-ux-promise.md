---
type: rule
purpose: Require that cron and queue cadence can deliver on any timing promise made in customer-facing copy, and that both sides are audited together whenever either changes.
read_when: Before shipping UX copy with timing language, or before changing any cron schedule or queue processing interval that backs a customer-facing promise.
tags: [cron, ux-copy, timing-promise, cadence, consistency]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---
# Cron Cadence Must Match UX Promise

When customer-facing copy makes a timing promise, the cron / queue / job cadence MUST be
able to deliver on that promise. Copy drift from system cadence creates false promises that
damage credibility.

## Rule

Before shipping UX copy with timing language ("within X minutes", "by end of day", "instantly"):
- Verify the system path end-to-end can meet that promise
- Specifically audit: cron schedules, queue processing intervals, external API latencies, propagation delays

When changing a cron / queue / job schedule:
- Audit what copy references that cadence
- Update BOTH sides or reject the change

## Why

Cron cadences drift over time for performance reasons (too frequent = spend, too rare = latency).
Copy drifts separately for marketing reasons. Neither owner audits the other side. The result is
a copy promise that becomes a lie the moment the cron schedule diverges -- often discovered by
a customer who waited much longer than promised.

## Concrete Audit for Copy + Cron

| Copy phrase | Required cadence |
|---|---|
| "Instantly" | < 5 sec, synchronous or near-synchronous |
| "Within a minute" | < 60 sec -- likely synchronous or 30-sec poll |
| "Within 5-10 minutes" | cron <= every 5 min, OR on-demand trigger |
| "Within an hour" | cron <= every 15 min |
| "Within 24 hours" | cron <= every 6 hours OR daily batch |
| "Next business day" | daily batch |

If the cron does not match, the copy is wrong.

## Prefer On-Demand Triggers Over Frequent Cron

For customer-facing promises, an on-demand trigger (enqueue processing immediately after
the user action) beats polling cron at any cadence. No drift, no wait, no cadence-to-copy
mismatch.

## How to Apply

- Grep for timing language in UX copy: "within", "minutes", "hours", "instant", "soon"
- For each match, identify the cron / queue that backs it
- Verify the cadence is tight enough
- Consider on-demand trigger if cron cadence would need to be <= 5 min
