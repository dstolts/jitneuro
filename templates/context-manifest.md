# Context Manifest -- DEPRECATED TEMPLATE

This template file is deprecated as of 2026-05-12 (Step 6 Layer B sweep).

The context-manifest.md pattern taught local routing tables. Do not recreate it
as a framework surface.

## What to do instead

When setting up a new repo with JitNeuro:

1. Install JitNeuro from the `jitneuro` checkout.
2. Keep framework files in the installed `.claude/` surfaces.
3. Use `.jitneuro/` only for repo/team-specific context that belongs with this repo.
4. If your team has an internal/shared catalog, reference it separately, for example:
   `# Shared catalog: see <private-catalog>/INDEX.md (resolved via your team's resolver)`

The public JitNeuro framework source is the `jitneuro` repo. Private company
catalogs are optional inputs and are not required for public adopters.
Do NOT create a local routing-weights.md or context-manifest.md with routing tables.

## Bundle catalog (non-routing sections)

If you need a local index of available bundles without routing, use your repo's
`.jitneuro/bundles/` directory listing. The engram at `.jitneuro/engrams/context.md`
should describe which bundles are available for this repo. Do not copy shared
framework content into `.jitneuro/`.

## Archive

The original context-manifest.md template is preserved at:
  `templates/.archive/context-manifest.md`
