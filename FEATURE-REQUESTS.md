# JitNeuro Feature Requests

## FR-001: Scheduled Task Agent
**Priority:** High
**Status:** Idea

Light local agent (Node or PowerShell) that:
- Reads a todo list (markdown or JSON)
- Kicks off Claude Code sessions via JitNeuro with the right bundles
- Runs on a schedule (cron/Task Scheduler)
- Each task gets its own session-state checkpoint
- Reports results back to the todo list (pass/fail/needs-Dan)

Use cases:
- Nightly code reviews across repos
- Scheduled blog drafts from content calendar
- Automated context file refresh (DOE spec freshness check)
- Sprint story pre-validation before Ralph runs
- Morning briefing: scan all active-work, summarize what needs attention

Architecture: minimal -- reads list, shells out to `claude` CLI with bundled context, captures output, updates list. No server, no API, no database.

## FR-002: Save Template Document
**Priority:** Medium
**Status:** Idea

Provide a structured template that Claude fills in when running /save, rather than
relying entirely on Claude's judgment. Ensures consistent format across saves and
makes /load parsing reliable. Template would define required sections (task, repos,
bundles, modified files, decisions, next steps) with placeholder prompts.

## FR-003: Blog Post -- "How to Get AI Coding Assistants to Actually Remember"
**Priority:** High (launch day)
**Status:** Planned

Thought leadership piece on jitai.co. Not a product announcement -- a problem statement every developer relates to.

Outline:
- The universal problem: context limits, memory loss, /clear kills everything
- The journey: months of iteration since Claude Code and Cursor first launched
- What doesn't work: giant CLAUDE.md files, manual reload, hoping for the best
- The framework: neural network metaphor (weights, layers, attention, checkpoints)
- The solution: JitNeuro -- bundles, routing weights, save/load, sessions
- Live example: managing 16 repos, 6 concurrent sessions
- Link to GitHub repo at the end

Publish on jitai.co, cross-post to Dev.to, share on LinkedIn with video.
Record walkthrough video using QUICKSTART.md as the demo script.

## FR-004: Install Command (/install)
**Priority:** Medium
**Status:** Idea

Slash command to install JitNeuro into a new repo from an existing workspace session.
Chicken-and-egg: can't install itself (need commands to run commands), but useful for
expanding into new repos when JitNeuro is already running at workspace or user level.
`/install` would create `.claude/` structure, copy templates, set up brainstem.

## FR-005: Landing Page (jitneuro.ai)
**Priority:** High (launch day)
**Status:** Planned

Build with Lovable. Hero, problem/solution, architecture diagram, context budget,
enterprise features, get started CTA to GitHub. Deploy to Vercel. See LAUNCH-TODO.md.

## FR-006: /health Command (Standalone Diagnostic)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\health.md

Standalone memory system diagnostic extracted from /learn. Checks MEMORY.md line count,
bundle sizes, engram coverage, stale sessions, routing integrity, manifest sync.
Read-only by default, fixes only with approval. Faster than /learn when you just
want a quick system check without evaluating session learnings.

## FR-007: /enterprise Command (Governance Quick-Reference)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\enterprise.md

Consolidated view of all DOE governance rules: trust zones, approval workflow,
quality gates (pre/post execution), cross-repo protocol, branch rules, file versioning.
Read-only overlay with optional deep-dive into holistic review docs. Useful before
sprints, during onboarding, or when planning cross-repo changes.

## FR-008: /status Command (Where Am I)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\status.md

Quick context snapshot: current branch per repo, dirty files, active sprint,
last commit, what bundle is loaded. Answers "where was I" in 5 seconds.

## FR-009: /dashboard Command (NEEDS DAN Aggregator)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\dashboard.md

Aggregate all NEEDS DAN items from active-work bundle, hub.md files across repos,
and pending approvals. Single prioritized list so Dan can triage in one view.

## FR-010: /audit Command (Repo Hygiene)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\audit.md

Scan repos for .env leaks, stale branches, uncommitted work, broken .gitignore,
missing CLAUDE.md, missing engrams. Security + hygiene in one pass.

## FR-011: /bundle Command (On-Demand Context Loading)
**Priority:** Low
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\bundle.md

Explicit bundle loading: `/bundle blog` loads blog.md into context. Useful when
routing weights don't auto-trigger and user knows what they need.

## FR-012: /onboard Command (New Repo Bootstrap)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\onboard.md

