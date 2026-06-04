---
type: pattern
purpose: Any agent or engineer authoring a PR that modifies paths governed by a living plan MUST update or cite that plan in the same PR -- firing at PR creation time in repos with active plan documents -- because merging code changes without touching the governing plan causes the plan to silently drift from reality, so subsequent agents consulting the plan act on stale guidance and produce work that conflicts with what was actually built.
read_when: Before opening a PR that modifies paths in any repo with active living-plan documents, to verify the governing plan is cited or updated.
tags: [pr-currency, living-plan, code-review, plan-staleness, scanner]
scope: public
community_reviewed: 2026-06-02
name: living-plan-currency
status: canonical
owner: org/architect
consumers: org/architect/managers/engineering-lead/CHARTER.md, org/architect/managers/qa-lead/CHARTER.md, playbooks/gtm-gate/SPEC-living-plan-currency.md
last_reviewed: 2026-05-13
last_evaluated: 2026-06-03
---

# Living Plan Currency

**Summary:** When code touches paths governed by a living plan, the plan must be touched or explicitly cited in the same PR. Plans that go stale while code keeps moving compound into customer-visible bugs.

---

## Why This Pattern Exists

A team launched a new vertical into staging. A deep-link URL failed to render content. Root-cause traced to three independent data-loading implementations in the codebase, each applying its own (or no) normalization to a shared data field. A sync-consolidation plan -- a `.HUB/` document over a thousand lines, authored months earlier -- had tracked this exact problem. PHASE 1 and PHASE 2 of the plan completed in the first months. The remaining phases stalled.

Later, a schema migration added several columnar fields. The author did not consult the stalled plan. The new columns inherited the fragmented sync system instead of being routed through the planned unified contract. Months later, a customer-visible regression surfaced at launch.

The plan existed. The engineering team was not equipped to know they should consult it. Reviewer attention is insufficient -- reviewers do not remember months-old `.HUB/` plans under launch pressure, and the connection between "touched file" and "governing plan" is invisible without tooling.

A mechanical scanner that runs on every PR -- checking whether any touched file is governed by a living plan, and whether that plan was consulted or updated in the same PR -- is the only reliable backstop.

---

## The Rule

**When code touches paths governed by a living plan, the plan must be touched OR explicitly cited in the same PR. Plans declare their own scope via frontmatter.**

"Living plan" means a `.HUB/<name>.md` document that tracks a consolidation, cleanup, refactor, or migration in progress. A plan becomes a living plan by opting in with `scanner: living-plan` frontmatter.

"Governed paths" are glob patterns declared in that frontmatter under `governs_paths`. Any PR whose changed-files set intersects with a plan's governed paths triggers the currency check for that plan.

A plan is "consulted" in a PR when either:
1. The plan file itself appears in the PR's changed-files set (the plan was touched), OR
2. The PR description text contains the plan filename AND an acknowledgement keyword within 200 characters of that mention (case-insensitive: "reviewed", "consulted", "updated", "current").

Plans with `status: completed` are permanently retired and never trigger. Plans with `status: dormant` are stricter: any PR touching their governed paths FAILs immediately (dormant plans must be resurrected to `active` before code in their domain may change).

---

## Frontmatter Schema (Canonical)

```yaml
---
scanner: living-plan
status: active | dormant | completed
last_verified: 2026-05-13          # ISO 8601 date
governs_paths:                     # POSIX glob list, relative to repo root
  - "src/services/teamSyncService.ts"
  - "src/services/database/**"
  - "src/services/repairs/**"
freshness_days: 30                 # WARN threshold; default 30 if omitted
---
```

`governs_paths` uses POSIX-style globs: `**` matches any depth, `*` matches one path segment, `?` matches one character. Implementors MUST use a placeholder-based `globToRegex` approach to avoid the double-star corruption bug where a naive sequential `**/` -> `.*` -> single-`*` replacement mangles already-inserted regex fragments. The pattern: convert `**/` and `**` to placeholder tokens first, then convert single `*`, then restore placeholders to their final regex values. The reference implementation is in `playbooks/gtm-gate/agents/docs-completeness.mjs` (`globToRegex` function).

Paths in `governs_paths` are relative to the repo root. Absolute paths in the changed-files set are normalized to repo-relative before matching.

---

## Status Enum Semantics

