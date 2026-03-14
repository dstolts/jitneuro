# Cursor and Cross-Vendor Use of JitNeuro

This doc answers: (1) Can Cursor leverage JitNeuro without change? (2) What changes make it cross-vendor useful?

---

## Summary

| Layer | Cursor as-is? | Cross-vendor approach |
|-------|----------------|------------------------|
| **Bundles, engrams, session-state, manifest** | ✅ Yes (read/write same paths) | Use vendor-neutral dir (e.g. `.ai/`) so both read same files |
| **Brainstem / core rules** | ⚠️ Adapt | Map CLAUDE.md → Cursor rules or AGENTS.md |
| **Slash commands** | ❌ No | Commands become “intent docs” + one Cursor rule that routes to them |
| **Hooks** | ❌ No | Claude-only; Cursor gets best-effort or no hooks |
| **Config (jitneuro.json)** | ✅ Yes | Same JSON in shared location |

---

## 1. What Cursor Can Use Without Change

- **Content under `.claude/`**  
  Cursor can read and write the same files Claude Code uses:
  - `context-manifest.md` (bundle index, routing)
  - `bundles/*.md`
  - `engrams/*.md`
  - `session-state/*.md`
  - `jitneuro.json`

  So the *concepts* (bundles, engrams, session state, routing) work in Cursor; the agent just needs to be told where they live and when to use them.

- **Workflows**  
  “Load bundle X for this task”, “save session state”, “read manifest for routing” are all file I/O. Cursor can do that from prompts or rules; no Claude-specific API is required.

- **Config**  
  `jitneuro.json` is just JSON. Cursor (or any tool) can read it if the path is known.

---

## 2. What Requires Adaptation

### 2.1 Slash commands

- **Claude Code:** Resolves `/save`, `/load`, etc. from `~/.claude/commands/` and `<repo>/.claude/commands/` and injects the corresponding `.md` as prompt.
- **Cursor:** No built-in “slash → load this .md as prompt.” So “commands” are not auto-invoked.

**Adaptation:** Treat commands as **intent handlers**, not as Cursor slash resolution:

- Keep the same command docs (e.g. `save.md`, `load.md`, `session.md`) as the single source of truth.
- Add **one** Cursor rule that defines trigger intents and what to do (so “when you see it, you know what to do” — no slash required).

**Done:** The rule is in `templates/cursor/rules/jitneuro-intents.mdc`. It is always-applied and covers:
- **Guardrails** — override goals, never bypass, full list in CLAUDE.md
- **Save** — trigger phrases + gather state → write `session-state/<name>.md` → sync Hub → update `.current` → confirm
- **Load** — resolve name/# → read session file → read listed bundles + manifest → update `.current` → report
- **Learn** — health check → scan session for learnings → proposed changes table → approve then execute

Copy that file to your repo’s `.cursor/rules/` (or workspace `.cursor/rules/`). Path can be `.claude/commands/` for full details; the rule inlines the essential steps so the agent can act without opening another file.

### 2.2 Hooks (PreCompact, SessionStart, PreToolUse, SessionEnd)

- **Claude Code:** Hooks are wired in `settings.local.json`, run bash scripts on lifecycle events.
- **Cursor:** No equivalent hook system (no PreCompact, SessionStart, etc.).

**Adaptation:**

- **Option A (pragmatic):** Document that Cursor does not support hooks. Users lose:
  - Pre-compact save prompt
  - Session-start recovery
  - Branch-protection on tool use
  - Session-end autosave  
  Mitigation: rely on the agent following the command docs (e.g. “before you summarize or drop context, offer /save”) and on manual discipline.

- **Option B (later):** Provide a Cursor extension or external watcher that approximates some of this (e.g. “on context clear, write a recovery hint file”) — larger effort, optional.

So: **no code change to JitNeuro**; only documentation and, optionally, a separate Cursor-side layer.

### 2.3 Brainstem (CLAUDE.md) and MEMORY.md

- **Claude Code:** Loads CLAUDE.md (and MEMORY.md) automatically at session start.
- **Cursor:** Uses `.cursor/rules/` (and optionally AGENTS.md), not CLAUDE.md/MEMORY.md.

**Adaptation:**

- **Brainstem:**  
  - Either copy “brainstem” content into a Cursor rule with `alwaysApply: true` (e.g. `.cursor/rules/jitneuro-brainstem.mdc`),  
  - Or put it in AGENTS.md and point Cursor at that file.  
  No need to change the *content* of the brainstem; only the *injection mechanism* (Claude = CLAUDE.md, Cursor = rule or AGENTS.md).

- **MEMORY.md / routing:**  
  Treat as a referenced doc: “When deciding which bundles to load, read MEMORY.md (and context-manifest) and use the routing weights.”  
  Add that to the same Cursor rule or to the “command router” rule so the agent always has the instruction to consult MEMORY + manifest.

