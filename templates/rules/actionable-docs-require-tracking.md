---
type: rule
purpose: Binding authoring-time rule for reports, triage docs, audits, plans, and other markdown artifacts that contain actionable follow-up; requires same-change todo/tracker linkage so work is not lost.
read_when: Before committing or opening a PR for any markdown artifact that contains future work, open recommendations, remediation steps, or next steps.
tags: [documentation, todo, tracker, governance, follow-up]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---

# Actionable Docs Require Tracking

Actionable documentation must create its tracking surface at authoring time.
Discovery trackers and sweeps are failsafes, not the primary workflow.

## Rule

When creating or modifying a markdown artifact that contains future work, open
recommendations, remediation steps, unresolved decisions, batch queues, owner
questions, or next steps, the same change must do one of the following:

1. Add or update a live todo/tracker row with status, owner, next action, and PR
   or issue linkage, then backlink from the source doc to that tracker.
2. Make the source doc itself a live tracker with status, owner, next action, and
   PR or issue linkage for each actionable row.
3. State `No follow-up actions` when the artifact is purely archival,
   informational, or reference material.

Do this before commit and before PR creation. A PR that introduces actionable
follow-up only as prose is incomplete even if a later sweep might discover it.

## Applies To

- Reports, triage docs, audits, RCAs, retrospectives, design reviews, and scan
  outputs
- Project plans with open work or batch queues
- Research or inventory docs that recommend implementation work
- Charter, rule, pattern, or governance updates that introduce migration work

## Acceptable Tracking Surfaces

- The repo's active `.hub/` priority plan or todo list
- A project tracker under `projects/` whose purpose and tags identify it as live
  work tracking
- A GitHub issue or PR that is linked from the doc and contains enough context to
  execute the work
- A `.HUB/Hub.md` OPEN FINDINGS row for repos using the finding tracker pattern

The tracker entry must survive context loss: status, owner, and next action are
required. `TBD`, "later", and "follow-up needed" without an owner/status are not
tracking.

## Relationship To Finding Tracker

`_patterns/finding-to-remediation.md` governs finding-style artifacts and the
scanner that validates their metadata. This rule is broader: it applies to any
documentation that creates work, even when the file is not a finding doc.

The finding tracker, broken-ref triage, and future scanners are failsafes. They
catch process leaks after the fact. Authors and reviewers still own real-time
tracking in the same change that creates the work.

## PR Review Gate

Reviewers must reject a PR when:

- A changed doc has sections such as `Open follow-ups`, `Next steps`,
  `Recommendations`, `Todo`, `Manual follow-ups`, or batch queues, but no live
  tracker backlink.
- A changed doc says work is "logged", "scheduled", "candidate", "deferred", or
  "pending" without a durable tracker row or issue link.
- A report contains actionable findings but is not itself structured as a live
  tracker.

If there are no follow-up actions, the doc should say `No follow-up actions` so
the absence of a tracker is intentional and reviewable.
