# JitNeuro Feature Requests

## FR-001: Scheduled Task Agent
**Priority:** High
**Status:** Idea

Light local agent (Node or PowerShell) that:
- Reads a todo list (markdown or JSON)
- Kicks off Claude Code sessions via JitNeuro with the right bundles
- Runs on a schedule (cron/Task Scheduler)
- Each task gets its own session-state checkpoint
- Reports results back to the todo list (pass/fail/needs-owner)

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
**Status:** Published
**Published URL:** https://www.jitai.co/sage/jitneuro-deep-dive-ai-coding-assistant-brain/

Thought leadership blog post. Not a product announcement -- a problem statement every developer relates to.

Outline:
- The universal problem: context limits, memory loss, /clear kills everything
- The journey: months of iteration since Claude Code and Cursor first launched
- What doesn't work: giant CLAUDE.md files, manual reload, hoping for the best
- The framework: neural network metaphor (weights, layers, attention, checkpoints)
- The solution: JitNeuro -- bundles, routing weights, save/load, sessions
- Live example: managing 16 repos, 6 concurrent sessions
- Link to GitHub repo at the end

Publish on your blog, cross-post to Dev.to, share on LinkedIn with video.
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
**Status:** Done (v0.1.1), Enhanced (v0.2.1) -- Hub.md drift/staleness checks, rules line budget, detail-index sync, runs in subagent

Standalone memory system diagnostic extracted from /learn. Checks MEMORY.md line count,
bundle sizes, engram coverage, stale sessions, routing integrity, manifest sync.
v0.2.1: Added Hub.md age/drift/completeness checks, rules total line budget (400/600),
detail-index orphan/unindexed detection. All data gathering dispatched to subagent
to prevent MemoryExhaustion. Read-only by default, fixes only with approval.

## FR-007: /enterprise Command (Governance Quick-Reference)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to .claude/commands/enterprise.md

Consolidated view of all DOE governance rules: trust zones, approval workflow,
quality gates (pre/post execution), cross-repo protocol, branch rules, file versioning.
Read-only overlay with optional deep-dive into holistic review docs. Useful before
sprints, during onboarding, or when planning cross-repo changes.

## FR-008: /status Command (Where Am I)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to .claude/commands/status.md

Quick context snapshot: current branch per repo, dirty files, active sprint,
last commit, what bundle is loaded. Answers "where was I" in 5 seconds.

## FR-009: /dashboard Command (NEEDS OWNER Aggregator)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to .claude/commands/dashboard.md

Aggregate all NEEDS OWNER items from active-work bundle, hub.md files across repos,
and pending approvals. Single prioritized list so the owner can triage in one view.

## FR-010: /audit Command (Repo Hygiene)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to .claude/commands/audit.md

Scan repos for .env leaks, stale branches, uncommitted work, broken .gitignore,
missing CLAUDE.md, missing engrams. Security + hygiene in one pass.

## FR-011: /bundle Command (On-Demand Context Loading)
**Priority:** Low
**Status:** Done (v0.1.1) -- deployed to .claude/commands/bundle.md

Explicit bundle loading: `/bundle blog` loads blog.md into context. Useful when
routing weights don't auto-trigger and user knows what they need.

## FR-012: /onboard Command (New Repo Bootstrap)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to .claude/commands/onboard.md

Generate CLAUDE.md + engram + brainstem for a new repo from its codebase.
Analyzes package.json, folder structure, git history to auto-populate identity,
tech stack, key files, and integration points.

## FR-019: /gitstatus Command (Cross-Repo Git Comparison)
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to .claude/commands/gitstatus.md

Cross-repo git status showing local vs uat vs main for every active repo.
One table showing: current branch, dirty files, commits ahead/behind between
branches, last commit message. Flags issues (dirty on main, diverged branches).
Supports filters: `/gitstatus dirty`, `/gitstatus behind`.

## FR-020: /diff Command (Repo Change Summary)
**Priority:** Medium
**Status:** Done (v0.1.1) -- deployed to .claude/commands/diff.md

Show what changed in a repo since last push or since diverging from main.
Formatted for quick review before push or PR. Shows commit log, stat summary,
uncommitted changes.

## FR-014: PreCompact Save Hook
**Priority:** High
**Status:** Done (v0.1.1) -- deployed to .claude/hooks/pre-compact-save.sh

Claude Code hook that fires before context compaction. Prompts Claude to offer
/save so session state is checkpointed before context gets compressed.

