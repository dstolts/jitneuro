---
type: rule
purpose: Require agent systems to maintain disjoint repo allowlists and explicitly assign single-system ownership so that conflicting commits and duplicate work are structurally impossible.
read_when: When adding a repo to any agent system's scope or when two agent systems are active in the same repository -- overlapping allowlists cause conflicting commits and trust-zone enforcement failures.
tags: [multi-agent, repo-ownership, coordination, allowlist, collision-prevention]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Multi-Agent Repo Coordination

When more than one agent system could write to the same repos, ownership must be explicit.
Implicit shared access causes conflicting commits, duplicate work, and broken trust-zone
enforcement. This rule codifies how repo ownership is assigned to agent systems and what
to do if overlap is ever unavoidable.

## The Default: Disjoint Repo Sets (PREFERRED SHAPE)

Each agent system maintains an explicit allowlist of repos it owns. Outside that list the
system is hands-off -- no issues filed, no branches pushed, no PRs opened.

- The deploying organization is responsible for maintaining allowlists at the system-config
  level. See "Allowlist locations" below for where each system declares its list.
- When a repo enters scope for one system, it is REMOVED from every other system's allowlist
  in the same change. Two systems on the same repo is never the default; it requires a
  deliberate temporary exception (see Fallback below).
- No coordination protocol is needed when allowlists are disjoint. Disjoint sets eliminate
  the entire class of conflict by design.

## The Fallback: Coordination Protocol (overlap that is genuinely unavoidable)

Use ONLY when a concrete reason forces two systems onto the same repo -- for example, a
migration window where one system hands a repo off to another over several days, or an
authorized cross-team sprint. This is not a permanent configuration.

Branch-prefix convention (prevents silent stomping):
- Each system registers a unique 2-letter or short prefix (e.g., `sys-a/*`, `sys-b/*`, `human/*`)
- Document the prefix registry in a shared file (see "Allowlist locations" below)

Conflict-detection requirement: BEFORE starting work on any overlapping repo, check for open
issues and open PRs from sibling systems touching the same files. If scope overlaps, PAUSE
and surface the conflict to Owner at the next opportunity. Do not guess or proceed.

Production-branch ownership: main and staging branches must have exactly ONE agent system
authorized to merge. Others open PRs only. Document the merge-owner per repo when invoking
the fallback.

Escalation: any unresolved overlap is a blocker. Surface it; do not work around it.

## What This Rule Does NOT Replace

- Agent write-domain enforcement WITHIN a single system (which agent role may commit to
  which files). That rule is intra-system; this rule is inter-system.
- The responsibility of each system to dispatch code work through its own pipeline rather
  than writing directly.
- Trust-zone push-to-main protection applies regardless of which agent system is acting.
  All systems respect it.

## What Violates This Rule

- Adding a repo to one system's allowlist without removing it from another's in the same change.
- Two systems both treating a repo as "ours" without an explicit single-owner allowlist entry.
- Using the coordination protocol as a permanent design instead of fixing the allowlists.
  The fallback is temporary. If it persists more than one sprint, reassign ownership.
- A system that has not declared its allowlist at all. Every active agent system MUST
  publish one. An undeclared system is in violation from the moment it first pushes to any repo.

## Allowlist Locations

Each active agent system MUST declare its allowlist. The location and format are
system-specific; what matters is that the list is discoverable, versioned, and maintained.

Common patterns:
- A `SCOPE.md` file in the system's primary repository listing Tier 1 / Tier 2 / Out-of-scope repos
- A routing config file that maps repos to dispatch labels or agent roles
- A shared `agent-systems.md` registry file documenting system name, allowlist location,
  branch prefix, and merge-owner policy for each active system

If a shared registry file does not exist, creating it is the FIRST task before any new
system is permitted to push to any repo.
