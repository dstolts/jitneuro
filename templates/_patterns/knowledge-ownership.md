---
type: pattern
purpose: Any agent or contributor authoring a new framework artifact or retiring a role MUST declare ownership using this schema before committing -- firing at the moment of file creation and again at the quarterly audit -- because omitting the owner field means the artifact has no accountable maintainer: it drifts, goes stale, and is treated as canonical even after it contradicts current operating practice.
read_when: Before committing any new framework artifact to ensure ownership frontmatter is declared and the artifact will be maintained.
tags: [knowledge-management, ownership, audit, role-retirement, artifact-governance]
scope: public
departments: [all]
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Knowledge Ownership

**Used by:** Knowledge auditor role (audits), all roles that author framework artifacts.
**Purpose:** Every artifact in the framework knowledge base has a declared owner role. Ownerless
artifacts decay, drift, and become unreliable. This pattern prevents decay.

---

## Frontmatter Requirement

Every Markdown file in the framework knowledge base MUST include
this frontmatter block:

```yaml
---
owner: <role-name>
owner_type: <executive|manager|specialist|skill>
last_reviewed: <YYYY-MM-DD>
review_cadence: <monthly|quarterly|on-change>
status: <active|sunset|archived>
---
```

Files missing this frontmatter are flagged in the quarterly audit as
"unowned" and routed to the most likely owner role for adoption or deletion.

---

## Ownership Responsibilities

The `owner` role is responsible for:

1. **Accuracy:** Content reflects current org state and policy.
2. **Staleness detection:** If the artifact references a retired role, deprecated
   tool, or superseded process, the owner updates or retires the file.
3. **Review cadence:** Owner reviews the file on the declared `review_cadence`.
   On review: update `last_reviewed` date and confirm or revise content.
4. **Promotion criteria:** If a pattern or playbook qualifies for promotion to
   the global rules layer, the owner files the proposal per
   `governance/PROMOTION-CRITERIA.md`.

---

## Quarterly Audit

The knowledge auditor role runs the audit in Q-end week 1:

1. Glob all `.md` files under the framework knowledge base root.
2. Flag files where:
   - Frontmatter is missing.
   - `last_reviewed` is older than `review_cadence` allows (e.g., monthly file
     not reviewed in > 45 days).
   - `owner` role is in `org/archived-roles/` (retired role still listed as owner).
   - `status` is `active` but the role or process it documents no longer exists.
3. File one [KNOWLEDGE-AUDIT] issue per flagged file, assigned to the listed owner
   or to the org lead if the owner is retired.
4. Owner has 2 weeks to resolve: update, transfer ownership, or archive.
5. Unresolved after 2 weeks: knowledge auditor archives the file (moves to `.archive/`).

---

## Ownership Transfer Protocol

When a role is retired (per `_patterns/role-retirement.md`) or a new role is created
to absorb an existing role's scope:

1. Org lead provides the list of framework files owned by the retiring role.
2. Inheriting role reviews each file:
   - Adopt: update `owner` frontmatter + `last_reviewed`.
   - Archive: move to `.archive/` + update `status: archived`.
   - Delete: only if content is fully superseded (requires knowledge auditor sign-off).
3. Transfer must complete within the coexistence period (1-2 sprints).

---

## Promotion Criteria (Summary)

A framework pattern is eligible for promotion to the global rules layer when:

- It has been active for >= 2 quarters with no material revisions.
- It applies across all org roles (not function-specific).
- Knowledge auditor has confirmed no compliance concerns.
- Framework owner approves the promotion (patterns in global rules affect all sessions).

Full criteria: `governance/PROMOTION-CRITERIA.md`.

---

## Anti-Patterns

- Creating a pattern file without a frontmatter owner block.
- Declaring `owner: TBD` as permanent state (TBD is acceptable for < 1 sprint; after that, assign or archive).
- Owner role retired without transferring their framework artifacts.
- Using the global rules layer path for org-specific content (wrong layer).

---

## Cross-References

- `_patterns/role-retirement.md` -- retirement triggers knowledge transfer
- `rules/file-versioning.md` -- version control discipline for framework files
- `governance/PROMOTION-CRITERIA.md` -- promotion from pattern to global rule
