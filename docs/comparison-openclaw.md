# JitNeuro vs OpenClaw -- Comparison

**Purpose:** Accurate positioning of JitNeuro relative to OpenClaw for adopters evaluating both.
**Sources:** GitHub repos, official docs, community articles, security research (as of March 2026).

---

## 1. Overview

### OpenClaw

- **What:** Open-source autonomous AI agent framework that wraps LLMs (Claude, GPT, Gemini, Llama) and exposes them through messaging platforms (WhatsApp, Telegram, Discord, Signal, Slack, iMessage) as a personal AI assistant.
- **Creator:** Peter Steinberger (Austrian developer). Originally published as "Clawdbot" November 2025, renamed "Moltbot" January 27, 2026 after an Anthropic trademark complaint, then "OpenClaw" January 30, 2026.
- **License:** MIT
- **Language:** TypeScript
- **GitHub:** github.com/openclaw/openclaw
- **Status:** Steinberger joined OpenAI February 14, 2026. Project transitioning to an independent, OpenAI-sponsored foundation.
- **Scope:** General-purpose personal AI assistant. Runs locally on Mac/Windows/Linux. Multi-channel messaging interface. 50+ integrations (Spotify, Obsidian, Twitter, GitHub, Gmail, smart home, etc.).

### JitNeuro

- **What:** Claude Code memory management and enterprise security framework. Adds structured memory persistence, cognition layers, session management, lifecycle hooks, and security guardrails specifically for Claude Code workflows.
- **Creator:** Just In Time AI, Inc.
- **License:** MIT
- **Language:** Shell (bash + PowerShell install scripts), Markdown configuration
- **GitHub:** github.com/dstolts/jitneuro
- **Version:** v0.5.0
- **Scope:** Claude Code-specific. Enhances the Claude Code CLI with structured memory, enterprise-grade guardrails, decision frameworks, and autonomous task execution patterns. Not a standalone agent -- augments an existing tool.

---

## 2. Feature Comparison Table