Generate CLAUDE.md + engram + brainstem for a new repo from its codebase.
Analyzes package.json, folder structure, git history to auto-populate identity,
tech stack, key files, and integration points.

## FR-019: /gitstatus Command (Cross-Repo Git Comparison)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\gitstatus.md

Cross-repo git status showing local vs uat vs main for every active repo.
One table showing: current branch, dirty files, commits ahead/behind between
branches, last commit message. Flags issues (dirty on main, diverged branches).
Supports filters: `/gitstatus dirty`, `/gitstatus behind`.

## FR-020: /diff Command (Repo Change Summary)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\commands\diff.md

Show what changed in a repo since last push or since diverging from main.
Formatted for quick review before push or PR. Shows commit log, stat summary,
uncommitted changes.

## FR-014: PreCompact Save Hook
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to D:\Code\.claude\hooks\pre-compact-save.sh

Claude Code hook that fires before context compaction. Prompts Claude to offer
/save so session state is checkpointed before context gets compressed.

Configurable behavior via jitneuro-hooks.json:
- `warn` (default): message injected, compaction proceeds, Claude asks about /save
- `block`: compaction blocked until user responds

Limitation: hooks cannot read context % directly. PreCompact fires when Claude
Code decides to compact (effectively "context is full"). The hook IS the threshold.

Future: if Claude Code exposes context % in hook input JSON, add configurable
threshold (e.g., fire at 90% instead of waiting for compaction trigger).

## FR-015: Tier 1 Hooks (SessionStart Recovery, Branch Protection, Auto-Save)
**Priority:** High
**Status:** Done (v0.1.1)

Three additional hooks deployed alongside FR-014:

1. **Post-Compact Context Recovery** (SessionStart, matcher: "compact")
   Re-injects most recent session state into Claude's context after compaction.
   Restores: active task, loaded bundles, modified files, next steps.

2. **Branch Protection** (PreToolUse, matcher: "Bash")
   Blocks RED zone git operations programmatically:
   - git push to main/master
   - git push --force (any branch)
   - git branch -D (force delete)
   - git reset --hard
   Exit code 2 blocks the command and tells Claude why.

3. **Session End Auto-Save** (SessionEnd)
   Safety net breadcrumb when session terminates. Writes timestamp, exit reason,
   duration, working directory to _autosave.md. Not a full /save -- just confirms
   a session was active if user forgot to checkpoint.

## FR-017: Tier 2 Hooks (Subagent Injection, Quality Gate, Audit Trail)
**Priority:** Medium
**Status:** Planned

1. **Subagent Bundle Injection** (SubagentStart)
   Auto-inject relevant bundle content into subagent context via additionalContext.
   Subagents currently start blind -- this gives them domain knowledge automatically.
   Could use routing weights to determine which bundles match the subagent's task.

2. **Quality Gate on Stop** (Stop, agent type hook)
   After Claude finishes responding, spawn an agent to verify:
   - tsc --noEmit passes (TypeScript repos)
   - Tests pass (if test suite exists)
   - No console.logs left in production code
   Returns ok: false with reason if anything fails, causing Claude to fix issues.
   Must check stop_hook_active to prevent infinite loops.

3. **Async Audit Trail** (PostToolUse, async)
   Log every tool call to .logs/audit-YYYYMMDD.log. Async so zero latency impact.
   Captures: timestamp, tool name, input summary, success/failure.
   Useful for debugging "what happened in that session" after the fact.

## FR-018: Tier 3 Hooks (Prompt Router, Config Guard, Input Modifier)
**Priority:** Low
**Status:** Planned

1. **Prompt Router** (UserPromptSubmit)
   Read prompt keywords, inject routing hints for bundle loading. Could replace
   manual routing weights with automatic detection. Concern: adds latency to
   every single prompt. May be better as a prompt-type hook using Haiku.

2. **Config Guard** (ConfigChange)
   Block unauthorized settings changes. Log all config modifications to audit trail.
   Enterprise use case -- overkill for solo developer.

3. **Modified Tool Input** (PreToolUse)
   Rewrite tool arguments before execution. Examples: force --no-cache on builds,
   inject environment variables, redirect file paths. Powerful but dangerous --
   very specific use cases only.

## FR-016: Context % Threshold Alert (Depends on Claude Code API)
**Priority:** Medium
**Status:** Blocked -- waiting for Claude Code to expose context metrics in hook input