Configurable behavior via jitneuro.json:
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
   Log every tool call to .logs/audit-{date}.md. Async so zero latency impact.
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
| * | main | RED (ask owner) | owner |
| * | uat | GREEN (push freely) | auto |
| * | sprint-* | GREEN (push freely) | auto |
| * | hotfix-* | YELLOW (push, report) | auto |
| jitai | prod | RED (ask owner) | owner |
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

## FR-021: Customizable Assistant and User Names
**Priority:** Medium
**Status:** Idea

Let users name their JitNeuro assistant and set their own display name.
Defaults to generic ("the assistant" / "the user") if not configured.

Configuration in CLAUDE.md or context-manifest.md:
```
## Identity
- assistant_name: Neuro     # or Jit, or whatever the user wants
- user_name: Owner           # used in session state, predictions, anti-patterns
```

Why this matters:
- Makes the framework feel personal, not generic
- Prediction rules and anti-patterns read more naturally with a name
- Users can pick a name that fits their team culture
- Default assistant name (if we pick one) becomes part of the brand

Candidate default names:
- **Neuro** -- clean, directly from JitNeuro, professional
- **Jit** -- short, punchy, casual ("Hey Jit, load the deploy bundle")
- None -- let users choose, no default persona name

Ties into FR-103 (Persona Weights) -- the name is part of the persona config.

## FR-022: Artwork and Logo
**Priority:** Low (post-launch)
**Status:** Idea

Create visual identity for JitNeuro:
- Text wordmark or minimal icon for GitHub avatar and README header
- Favicon for landing page (when built)
- Monospace/developer aesthetic, dark theme friendly
- Simple enough to work as a 64x64 GitHub avatar

Options: generate in Lovable with landing page, or commission separately.
Not a launch blocker -- many respected dev tools ship text-only.

## FR-024: Subagent-Based Command Execution
**Priority:** High
**Status:** Done (v0.2.1) -- /health, /audit, /gitstatus, /learn (Step 0), /onboard all dispatch data gathering to subagents

Commands that read 25+ files now dispatch data gathering to a subagent to prevent MemoryExhaustion crashes. Master receives only a summary table, then handles fix approval and execution. Motivated by two crashes in two days during 89-file memory audit.

## FR-025: Deploy Monitoring (Auto-Detect + Monitor After Every Push)
**Priority:** High
**Status:** Done (v0.2.1) -- templates/rules/deploy-monitoring.md

After any `git push` (any branch), automatically spawns a background subagent to monitor the CI/CD pipeline. Auto-detects deploy method from repo config files (GitHub Actions, Vercel, Azure Pipelines, etc.). Displays results in ASCII box. Supports CLAUDE.md `## Deployment` override for custom CI/CD. 12 provider reference table for customization.

## FR-026: Pending Questions Queue
**Priority:** High
**Status:** Done (v0.2.1) -- templates/rules/pending-questions.md

Tracks unanswered questions during a session. Surfaces them at the end of every response. Persists to Hub.md on /save. Reloads on /load. Connects to subagent communication protocol (BLOCKED agents become visible questions for the user).

## FR-027: Memory Detail-Index Pattern
**Priority:** High
**Status:** Done (v0.2.1) -- templates/memory/detail-index.md, templates/memory/README.md

MEMORY.md gets one pointer line to detail-index.md instead of one line per feedback/project/reference file. Saved 78 lines in a real deployment. Documented in docs/memory-maintenance.md with 5 remediation strategies for MEMORY.md overflow.

## FR-028: Feedback Classification (Personal vs Publishable)
**Priority:** Medium
**Status:** Done (v0.2.1) -- docs/feedback-classification.md

Decision tree for /learn to classify feedback as personal (stays in memory/) vs publishable (jitneuro feature request). Includes auto-submit flow via `gh issue create` with structured issue template. Enables jitneuro to self-improve from daily usage.

## FR-029: Ralph Headless + Named Terminal Integration
**Priority:** High
**Status:** Done (v0.2.1) -- docs/ralph-integration.md

Verified `ralph-tui run --headless --no-setup --prd prd.json` works for Claude Code automation. Documented 4 launch modes (TUI automated, headless, parallel, headless+parallel). Claude Code can launch ralph in named Windows Terminal tabs (`wt new-tab --title`) or tmux sessions that auto-close on completion.

## FR-030: Subagent Communication Protocol
**Priority:** High
**Status:** Done (v0.2.1) -- docs/multi-agent-orchestration-01.md

