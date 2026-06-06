---
type: rule
purpose: BINDING for every backend/API agent and master orchestrator handling Owner-facing production changes -- the gate sequence (API contract MD -> schema design -> migrations PR -> code PR -> smoke -> deploy) is mandatory with explicit Owner approval at each gate; skipping means code implementing an unapproved contract ships to production, requiring rework or shipping unreviewed decisions directly to customers.
trigger: any agent about to write a migration file, open a PR, or deploy after Owner answers questions about a new endpoint, schema change, or feature design
read_when: Before writing any migration file, handler, or schema change, and after Owner answers design questions about a new endpoint or feature.
tags: [gate-discipline, pr-discipline, deployment, contract-first, approval-workflow]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_gate_discipline_contract_before_code.md) -- Knowledge session 2026-06-01
---

# Contract Before Code

## Rule

Owner-facing production changes proceed through gates in strict order. Each gate requires explicit Owner approval before the next begins:

1. **API contract MD** -- endpoints, request/response shapes, error envelope, enum values. No schema, no code.
2. **Schema design** -- DB tables backing the contract. No migration files yet.
3. **Migrations PR** -- `.sql` files only. No application code.
4. **Code PR** -- handlers, validators, services.
5. **Smoke tests** -- real DB, real external APIs.
6. **Deploy** -- from main only, after UAT smoke + Owner sign-off.

When Owner answers questions about schema shape or endpoint design, the correct next action is to DRAFT THE CONTRACT MD for Owner review -- not to open a migrations PR, not to write code. Answers are inputs to the next gate artifact, not authorization to skip gates.

Each gate is a hard stop. Per approval-workflow rule: "Answering a question is NOT approval."

## Why

- Jumping ahead produces code that implements a contract Owner has not yet approved, requiring rework or shipping unreviewed decisions.
- Two incidents in the same session (2026-05-19) both traced to the same root: having partial answers and treating them as authorization to execute the next phase.
- The gate sequence exists precisely to surface misalignments cheaply (at contract/schema stage) rather than expensively (after code or after prod deployment).

## What violates this rule

- Opening a migrations PR immediately after Owner answers schema questions without first drafting + getting approval on the contract MD.
- Writing code before the schema design is approved.
- Deploying from a feature branch before PR review (see no-feature-branch-to-production rule).
- Treating a handoff or session plan as authorization when it conflicts with gate sequence.

## Origin

Origin incident -- a feature with a new data contract: (1) a feature branch was deployed to production before the PR was reviewed; (2) the contract document was skipped entirely after the schema questions were answered, going straight to migrations and code. The result was building before the schema was approved and before the contract was even presented -- exactly backwards. This rule exists so that sequence cannot repeat.