| Feature | OpenClaw | JitNeuro v0.5.0 |
|---------|----------|-----------------|
| **Primary Purpose** | General AI assistant via messaging | Claude Code memory + enterprise guardrails |
| **Target User** | Anyone wanting a personal AI assistant | Claude Code power users, enterprise developers |
| **LLM Support** | Claude, GPT, Gemini, Llama (any) | Claude only (Claude Code native) |
| **Interface** | WhatsApp, Telegram, Discord, Signal, Slack, iMessage, browser | Claude Code CLI |
| **Memory Persistence** | 4-layer: bootstrap files, session transcripts, context window, retrieval index | 5-layer: CLAUDE.md identity, rules/, MEMORY.md facts, settings.json, workspace.json |
| **Memory Files** | SOUL.md, AGENTS.md, USER.md, MEMORY.md, TOOLS.md | CLAUDE.md, rules/*.md, MEMORY.md, bundles/, engrams/ |
| **Memory Search** | Semantic vector search (embeddinggemma-300m) + keyword hybrid RAG | Routing weights (keyword-based bundle loading), Grep/Glob search |
| **Context Compaction** | Built-in compaction with pre-compaction memory flush | Pre-compact hook (lifecycle hook triggers context save) |
| **Session Management** | Named sessions (session:custom-id), session transcripts as JSONL | /save, /load, /sessions, /pulse, session-state files, post-clear picker |
| **Identity/Persona** | SOUL.md + IDENTITY.md per agent, mutable soul evolution, soul-evil hook for persona swapping | 16 personas in cognition/personas.md, owner persona overlay, per-request persona activation |
| **Multi-Agent** | Native sub-agents, configurable nesting depth, orchestrator pattern, per-agent workspaces | Shipped: scheduled agents, background sub-agent spawning, cross-session orchestration via hooks |
| **Hooks** | Event-driven hooks on agent lifecycle events | 10 hook scripts / 9 hook events (pre-compact save, session-id write, heartbeat, post-compact recovery, post-clear picker, scheduled-agents spawner, branch protection, pre/post agent register, session-end auto-save) |
| **Scheduling** | Cron jobs (at/every/cron expressions), heartbeat monitoring | Scheduled agents (interval-based, configurable per jitneuro.json) |
| **Skills/Commands** | ClawHub marketplace (4,000+ community skills), CLI-installable | 17 commands + 5 shortcuts, project-scoped |
| **Decision Framework** | No formal framework -- operational rules in AGENTS.md | 4 decision models, priority weights (security > reliability > correctness > ...), divergent thinking |
| **Security Guardrails** | Broad filesystem access by default, sandbox mode optional | Trust Zones (GREEN/YELLOW/RED), branch protection hook, file versioning, definition of done |
| **Friction Detection** | Not present | Pattern matching on owner frustration signals, correction cascades, anti-patterns |
| **Install Method** | curl one-liner, npm, or git clone | bash + PowerShell scripts, 3 modes (user/workspace/project) |
| **Configuration** | JSON config + markdown workspace files | Pure markdown + JSON (settings.json, workspace.json) |
| **File Size Limits** | 20K chars per file, 150K aggregate bootstrap | Line-count limits (MEMORY.md < 200, bundles < 180, engrams < 150) |
| **AFK/Autonomous** | Heartbeat system, cron-driven autonomous tasks, 24/7 daemon | Scheduled housekeeper agent, AFK pattern for autonomous task execution within Claude Code sessions |
| **Integrations** | 50+ (Spotify, smart home, GitHub, Gmail, etc.) | Claude Code native only (MCP servers for external tools) |
| **Customization Guide** | Community docs, blog posts, ClawHub examples | Post-install review guide, rule templates (Definition of Done, Trust Zones, File Versioning) |
| **Enterprise Focus** | Minimal -- personal assistant first | Core design principle -- enterprise security, compliance, audit trails |

---

## 3. Architecture Differences

### OpenClaw Architecture

OpenClaw is a **standalone agent runtime** (Gateway daemon) that:
- Runs as a background process on the user's machine
- Connects to LLM APIs (Claude, GPT, etc.) as a backend
- Exposes the agent through messaging platform bindings (Telegram, WhatsApp, etc.)
- Manages its own session store, memory index, and tool execution
- Supports multi-agent: each agent gets an isolated workspace with its own SOUL.md, IDENTITY.md, state directory
- Message routing via bindings (specificity-based: peer > guild > team > account > channel > default)
- Plugin architecture with ClawHub marketplace for extensibility

The architecture is: **User -> Messaging Platform -> OpenClaw Gateway -> LLM API -> Tool Execution -> Response**

### JitNeuro Architecture

JitNeuro is a **configuration framework** that augments Claude Code:
- Does not run its own daemon or process -- operates within Claude Code's existing runtime
- Installs structured markdown files into Claude Code's configuration directories (~/.claude/, .claude/, project root)
- Relies on Claude Code's native hook system for lifecycle events
- Memory is organized in layers: identity (CLAUDE.md), instructions (rules/), facts (MEMORY.md), controls (settings.json), structured data (workspace.json)
- Cognition layer adds personas, decision frameworks, and friction detection as instruction files
- Session state managed through markdown files and Claude Code slash commands

The architecture is: **User -> Claude Code CLI -> (JitNeuro config loaded automatically) -> Claude API -> Tool Execution -> Response**

### Key Architectural Distinction

OpenClaw is a **runtime** -- it is the agent. JitNeuro is a **configuration layer** -- it shapes how Claude Code behaves. This is the fundamental difference. OpenClaw replaces the interface between human and LLM. JitNeuro enhances an existing interface (Claude Code) with structured memory and guardrails.

---

## 4. What JitNeuro Has That OpenClaw Doesn't

| Capability | Details |
|-----------|---------|
| **Formal Decision Priority Weights** | Explicit ordering: security > reliability > correctness > maintainability > owner effort > simplicity > time to market > cost. OpenClaw has no equivalent formal framework. |
| **Friction Detection** | Automated pattern matching on owner frustration signals (expletives, repeated asks, wrong assumptions, habitual mistakes). Triggers correction cascades. OpenClaw has nothing comparable. |
| **16 Named Personas with Per-Request Activation** | Specialist personas activated based on task context, announced at response start, with conflict reconciliation. OpenClaw has SOUL.md for a single agent personality, not task-specific persona switching. |
| **Divergent Thinking Process** | Structured FRAME > DIVERGE > EVALUATE > CONVERGE > EXECUTE process for enterprise decisions. Forces multi-approach evaluation before committing. |
| **Trust Zones (GREEN/YELLOW/RED)** | Formal permission model with escalation gates. RED actions require explicit owner approval. OpenClaw has sandbox mode but no structured trust zone model. |
| **Anti-Pattern Tracking** | Documented anti-patterns that persist across sessions via cognition/anti-patterns.md. |
| **Root Cause Analysis Protocol** | Formal RCA process triggered by friction detection or explicit request. Traces to root cause before fixing. |
| **File Versioning with Archive** | Mandatory copy-before-edit with -01/-02 naming, .archive/ directories, import verification before archiving. |
| **Definition of Done** | Three conditions: value delivered + customer knows how to use it + customer validated. Applied to all work. |
| **Routing Weights** | Keyword-based automatic bundle loading. Task context determines which knowledge files load. Reduces token waste. |
| **Branch Protection Hook** | Lifecycle hook preventing commits to main without explicit permission. |
| **Gap Analysis** | Mandatory extra thought time before delivering code: edge cases, missed personas, wrong assumptions. |
| **Engram System** | Per-project deep context files (engrams/) with toggle control via toggles.json. Separate from operational memory. |
| **Cross-Project Orchestration** | API contract-first rule for cross-repo changes. Sprint protocol with per-repo build verification. |
| **Pure Markdown Config** | No runtime dependencies. Everything is markdown files that Claude Code reads natively. Zero attack surface from the framework itself. |

---

## 5. What OpenClaw Has That JitNeuro Doesn't

| Capability | Details |
|-----------|---------|
| **Standalone Agent Runtime** | Runs as a background daemon (Gateway) independent of any specific CLI tool. JitNeuro requires Claude Code. |
| **Multi-Platform Messaging** | WhatsApp, Telegram, Discord, Signal, Slack, iMessage, browser. JitNeuro is CLI-only through Claude Code. |
| **Multi-LLM Support** | Works with Claude, GPT, Gemini, Llama, and other models. JitNeuro is Claude-only. |
| **Semantic Memory Search** | Vector embeddings (embeddinggemma-300m) + keyword hybrid RAG for memory retrieval. JitNeuro uses keyword-based routing and grep. |
| **Native Multi-Agent at Runtime** | Sub-agent spawning with configurable nesting depth, orchestrator patterns, per-agent isolated workspaces managed by the Gateway daemon. |
| **Cron Scheduling** | Built-in cron jobs (at/every/cron expressions) managed by the Gateway daemon outside Claude Code sessions. |
| **Skills Marketplace** | ClawHub with 4,000+ community-contributed skills, CLI-installable. JitNeuro commands are author-maintained only. |
| **50+ Platform Integrations** | Spotify, Obsidian, smart home, Twitter, GitHub, Gmail, etc. JitNeuro relies on Claude Code's MCP servers for external tool access. |
| **Mutable Agent Identity** | Agents can modify their own SOUL.md across sessions, enabling personality evolution. JitNeuro personas are static configuration. |
| **Dynamic Persona Swapping** | soul-evil hook enables random or scheduled persona changes. |
| **Session Transcripts as JSONL** | Full conversation history stored on disk in structured format. JitNeuro session state is markdown checkpoints. |
| **AWS Managed Service** | AWS Lightsail managed hosting option available. JitNeuro is self-managed configuration only. |

---

## 6. When to Use Which

### Use JitNeuro When:

- You are a **Claude Code user** who wants structured memory and enterprise guardrails without leaving your existing workflow
- You need **enterprise security patterns** -- trust zones, branch protection, formal approval gates, audit trails
- You want **cognitive frameworks** -- decision models, persona-based reasoning, friction detection, root cause analysis
- You work across **multiple repositories** and need cross-project orchestration with API contract-first rules
- You want **zero runtime dependencies** -- pure markdown configuration with no daemon, no server, no attack surface
- You need **ADHD-optimized workflows** -- file versioning, HUB.md single source, minimize sprawl patterns
- You want **deterministic behavior** -- explicit priority weights, defined personas, structured decision processes
- **Security is non-negotiable** -- JitNeuro was designed security-first; OpenClaw has had multiple critical CVEs (CVE-2026-25253, CVE-2026-22175)

### Use OpenClaw When:

- You want a **general-purpose AI assistant** accessible from your phone via messaging apps
- You need **multi-LLM flexibility** -- ability to switch between Claude, GPT, Gemini, or local models
- You want **24/7 autonomous operation** -- heartbeat monitoring, cron scheduling, background daemon
- You need **semantic memory search** -- RAG-based retrieval across large document collections
- You want a **multi-agent system** -- orchestrator patterns with sub-agent spawning
- You need **platform integrations** -- Spotify, smart home, social media, etc.
- You want **community extensions** -- browse and install from 4,000+ skills on ClawHub
- You are building a **personal assistant** rather than a development workflow tool

### They Are Not Direct Competitors

OpenClaw and JitNeuro solve different problems at different layers:
- OpenClaw is an **agent runtime** -- it IS the AI assistant
- JitNeuro is a **configuration framework** -- it makes Claude Code better at being an AI coding assistant

A user could use both: OpenClaw as a general assistant on messaging platforms, and JitNeuro to enhance their Claude Code development sessions. They do not conflict.

---

## 7. Roadmap Considerations Based on This Analysis

### High Priority (borrow concepts, adapt to JitNeuro's architecture)

1. **Semantic Memory Search** -- OpenClaw's hybrid RAG (vector + keyword) for memory retrieval is a significant advantage over keyword-based routing weights. Consider adding an MCP server that provides semantic search across engrams and bundles. This would make context loading smarter without changing the markdown-first architecture. Could leverage Claude Code's native MCP support.

2. **Pre-Compaction Memory Flush** -- OpenClaw's configurable `reserveTokensFloor` (40K tokens) ensures critical context is saved before compaction. JitNeuro has a pre-compact hook; verify it has enough reserved token budget to execute reliably and document recommended settings.

3. **Richer Heartbeat / Check-In Logic** -- The HEARTBEAT.md pattern (agent periodically evaluates a checklist and decides whether to act) is elegant and low-overhead. JitNeuro's scheduled housekeeper agent covers this; consider expanding its checklist coverage.

### Medium Priority (valuable but not urgent)

4. **Session Transcripts** -- OpenClaw stores full session history as JSONL. JitNeuro sessions are markdown checkpoints. The /conversation-log command is already in the command list; consider making structured session logging default-on for audit and replay.

5. **Curated Skills Sharing** -- OpenClaw's ClawHub enables community contribution at scale. JitNeuro could publish command and rule templates as a reviewed collection. Quality over quantity -- avoid the supply-chain risks ClawHub has encountered.

6. **Guided Persona Evolution** -- OpenClaw agents can modify their own SOUL.md. JitNeuro personas are static. The /learn command could propose persona refinements based on session patterns, subject to owner approval.

### Low Priority (interesting but different scope)

7. **Multi-LLM Support** -- Not relevant while JitNeuro is Claude Code-specific, but if Claude Code ever supports multiple model backends, the framework should be model-agnostic.

8. **Messaging Platform Interface** -- Outside JitNeuro's scope. The CLI-first approach is a feature, not a limitation, for the target audience.

### What NOT to Adopt from OpenClaw

- **Broad default filesystem access** -- OpenClaw's permissive default permissions contributed to critical CVEs. JitNeuro's Trust Zones are the correct approach.
- **Unreviewed skills marketplace** -- ClawHub's high malicious-skill and vulnerability rates prove that community contribution without review is dangerous. If JitNeuro adds community sharing, gate it with review.
- **Mutable identity without guardrails** -- Allowing agents to modify their own SOUL.md creates attack vectors for prompt injection persistence. JitNeuro's approach (owner controls identity, AI proposes via /learn) is safer.
- **Runtime daemon architecture** -- Adding a background process would increase JitNeuro's attack surface and complexity. The markdown-only approach is a security advantage.

### Security Lessons from OpenClaw's CVE History

OpenClaw's security history is instructive:
- **CVE-2026-25253** (CVSS 8.8): Control UI accepted unvalidated gateway URLs, leaking auth tokens. Widespread exposure, high authentication bypass rate.
- **CVE-2026-22175**: Exec approval bypass via unrecognized shell wrappers (busybox, toybox).
- **ClawHub supply chain**: A significant fraction of community skills contained exploitable vulnerabilities or malicious payloads.
- Stored LLM API credentials exposed on public-facing cloud servers at scale.

JitNeuro's architecture (pure markdown config, no daemon, no network listener, no marketplace) inherently avoids these attack vectors. This is a meaningful differentiator for security-conscious adopters.

---

## Summary

| Dimension | OpenClaw | JitNeuro |
|-----------|----------|----------|
| **Scope** | General AI assistant | Claude Code enhancement |
| **Architecture** | Agent runtime (daemon) | Configuration framework (markdown) |
| **Security** | Multiple critical CVEs; permissive defaults | Zero attack surface by design; Trust Zones |
| **Memory** | Semantic search + bootstrap files | Layered markdown + routing weights |
| **Autonomy** | Cron + heartbeat + sub-agents (daemon) | Scheduled housekeeper + AFK pattern + hooks |
| **Enterprise** | Minimal governance | Trust zones, decision frameworks, audit trails |
| **Cognition** | Single SOUL.md personality | 16 personas, 4 decision models, friction detection |
| **Community** | Large, active, third-party ecosystem | Author-maintained, focused on quality |

OpenClaw and JitNeuro are complementary rather than competitive. OpenClaw is a broad AI assistant platform with a large community and rich integrations. JitNeuro is a focused, security-first enhancement layer for Claude Code with enterprise-grade cognitive frameworks. The primary opportunities for JitNeuro are: semantic memory search, richer scheduled autonomy, and curated community sharing -- all implementable without compromising the framework's zero-runtime-dependency security model.
