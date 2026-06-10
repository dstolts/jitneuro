# Routing Weights -- DEPRECATED TEMPLATE

This template file is deprecated as of 2026-05-12 (Step 6 Layer B sweep).

The routing-weights.md pattern enacted routing locally. Do not recreate that
legacy local router.

## What to do instead

Do NOT create a routing-weights.md in your repo's `.claude/rules/`. Instead:

1. Install JitNeuro from the `jitneuro` checkout.
2. Keep framework-owned files in the installed `.claude/` surfaces.
3. Keep repo/team-specific context in `.jitneuro/` when needed.
4. If your team maintains an internal/shared catalog, reference that catalog
   separately through your team's resolver or submodule.

For system-specific routing extensions, update the configured shared catalog if
one exists. Otherwise, document repo-local context in `.jitneuro/`; do not
maintain a parallel `routing-weights.md` router.

## Archive

The original routing-weights.md template is preserved at:
  `templates/.archive/rules-routing-weights.md`
