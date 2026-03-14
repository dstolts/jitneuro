# Cursor Enablement — Context Document

This document defines what must exist and be deployed in the **jitneuro** repo so that **others can use JitNeuro from Cursor**. Use it as the source of truth for Cursor enablement: what we ship, where it lives, and what’s left to do.

---

## 1. Goal

**Cursor enablement** means: someone who uses **Cursor** (not Claude Code) can use JitNeuro’s core behavior — **guardrails**, **save**, **load**, **learn** — without relying on slash commands or Claude-specific hooks. The agent recognizes intent (from natural language or phrases like “save session”, “load my-task”, “run learn”) and knows what to do. Guardrails, routing, and project rules always come from **reading** CLAUDE.md and MEMORY.md (live sources), never from copied or cached text.

---

## 2. What We Need to Deploy (Checklist)

### 2.1 Artifacts that must be in the repo

| Artifact | Path | Purpose |
|----------|------|---------|
| **Cursor rule** | `templates/cursor/rules/jitneuro-intents.mdc` | Single always-on rule: when the agent sees save/load/learn/guardrail intent, follow the defined steps. Instructs to **read** CLAUDE.md and MEMORY.md when needed. |
| **Cursor README** | `templates/cursor/README.md` | How to install the rule (copy to `.cursor/rules/`), path resolution, dependency on existing `.claude/` layout. |
| **Cross-vendor doc** | `docs/cursor-and-cross-vendor.md` | Explains what Cursor can use as-is, what requires adaptation, and points to the intent rule. |
| **This context doc** | `docs/cursor-enablement-context.md` | Defines what “Cursor enablement” means and what we deploy for it. |

### 2.2 Content the Cursor rule must enforce

- **Guardrails:** Override goals; never bypass; get current list by **reading** project/workspace `.claude/CLAUDE.md` (and repo `CLAUDE.md`). No cached copy.
- **Save:** Trigger phrases → determine session name → gather state → write `.claude/session-state/<name>.md` → sync Hub if present → update `.current` → confirm. If compact/preserve rules needed, **read** CLAUDE.md.
- **Load:** Resolve session (name or #) → **read** session file → **read** listed bundles → **read** `.claude/context-manifest.md` and **MEMORY.md** (routing; always read file) → update `.current` → report.
- **Learn:** **Read MEMORY.md** (no cache) → health check (line counts, routing, sessions, bundles, engrams) → scan conversation for learnings → proposed changes table → approve then execute.
- **Source-of-truth principle:** At top of rule and where relevant: CLAUDE.md and MEMORY.md are live; **read** when needed, never copy into the rule or rely on stale context.

### 2.3 Documentation that must reference Cursor

- **Main README** (`README.md`): Add a short “Using JitNeuro with Cursor” section that links to `templates/cursor/README.md` or `docs/cursor-and-cross-vendor.md`, and states that Cursor users copy the intent rule to `.cursor/rules/` and rely on the same `.claude/` layout.
- **Setup guide** (`docs/setup-guide.md`): Optional “Cursor users” subsection: install `.claude/` via existing install script (for shared context); then copy `templates/cursor/rules/jitneuro-intents.mdc` to `.cursor/rules/`. No hooks in Cursor; guardrails/save/load/learn work via the rule.

### 2.4 Optional (not required for “others can use Cursor”)

- **Install script changes:** Add a Cursor mode or flag to `install.sh` / `install.ps1` that also copies `templates/cursor/rules/jitneuro-intents.mdc` to the target’s `.cursor/rules/` (creating `.cursor/rules/` if needed). Useful for one-command Cursor setup.
- **Verify:** A Cursor-specific verification (e.g. “does `.cursor/rules/jitneuro-intents.mdc` exist?”) could be added to a doc or a separate small script; not required for minimal enablement.
- **Engram:** If the jitneuro engram (e.g. in the workspace `.claude/engrams/`) is used for contributor context, add a line that Cursor enablement = intent rule + read CLAUDE.md/MEMORY.md; artifacts live under `templates/cursor/` and `docs/cursor-*.md`.

---

## 3. Where Things Live (Summary)

```
jitneuro/
├── templates/
│   └── cursor/
│       ├── README.md                    # Install + path note for Cursor
│       └── rules/
│           └── jitneuro-intents.mdc     # Guardrails, save, load, learn (read CLAUDE.md / MEMORY.md)
├── docs/
│   ├── cursor-and-cross-vendor.md       # Cursor vs Claude; intent-based behavior
│   └── cursor-enablement-context.md      # This file — what we deploy for Cursor
└── README.md                            # Add "Using JitNeuro with Cursor" → cursor template / cross-vendor doc
```

User’s repo or workspace after setup:

- **Claude Code:** `.claude/` populated by install script (commands, hooks, bundles, session-state, etc.).
- **Cursor:** Same `.claude/` (shared context); plus `.cursor/rules/jitneuro-intents.mdc` copied from `templates/cursor/rules/`. Agent reads CLAUDE.md and MEMORY.md from their normal locations.

---

## 4. Out of Scope for This Enablement

- Cursor extension (hooks, PreCompact, etc.): not required for guardrails/save/load/learn; can be a later project.
- Changing JitNeuro’s core behavior for Claude Code: Cursor enablement is additive (rule + docs), not a change to existing commands or hooks.
- Vendor-neutral directory (e.g. `.ai/`): optional refactor; current enablement uses existing `.claude/` and only adds a Cursor rule that reads from it.

---

## 5. Definition of Done for “Cursor enablement deployed”

- [ ] `templates/cursor/rules/jitneuro-intents.mdc` is in repo and enforces guardrails, save, load, learn with “read CLAUDE.md / MEMORY.md” (no copy).
- [ ] `templates/cursor/README.md` describes install (copy rule to `.cursor/rules/`) and `.claude/` dependency.
- [ ] `docs/cursor-and-cross-vendor.md` exists and points to the intent rule and install.
- [ ] `docs/cursor-enablement-context.md` (this doc) exists and defines the deployment checklist.
- [ ] Main `README.md` has a “Using JitNeuro with Cursor” (or similar) section linking to the Cursor template or cross-vendor doc.
- [ ] Optional: setup guide mentions Cursor one-time step (copy rule); optional: install script can copy the Cursor rule.

When all required items are true, “Cursor enablement” is deployed: others can use Cursor with JitNeuro by copying the rule and using the same `.claude/` layout, with guardrails and live rules coming from reading CLAUDE.md and MEMORY.md.