| Status | Meaning |
|---|---|
| `active` | Plan is governing. Any PR touching governed paths must satisfy the currency check (touch or cite). |
| `dormant` | Plan is stalled. Any PR touching governed paths FAILs immediately. To proceed, the plan must be resurrected to `active` status in the same PR, or the maintainer override label must be applied. |
| `completed` | Plan is retired. Scanner ignores this plan forever. No future PR will be checked against it. |

A plan transitions `active` -> `dormant` when the engineering team knows the consolidation is paused and wants strict enforcement. It transitions `active` -> `completed` when all tracked work is done. The transitions are deliberate author actions; the scanner does not infer them.

---

## Citation Contract

"PR description contains the plan filename" is satisfied when:
- The literal filename (e.g., `Data-Consolidation-Plan.md`) appears anywhere in the PR body text, including inside code fences or blockquotes.
- Within 200 characters of that filename mention (measured by character offset in the raw text), at least one acknowledgement keyword appears (case-insensitive): `reviewed`, `consulted`, `updated`, `current`.

Example of a valid citation: `"I reviewed Data-Consolidation-Plan.md -- it is current as of 2026-05-13 and this migration does not affect the planned unified contract."`

Example of an invalid citation (keyword too far away): a 500-word paragraph where the filename appears at the start and the nearest acknowledgement keyword is 400 characters later.

The citation mechanism exists for PRs where the plan genuinely does not need updating -- the author has read it and confirmed it is still accurate. It is not a way to skip the plan; it is a way to document "I read it and it is still current."

---

## Override Semantics

A PR labeled `scanner-override` by a maintainer is exempt from blocking. The scanner:
- Still posts its full comment (the override is visible in the audit trail).
- Sets the GitHub check status to PASS.
- Enforces that the label was applied by a maintainer (per the `maintainers` list in the product manifest config); if applied by a non-maintainer, the override is rejected and the PR FAILs.

The override is an escape hatch for bootstrapping (the PR that adds the scanner workflow itself) and extraordinary circumstances. It is not a workaround for skipping plan work. Every override is visible in the PR history.

---

## Enforcement Implementations (Non-Exhaustive)

The frontmatter schema is the contract. Any tool that reads it correctly is a valid enforcement implementation. Current and planned implementations:

**GTM Gate scanner (v1 -- this SPEC):** `playbooks/gtm-gate/agents/living-plan-currency.mjs`. Runs as a GTM Gate sub-agent in the `pre-deploy` stage. Reads changed-files from `git diff` or GitHub Actions context, reads `.HUB/` plans from the PR head commit, emits PASS/WARN/FAIL per plan, aggregates, posts a PR comment. See `playbooks/gtm-gate/SPEC-living-plan-currency.md` for the full build specification.

**Future: GitHub Actions workflow (standalone):** `.github/workflows/pr-scanner-living-plan.yml` per repo. Posts PR comment and sets required check status directly. v1 ships as advisory (comment only); v2 graduates to required check after 2-week advisory period.

**Future: Pre-commit hook:** Local enforcement before push. Same schema, same algorithm, no comment posting.

**Future: IDE plugin:** Highlights governed files when opened, shows which plans govern them.

All implementations share the same frontmatter schema. A plan authored correctly once works across all enforcement surfaces without modification.

---

## Cross-System Applicability

This pattern is designed to be consumed across any agent or human workflow:

- **Engineering Lead role:** Validates plan currency before approving a PR; the currency check is part of the PR review checklist.
- **QA Lead role:** Includes the currency check in acceptance criteria during sprint offboarding. If a plan governing the sprint's touched paths was not updated or cited, the PR does not advance past the review gate.
- **JitNeuro and any agentic PR author:** Any agent authoring a PR in a repo with `.HUB/` plans is responsible for checking plan currency per this pattern. The rule is repo-agnostic; it applies wherever a plan with `scanner: living-plan` frontmatter exists.

Same schema, same discipline, across all systems. The scanner is the mechanical backstop; this pattern is the human discipline it enforces.

---

## Cross-References

- `playbooks/gtm-gate/SPEC-living-plan-currency.md` -- build specification for the GTM Gate scanner implementation
- `_patterns/validation-gates.md` -- the 4-layer gate chain this pattern integrates into (plan currency is a Manager-level gate)
- `_patterns/agent-communication-protocol.md` -- PR pipeline state machine; living-plan-currency check is a CI gate that blocks downstream agent review
- `playbooks/gtm-gate/agents/docs-completeness.mjs` -- reference `globToRegex` implementation