Structured return schema (OK/BLOCKED/PARTIAL) for subagent-to-master communication. SendMessage relay for continuing BLOCKED agents. Dashboard JSON integration for real-time agent status. Connects to pending questions queue for user escalation.

## FR-031: Terminal Best Practices Documentation
**Priority:** Medium
**Status:** Done (v0.2.1) -- docs/terminal-best-practices.md

Multi-session workflow guide: 5 layout options with ASCII diagrams, Windows Terminal / tmux / VS Code comparison, CPU and resource management (per-session costs, hardware guidelines, WSL2 optimization), ralph launch patterns from Claude Code. Covers the "how to actually use multi-agent in practice" gap.

## FR-032: Hub.md Mandatory Sync on /save
**Priority:** High
**Status:** Done (v0.2.1) -- templates/commands/session.md

Fixed bug where /save didn't update Hub.md despite template instructions. Hub.md sync now mandatory step with verification output. Stale Hub.md flagged in /session status and /session dashboard. Documented as #1 reliability issue in the template.

## FR-033: Rule Templates (Enterprise)
**Priority:** High
**Status:** Done (v0.2.1) -- 7 new templates in templates/rules/

New rule templates shipped: context-safety, security-guardrails, proactive-quality, code-reuse, deploy-monitoring, pending-questions, plus 5 remediation strategies in memory-maintenance.md. All generic, no owner-specific content.

---

# Possible Integrations

Future optional integrations -- not planned, just noted for consideration:

- GitHub Issues/Projects for task routing (replacing HUB.md pattern). /dashboard could read from GitHub instead of scanning .HUB/ files across repos.
- Investigate WSL requirement on Windows: do hooks work with Git Bash alone, or is WSL truly required for full functionality at scale? Test: stat command (GNU vs BSD), jq availability, async hooks, path resolution. Goal: document minimum requirements and ideally make hooks portable without WSL.
- beads-rust (br CLI) for sprint task management alongside ralph-tui.
- MCP server for exposing JitNeuro memory to external tools.

---

# Phase 2: Decision Frameworks

Phase 1 (v0.1.x) solves memory -- what to know and when to load it.
Phase 2 adds structured decision-making patterns -- teaching Claude not just
your project context, but your preferences and workflows.

Current guardrails (trust zones, approval workflows, critical rules) are the
simplest form of this: hard-coded decision boundaries. Phase 2 extends this
into reusable decision frameworks, prediction rules, and learned constraints.

Note: The neural network metaphor below is a conceptual analogy for organizing
these patterns, not a claim about actual neural network implementation.

## FR-100: Decision Models
**Priority:** High
**Status:** Phase 2 Design

**Core schema (from pre-compact hook failure, 2026-03-10):**
Every agent directive should have four components:
- **Goal:** what outcomes we are looking for
- **Guardrails:** what the agent should NOT do to accomplish the task
- **Clarification:** under what circumstances it should stop and ask
- **OverridingRule:** if goal and guardrails conflict, guardrails always win

This schema applies to CLAUDE.md brainstems, slash command instructions,
agent dispatch, and sprint stories. Concrete design TBD in Phase 2.

A new file type: `.claude/cognition/decisions/`

Decision models are structured frameworks that Claude applies when evaluating
choices. They encode the user's actual decision-making patterns -- not generic
best practices, but how THIS user thinks.

Example file: `build-vs-skip.md`
```
When evaluating whether to build a feature:
1. MINIMUM VIABLE: What's the absolute minimum? If Phase 1 hasn't proven need, skip Phase 2.
2. AI LEVERAGE: Can AI do this? If yes, build it. If it requires human judgment, flag.
3. MEASURABLE: Can we measure success? No metric = no build.
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
- "When the user finishes API stories, they always deploy to uat next"
- "After a sprint review, the user always asks for the push approval checklist"
- "When the user says 'what's next', check active-work bundle before answering"
- "After fixing a bug, the user runs tests then commits -- anticipate the commit step"

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
- Never push to main without approval
- Never use emojis unless requested
- Never claim "missing" without full codebase search
- Always fetch before push

Phase 2 adds:
- Structured format with the correction that triggered each anti-pattern
- Severity levels (hard stop vs soft warning)
- Context scoping (anti-pattern applies to specific repos or domains)
- /learn automatically proposes new anti-patterns when user corrects Claude

Format:
```
| Anti-Pattern | Severity | Scope | Trigger |
|---|---|---|---|
| Never skip tests before commit | Hard | all repos | User corrected after broken deploy |
| Always fetch before push | Hard | all repos | User's standing preference |
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
- Sprint execution -> Task runner (fast, autonomous, follow the spec)
- Content creation -> Technical writer (clear, structured, SEO-aware)
- Bug investigation -> Reliability engineer (fail-fast, root cause, evidence)
- Code review -> Security engineer (OWASP-aware, defensive patterns)

