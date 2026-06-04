---
type: pattern
purpose: Any agent or engineer authoring a finding, audit result, issue, or RCA document MUST apply this pattern before committing the file -- firing at the moment a finding doc is created -- because omitting the machine-readable frontmatter or rollup registration means the finding is invisible to scanners, never reaches a tracked remediation queue, and is silently dropped: the defect or risk persists while the team believes it is being managed.
read_when: Before committing any finding, audit result, RCA, or issue document to ensure machine-readable frontmatter and Hub.md rollup registration are present.
tags: [findings, remediation, audit-tracking, code-quality, hub-rollup, scanner]
scope: public
community_reviewed: 2026-06-02
name: finding-to-remediation
status: canonical
finding_tracker: ignore
owner: org/architect
consumers: org/architect/managers/engineering-lead/CHARTER.md, org/architect/managers/qa-lead/CHARTER.md, org/security/CHARTER.md, playbooks/finding-tracker/SPEC-finding-tracker.md
last_reviewed: 2026-05-14
last_evaluated: 2026-06-03
---

# Finding-to-Remediation

**Summary:** Every finding doc -- audit, RCA, code-quality issue, security review, design review -- must carry frontmatter declaring its severity, status, owner, target close date, and code paths, AND must appear on the repo's `.HUB/Hub.md` OPEN FINDINGS rollup until closed. A documented finding without a tracked remediation row is a process leak; the scanner blocks commits that create them.

---

## Why This Pattern Exists

A common failure mode in codebases: a reviewer or agent documents a real problem, but the file uses freeform prose for severity, status, and scheduling ("scheduled for backlog", "medium priority", "can be done anytime"). No machine-readable schema means no scanner can find it. No rollup row means no human will scan past it. The file ages until someone notices, by which point ownership is ambiguous and context has decayed.

A scan of a mature API repository surfaced more than two dozen similar orphan docs scattered across the repo root and `.HUB/`: security audits, code quality issues, architectural review notes, and urgent query analyses. None of them appeared on `Hub.md`'s OPEN TASKS section. `Hub.md` was structured for feature work, not findings. Findings lived nowhere except the files that documented them, and the files had no machine-readable indication of severity, status, owner, or target close date.

The pattern across these incidents is identical to the one `living-plan-currency.md` exists to prevent, but applied to a different artifact:

- A reviewer or agent identifies a real problem
- The reviewer documents the problem in a new file (good)
- The file uses freeform prose for severity, status, scheduling
- No machine-readable schema means no scanner can find it
- No rollup row means no human will scan past it
- The file ages until someone notices, by which point ownership is ambiguous and context has decayed

Reviewer attention is insufficient. The same way `living-plan-currency` solved plan-staleness with a scanner, `finding-to-remediation` solves finding-orphaning with a scanner.

---

## The Rule

**When a finding doc is created or modified in a repo with this pattern enabled, the doc MUST have valid frontmatter AND, if `status: open` or `status: in-progress`, MUST appear as a row in that repo's `.HUB/Hub.md` OPEN FINDINGS section. The scanner blocks commits or PRs that violate either condition.**

A "finding doc" is any markdown file whose path matches one of these glob patterns:

```
*ISSUE*.md, **/*ISSUE*.md
*FINDING*.md, **/*FINDING*.md
*AUDIT*.md, **/*AUDIT*.md
*REVIEW*.md, **/*REVIEW*.md
*RCA*.md, **/*RCA*.md
*ADR*.md, **/*ADR*.md
*INCIDENT*.md, **/*INCIDENT*.md
```

(Case-insensitive match. ADR is included because Architecture Decision Records often contain unresolved findings.)

A file is opted out of the pattern by adding `finding_tracker: ignore` to its frontmatter. This is the only way to exempt a file -- there is no filename-based opt-out, because the filename is what triggers the match.

---

## Frontmatter Schema (Canonical)

```yaml
---
finding_tracker: enabled         # or: ignore (to opt out)
finding_id: <repo>-<YYYYMMDD>-<slug>   # e.g., my-api-20260413-password-duplication
severity: critical | high | medium | low
status: open | in-progress | closed | wont-fix | duplicate
discovered: 2026-04-13           # ISO 8601 date
target_close: 2026-05-30         # ISO 8601 date; REQUIRED when severity in [critical, high, medium]
owner: <agent-role or human:initials>   # e.g., sys-backend, sys-security, human:JS
code_paths:                      # POSIX path:line list; the code locations the finding refers to
  - "routes/leads/capture.js:25-35"
  - "routes/webhooks/stripe.js:317-327"
tracking:                        # at least one of: hub-row, gh-issue
  hub_row: .HUB/Hub.md#finding-<finding_id>
  gh_issue: 542                  # optional; the GitHub issue number if one was filed
closed_by: PR-NNN                # REQUIRED when status in [closed, wont-fix, duplicate]
closed_date: 2026-05-30          # REQUIRED when status in [closed, wont-fix, duplicate]
---
```

### Field semantics

