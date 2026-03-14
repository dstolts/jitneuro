# Bundle

Manage context bundles -- load, create, refresh, or inspect domain knowledge.

## When to Use
- Load domain context that wasn't auto-loaded
- Create a new bundle for a repo or domain
- Refresh a stale bundle with current codebase state
- Inspect what's in a bundle before deciding to use it

## Instructions

When invoked as `/bundle <name>`:

### 1. Check if the bundle exists

Read `.claude/bundles/<name>.md`.

### 2. If the bundle EXISTS: load it

Read the file and output its contents prefixed with:
```
[Bundle loaded: <name>]
```

If the bundle is over 70 lines, note the line count and suggest reviewing
with /learn if it should be split.

### 3. If the bundle DOES NOT EXIST: offer to create it

Do NOT just list alternatives. Instead:

a. **Look for context to build from.** Search the workspace for a repo, directory,
   or domain matching `<name>`. Check:
   - Is there a repo at `../<name>/` or nearby with a similar name?
   - Is there an engram at `.claude/engrams/<name>-context.md`?
   - Is there a CLAUDE.md in a matching repo?
   - Grep for `<name>` in existing bundles and MEMORY.md for related context.

b. **If source material found:** Analyze it (package.json, README, CLAUDE.md,
   key files, recent commits, engram) and draft a bundle. A good bundle is
   50-180 lines covering:
   - Identity (what is this, one line)
   - Architecture (how it's structured, key patterns)
   - Key Files (table: path, purpose -- most important files only)
   - Conventions (coding patterns, naming, workflow rules)
   - Integrations (what it connects to, API contracts)
   - Current State (active work, known issues, recent changes)

c. **If no source material found:** Ask the user what this bundle should cover.
   Use brief Q&A (3-5 questions max) to gather enough to draft it.

d. **Present the draft** and ask for approval before writing.

e. **On approval:** Write to `.claude/bundles/<name>.md`, update
   `context-manifest.md` (add row to Available Bundles table), and suggest
   routing weight entries for MEMORY.md.

### 4. Without arguments (`/bundle`):

a. Scan `.claude/bundles/` for actual files. Count lines in each.
b. Read `context-manifest.md` and compare -- flag bundles that exist on disk
   but aren't in the manifest, or manifest entries with no matching file.
c. Present:

```
Bundles:
| Bundle | Lines | Status | Description |
|--------|-------|--------|-------------|
| active-work | 42 | OK | Current sprints, blockers |
| blog-content | 61 | WARN | Approaching 180-line limit |
| deploy | -- | MISSING | In manifest but no file |
| new-thing | 35 | UNLISTED | File exists, not in manifest |

Load: /bundle <name>
Create: /bundle <name> (will draft from repo/domain analysis)
```

d. If there are MISSING or UNLISTED items, offer to fix the manifest.

## Refreshing a Bundle

If the user says "refresh", "update", or "rebuild" in the context of a bundle
(e.g., "refresh the blog bundle", "/bundle blog -- it's stale"):

1. Read the current bundle content
2. Re-analyze the source (repo, engram, recent commits, current files)
3. Show a diff of what changed (added/removed/updated sections)
4. Ask for approval before overwriting
5. After writing, verify line count is under 80

## Splitting a Bundle

If a bundle is over 180 lines, or the user asks to split:

1. Identify natural subdomain boundaries in the content
2. Propose split: `<name>-a.md` and `<name>-b.md` with clear names
3. Show what goes where
4. On approval: write both files, archive original, update manifest,
   update routing weights to reference both

## Important
- Always ask before writing or modifying bundle files.
- Keep bundles under 180 lines. Over 80 means Claude may skip content.
- One bundle = one domain. If a bundle covers two unrelated things, split it.
- After any write, update context-manifest.md to match reality.
- Routing weights live in MEMORY.md -- suggest entries but let the user approve.