Each persona includes:
- Voice/tone description
- Decision bias (conservative vs aggressive, speed vs safety)
- Key phrases and vocabulary to use or avoid
- Which bundles/engrams to auto-load

Loaded by /orchestrate based on task classification. User can override
("use the architect voice for this").

## FR-104: Enhanced /learn (Decision Pattern Capture)
**Priority:** High
**Status:** Phase 2 Design

Extends /learn to capture decision patterns, not just facts:
- "User overrode my recommendation" -> extract the decision framework, propose decision model update
- "User asked for X before I suggested it" -> propose prediction rule
- "User said never do Y" -> propose anti-pattern entry
- "User chose option A over B" -> analyze what framework drove the choice, update persona weights
- "User corrected my tone/approach" -> update persona for that task type

Output adds a "Cognitive Updates" section to the /learn table:
```
| # | Type | File | Change | Reason |
|---|------|------|--------|--------|
| 7 | Decision | decisions/build-vs-skip.md | Add "check existing code first" | User corrected duplicate utility |
| 8 | Prediction | predictions.md | Add "after sprint -> deploy uat" | Observed 3 times |
| 9 | Anti-Pattern | anti-patterns.md | Add "always run tests first" | User corrected |
```

## FR-023: Autosave Toggle
**Priority:** Low
**Status:** Idea

Add a config switch to disable the SessionEnd _autosave hook. Some users may not
want the breadcrumb file written on every session exit. Config in jitneuro.json:
```json
{ "autosave": false }
```
When disabled, the SessionEnd hook skips writing _autosave.md entirely.
Default: enabled (current behavior).

---

## FR-105: Autonomous Orchestration
**Priority:** High (next release)
**Status:** In Progress -- foundation shipped in v0.2.1 (subagent protocol, deploy monitoring, ralph CLI, dashboard JSON, pending questions). Remaining: scheduled execution, event-driven triggers, cross-session spawn API.

Letting Claude drive the discussions with full autonomous orchestration, including
running Claude from schedulers and spawning sessions from other sessions.

### Vision

Today, JitNeuro gives Claude persistent memory and cognitive frameworks. But every
session still requires a human to start it. FR-105 removes that constraint --
Claude sessions can be triggered by events, schedules, and other sessions.

### Capabilities

**Scheduled execution:**
- Scheduled /learn runs (daily memory health, weekly engram updates)
- Nightly /audit across all repos (security scan, stale branch detection)
- Weekly /health reports delivered to a dashboard or notification channel

**Event-driven sessions:**
- Git push triggers /diff analysis on the changed repo
- CI/CD failure triggers root-cause-analysis session with full context
- Webhook fires and Claude auto-starts to handle it (support ticket, deployment alert)

**Cross-session orchestration:**
- Active session spawns background research sessions (parallel investigation)
- Automated sprint kickoff (scheduler triggers execution with prepared task list)
- Cross-session task delegation (session A assigns work to session B with full context)

**Session-to-session communication:**
- Sessions can read each other's state via session-state files (already works)
- Sessions can write tasks to shared pending queues (already works via /task)
- NEW: Sessions can spawn new sessions with specific commands and context injection

### Architecture Requirements

- Claude Code CLI headless mode (no interactive terminal required)
- Session spawn API (programmatic session creation with context injection)
- Credential passthrough (spawned sessions inherit auth from parent/scheduler)
- Audit trail for all autonomous actions (who spawned what, when, why)
- Trust zone inheritance: autonomous sessions inherit the trust zone of the
  scheduler/parent, not an elevated zone. A cron job gets GREEN zone, not RED.

### Security Model

- Autonomous sessions CANNOT escalate trust zones (cron job stays GREEN)
- All autonomous actions are logged with source (scheduler name, parent session ID)
- RED zone actions (push to main, production deploy) are NEVER autonomous
- Kill switch: any session can be stopped by the user at any time
- Rate limiting: autonomous sessions have a configurable action-per-hour cap

### Integration Points

- Scheduler backends: cron, n8n, GitHub Actions, ADO Pipelines
- Notification targets: Slack, email, dashboard, session-state files
- Context injection: bundles, engrams, and session state passed at spawn time
- Result collection: spawned sessions write results to a shared location

