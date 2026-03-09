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
