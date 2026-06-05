---
type: rule
purpose: BINDING for every backend/API and frontend agent writing business-logic code -- all prices, tier limits, pack sizes, and numeric business values MUST be read from the database at runtime, never hardcoded; and pricing ambiguity MUST NEVER gate marketing, infrastructure, or non-pricing work; skipping means a pricing change requires a code deploy and blocks downstream tasks unnecessarily.
trigger: any agent writing code that references a dollar amount, plan limit, tier threshold, or cap inline as a literal, OR any agent adding a task dependency on pricing resolution before proceeding with non-pricing work
tags: [pricing, database, architecture, marketing, blockers]
scope: public
departments: [engineering]
read_when: Before writing any code that references a price, plan limit, tier threshold, or numeric business value inline as a literal.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_pricing_marketing_concern.md, feedback_pricing_never_blocks.md) -- Knowledge session 2026-06-01
---

# Pricing Never in Code, Never a Blocker

## Rule

### Part 1 -- Pricing lives in DB, never in code

Prices, query limits, Q-round caps, pack sizes, tier thresholds, and any numeric
business value MUST resolve from the database at runtime. Code must never need to
change in order to change a price or a limit.

- API contracts: no hardcoded prices or plan limits. Read from `/api/subscription/plans`
  and `/api/user/entitlements`. Iterate over whatever the API returns.
- DB schemas: safety DEFAULTs (e.g., `DEFAULT 1`) are NULL guards only. Document them
  as such. They are not business values.
- UI copy and confirmation dialogs: interpolate from API response. Never hardcode dollar
  amounts or round counts in rendered strings.
- Stripe: price objects live in Stripe, keyed by DB-stored price IDs. Code never
  contains a Stripe price ID literal.

### Part 2 -- Pricing is never a blocker on other work

Pricing ambiguity or a pending pricing rework NEVER blocks marketing, outbound,
content, infrastructure, or launch work. Build around current public pricing. If no
public pricing exists yet, use the last-approved number from the session, log the
assumption, and proceed.

When a task surfaces "blocked on pricing" -- override it. Pricing is a 15-minute
edit (website copy + Stripe product). Everything else should proceed.

## Why

Pricing changes happen frequently for marketing reasons: promos, tier restructuring,
A/B tests. Tying any of those to a code deploy creates friction that kills marketing
agility and forces engineering into business decisions.

In 2026-04 a pricing rework blocked 6 downstream tasks (Stripe setup, N8N imports,
jit-dash modules, cache layer, tier enforcement, forum automation) unnecessarily. Each
of those tasks needed only the CURRENT number, not the final perfect price.

## What violates this rule

- Hardcoding a dollar amount, plan limit, or tier cap anywhere in application code.
- Adding `if tier === 'pro'` guards where the threshold is an inline literal.
- Staging downstream work (campaigns, infra, content) as "blocked on pricing."
- Using `<from DB>` placeholders in API specs but then populating them with constants
  in the implementation.

## Origin

2026-04-14: Owner during a product review: "should not need to change code to
change a price... price is not a concern for development, it is a concern for marketing."
2026-04-15: a sales session -- 6 tasks incorrectly blocked on pricing rework.
Owner: build around current pricing, ship the tasks.
