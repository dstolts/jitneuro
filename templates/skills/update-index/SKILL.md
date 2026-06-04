---
type: skill
name: update-index
description: Refresh INDEX.md from current jit-knowledge filesystem state. Trigger phrases include "update the index", "refresh INDEX.md", "update jit-knowledge index", "rebuild manifest", "audit INDEX". Use after adding, renaming, archiving (.zArchive), or removing any artifact in jit-knowledge so the manifest stays canonical.
purpose: BINDING INDEX.md refresh skill -- runs rebuild-index.py + rebuild-manifest.py to bring the auto-managed regions (engram routing + artifact manifest) back in sync with filesystem state, then opens a PR for Owner review. MUST be invoked whenever the artifact set changes, regardless of actor -- AI adds/renames/removes a file, AI versions a file (copy file-01.md to file-02.md AND archive file-01.md per file-versioning rule -- both state changes refresh-trigger), Owner manually archives via .zArchive convention or moves files in the filesystem, a charter/spec is bumped to a new revision, or CI's `rebuild-manifest.py --check` reports drift. Skipping means INDEX.md drifts from filesystem reality and downstream AI agents route on stale paths, miss newly-added artifacts entirely, or load files that have been archived/superseded.
tags: [skill, index, manifest, update-index, jit-knowledge, dispatch-rule, post-write, file-versioning, archive, user-action-trigger]
scope: public
owner_role: cos
read_when: After adding, renaming, archiving, or removing any artifact in jit-knowledge, or when CI reports INDEX.md drift.
last_evaluated: 2026-06-03
---

# Update INDEX (Refresh the Capability Manifest)

INDEX.md has two auto-managed regions and a few hand-curated regions. This skill refreshes the auto-managed regions from current filesystem state and surfaces anything in the hand-curated regions that needs Owner attention.

## What's auto-managed vs hand-curated

| Region | Marker block | Tool | Frequency |
|---|---|---|---|
| Routing Index -- Engrams (auto-synced) | `<!-- ROUTING-INDEX-AUTO-START / END -->` | `scripts/rebuild-index.py` | every 6h via `.github/workflows/refresh-index.yml` + repository_dispatch |
| Artifact Manifest (every shipped artifact) | `<!-- ARTIFACT-MANIFEST-AUTO-START / END -->` | `scripts/rebuild-manifest.py` | on demand via this skill + CI `--check` gate |
| Routing Index -- Engrams (workspace-pending) | (no markers) | hand-curated | reviewed quarterly |
| Routing Index -- Bundles (workspace-pending + cross-cutting) | (no markers) | hand-curated | reviewed quarterly |
| Routing Index -- Rules / Cross-cutting canonical pointers | (no markers) | hand-curated | reviewed quarterly |
| Artifact Manifest sub-section labels (`## sync`, `## governance`, etc.) | -- | derived from path category by rebuild-manifest.py | per-run |

## When to use

- After adding a new skill, charter, pattern, playbook, workflow, reference, or governance doc
- After archiving a file with the `.zArchive` convention (rename `Foo.md` -> `Foo.md.zArchive`)
- After renaming or moving any artifact (the manifest paths must follow)
- After bumping a charter / spec to a new revision (the auto-extracted purpose may change)
- Before tagging a new version of jit-knowledge (PIN-POLICY requires a clean manifest)
- When CI surfaces "Artifact Manifest is out of date" via `rebuild-manifest.py --check`

## Procedure

### 1. Verify the AUTO markers exist

The Artifact Manifest region in INDEX.md must be bracketed by:

```
<!-- ARTIFACT-MANIFEST-AUTO-START -->
... auto-generated content ...
<!-- ARTIFACT-MANIFEST-AUTO-END -->
```

If absent, add the marker pair at the location where the manifest should live (today, replace the existing hand-curated `## top-level` ... `## projects` block). Run the script -- it now owns that range.

### 2. Refresh the engram routing region (auto-managed)

```
python scripts/rebuild-index.py
```

Requires `gh` CLI authenticated + a GitHub token (`GH_TOKEN`) with read on subscribed repos. If the local clone has the env var, the script regenerates between `<!-- ROUTING-INDEX-AUTO-START -->` markers. If env is absent, the script logs WARN and proceeds (engram rows show `status: missing` rather than the live URL).

