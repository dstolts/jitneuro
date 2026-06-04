# Context Manifest -- DEPRECATED TEMPLATE

This template file is deprecated as of 2026-05-12 (Step 6 Layer B sweep).

The context-manifest.md pattern taught local routing. Routing now lives exclusively in:

  https://github.com/dstolts/jit-knowledge/blob/main/INDEX.md

## What to do instead

When setting up a new repo with JitNeuro:

1. Clone or add jit-knowledge as a submodule: `.jit-knowledge/`
2. Set up `~/.claude/url-resolver.md` with the repo URL -> local path map
3. In your repo's CLAUDE.md, reference INDEX.md for routing:
   `# Routing: see .jit-knowledge/INDEX.md (resolved via ~/.claude/url-resolver.md)`

The INDEX.md is the single source of truth for all task-keyword -> bundle mappings.
Do NOT create a local routing-weights.md or context-manifest.md with routing tables.

## Bundle catalog (non-routing sections)

If you need a local index of available bundles without routing, use your repo's
`.jitneuro/bundles/` directory listing. The engram at `.jitneuro/engrams/context.md`
should describe which bundles are available for this repo.

## Archive

The original context-manifest.md template is preserved at:
  `templates/.archive/context-manifest.md`