### Dependencies

- Phase 2 cognition layer shipped (personas, decisions, anti-patterns, friction detection)
- /task command operational (cross-session task delegation)
- Session state system stable (cross-session communication via files)
- Claude Code CLI supports headless invocation

## FR-106: Modular Component Setup (Install/Uninstall by Feature)
**Priority:** Medium
**Status:** Idea -- community feedback requested

Today JitNeuro installs everything: 17 commands, 9 hooks, dashboard, cognition layer, rules, scripts. Some users may want a subset -- lightweight session management without the dashboard, or commands without the cognition layer.

### Context (from v0.3.0 development)

Performance benchmarking showed dashboard hooks (heartbeat, agent-register, agent-complete) add ~60s of wall time across a 200-tool-call session on Windows. This is non-blocking and invisible to the user, but some teams on constrained environments may prefer to opt out of dashboard tracking while keeping session management and branch protection.

Currently the workaround is manual: edit settings.local.json to remove specific hook entries. This works but isn't discoverable.

### Proposed Components

| Component | Includes | Default |
|-----------|----------|---------|
| Commands | 17 slash commands + 5 shortcuts | ON |
| Session management | save/load hooks (session-start, session-end, pre-compact) | ON |
| Branch protection | PreToolUse(Bash) hook | ON |
| Dashboard + agent tracking | 3 hooks (heartbeat, pre-agent-register, post-agent-complete) + server.js + dashboard.html | ON |
| Cognition layer | Personas, anti-patterns, decision models, owner-persona | ON |
| Rules templates | 8+ rule files for common patterns | ON |
| Cursor integration | .mdc rules for Cursor IDE | OFF (opt-in) |

### UX Options

**Option A: Interactive installer** -- installer prompts "Enable dashboard? [Y/n]" for each component.

**Option B: Feature flags in jitneuro.json** -- `"features": { "dashboard": true, "cognition": true }` and hooks/files are installed based on flags.

**Option C: /setup command** -- Claude Code reads jitneuro.json flags, adds/removes hooks and files, reports what changed.

**Option D: Per-feature install/uninstall commands** -- `/dashboard install`, `/dashboard uninstall`, `/cognition install`, etc.

### Community Input Welcome

If this feature would be valuable to you, comment on the issue with:
- Which components you would disable and why
- Whether you prefer interactive installer, feature flags, or per-command install/uninstall
- Your environment (team size, OS, constrained hardware?)

## FR-108: Cold Start Routing -- Auto-Discover Dependencies at Install
**Priority:** High
**Status:** Idea -- design needed

JitNeuro's routing weights require time to build up via /learn. New adopters start with empty routing and must manually /bundle load context. Semantic search frameworks solve this by embedding everything -- but at the cost of heavy dependencies.

**Better approach:** Scan repos at install/onboard time and auto-generate routing weights from what's already in the code.

### What to Scan

| Source | What it reveals | Example |
|--------|----------------|---------|
| `.env` files | Service dependencies | `AUTH_API_URL=https://auth.example.com` -> links to auth service |
| `package.json` dependencies | Tech stack | `express`, `firebase-admin`, `stripe` -> load API, auth, payments bundles |
| Import statements | Cross-repo references | `import { auth } from '../AuthFirebase'` -> repo dependency |
| `docker-compose.yml` | Service graph | `depends_on: [api, redis]` -> infrastructure bundle |
| API endpoint definitions | Integration points | Routes referencing external services |
| `CLAUDE.md` / `README.md` | Project identity | Tech stack, purpose, key paths |
| `.env.*.example` files | Environment configs | Which services per environment |

### How It Works

```
/onboard <repo>
  1. Scan the repo for dependency signals (above table)
  2. Generate initial routing weights: keyword -> bundle mappings
  3. Generate initial engram: tech stack, key files, architecture
  4. Write to .claude/context-manifest.md (or .jitneuro/ in team mode)
  5. Present to user: "I found these dependencies. Correct?"
```

For workspace-level install:
```
install.sh --scan-repos
  1. For each repo under workspace: run the dependency scan
  2. Build a cross-repo integration map
  3. Generate routing weights that include cross-repo patterns
  4. Example: "auth" -> [api-patterns, auth-service engram]
```

### Cross-Repo Discovery

The real power: scanning ACROSS repos reveals the integration graph.
- Repo A's .env references Repo B's URL -> A depends on B
- Repo B's package.json has firebase-admin -> B is the auth service
- Repo C's imports reference Repo A's API client -> C is a frontend for A

