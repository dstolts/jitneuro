---
type: rule
purpose: BINDING for every development-phase agent or master session when Owner says "test local" -- test the change on the already-checked-out feature branch against the local running server, iterate in place, and only promote to uat when ready; pushing to uat for a round-trip first pollutes the team integration branch with un-vetted work and costs Owner time waiting for a deploy cycle.
trigger: Owner says "test local", "test on local", "verify locally", "get it working in dev", or any equivalent phrase directing verification to happen on the local machine before uat promotion
tags: [dev-flow, local-testing, feature-branch, uat-promotion, owner-time]
scope: public
departments: [engineering]
read_when: When Owner says "test local", "test on local", "verify locally", or any equivalent phrase directing verification to happen on the local machine.
last_evaluated: 2026-06-03
---

# "Test Local" Means The Feature Branch, Not A uat Round-Trip

When the Owner says **"test local"** (or "test on local", "verify locally", "get
it working in dev"), it means: test the change on the **feature branch that is
already checked out** in the local repo. It does NOT mean push the branch to
`uat` and pull it back down to the local machine.

## The canonical development flow

```
feature branch  ->  local test + iterate  ->  promote to uat  ->  team deeper test  ->  human gate  ->  main
```

- The feature branch is **already the working branch** -- there is nothing to
  "check out". The change lives on it right now.
- "Test local" = on that branch, ask the Owner to **reboot the local servers**
  (API + App), then exercise the change against the local build.
- Keep **working and testing on the feature branch** until the change is
  **ready to promote**. Iterate in place; do not involve uat yet.
- `uat` is the **team integration / deeper-testing stage** -- where the larger
  team validates a change that is already believed-good. It is NOT the first
  test surface, and it is NOT a substitute for local feature-branch testing.
- Only after local testing says "ready" does the branch get promoted to uat.

## Anti-patterns (do NOT do these)

- Pushing the feature branch to `uat` so it can be "tested", then pulling uat
  down to the local machine. This skips local feature-branch testing entirely
  and pollutes the team integration branch with un-vetted work.
- Treating uat as the default place to verify a fix. uat is downstream of local
  testing, not in place of it.
- Re-checking-out or creating a branch when the feature branch is already the
  current working branch. There is nothing to check out.
- Asking the Owner to do a uat round-trip when the request was "test local".

## How to apply

When the Owner asks to test local:
1. Confirm the working (feature) branch is the one with the change (it already
   is -- do not switch branches).
2. Ask the Owner to reboot the local servers so they load the branch's code
   (per the repo's NEVER-auto-restart-node rule, the Owner restarts).
3. Run the verification against the local build (real user outcome, not
   200/event presence).
4. Iterate on the feature branch until ready.
5. Only then promote to uat for the team's deeper testing.

## Origin

2026-06-01 (a live-bug fix arc). The session, following a prior handoff that
chose "the clean path is uat verification", asked the Owner to merge feature
branches to uat for testing. Owner correction (repeated, frustrated): "when I
ask to test local instead of UAT, that does not mean push to uat and then pull
to local. It means test on local branch ... we keep working and testing on the
feature branch until it is ready to promote to uat for deeper testing by the
larger team."

## Related

- `rules/uat-green-before-main-pr.md` -- the gate AFTER uat (uat green + human
  gate before main); this rule governs the stage BEFORE uat.
- `rules/pull-before-pr.md` -- branch currency discipline when promoting.
- The group `CLAUDE.md` promotion process: test local -> PR uat -> test uat ->
  human gate -> PR main -> standard merge (NEVER --admin).
