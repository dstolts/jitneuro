# User Story: Complete Dan->Owner Scrub (Remaining Files)

**Created:** 2026-03-27
**Priority:** 95/100 (do FIRST, before any sprint work)
**Status:** Ready for execution
**Handoff:** Agent-ready

## Desired State

Every file in the jitneuro repo and the DOE Framework Spec uses "Owner" instead of "Dan" for person references. The repo is fully open-source clean. No personal names leak into published content.

## User Value

Open-source credibility. A repo with "Dan" scattered through it looks like a personal tool, not a framework. Clean generic references signal professional, reusable software.

## Objectives

1. Scrub DOE Framework Spec (`D:\Code\Automation\Projects\Orchestration\DOE-Framework-Spec-04.md`)
2. Scrub any NEW jitneuro files added since the v0.4.0 scrub (PRDs, new docs)
3. Verify all previously scrubbed files are still clean

## Context

### Already scrubbed (v0.4.0, PR #20):
- jitneuro repo docs (comparison-openclaw, feedback-classification, HANDOFF)
- Workspace CLAUDE.md, backup commands, bundles (64 replacements across 19 files)

### Not yet scrubbed:
- `D:\Code\Automation\Projects\Orchestration\DOE-Framework-Spec-04.md` -- the DOE framework spec, referenced by many repos
- `D:\Code\jitneuro\PRDs\*.md` -- 7 PRD files created this session (should be clean but verify)
- Any jitneuro template files that may have been missed

### Exceptions (keep "Dan" as-is):
- `LICENSE` -- copyright attribution is standard
- `README.md` author line -- standard open-source practice
- References to "Dan Martell" (different person, author credit)
- YouTube channel names (`@DanStolts-JitAI`) -- external system identifiers
- Meta-references in rules about the scrub itself (e.g., "never use Dan in jitneuro")

## Acceptance Criteria

- [ ] DOE-Framework-Spec-04.md has zero "Dan" person references (use "Owner")
- [ ] All jitneuro PRDs have zero "Dan" person references
- [ ] `grep -r "\bDan\b" D:\Code\jitneuro\` returns only exceptions listed above
- [ ] Changes committed on a feature branch, PR created, merged before sprint work begins

## Test Plan

1. `grep -rn "\bDan\b" D:\Code\jitneuro\` -- only exceptions remain
2. `grep -n "\bDan\b" D:\Code\Automation\Projects\Orchestration\DOE-Framework-Spec-04.md` -- zero results
3. Review each change to confirm "Owner" reads naturally in context
