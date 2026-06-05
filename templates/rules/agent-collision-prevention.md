---
type: rule
purpose: 'Require every multi-agent deployment to use distinct label namespaces and tracking mechanisms so that one system''s automation never accidentally triggers another system''s dispatch pipeline.'
read_when: Before creating GitHub issues or labels in any repo where multiple agent systems are active, or when onboarding a new agent system alongside existing ones.
tags: [agent-systems, label-namespace, collision-prevention, github-issues, multi-agent]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Agent System Collision Prevention

When multiple agent systems operate in the same repository ecosystem, each system MUST
use distinct label namespaces and tracking mechanisms. Cross-contaminating labels causes
one system's automation to accidentally trigger another system's dispatch pipeline.

## The Core Problem

If System A uses labels like `dispatch`, `agent:backend`, `agent:frontend` to trigger
its workers, and System B accidentally applies those same labels to issues it files, then
System A's workers pick up work they were never assigned. Result: duplicate work, billing
surprises, scope violations, and wasted tokens.

## Label Namespace Rule

Each agent system owns a distinct label prefix. When creating issues or PRs:

- Apply ONLY your own system's labels
- NEVER apply labels that belong to another system's dispatch namespace
- Read the shared registry (`agent-systems.md` or equivalent) to know what other systems' label prefixes are
- When a needed label does not exist and creating it risks namespace confusion, use a
  plain-text `[SYSTEM-NAME]` prefix in the issue title instead of creating the label

## Issue Creation Policy

Prefer file-based tracking and pull requests over GitHub issues where possible.

**Primary tracking surfaces (prefer these):**
- Task files within the repo (e.g., `.HUB/Hub.md`, `TASKS.md`)
- Per-session state files
- Pull requests (the work product itself is the tracking artifact)

**GitHub issues: only when no PR alternative exists.**
When an issue must be opened, use only your own system's label prefix or standard
GitHub labels (`bug`, `enhancement`, `documentation`, `question`).

## PR-Not-Issue Preference

An agent system's primary work product is a pull request, not an issue.

Open PRs for: code changes, config edits, doc updates, workflow additions.
Open issues only for: things that genuinely cannot be a PR (cross-system dependencies,
decisions needed before any code exists, out-of-scope findings that need routing to
the correct owner).

## Out-of-Scope Findings

When an agent reads a file and notices something wrong OUTSIDE its write domain:

1. Do NOT commit a change to that file
2. File a scoped escalation issue using your own system's label prefix
3. Document what was observed: file, line, what looks wrong, recommended action
4. Continue own work -- do not block on the escalation resolving

## Watcher Audit

Each system that uses event-driven dispatch (e.g., GitHub Actions that watch for labels)
MUST periodically audit which repositories that watcher monitors. If the watcher's repo
list overlaps with another system's allowlist, the overlap is a configuration error.

Audit cadence: quarterly or whenever your system's repo scope changes.

## What Violates This Rule

- Applying another system's dispatch trigger label to any issue, for any reason
- Creating an issue with another system's agent-role labels (even if the intent is informational)
- Using another system's label conventions when the namespace hasn't been registered
- Commenting on another system's issues in a way that could trigger label automation
- Not registering your system's label prefix in the shared registry before going live