The ideal version of FR-014: fire a hook at a configurable % threshold (e.g., 90%)
BEFORE compaction is triggered. This would give the user time to /save, /clear,
or switch tasks proactively instead of reactively.

Requires Claude Code to include context usage data in hook input JSON:
```json
{
  "context_used_pct": 92,
  "context_tokens_used": 184000,
  "context_tokens_max": 200000
}
```

Until then, PreCompact (FR-014) is the best available signal.

## FR-013: Branching and Governance Rules Engine
**Priority:** High
**Status:** Phase 2 Design

Externalize branching rules, trust zones, and approval workflows into structured
config files that Claude reads and enforces programmatically.

### Problem
Currently, branching rules and governance are prose in CLAUDE.md files. This works
but has limitations:
- Rules are scattered across global, workspace, and project CLAUDE.md files
- No single source of truth for "can I push to this branch?"
- Adding a new repo means copying prose rules manually
- No way to have per-repo branch policies (some repos may allow main pushes)
- Validation is honor-system -- Claude interprets prose, not structured rules

### Proposed Design
New directory: `.claude/governance/`

**Branch policies** (`.claude/governance/branches.md` or `.yaml`):
```
| Repo | Branch | Policy | Approver |
|------|--------|--------|----------|
| * | main | RED (ask Dan) | Dan |
| * | uat | GREEN (push freely) | auto |
| * | sprint-* | GREEN (push freely) | auto |
| * | hotfix-* | YELLOW (push, report) | auto |
| jitai | prod | RED (ask Dan) | Dan |
```

**Merge policies**:
- Which branches can merge into main (only uat? only sprint-* after review?)
- Required checks before merge (tsc, tests, /enterprise review)
- Auto-delete branch after merge?

**Commit policies**:
- Max files per commit (prevent mega-commits)
- Required commit message format
- Pre-commit validation hooks

**Deployment gates**:
- Which branches trigger which environments
- Required approvals per environment
- Rollback rules

### Integration with /enterprise
The /enterprise command would read these structured rules instead of parsing
prose from multiple CLAUDE.md files. Single source of truth.

### Integration with /audit
The /audit command validates repos comply with governance rules:
- Correct branch protection settings
- No stale feature branches
- All repos have required CLAUDE.md sections

### Migration Path
1. Define governance config format
2. Extract current prose rules into config
3. Update /enterprise to read config
4. Update /audit to validate against config
5. Keep prose in CLAUDE.md as human-readable summary, config as machine-readable source

---

# Possible Integrations

Future optional integrations -- not planned, just noted for consideration:

- GitHub Issues/Projects for task routing (replacing HUB.md pattern). /dashboard could read from GitHub instead of scanning .HUB/ files across repos.
- Investigate WSL requirement on Windows: do hooks work with Git Bash alone, or is WSL truly required for full functionality at scale? Test: stat command (GNU vs BSD), jq availability, async hooks, path resolution. Goal: document minimum requirements and ideally make hooks portable without WSL.
- beads-rust (br CLI) for sprint task management alongside ralph-tui.
- MCP server for exposing JitNeuro memory to external tools.

---

# Phase 2: Cognitive Layer

Phase 1 (v0.1.0) solves memory -- what to know and when to load it.
Phase 2 solves cognition -- how to think, decide, and anticipate.

Current guardrails (trust zones, approval workflows, critical rules) are the
simplest form of this: hard-coded decision boundaries. Phase 2 extends this
into full cognitive modeling -- teaching Claude not just what you know, but
how you think.

## FR-100: Decision Models
**Priority:** High
**Status:** Phase 2 Design

A new file type: `.claude/cognition/decisions/`

Decision models are structured frameworks that Claude applies when evaluating
choices. They encode the user's actual decision-making patterns -- not generic
best practices, but how THIS user thinks.

Example file: `build-vs-skip.md`
```
When evaluating whether to build a feature:
1. MUSK DELETE: What's the absolute minimum? If Phase 1 hasn't proven need, skip Phase 2.
2. MARTELL BUYBACK: Can AI do this? If yes, build it. If it requires human judgment, flag.
3. ROBERGE NUMBERS: Can we measure success? No metric = no build.
Apply in order. If step 1 says skip, stop.
```

Decision models differ from bundles:
- Bundles = domain knowledge ("how to deploy")
- Decision models = cognitive patterns ("how to decide whether to deploy")

They also differ from guardrails:
- Guardrails = hard boundaries ("never push to main without approval")
- Decision models = soft heuristics ("when choosing between options, prefer X because...")

