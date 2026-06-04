---
type: pattern
purpose: Binding PR lifecycle and reviewer-dispatch rule for multi-agent engineering orchestration (Author -> CI -> Security -> QA -> SRE -> Architect -> Owner); any orchestrator or PR-handling agent MUST consult this before deciding which review agents to summon, or required reviewers (sys-security, sys-qa, sys-sre, sys-architect) may be silently skipped and PRs ship without their blocking gates.
read_when: Before deciding which review agents to summon for any PR in a multi-agent engineering pipeline.
tags: [agent-communication, pr-pipeline, github-labels, multi-agent, code-review, pr-review, dispatch-rule, gate-skip-prevention, agent-onboarding]
scope: public
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Agent Communication Protocol -- Multi-Agent PR Pipeline Pattern

**Status:** APPROVED -- active
**Pattern type:** Multi-agent PR lifecycle with label-based state machine

---

## Problem

Agents operating as isolated units each have a role definition, toolset, and heartbeat, but without a defined protocol for:
- How agents signal completion to downstream agents
- What order agents review and approve PRs
- How blocking gates work (pass/fail, not warn)
- How a token-governor enforces budgets
- How stall/block status propagates across dependent agents

The result: a DevOps agent could warn on a SAST finding that a Security agent also catches independently. An Architect agent could merge a PR before a QA agent has tested it. No agent knows what other agents have already done on the same PR.

---

## Design: PR Lifecycle Pipeline

Every PR flows through a defined pipeline. Each stage is a BLOCKING gate -- the PR cannot advance until the gate passes.

### Stage Order

```
1. AUTHOR  -- a feature agent (backend, frontend, repo-specific) creates the PR on a feature branch
     |
2. CI GATE  -- DevOps agent runs the GitHub Actions pipeline (automated, blocking)
     |         - Build: type-check / compile (BLOCK on failure)
     |         - Semgrep SAST: p/owasp-top-ten, p/cwe-top-25, p/secrets (BLOCK on HIGH/CRITICAL)
     |         - Dependency audit: npm audit / pip audit (BLOCK on HIGH+)
     |         - Unit tests (BLOCK on failure)
     |
3. SECURITY REVIEW  -- Security agent reviews (blocking)
     |         - Differential security review (new attack surface, auth changes, input handling)
     |         - Credential scan (secrets in code, hardcoded values)
     |         - Signs off with label: security-approved
     |
4. QA REVIEW  -- QA agent reviews (blocking)
     |         - Contract tests pass (API response shapes match consumer expectations)
     |         - Critical path e2e tests pass
     |         - Signs off with label: qa-approved
     |
5. SRE CHECK  -- SRE agent reviews (blocking for infra-touching PRs, advisory otherwise)
     |         - Health endpoint still responds
     |         - No new unhandled error paths
     |         - Signs off with label: sre-approved (or sre-advisory if non-infra)
     |
6. ARCHITECT MERGE  -- Architect agent reviews LAST (blocking, final gate)
     |         - Verifies all upstream labels present (security-approved, qa-approved)
     |         - Architecture review: patterns, contracts, cross-repo impact
     |         - Merges to staging branch (GREEN zone) or flags for Owner (production = RED zone)
     |
7. OWNER APPROVAL  -- Only for production branch merges (RED zone)
           - Architect agent presents the PR with all sign-off labels visible
           - Owner approves or rejects
```

### Why This Order

- CI runs first because it is cheapest and fastest. No point in human-agent review if the build is broken.
- Security before QA because a security flaw makes test results irrelevant.
- QA before SRE because functional correctness matters before operational review.
- Architect LAST because the architect needs to see that all other concerns are resolved before making the merge decision. The architect does not duplicate security/QA work -- it trusts the labels.
- Owner only for production branch merges. Staging merges are the Architect's GREEN zone.

---

## Design: Agent Communication Mechanism

### GitHub Labels as State Machine

