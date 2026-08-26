---
type: reference
purpose: Explains the engram system -- what engrams are, how they differ from bundles, and how to use them.
tags: [engram, memory, context, readme, template]
scope: internal
status: canonical
graduation_target: templates/engrams/README.md
read_when: Before creating or updating a per-project engram to understand how engrams differ from bundles and what belongs in each.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# Engrams

## What is an Engram?

An "engram" is a memory trace -- a durable record of what a project IS. Per-project engram files give Claude persistent context about a codebase that would otherwise require re-reading source files every session.

The name comes from neuroscience: engrams are the physical traces of memories in the brain. In JitNeuro, they serve the same function -- fast recall of project identity without re-reading everything.

## Why "Engrams"?

- **Session-persistent:** Loaded at session start, available throughout without re-reading code
- **Curated:** Written by /learn after human review, not auto-generated from code
- **Compact:** 50-150 lines of high-signal context (not raw file dumps)
- **Versioned:** Updated at sprint completion or architecture changes, not every session

## Engrams vs Bundles

| | Engrams | Bundles |
|--|---------|---------|
| Scope | One project | One domain (may span projects) |
| Content | Project identity, conventions, key files | Domain knowledge, patterns, how-to |
| Size | 50-150 lines | 50-280 lines |
| Updated by | /learn (per sprint) | /learn (as domain knowledge grows) |
| Loading | Auto-load if enabled in toggles.json | On-demand via routing weights or /bundle |

## Usage

### Path
`<workspace>/.knowledge/engrams/<repo-name>-context.md`

### Naming
Kebab-case of the GitHub repo name. Examples:
- `jitai-api-context.md` for `dstolts/jitai-api`
- `jit-knowledge-context.md` for `dstolts/jit-knowledge`

### Size
Keep under 150 lines. If an engram grows beyond 150 lines, split domain knowledge into a bundle and keep only identity/architecture in the engram.

### Updated by
`/learn` evaluates the session and proposes engram updates. Owner approves before writing.

### Toggling
Each engram can be enabled/disabled in `<workspace>/.claude/toggles.json`:
```json
{ "jitai-api": true, "jitai-www": false }
```
False = do not load this engram (useful when context is tight).