| Field | Required when | Notes |
|---|---|---|
| `finding_tracker` | Always | `enabled` (default) or `ignore` (opt out). |
| `finding_id` | `finding_tracker: enabled` | Stable identifier. `<repo>-<YYYYMMDD>-<kebab-slug>`. Must match the anchor in `tracking.hub_row` if present. |
| `severity` | `finding_tracker: enabled` | Drives prioritization. `low` is the only severity that may omit `target_close`. |
| `status` | `finding_tracker: enabled` | State machine; see Status Enum Semantics below. |
| `discovered` | `finding_tracker: enabled` | When the finding was first documented. Immutable after creation. |
| `target_close` | severity in [critical, high, medium] | Latest acceptable close date. Past dates with `status: open` flag the finding as stale. |
| `owner` | `finding_tracker: enabled` | Single owner -- agent role id or `human:<initials>`. No "TBD". |
| `code_paths` | `finding_tracker: enabled` | At least one entry. `path:line` or `path:line-range`. Empty list is invalid. |
| `tracking` | `status` in [open, in-progress] | Must have `hub_row` OR `gh_issue` (or both). Both empty means orphaned. |
| `closed_by` | `status` in [closed, wont-fix, duplicate] | PR number, commit SHA, or external reference. |
| `closed_date` | `status` in [closed, wont-fix, duplicate] | ISO 8601 date. |

---

## Status Enum Semantics

| Status | Meaning | Hub.md row | Scanner behavior |
|---|---|---|---|
| `open` | Finding identified, no work started | REQUIRED | Validate frontmatter completeness + Hub.md row exists |
| `in-progress` | Remediation underway | REQUIRED | Same as `open` |
| `closed` | Remediation shipped, verified | OPTIONAL (may be removed from Hub.md) | Validate `closed_by` + `closed_date` present |
| `wont-fix` | Closed without remediation; reason documented in body | OPTIONAL | Same as `closed`, plus body must contain `## Decision` section explaining why |
| `duplicate` | Superseded by another finding | OPTIONAL | `closed_by` must reference the canonical `finding_id` |

A finding transitions `open` -> `in-progress` when work starts (PR opened with `Closes finding-id` in body), `in-progress` -> `closed` when the closing PR merges. The scanner does not automate the transition; humans or agents update the frontmatter as part of the work.

---

## Hub.md OPEN FINDINGS Section (Canonical Format)

Every repo with this pattern enabled MUST have an `## OPEN FINDINGS` section in `.HUB/Hub.md`. The section sits between `## CLAIMED -- IN PROGRESS` and `## OPEN TASKS FOR AGENTS`. It is owned by the scanner, but humans/agents may hand-edit between scans.

### Format

```markdown
## OPEN FINDINGS

Findings discovered by audits, code reviews, RCAs, or scanners. Closed findings are removed
from this table (the source doc remains; query by `finding_id`).

| finding_id | severity | file | discovered | target_close | owner | status |
|---|---|---|---|---|---|---|
| my-api-20260413-password-duplication | medium | CODE_QUALITY_ISSUE_PASSWORD_DUPLICATION.md | 2026-04-13 | 2026-05-30 | sys-backend | open |
| my-api-20260415-security-contract | high | .HUB/ADR-2026-04-15-Security-Contract-Audit.md | 2026-04-15 | 2026-04-30 | sys-security | in-progress |
```

### Anchor convention

Each row's `finding_id` cell is wrapped in an HTML anchor:

```markdown
| <a id="finding-my-api-20260413-password-duplication"></a>my-api-20260413-password-duplication | medium | ... |
```

This is what `tracking.hub_row: .HUB/Hub.md#finding-<id>` in the finding doc resolves to.

### Sort order

The scanner maintains the table sorted by: `severity` (critical -> high -> medium -> low), then `target_close` (ascending; null last), then `discovered` (ascending). Hand-edits are preserved across re-sorts as long as the row data matches the source doc.

---

## Tracking Contract

A finding is "tracked" when at least one of these is true:

1. **Hub.md row exists**: `.HUB/Hub.md` contains a row whose `finding_id` cell matches the doc's frontmatter `finding_id`.
2. **GitHub issue exists**: a GH issue exists in the same repo with `Finding-ID: <finding_id>` in its body, and the issue is open (or the finding doc's `status` matches the issue's state).

Both surfaces are valid; many findings will have both. The scanner accepts either.

### What "tracked" does NOT mean

- "I mentioned the finding in a team chat message"
- "It's on someone's mental list"
- "The PR description says we'll fix it later"
- "There's a TODO comment in the code"

None of these are durable, machine-queryable surfaces. The scanner ignores them.

---

## Stale-Finding Detection

The scanner flags as STALE any finding where:

- `status` in [`open`, `in-progress`]
- `target_close` is set AND is in the past

Stale findings are not a commit-blocker by default (they are not regressions; they are accumulated debt). They are emitted as `WARN` in the scanner output and surfaced on the `Hub.md` OPEN FINDINGS table with a `(STALE)` suffix on the `target_close` cell. A weekly digest agent (see `playbooks/finding-tracker/SPEC-finding-tracker.md`) summarizes stale findings for the team.

Repos may opt into strict mode (stale = FAIL) via `findingTracker.strictStale: true` in the product manifest.

---

## Override Semantics