Loaded by /orchestrate when a decision point is detected. Updated by /learn
when the user overrides a recommendation.

## FR-101: Prediction Rules
**Priority:** Medium
**Status:** Phase 2 Design

A new section in MEMORY.md or a dedicated file: `.claude/cognition/predictions.md`

Patterns that let Claude anticipate what the user will want next, based on
observed sequences across sessions.

Examples:
- "When Dan finishes API stories, he always wants to deploy to uat next"
- "When Dan asks about pricing, he'll ask about the sales script within 2 prompts"
- "After a sprint review, Dan always asks for the push approval checklist"
- "When Dan says 'what's next', check active-work bundle before answering"

Updated by /learn when Claude observes repeated sequences. Presented to user
for confirmation before being added ("I noticed you always do X after Y. Should
I anticipate this?").

## FR-102: Anti-Patterns (Learned Constraints)
**Priority:** High
**Status:** Phase 2 Design

A new file: `.claude/cognition/anti-patterns.md`

Things Claude should NEVER do, learned from corrections. Stronger than routing
weights (which guide what to load) -- anti-patterns are hard stops.

Current examples already in guardrails:
- Never use jitai.com (always jitai.co)
- Never push to main without approval
- Never use emojis unless requested
- Never claim "missing" without full codebase search

Phase 2 adds:
- Structured format with the correction that triggered each anti-pattern
- Severity levels (hard stop vs soft warning)
- Context scoping (anti-pattern applies to specific repos or domains)
- /learn automatically proposes new anti-patterns when user corrects Claude

Format:
```
| Anti-Pattern | Severity | Scope | Trigger |
|---|---|---|---|
| Never suggest free pilot for AIBM | Hard | aibm | Dan corrected 2026-02-15 |
| Always fetch before push | Hard | all repos | Dan's standing preference |
| Don't over-engineer | Soft | all | Repeated corrections on abstractions |
```

## FR-103: Persona Weights
**Priority:** Medium
**Status:** Phase 2 Design

A new file: `.claude/cognition/personas.md`

Which expert voice to use for which type of task. Currently implicit (Claude
picks a tone), Phase 2 makes it explicit and tunable.

Examples:
- Strategy discussion -> Sr Software Architect (conservative, risk-aware)
- Sprint execution -> Ralph AFK (fast, autonomous, follow the spec)
- Sales materials -> Marketing copywriter (Dan's voice, benefit-led)
- Blog post -> Julia McCoy style (expert depth, repurposable, SEO-aware)
- Bug investigation -> Reliability engineer (fail-fast, root cause, evidence)

Each persona includes:
- Voice/tone description
- Decision bias (conservative vs aggressive, speed vs safety)
- Key phrases and vocabulary to use or avoid
- Which bundles/engrams to auto-load

Loaded by /orchestrate based on task classification. User can override
("use the architect voice for this").

## FR-104: Cognitive /learn (Backpropagation v2)
**Priority:** High
**Status:** Phase 2 Design

Extends /learn to capture cognitive patterns, not just facts:
- "Dan overrode my recommendation" -> extract the decision framework, propose decision model update
- "Dan asked for X before I suggested it" -> propose prediction rule
- "Dan said never do Y" -> propose anti-pattern entry
- "Dan chose option A over B" -> analyze what framework drove the choice, update persona weights
- "Dan corrected my tone/approach" -> update persona for that task type

Output adds a "Cognitive Updates" section to the /learn table:
```
| # | Type | File | Change | Reason |
|---|------|------|--------|--------|
| 7 | Cognitive | decisions/build-vs-skip.md | Add "check existing code first" | Dan corrected duplicate utility |
| 8 | Cognitive | predictions.md | Add "after sprint -> deploy uat" | Observed 3 times |
| 9 | Cognitive | anti-patterns.md | Add "don't suggest free pilot" | Dan corrected |
```

## Neural Network Mapping (Phase 2)

| Neural Network | Phase 1 (Memory) | Phase 2 (Cognition) |
|---|---|---|
| Weights | MEMORY.md routing | Decision models (how to choose) |
| Layers | Bundles (domain knowledge) | Personas (expert voices) |
| Attention | Routing weights | Prediction rules (anticipation) |
| Inhibition | Guardrails (hard stops) | Anti-patterns (learned constraints) |
| Backpropagation | /learn (facts) | /learn v2 (cognitive patterns) |
| Transfer learning | Cross-project engrams | Cross-domain decision models |
