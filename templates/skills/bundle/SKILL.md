---
type: skill
purpose: Manage context bundles -- load, create, refresh, inspect, and split domain knowledge files.
tags: [bundles, context-management, memory, routing-weights]
scope: public
departments: [all]
status: canonical
graduation_target: skills/bundle/SKILL.md
read_when: When running the /bundle command to load, create, refresh, inspect, or split a context bundle.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /bundle <name>

Manage context bundles. Bundles are domain knowledge files loaded on-demand to provide focused context.

## Operations

### Load: `/bundle <name>`
Read the bundle file from `.knowledge/bundles/<name>.md` (or workspace bundles if not found in repo).
Display its contents to load the context.
Target: bundles stay under 280 lines.

### Create: `/bundle create <name>`
Create a new bundle file at `.knowledge/bundles/<name>.md`.
Template structure:
- What This Covers (2-3 sentences)
- Key Files (table: path | purpose)
- Conventions (bullet list)
- Commands (relevant slash commands)
- Architecture Decisions (ADRs that affect this domain)
- Common Patterns (code snippets)
- Gotchas (known pitfalls)

### Refresh: `/bundle refresh <name>`
Re-read the codebase for the bundle's domain and update stale entries.
Dispatch a subagent to scan relevant files and propose updates.

### Inspect: `/bundle inspect <name>`
Show bundle metadata: line count, last updated, related routing weights.
Flag if over the 280-line warning threshold.

### Split: `/bundle split <name>`
If a bundle exceeds 280 lines, propose splitting into two focused sub-bundles.
Present the proposed split to the user before executing.

## Bundle location resolution

1. `<repo>/.knowledge/bundles/<name>.md` (repo-specific)
2. `<workspace>/.knowledge/bundles/<name>.md` (workspace shared)
3. Fallback: report not found

## Size thresholds

- Under 230 lines: OK
- 230-279 lines: WARN (approaching limit)
- 280+ lines: OVER (recommend split)