---

## 3. Changes That Make JitNeuro Cross-Vendor Useful

### 3.1 Vendor-neutral directory (recommended)

- **Idea:** Keep one set of content that both Claude and Cursor read/write.
- **Option 1 – Shared under `.claude/`:**  
  Cursor is told (via rule/AGENTS.md): “JitNeuro context lives under `.claude/`: bundles, engrams, session-state, context-manifest, commands.”  
  No move; only document that Cursor uses the same paths.

- **Option 2 – New vendor-neutral root:**  
  Introduce something like `.ai/` (or `ai-context/`) and move (or symlink/copy) there:
  - `context-manifest.md`
  - `bundles/`
  - `engrams/`
  - `session-state/`
  - `commands/` (intent docs)
  - `jitneuro.json`

  Then:
  - **Claude:** Keep using `.claude/` but have install script (or docs) copy/symlink from `.ai/` → `.claude/`, or point Claude at `.ai/` if it ever supports a configurable root.
  - **Cursor:** One rule: “JitNeuro context lives under `.ai/`. Commands, bundles, engrams, session-state, manifest live there.”

  Benefit: one canonical place; both vendors “point” at it (Claude today via .claude, Cursor via rule). Easiest long-term is “keep .claude, document it as shared” (Option 1); Option 2 is for a cleaner cross-tool story.

### 3.2 Single “command router” rule for Cursor

Add a Cursor rule (e.g. `.cursor/rules/jitneuro-commands.mdc`) that:

1. **Path:** Assumes JitNeuro root is `.claude/` (or `.ai/` if you adopt that).
2. **Intents:** On user intent matching a known command (`/save`, `/load`, `/session`, `/bundle`, `/learn`, “checkpoint session”, “load session X”, etc.), read the corresponding `commands/<name>.md` (or the consolidated session.md, save.md, load.md, etc.) and follow its instructions.
3. **Manifest + MEMORY:** When loading context for a task, read `context-manifest.md` and MEMORY.md (routing weights) and load the suggested bundles.

No change to the existing command markdown; they stay the single source of truth for both Claude and Cursor.

### 3.3 Document “Cursor mode” in setup guide

In `docs/setup-guide.md` (or a dedicated `docs/cursor.md`):

- State that Cursor can use the same bundles, engrams, session-state, and manifest.
- Explain that slash commands work via “intent + rule” (and where the rule lives).
- State that hooks are Claude Code–only; list what Cursor users don’t get and suggest mitigations (e.g. “ask the agent to offer /save before big context changes”).
- Optionally: one-time setup steps (e.g. “Add `.cursor/rules/jitneuro-commands.mdc` and, if desired, copy brainstem into a Cursor always-on rule”).

### 3.4 Optional: install script variant for Cursor

- **User-level:** Script creates or updates:
  - `.cursor/rules/jitneuro-commands.mdc` (command router)
  - Optionally `.cursor/rules/jitneuro-brainstem.mdc` from CLAUDE-brainstem.md
- **Project-level:** Same rule files under `<repo>/.cursor/rules/`.

No change to hook or Claude-only config; just adding Cursor rule files so “install for Cursor” is one command.

---

## 4. What Stays Claude-Only (No Change to JitNeuro Core)

- **Hook registration** (`settings.local.json`, `jitneuro.json` hook events): only meaningful in Claude Code.
- **Slash resolution** (loading `.md` from `commands/` when user types `/save`): Claude feature; Cursor uses the “intent + rule” approach above.
- **MEMORY.md / CLAUDE.md auto-loading:** product-specific; Cursor uses rules/AGENTS.md to get the same content.

The JitNeuro *design* (bundles, engrams, session state, manifest, command semantics) stays the same; only the *integration point* (Claude vs Cursor) differs.

---

## 5. Minimal Checklist for “Cursor + cross-vendor”

- [ ] **Document:** Cursor can use `.claude/` (or `.ai/`) content as-is; no change to bundle/engram/session-state format.
- [ ] **Add:** One Cursor rule (or AGENTS.md block) that routes user intents to the existing command .md files and tells the agent to use manifest + MEMORY for routing.
- [ ] **Add:** Optional Cursor rule that injects brainstem content (from CLAUDE-brainstem.md) so Cursor has the same “always on” rules.
- [ ] **Document:** Hooks are Claude Code–only; Cursor behavior and mitigations.
- [ ] **Optional:** Vendor-neutral root (e.g. `.ai/`) and/or install script that writes the Cursor rule(s) so one install works for both.

With that, Cursor leverages the same process (context model, commands, session state, routing) with minimal change; the only real gaps are hooks and native slash resolution, both addressed by documentation and one small rule layer.
