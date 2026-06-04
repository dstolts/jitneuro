# Decision Routing

This file defines a simple trust model: what actions the AI handles autonomously,
what it executes and then reports, and what it stops to ask you about first.

Fill in the starter table below with the action types that matter for your context.
The goal is to minimize friction on low-stakes decisions while ensuring you stay in
control of anything that is hard to reverse, costs real money, or affects customers.

---

## Trust Tiers (Starter Table -- Edit to Match Your Context)

| Tier | Label | Behavior | Default Action Types |
|---|---|---|---|
| 1 | Proceed Autonomously | Execute without reporting unless something unexpected happens | [FILL IN: e.g., read files, run tests, research, write drafts, update internal docs] |
| 2 | Proceed + Report | Execute, then summarize at next checkpoint | [FILL IN: e.g., commit to a feature branch, create a GitHub issue, update config files] |
| 3 | Stop and Ask | Do not proceed until you give explicit approval | [FILL IN: e.g., push to production, send external communication, delete data, spend money] |

---

## Your Tier 1 Actions (AI Proceeds Without Asking)

[FILL IN: List the specific action types where you trust the AI to proceed on
its own. Be concrete -- not "coding" but "edit files in a feature branch".]

<!-- Example:
- Read any file in the repository
- Write or edit files that are not customer-facing
- Run tests locally
- Research online and summarize findings
- Update internal documentation
- Create or update GitHub issues
-->

---

## Your Tier 2 Actions (AI Proceeds + Reports at Checkpoint)

[FILL IN: Actions where you want the AI to move forward but loop you in at a
natural stopping point before moving on to the next major step.]

<!-- Example:
- Commit code to a feature or staging branch
- Push a PR for review (not merge)
- Update a config file that affects behavior in staging
- Send a draft to a shared folder for your review
- Make schema changes in a non-production database
-->

---

## Your Tier 3 Actions (AI Stops and Asks First)

[FILL IN: Actions that require your explicit approval every time, no matter
the context. These are your hard stops.]

<!-- Example:
- Push to main or production
- Merge a pull request
- Send anything to a real customer
- Spend money or create paid subscriptions
- Delete files, records, or branches
- Make changes to authentication or access control
-->

---

## Override Rule

[FILL IN: How can you temporarily change a tier during a session? What phrase
signals that the AI should proceed on something it would normally stop for?
What signals that it should be more cautious than usual?]

<!-- Example:
- "Go ahead" or "Approved" = proceed on a Tier 3 action I just described
- "Check with me first" added to a request = treat this request as Tier 3 even
  if the action type is normally Tier 1 or Tier 2
- "AFK" = continue all Tier 1 and Tier 2 work autonomously while I am away;
  queue Tier 3 items for when I return
-->

---

## Notes on Irreversibility

[FILL IN: Are there any action types where the tier should increase
automatically based on reversibility? For example, you might allow Tier 2 for
database writes in staging but require Tier 3 for any production database write.]

<!-- Example:
- Database writes in staging: Tier 2
- Database writes in production: Tier 3, always
- Deleting anything: Tier 3, always -- archive instead when possible
-->
