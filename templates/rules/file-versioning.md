# File Versioning

For documentation and spec files that evolve over time.

## Process

1. **Search first** -- grep/glob for existing files before creating new ones
2. **Ask user** -- update existing or create new version?
3. **Version** -- copy File-01.md to File-02.md, archive File-01.md, THEN edit File-02.md
4. **Format** -- Name-01.md, Name-02.md (exception: CLAUDE.md files are NOT versioned)

## Archive Process

1. Create `.archive/` directory in the same folder (if it doesn't exist)
2. Move the old version to `.archive/` (e.g., `.archive/Name-01.md`)
3. Verify the old file is no longer imported or referenced before archiving
4. `.archive/` folders should be in `.gitignore`
5. Never delete files -- always archive. Archives are the safety net.
