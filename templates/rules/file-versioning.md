---
type: rule
purpose: Require documentation and spec files to be versioned by copying to a new numbered name and archiving the old version rather than editing in place or deleting.
read_when: Before creating, editing, or archiving any versioned documentation or spec file -- skipping destroys history and may overwrite canonical versions.
tags: [file-versioning, archiving, documentation, version-control, history]
scope: public
last_evaluated: 2026-06-03
---
# File Versioning

For documentation and spec files that evolve over time.

## Process

1. **Search first** -- search for existing files before creating new ones
2. **Ask user** -- update existing or create new version?
3. **Version** -- copy File-01.md to File-02.md, archive File-01.md, THEN edit File-02.md
4. **Format** -- Name-01.md, Name-02.md

Exception: active task list files (Hub.md or equivalent) are NOT versioned -- they are
updated in place.

## Archive Process

1. Create an `.archive/` directory in the same folder (if it does not exist)
2. Move the old version to `.archive/` (e.g., `.archive/Name-01.md`)
3. Verify the old file is no longer imported or referenced before archiving
4. `.archive/` folders should be in `.gitignore`
5. Never delete files -- always archive. Archives are the safety net.

## Why

Versioning preserves history without losing the working file. Archiving prevents accidental
use of stale versions while keeping them recoverable. Deleting loses information permanently.
