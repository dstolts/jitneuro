# Minimize Sprawl

Reduce file proliferation. Every new file is future cognitive load.

## Rules

- One file per concern. Do not split related content across multiple files.
- Version files with a suffix: `Name-01.md`, `Name-02.md`. When creating a new version, archive the old one to `.archive/` in the same directory.
- Never modify an existing versioned file directly. Copy to the next version number first.
- Use a single hub file (HUB.md) as the source of truth for active work, status, and decisions.
- Before creating a new file, search for an existing one that covers the same concern. Extend it instead of duplicating.
- Never delete files. Archive them. Archives are the safety net.

## Why

Scattered information across many files forces context-switching to piece things together. A single source of truth reduces the mental overhead of "where did I put that?"