Each PR carries labels that represent its pipeline state. Agents read labels before acting.

| Label | Set By | Meaning |
|-------|--------|---------|
| `ci-passed` | DevOps agent (via GitHub Actions) | Build, SAST, tests all green |
| `ci-failed` | DevOps agent (via GitHub Actions) | Pipeline failed -- blocks all downstream |
| `security-approved` | Security agent | Security review passed |
| `security-blocked` | Security agent | Security issue found -- blocks merge |
| `qa-approved` | QA agent | Tests pass, contract verified |
| `qa-blocked` | QA agent | Test failure or contract drift -- blocks merge |
| `sre-approved` | SRE agent | Operational review passed |
| `sre-advisory` | SRE agent | Non-infra PR, SRE noted no concerns |
| `architect-approved` | Architect agent | Final review passed, ready to merge |
| `needs-owner` | Architect agent | RED zone action, Owner must approve |
| `stalled` | Orchestrator agent | No progress in 16h |

### Gate Rules

An agent MUST NOT begin its review until all upstream labels are present:

| Agent | Required Labels Before Acting |
|-------|-------------------------------|
| Security agent | `ci-passed` |
| QA agent | `ci-passed` |
| SRE agent | `ci-passed` |
| Architect agent | `ci-passed` AND `security-approved` AND `qa-approved` |
| Owner (production merge) | `architect-approved` AND `needs-owner` |

Security, QA, and SRE agents can run in PARALLEL after CI passes. The Architect agent waits for all three.

### Signaling Pattern

When an agent completes its review, it:
1. Adds its label to the PR (`gh pr edit --add-label <label>`)
2. Posts a structured comment:

```
## [agent-name] Review: PASSED
**Checked:** [what was reviewed]
**Findings:** [count] issues, [count] resolved
**Label:** security-approved
```

Or on failure:
```
## [agent-name] Review: BLOCKED
**Issue:** [one-line description]
**File:** [path:line]
**Severity:** HIGH
**Label:** security-blocked
**Action required:** [who needs to fix this and what to do]
```

### Token Governor Integration

The token-governor agent enforces token budgets across the pipeline:

1. **Budget per agent per day:** Defined in each agent's role configuration (e.g., Backend agent: 500K tokens/day)
2. **Logging:** Every agent logs token usage after each run
3. **Enforcement:** The token-governor reads the daily log on its scheduled run. If any agent exceeded its budget:
   a. Adds a `budget-exceeded` label to the agent's active issues
   b. Comments on the issue: "Token budget exceeded -- logging for analysis."
   c. Agents are NEVER skipped due to budget. Work continues. Non-compliance is logged so patterns can be identified and root causes fixed (task too large? prompt too broad? thrashing?).
4. **Escalation:** If an agent exceeds budget 3 days in a row, the token-governor creates a GitHub issue for the Architect agent to investigate root cause. The fix is to improve the agent's efficiency, not to stop it from working.

---

## Design: DevOps CI Pipeline (Blocking Gates)

The DevOps agent owns the GitHub Actions workflow. All checks BLOCK the PR -- no "warn and continue."

```yaml
# Simplified -- DevOps agent writes the full workflow per repo
jobs:
  build:
    - tsc --noEmit (TypeScript repos)
    - npm run build / python -m py_compile (all repos)
    - FAIL = ci-failed label, PR blocked

  sast:
    - semgrep --config p/owasp-top-ten p/cwe-top-25 p/secrets
    - HIGH or CRITICAL findings = ci-failed label, PR blocked
    - MEDIUM findings = warning comment, does not block

  dependency-audit:
    - npm audit --audit-level=high / pip audit
    - HIGH+ vulnerabilities = ci-failed label, PR blocked

  unit-tests:
    - npm test / pytest
    - Any failure = ci-failed label, PR blocked
```