This graph becomes routing weights automatically:
```
- auth / login / token         -> [auth-service engram, api-patterns]
- payments / stripe / subscribe -> [payments engram, api-patterns]
- frontend / app / UI          -> [frontend engram, api-patterns]
```

### Keeps Getting Better

Initial scan provides day-1 routing. /learn refines it over time. The cold start is solved without semantic search, without embeddings, without any external dependency.

### Commands

- `/onboard <repo>` -- already exists, add dependency scanning
- `/onboard --scan-all` -- scan all repos in workspace
- `/verify --routing` -- verify routing weights match current repo state (detect drift)

### Community Input Welcome

- What dependency signals does your stack expose? (package.json, go.mod, requirements.txt, etc.)
- Would you trust auto-generated routing weights or want to review first?
- Should the scan run on every /verify or only on /onboard?

## FR-109: Auto-Learn (Intentionally Rejected)
**Priority:** N/A
**Status:** Rejected by design

Auto-learn would run /learn automatically after every session (or on a schedule) without owner approval. This has been evaluated and intentionally rejected.

**Why not:**
- **Precision at risk.** A wrong correction becomes a permanent rule. Wrong rules load wrong context. Wrong context produces more wrong corrections. The feedback loop compounds in the wrong direction.
- **Security at risk.** A misclassified lesson could weaken a security guardrail, relax a trust zone, or change an approval workflow without the owner noticing.
- **Performance at risk.** Bad routing weights load irrelevant bundles, wasting tokens and degrading Claude's reasoning quality.
- **The system's value IS the approval gate.** /learn proposes. Owner decides. That 30-second review prevents weeks of drift.

**What we do instead:**
- Lessons stage to Hub.md in real-time (crash-safe, zero overhead)
- /learn presents a table with recommendations (Owner corrects if needed)
- Housekeeper agent reminds to run /learn (but never runs it automatically)
- The approval step IS the quality control

**The deeper point:** AI is not perfect. The rules and routing weights that govern how Claude thinks about YOUR projects are too important to leave to AI 100%. Human judgment at the /learn approval step is not overhead -- it's the quality control that makes the entire system trustworthy.

If you think auto-learn should be reconsidered, open an issue with a specific use case where the approval gate adds friction without value.

## FR-107: Effort Level Inheritance for Subagents
**Priority:** Low
**Status:** Idea -- community feedback requested

Currently, subagents inherit the master's `effortLevel` setting. This means a high-effort master spawns high-effort workers, even when the worker's task is simple (file lookup, grep, score one item).

### Question

Should JitNeuro add rules that adjust effort level based on agent type?

| Agent Type | Current (inherited) | Proposed |
|-----------|-------------------|----------|
| Explore / lookup | Master's level | Low (always -- focused, scoped) |
| Plan / discovery / analysis | Master's level | Inherit master (these need depth) |
| Workers (batch) | Master's level | Low-medium (focused single task) |
| Sub-orchestrator | Master's level | Low (routing only, no deep thinking) |
| Housekeeper / enforcer | Master's level | Low (quick checks, not analysis) |

This parallels the divergent thinking inheritance model (divergent-thinking.md) where some agent types inherit the mode and others are always serial.

### Tradeoffs

**Keep inheritance (current):**
- Simple. No new rules. Master controls everything.
- If master is on high effort, all work gets thorough treatment.

**Add type-based rules:**
- Token savings: low-effort workers use fewer tokens per task.
- Speed: batch operations with 10 workers finish faster at low effort.
- Risk: a worker that needed high effort but got low might miss something.

### Community Input Welcome

- Do you notice token/speed differences between effort levels in subagents?
- Would you want per-agent effort control, or is master inheritance sufficient?
- Should this be configurable in jitneuro.json or automatic based on agent type?

---

## Neural Network Mapping (Phase 2 -- Conceptual Analogy)

| Neural Network | Phase 1 (Memory) | Phase 2 (Decision Frameworks) |
|---|---|---|
| Weights | MEMORY.md routing | Decision models (how to choose) |
| Layers | Bundles (domain knowledge) | Personas (expert voices) |
| Attention | Routing weights | Prediction rules (anticipation) |
| Inhibition | Guardrails (hard stops) | Anti-patterns (learned constraints) |
| Backpropagation | /learn (facts) | /learn v2 (cognitive patterns) |
| Transfer learning | Cross-project engrams | Cross-domain decision models |