### 3. Refresh the artifact manifest region

```
python scripts/rebuild-manifest.py
```

Walks every artifact directory (governance, horizon, workflows, playbooks, org, _patterns, agents, references, projects, rules, cognition, templates, skills, scripts), categorizes by directory, extracts type / tags / purpose / scope from frontmatter or H1 inference, replaces content between `<!-- ARTIFACT-MANIFEST-AUTO-START / END -->`. Excludes `.zArchive` files (archive convention), `node_modules`, `.git`, `.github`, `__fixtures__`, lockfiles.

CI mode (gate the branch on a clean manifest):

```
python scripts/rebuild-manifest.py --check
```

Exits non-zero if INDEX.md does NOT match what the script would generate. Wire into a GitHub workflow on every PR.

Dry-run mode (preview without writing):

```
python scripts/rebuild-manifest.py --dry-run
```

### 4. Review the diff

```
git diff INDEX.md
```

Expected diffs:
- New artifacts: rows added under their category
- Renamed/moved artifacts: rows moved or their path field changes
- Newly archived (`.zArchive`): rows REMOVED from the manifest
- Bumped frontmatter `description` or H1: purpose field changes

Unexpected diffs (audit before commit):
- A category section disappears entirely (script may have an exclusion bug)
- The "Last refreshed" timestamp jumps without other changes (may indicate clock skew in CI)
- A row appears with type `doc` when it should be a richer type (the artifact's frontmatter is missing `metadata.type` -- consider adding it)

### 5. Commit and PR

INDEX.md changes are PR-gated per `governance/PR-CHECKLIST.md`. Open a PR with the manifest diff plus any artifact additions / archives that motivated this refresh. Title format: `chore(index): refresh manifest after <reason>`.

## QA Gates

Reject or revise the output if any of these are true:

- The skill edited INDEX.md WITHOUT going through `rebuild-manifest.py` (manual edits inside AUTO markers will be overwritten on next refresh)
- The skill regenerated Artifact Manifest entries from a SUBSET of artifacts (the script must walk the full canonical directory list, not a "what changed" delta)
- The skill silently changed entries in the hand-curated Routing Index regions (engram workspace-pending, bundles workspace-pending / cross-cutting, rules pointer table) -- those are owned by Owner; surface proposed changes for review, do not edit
- The skill failed to honor the `.zArchive` convention (an archived file's row stayed in the manifest)
- The skill added `node_modules` paths or test fixtures to the manifest (filter / exclusion bug)
- The skill ran rebuild-index.py without `gh` auth and committed `status: missing` rows for engrams that DO exist (the missing-row state should be transient diagnostic, not a permanent regression)

## Required Tooling

- Python 3.11+ with PyYAML (`pip install pyyaml`)
- `gh` CLI authenticated to the GitHub org (for the engram routing refresh only -- artifact manifest needs no network)
- A local jit-knowledge clone with the AUTO markers present in INDEX.md

## After This Skill Completes

INDEX.md is up to date. The Routing Index auto region reflects subscribed repos' current engrams; the Artifact Manifest auto region reflects the local filesystem. Hand-curated regions (workspace-pending tables, bundle pointers, rules pointer table) are unchanged unless Owner explicitly approved a follow-up edit.

The manifest's `Last refreshed:` line at the top of INDEX.md is updated by the rebuild-index.py routing refresh; the artifact manifest doesn't need a separate timestamp because the entries themselves describe the live state.

## Related

- `scripts/rebuild-index.py` -- engram Routing Index refresh (network-bound; runs in CI)
- `scripts/rebuild-manifest.py` -- Artifact Manifest refresh (filesystem-bound; runs locally + CI)
- `.github/workflows/refresh-index.yml` -- 6-hourly + dispatch trigger for engram refresh
- `governance/PIN-POLICY.md` -- pin policy requires a clean manifest before tagging
- `governance/PROMOTION-CRITERIA.md` -- artifact intake criteria; new artifacts must show up in the next manifest refresh
- `skills/install/SKILL.md` -- one-shot install of jit-knowledge on a new consuming machine