**Why block and not warn:** The DevOps CI gate is the cheapest gate. If SAST finds a HIGH severity issue and only warns, the PR continues through security review, QA, architect -- wasting multiple agents' time on a PR that should have been rejected in 30 seconds. Block early, fix fast, re-run.

**Overlap with Security agent:** The DevOps CI gate runs automated SAST (tool-driven, pattern matching). The Security agent does differential review (reasoning about attack surface). They are complementary:
- DevOps CI catches: known vulnerability patterns, secrets in code, dependency CVEs
- Security agent catches: logic flaws, auth boundary mistakes, insecure defaults, new attack surface

Both are needed. Neither duplicates the other.

---

## Design: Architect Agent Merge Authority

### What Changes

**Before (undefined):** Architect agent reviews PRs but merge order is undefined. Could merge before security/QA.
**After:** Architect agent merges LAST. Cannot merge until all upstream labels are present.

### Merge Rules

1. **Staging merge (GREEN zone):** Architect agent can merge when `ci-passed` + `security-approved` + `qa-approved` are all present. No Owner approval needed.
2. **Production merge (RED zone):** Architect agent adds `needs-owner` label and presents the PR to the Owner. Owner approves or rejects. Architect agent executes the merge only after Owner says "approved."
3. **Conflict resolution:** If `security-blocked` and `qa-approved` (or vice versa), the blocking label wins. PR stays open until the blocker is resolved.
4. **Cross-repo PRs:** Both PRs must have all labels before either merges. Architect agent coordinates the merge order (API first, then frontend).

---

## Design: Backend Agent Cross-Repo Scope

### Division of Labor

| Agent | Role | Cadence |
|-------|------|---------|
| Repo scan agent (per repo) | Scheduled scan: drift, debt, new issues | Weekly |
| Backend agent | Sprint execution: fix bugs, implement features, create PRs | Daily |

Repo scan agents FIND issues. The Backend agent FIXES issues. The Backend agent works on whatever issue is highest priority in the active sprint backlog, regardless of which repo it lives in.

---

## RED Zone Additions (All Agents)

These actions are ALWAYS RED regardless of which agent encounters them. The agent stops, creates a `needs-owner` issue, and moves to the next task:
- **Auth boundary changes:** Adding or removing authentication on any endpoint
- **Payment/billing changes:** Modifying subscription tiers, payment flows, or pricing logic

---

## Open Questions

1. **Agent concurrency on PR review:** Should security/QA/SRE review the same PR simultaneously (parallel), or sequentially? Parallel is faster but uses more tokens. Sequential is cheaper but adds latency. **Recommendation: Parallel** -- these agents typically run during off-peak hours where throughput matters more than marginal token cost.

2. **Token budget defaults:** What should the daily token budget be per agent? Need baseline data from initial runs. **Recommendation: Start with no hard limit for Week 1, log everything, set budgets in Week 2 based on actual usage.**

3. **Repo-specific agents vs system agents on the same PR:** If a repo scan agent found the issue and the Backend agent fixes it, should the repo scan agent review the fix? **Recommendation: No** -- a dedicated code-reviewer agent handles code review. Repo agents find, system agents fix, code-reviewer agent reviews.

---

## Implementation Plan

Wire this into agent role files in this order:

1. Update DevOps agent role: CI pipeline is blocking, label definitions
2. Update Security agent role: wait for ci-passed, add security-approved/blocked labels
3. Update QA agent role: wait for ci-passed, add qa-approved/blocked labels
4. Update SRE agent role: wait for ci-passed, add sre-approved/advisory labels
5. Update Architect agent role: merge LAST, require all upstream labels, staging=GREEN production=RED
6. Update Code Reviewer agent role: runs parallel with security/QA, adds code-review-approved label
7. Update Token Governor agent role: budget enforcement, budget-exceeded labels
8. Update Orchestrator agent role: read budget-exceeded labels, log non-compliance (never skip agents)
9. Create GitHub Actions workflow template for DevOps agent to implement per repo
10. Add label definitions to all repos via `gh label create`
