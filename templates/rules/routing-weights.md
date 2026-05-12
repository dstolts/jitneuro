# Routing Weights -- DEPRECATED TEMPLATE

This template file is deprecated as of 2026-05-12 (Step 6 Layer B sweep).

The routing-weights.md pattern enacted routing locally. Routing now lives exclusively in:

  https://github.com/dstolts/jit-knowledge/blob/main/INDEX.md

## What to do instead

Do NOT create a routing-weights.md in your repo's `.claude/rules/`. Instead:

1. Add jit-knowledge as a submodule at `.jit-knowledge/` in your repo
2. Set up `~/.claude/url-resolver.md` mapping the jit-knowledge GitHub URL to the local submodule path
3. Reference INDEX.md for routing at session start (via CLAUDE.md or brainstem)

For system-specific routing extensions (routes not in INDEX.md), add them ONLY to INDEX.md
via a PR to jit-knowledge. Do not maintain a parallel local router.

## Archive

The original routing-weights.md template is preserved at:
  `templates/.archive/rules-routing-weights.md`
