# Engrams

Per-project deep context files. One file per project or repository.

## Why "engrams"?

In neuroscience, an engram is the physical trace a memory leaves in the brain --
a pattern of neural connections that encodes a specific piece of knowledge.
Engrams aren't the experience itself, they're the compressed representation of it.

That's exactly what these files are: not the codebase, but the compressed knowledge
about it. They strengthen over time as /learn updates them with new discoveries.

We chose "engrams" over "context" to avoid collision with existing `context/`
folders that projects may already have.

## Usage

- **Path:** `.claude/engrams/` (project or workspace level)
- **Naming:** `<project-name>.md` (one per project/repo)
- **Size:** 50-150 lines. Trim stale content if longer.
- **Updated by:** `/learn` command (presents changes for approval before writing)
- **Loaded by:** orchestrator or /load when a session involves that project

## What belongs here vs. bundles

- **Bundles** cut across projects by domain (deploy, testing, API design)
- **Engrams** cut across domains by project (everything about one repo)

A deploy task on your API loads the deploy **bundle** AND the API **engram**.
They're orthogonal -- bundles are "how to work," engrams are "what this is."
