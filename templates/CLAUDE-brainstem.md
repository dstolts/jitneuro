# [Project Name]

<!--
  CLAUDE.md -- THIN IMPORTER (do NOT duplicate AGENTS.md here)

  JitNeuro's canonical, vendor-neutral instruction surface is AGENTS.md.
  Cursor, Codex, Claude Code, and other agents all read the SAME standard.
  This file exists only so Claude Code (which auto-loads CLAUDE.md) is
  pointed at that standard. Keep it thin -- a pointer, not a copy.

  TWO WAYS TO IMPORT (use whichever your Claude Code version supports):

  1) @import (preferred when supported). Uncomment the next line:
       @AGENTS.md
     Claude Code inlines AGENTS.md so the agent gets the full standard.

  2) Explicit directive (always works, even if @import is unsupported):
     The "Read This First" section below instructs the agent to read
     AGENTS.md before doing anything. No content is duplicated.

  Replace bracketed content with your project specifics. Everything that
  is NOT a Claude-Code-only adapter detail belongs in AGENTS.md, not here.
-->

<!-- @AGENTS.md  -- uncomment if your Claude Code build supports @-imports -->

## Read This First (canonical standard)
The complete, vendor-neutral instruction surface for this project lives in **`AGENTS.md`**.
Before any reasoning or tool use, **read `AGENTS.md`** (repo root). It defines:
- Identity, Cognitive Identity, Decision Priority Weights
- Divergent Thinking, Critical Rules, Guardrails
- JitNeuro Mode, KNOWLEDGE_ROOT, Context Loading, Compact Instructions

Do not rely on a cached copy -- `AGENTS.md` changes constantly; read the live file.
This CLAUDE.md adds ONLY Claude-Code-specific adapter notes below; it never restates AGENTS.md.

## Claude Code Adapter (this tool only)
These activate only under Claude Code and are layered on top of the portable core:
- **Slash commands:** `.claude/commands/` (e.g. /save, /load, /learn, /onboard, /verify)
- **Hooks:** `.claude/hooks/` (branch protection, heartbeats, PreCompact save, session recovery)
- **Conversation logging:** when `conversation_log` is "on" in session-state.md, the
  FIRST action on every user message is to append the prompt to the log file; write the
  prior response first if the previous entry has none. See `.claude/commands/conversation-log.md`.

On non-Claude tools (Cursor, Codex, others), these adapters are absent -- the portable
core in `AGENTS.md` plus `.claude/rules/`, bundles, engrams, and the knowledge store
is the contract. See `AGENTS.md` "Tool Adapters" for the full layering map.

## Compact Instructions
Follow the "Compact Instructions" section in `AGENTS.md`. (Compaction is a Claude Code
feature; the preserve/drop list there is the source of truth.)
