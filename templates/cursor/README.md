# Cursor rules for JitNeuro

Cursor doesn't use slash commands. The agent needs to recognize **intents** (save, load, learn, guardrails) and know what to do.

## Canonical standard

JitNeuro's vendor-neutral standard is `AGENTS.md` (repo root). Cursor, Codex, Claude Code,
and other agents all read the SAME file. The Cursor bridge below points at that standard;
it does not duplicate it.

## What's here

- **`rules/jitneuro-intents.mdc`** -- Single always-on rule that defines:
  - **Guardrails** -- override goals; never bypass; full list in `AGENTS.md`
  - **Save** -- when user wants to checkpoint: gather state, write session-state, sync Hub, confirm
  - **Load** -- when user wants to restore: resolve session, read state + bundles, report
  - **Learn** -- when user wants to persist learnings: health check, propose updates, approve then execute

No slash required. When the agent sees the intent (or phrases like "save session", "load my-task", "run learn"), it follows the steps in the rule.

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

Ensure your `.claude/` (or workspace `.claude/`) has the usual layout: `session-state/`, `bundles/`, `engrams/`, `rules/`. The rule references those paths. Repo/team context can live in `.jitneuro/` when present. The KNOWLEDGE_ROOT store is ALWAYS present: it resolves via the `KNOWLEDGE_ROOT` env var, then `jitneuro.json` `knowledgeRoot`, then the local `.knowledge/` store created at install. An external shared catalog (a separate repo) is an OPTIONAL upgrade -- point `KNOWLEDGE_ROOT` at it; the local store remains the fallback.

Cursor has no hooks or slash commands, so the Claude Code adapter (hooks/commands) does not apply here. The portable core -- `AGENTS.md` + `.claude/rules/` + bundles + engrams + the knowledge store -- is the full contract on Cursor.

## Paths

The rule uses `.claude/` for session-state, bundles, engrams, and rules. Resolve `.claude/` from the workspace root or the project root that actually contains it (e.g. in a multi-root workspace, the root that has `session-state/`). Resolve `.jitneuro/` from the active repo when present. Resolve KNOWLEDGE_ROOT through the `KNOWLEDGE_ROOT` env var, then `jitneuro.json` `knowledgeRoot`, then the local `.knowledge/` store.
