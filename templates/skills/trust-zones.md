---
type: skill
purpose: Structured GREEN/YELLOW/RED permission model for AI actions that governs what an agent executes freely, executes-and-reports, or must stop and ask Owner before doing. Read this before any action to classify and get the right permission level.
tags: [skill, trust-zones, permissions, guardrails, agent-behavior]
scope: public
departments: [all]
read_when: Before taking any action whose scope or permission level is unclear; consult at session start to internalize zone boundaries.
last_evaluated: 2026-06-03
---

# Trust Zones

Structured permission model for AI actions. Know what you can do freely, what to execute and report, and what requires Owner approval before touching.

## Zone Definitions

| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze, research | Execute freely |
| YELLOW | Schema changes, new dependencies, API contracts, .env writes | Execute, report at checkpoint |
| RED | Push to main, production deploy, delete files/branches, DB migrations, auth boundary changes, pricing/payment changes | Stop and ask Owner |

## When to Apply

Before every action, classify it. When uncertain, treat it as one zone higher (YELLOW if you think GREEN, RED if you think YELLOW).

## Core Process

1. Identify the action you are about to take.
2. Match it to a zone using the table above.
3. GREEN: proceed immediately.
4. YELLOW: execute, then report what you did at the next checkpoint. Do not ask first unless the change is unusually large.
5. RED: STOP. State what you were about to do and why. Ask Owner for explicit permission. Do not proceed until permission is given.

## Git Zone Rules

- Commit local: GREEN
- Push to feature branch or uat: GREEN
- Push to main: RED (requires explicit Owner permission every time)
- Force push: always RED regardless of branch

## RED Zone Specifics

These actions are ALWAYS RED regardless of context:
- **Auth boundary changes**: Adding or removing authentication on any endpoint or route
- **Pricing/payment changes**: Modifying Stripe integration, pricing logic, subscription tiers, or payment flows
- **Push to main**: Every time, every repo
- **Production deploy**: Direct production changes
- **Delete files/branches**: Permanent removal of code or history
- **DB migrations**: Schema changes to production databases

## Owner Identity (CRITICAL)

All agents and Owner may share the same GitHub account. Distinguishing Owner input from agent input:

**Owner signals (treat as blocking directives):**
- Comment starts with `Owner:` -- this is the primary signal
- PR/issue has `owner-feedback` label (optional reinforcement)

**Agent signals:**
- Comments always start with `## sys-*` or `## repo-*` prefix
- Commits include agent name in message (e.g., `fix(sys-backend):`)

**Rules:**
- Any comment starting with `Owner:` is a blocking directive from the business owner. It overrides agent recommendations. Do not merge, approve, or proceed until the directive is addressed. Agents NEVER prefix their comments with `Owner:`.
- `Owner: merged` means Owner manually merged the PR. Not a process violation. Close linked issues, release file locks in sprint-state.json.
- `Owner: approved` means Owner approves a RED zone action. Proceed.
- If a PR is merged and no agent posted a `## sys-architect: MERGED` comment, this is an UNATTRIBUTED MERGE. Do NOT silently assume Owner did it. Create a `needs-owner` issue: "PR #N merged without agent attribution. Was this Owner or a guardrail violation?" Log to action-log API for dash visibility. Owner confirms or flags the violation.

## What to Avoid

- Treating "I think this is probably fine" as GREEN
- Asking permission for GREEN zone actions (wastes Owner time)
- Proceeding on RED zone actions because the task seems urgent
- Lumping YELLOW actions in with GREEN and skipping the checkpoint report

## Integration

Used by: all engineering roles -- sys-architect, sys-backend, sys-frontend, sys-devops, sys-sre, sys-qa, sys-security, sys-compliance, security-developer, mssp-engineer, and all repo-* agents
