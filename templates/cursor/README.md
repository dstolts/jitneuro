# Cursor rules for JitNeuro

Cursor doesn’t use slash commands. The agent needs to recognize **intents** (save, load, learn, guardrails) and know what to do.

## What’s here

- **`rules/jitneuro-intents.mdc`** — Single always-on rule that defines:
  - **Guardrails** — override goals; never bypass; full list in CLAUDE.md
  - **Save** — when user wants to checkpoint: gather state, write session-state, sync Hub, confirm
  - **Load** — when user wants to restore: resolve session, read state + bundles, report
  - **Learn** — when user wants to persist learnings: health check, propose updates, approve then execute

No slash required. When the agent sees the intent (or phrases like “save session”, “load my-task”, “run learn”), it follows the steps in the rule.

## Install

Copy the rule into your project or workspace so Cursor loads it:

```bash
# From repo root (project-level)
mkdir -p .cursor/rules
cp jitneuro/templates/cursor/rules/jitneuro-intents.mdc .cursor/rules/

# Or workspace-level (e.g. your parent workspace dir)
mkdir -p .cursor/rules
cp jitneuro/templates/cursor/rules/jitneuro-intents.mdc .cursor/rules/
```

Ensure your `.claude/` (or workspace `.claude/`) has the usual layout: `session-state/`, `bundles/`, `engrams/`, `context-manifest.md`. The rule references those paths.

## Paths

The rule uses `.claude/` for session-state, bundles, engrams, and manifest. Resolve it from the workspace root or the project root that actually contains `.claude/` (e.g. in a multi-root workspace, the root that has `session-state/`).
