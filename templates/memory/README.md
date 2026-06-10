# Memory Templates

## The Index Pattern

MEMORY.md has a hard 200-line limit (Claude Code silently truncates beyond that). With dozens of feedback, project, and reference files, listing each one in MEMORY.md exhausts the budget fast.

**Solution:** MEMORY.md gets ONE pointer line to `detail-index.md`. The index holds the full table of detail files grouped by category. Claude loads the index on-demand when context is needed.

### MEMORY.md entry (one line)
```
## Detail Files
75+ detail files in memory/ -- read [detail-index.md](detail-index.md) to find the right file by topic.
```

### detail-index.md
The full searchable table with descriptions, grouped by type (user, project, reference, feedback). When feedback grows large, subdivide by domain (e.g., "Feedback -- N8N", "Feedback -- Salesforce").

### Adding new memories
When creating a new feedback/project/reference file, add the entry to `detail-index.md`, NOT to MEMORY.md. MEMORY.md holds facts Claude needs every session (business context, project index). Repo/team context can live in `.jitneuro/`; internal/team shared catalogs are configured separately. Detail files are loaded on-demand.

## What goes where

| Content | Location | Why |
|---------|----------|-----|
| Business facts, project index | MEMORY.md | Needed every session |
| Individual feedback, project details, references | detail-index.md -> individual .md files | Loaded on-demand |
| Instructions, process, guardrails | ~/.claude/rules/ | Loaded every session (no line limit) |
| Domain knowledge, cross-project context | bundles/ | Loaded on demand by the orchestrator |
| Repo/team-specific context | .jitneuro/ | Committed context for this repo only |
| Project identity, architecture, key files | engrams/ | Loaded when working on that project |
