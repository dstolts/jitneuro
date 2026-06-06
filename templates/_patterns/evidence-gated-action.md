---
type: pattern
purpose: Any agent or gate designer authorizing an irreversible, high-risk, or production-promotion action MUST apply this pattern before execution -- firing whenever a proposed action cannot be trivially undone or when an RCA follow-up is being actioned -- because proceeding without fresh cited evidence means the action is based on stale diagnosis or assumption, causing fixes that address the wrong cause and promotions that ship the unfixed defect to production.
read_when: Before executing any irreversible, production-promotion, or high-risk action to verify the required evidence chain is complete and fresh.
tags: [evidence-gate, validation, promotion, rca, trust-zones, verification]
scope: public
departments: [all]
name: evidence-gated-action
status: canonical
owner: org/architect
consumers: org/architect/managers/engineering-lead/CHARTER.md, org/architect/managers/qa-lead/CHARTER.md, _patterns/validation-gates.md
last_reviewed: 2026-05-14
last_evaluated: 2026-06-03
community_reviewed: 2026-06-02
---

# Evidence-Gated Action

**Summary:** An agent may not execute an irreversible, externally visible, high-risk,
or promotion action until the required evidence exists, is fresh, and is cited in
the action record. Confidence, memory, stale green checks, or "should be fine" are
not evidence.

---

## Why This Pattern Exists

A recurring failure mode: a system acts as though a promotion path is safe before
the actual evidence chain is complete. A concrete example is opening a staging-to-main
promotion PR before both automated E2E verification and human verification are green.

That specific gate is correct, but it is also too narrow to be the only expression of
the principle. The same failure shape appears across several related patterns:

- `living-plan-currency` requires a touched or cited plan before changing governed
  paths.
- `finding-to-remediation` requires tracked frontmatter and a task-tracker row before a
  finding can be treated as durable.
- `verify-before-presenting` requires the agent to inspect the actual result before
  handing work to a reviewer.
- `testing-method` requires every verification claim to state the method used.

The general rule is: when an action depends on a fact being true, the fact must be
proven in a durable, inspectable surface before the action executes.

---

## The Rule

**Before executing an evidence-gated action, the agent MUST cite evidence that
satisfies the gate's evidence contract. If the evidence is missing, stale, scoped
to the wrong artifact, or unverifiable, the action is blocked.**

An action is evidence-gated when any of these conditions are true:

1. It promotes work toward production, publication, customer visibility, billing,
   security posture, or Owner approval.
2. It crosses a trust-zone boundary from GREEN into YELLOW or RED.
3. It relies on a claim that can be checked mechanically, such as tests passing,
   a deployment being live, a plan being current, a finding being tracked, or a
   credential not being present.
4. A prior RCA, rule, charter, pattern, or PR checklist names evidence as a
   prerequisite.

If any condition applies, the agent either supplies the evidence or stops and drives
the missing evidence to green. It does not ask Owner to review unfinished work as a
substitute for evidence.

---

## Evidence Contract

Every concrete gate defines its own evidence contract, but all contracts share these
fields:

| Field | Required | Meaning |
|---|---|---|
| `gate` | Yes | Stable gate name, such as `uat-green-before-main-pr`, `living-plan-currency`, or `finding-tracker`. |
| `action` | Yes | The action being attempted. |
| `scope` | Yes | Repo, PR, branch, URL, file set, or artifact the evidence applies to. |
| `evidence` | Yes | Link, file path, command output reference, screenshot path, check run, Hub.md row, PR comment, or other durable proof. |
| `method` | Yes | How the evidence was produced, per `rules/testing-method.md`. |
| `timestamp` | Yes | When the evidence was produced or last verified. |
| `actor` | Yes | Agent, human, CI job, or system that produced the evidence. |
| `result` | Yes | `pass`, `warn`, `fail`, or `blocked`. |

Evidence is valid only when all are true:

- It is specific to the action's scope.
- It is fresh enough for the gate. If the gate does not define freshness, use the
  current PR head or current deployed build as the freshness boundary.
- It is inspectable by another agent or Owner.
- It states the verification method, not just the conclusion.
- It has not been invalidated by a later commit, deploy, failed check, or Owner
  correction.

---

## Evidence Levels

Different actions need different evidence strength. Use the lowest level that
actually proves the action is safe.

| Level | Action type | Minimum evidence |
|---|---|---|
| L0 | Trivial recall or non-actionable summary | State uncertainty if not verified; no external claim of certainty. |
| L1 | Claim about repo contents or configuration | File path, line reference, grep result, or direct file read. |
| L2 | Recommendation or diagnosis | L1 evidence plus rationale connecting evidence to conclusion. |
| L3 | Source or doc change completion claim | Diff review plus relevant command output, generated artifact check, or read-after-write verification. |
| L4 | Customer-facing, release, security, compliance, billing, or promotion action | Fresh gate-specific proof, such as CI, real API/browser test, scanner report, Owner approval, or deployment evidence. |

When the action crosses levels, the higher level wins. For example, a one-line
documentation edit is usually L3, but if it changes public compliance claims it is L4.

---

## Compact Output Contract

When returning from an evidence-gated action, use this compact status block:

```markdown
Evidence checked:
- <evidence item> (method: <how verified>)
Result: pass | warn | fail | blocked
Remaining uncertainty: <none or explicit uncertainty>
Action: allowed | blocked | owner-approval-required
```

If evidence surfaces a defect outside the current task scope, do not silently fix
outside scope. Track it per `_patterns/finding-to-remediation.md` or escalate through
the relevant charter.

---

## Canonical Evidence Record

Use this shape in PR bodies, Hub.md updates, RCA follow-ups, or scanner output:

```markdown
Evidence-Gated Action:
- gate: staging-green-before-main-pr
- action: open staging -> main promotion PR
- scope: your-org/your-repo@staging commit <sha>
- evidence:
  - AI E2E: <check-run-url-or-report-path>
  - Human verification: <reviewer-confirmation-reference>
- method:
  - AI E2E: Playwright real-browser run against deployed staging URL
  - Human verification: reviewer clicked through customer-visible staging flow
- timestamp: <ISO-8601>
- actor: qa-agent + reviewer
- result: pass
```

For file-based gates, the evidence can be local and repo-relative:

```markdown
Evidence-Gated Action:
- gate: living-plan-currency
- action: modify sync implementation
- scope: PR changed files under src/services/repairs/
- evidence: .HUB/Sync-System.md touched in this PR
- method: changed-files comparison against governs_paths frontmatter
- timestamp: 2026-05-14
- actor: GTM Gate scanner
- result: pass
```

---

## What Counts As Evidence

Valid evidence:

- CI check run URL with a passing result for the current commit.
- Test report path committed or uploaded as a PR artifact.
- Command output summarized in the PR body with the command named.
- Screenshot, trace, or DOM evidence from a real-browser run.
- Hub.md row or GitHub issue that tracks an open finding.
- Touched or cited living plan with explicit "reviewed/current" acknowledgement.
- Owner approval captured in the current session, PR comment, issue comment, or
  other durable record.

Invalid evidence:

- "I remember this was green."
- A passing check from an older commit.
- A local-only result when the gate requires deployed UAT.
- A screenshot with no URL, commit, timestamp, or flow description.
- A PR description that says "tested" without method.
- A plan filename mentioned without an acknowledgement that it was reviewed.
- A finding doc with no frontmatter and no tracking surface.

---

## Blocking Behavior

When evidence is missing or invalid:

1. Do not execute the gated action.
2. Record `result: blocked` with the missing evidence named explicitly.
3. Drive the missing evidence to green if it is within the agent's scope.
4. If the missing evidence requires Owner action, ask only for that specific action
   and include the cost/risk context.
5. Re-check evidence after any new commit, deploy, or material scope change.

The block is not a failure of autonomy. The autonomous action is to produce the
missing evidence or preserve the stop condition.

---

## Interaction With Trust Zones

Evidence-gated actions often overlap with trust-zone boundaries:

| Zone | Evidence behavior |
|---|---|
| GREEN | Agent may gather evidence and proceed when the gate passes. |
| YELLOW | Agent may execute after evidence is present, then report at checkpoint. |
| RED | Agent must stop after evidence is present and wait for Owner approval unless the Owner has explicitly delegated that exact action. |

Evidence does not downgrade a RED action into a GREEN action. It only makes the
action eligible for the appropriate approval path.

---

## Common Gates

| Gate | Evidence required before action |
|---|---|
| Staging-to-main promotion | Automated E2E against deployed staging and human reviewer verification, both current for the promoted commit. |
| Public content publish | Content-quality score, security review, brand-voice check, and explicit publish approval when required. |
| Finding closure | `closed_by`, `closed_date`, and remediation verification method in the finding frontmatter. |
| Living-plan governed code change | Governing plan touched or validly cited in the PR body. |
| External claim | Source, scan output, or product evidence proving the claim is true. |
| Budget-affecting action | Current budget envelope, projected cost, ROI rationale, and approval when required. |
| Security-sensitive change | Security review evidence, secret scan where applicable, and rollback path. |

---

## Scanner Semantics

Mechanical implementations should emit one of four results:

| Result | Meaning | Action |
|---|---|---|
| `pass` | Required evidence exists and is valid for the current scope. | Proceed according to trust zone. |
| `warn` | Evidence exists but has a non-blocking freshness or completeness concern. | Proceed only when the concrete gate allows warnings. |
| `fail` | Evidence contradicts the action, such as failing tests or stale plan status. | Block. |
| `blocked` | Evidence is missing or cannot be inspected. | Block until evidence exists. |

Default behavior is strict: `fail` and `blocked` stop the action. `warn` stops the
action unless the concrete gate explicitly defines warning-only behavior.

---

## Cross-System Applicability

This pattern applies across any AI agent system, CI pipeline, or automated workflow
regardless of the tooling used. The tool-specific surface may differ, but the contract
is the same:

1. Resolve the concrete gate.
2. Gather evidence.
3. Cite evidence in a durable place.
4. Proceed only if the gate result permits the action.

No agent system gets to substitute confidence for evidence.

---

## Cross-References

- `rules/testing-method.md` -- verification claims must state method.
- `rules/verify-before-presenting.md` -- reviewers see finished, verified work.
- `rules/verify-before-claiming.md` -- missing/broken claims require full search and
  file evidence.
- `rules/proactive-quality.md` -- agents must inspect real outputs and configured
  vs actual behavior before completion.
- `rules/testing-critical-path.md` -- critical customer path must be tested end to end.
- `rules/definition-of-done.md` -- done requires acceptance, validation, and docs.
- `rules/trust-zones.md` -- GREEN/YELLOW/RED action authority.
- `_patterns/living-plan-currency.md` -- file-scope evidence gate for living plans.
- `_patterns/finding-to-remediation.md` -- evidence gate for finding tracking.
- `_patterns/validation-gates.md` -- L1-L4 review chain that consumes gate results.
- `_patterns/agent-communication-protocol.md` -- PR lifecycle state and blocking
  gate propagation.
- `governance/FRONTMATTER-SCHEMA.md` -- required metadata for canonical artifacts.
- `governance/PROMOTION-CRITERIA.md` -- promotion requirements for shared artifacts.