The artifact scanner has no silent override. Filename-matched non-finding artifacts must opt out explicitly with `finding_tracker: ignore`.

Downstream repo CI wrappers may add a maintainer-approved override label for bootstrap or retroactive sweep PRs, but the override must be visible in the PR audit trail and must not change the canonical frontmatter contract.

---

## Enforcement Implementations (Non-Exhaustive)

The frontmatter schema is the contract. Any tool that reads it correctly is a valid enforcement implementation.

**Framework artifact scanner:** `scripts/rebuild-manifest.py --validate-findings --check`. This is the canonical enforcement path because it already scans every in-scope artifact and reads YAML frontmatter through the same code path that generates `INDEX.md`.

**GitHub Actions workflow (per-repo):** downstream repos may call the pinned scanner, or a thin adapter generated from it, to post PR comments and set required check status. They must not fork a second schema.

**Weekly digest agent:** A scheduled agent that scans every repo with the pattern enabled, aggregates open findings + stale findings, and posts a summary to the team. Same schema, read-only.

**Retroactive sweep tool:** `playbooks/finding-tracker/tools/sweep-orphan-findings.mjs`. One-time-per-repo: walks the repo, finds finding-pattern-matched files that lack frontmatter, generates a triage stub for each, and produces a draft `Hub.md` OPEN FINDINGS section. Output is reviewed by a human/agent before commit.

All implementations share the same frontmatter schema. A finding authored correctly once works across all enforcement surfaces without modification.

---

## Interaction With Existing Patterns

| Pattern | Relationship |
|---|---|
| `living-plan-currency` | Sibling pattern. Living plans govern code paths; findings govern problems. Both use frontmatter + scanner + Hub.md rollup. A finding can reference a living plan in its body when the remediation requires plan-level coordination. |
| `validation-gates` | finding-tracker scanner is a Layer-2 (Manager-level) gate. Engineering Lead validates frontmatter; QA Lead validates Hub.md sync. |
| `agent-communication-protocol` | When a sub-agent identifies a problem outside its write domain, it emits a SCOPE-ESCALATION finding doc per this schema rather than free-text. |
| `agent-scope-guardrail` | SCOPE-ESCALATION issues authored by agents follow this schema. The `owner` field receives the correct agent role. |
| `proactive-quality` | Agents must proactively flag issues. This pattern defines HOW the flag gets durably tracked. |
| `pending-wiring-todos-are-alarms` | TODO comments in code are alarms. This pattern is the durable surface those alarms get promoted to when they require remediation tracking. |

---

## Cross-System Applicability

This pattern is repo-agnostic and agent-system-agnostic. Any agent role that produces audit docs, code reviews, RCAs, or architectural reviews must conform to this schema. The scanner is the mechanical backstop; this pattern is the human discipline it enforces.

Roles that commonly produce finding docs: engineering leads, QA leads, security reviewers, on-call incident handlers, and automated audit agents. The schema is the same regardless of who authors the finding.

---

## Retroactive Sweep (Per-Repo, One-Time)

When the pattern is first enabled in a repo, existing finding-pattern-matched files must be triaged. The sweep tool (`playbooks/finding-tracker/tools/sweep-orphan-findings.mjs`) automates the discovery and stub generation; humans/agents make the close-or-keep-open decision per file.

### Sweep procedure

1. Run sweep tool: produces a triage CSV with one row per orphan file (filename, last-modified date, first-line-of-body summary, suggested severity).
2. For each row, decide:
   - **Keep open** -- fill out frontmatter, add to Hub.md
   - **Close as resolved** -- the problem was fixed without updating the doc; add frontmatter with `status: closed` and `closed_by: <best-guess PR or "retro-sweep">`
   - **Close as wont-fix** -- the problem is not worth fixing; add frontmatter + `## Decision` section
   - **Close as duplicate** -- another finding covers this; link via `closed_by: <canonical-finding-id>`
   - **Delete** -- the doc is irrelevant / stale / superseded; archive per the project's file-versioning convention (move to `.archive/`)
3. Commit the sweep as a single PR. If the consuming repo's CI wrapper supports a maintainer override, use it only for bootstrap; the pattern itself requires explicit `finding_tracker: ignore` for non-finding false positives.
4. After merge, the scanner is enforced on all future changes.

A typical repo sweep is 1-3 hours per 25 orphan docs.

---

## Cross-References

- `playbooks/finding-tracker/SPEC-finding-tracker.md` -- build specification for the scanner implementation
- `scripts/rebuild-manifest.py` -- canonical artifact scanner and finding metadata validator
- `_patterns/living-plan-currency.md` -- sibling pattern; same frontmatter+scanner+rollup approach for living plans
- `_patterns/validation-gates.md` -- the 4-layer gate chain this pattern integrates into (finding-tracker is a Manager-level gate)
- `_patterns/agent-communication-protocol.md` -- SCOPE-ESCALATION findings authored by agents conform to this schema
- `rules/proactive-quality.md` -- the human discipline this pattern mechanically enforces
- `rules/pending-wiring-todos-are-alarms.md` -- TODO comments are alarms; findings are the durable surface alarms get promoted to
