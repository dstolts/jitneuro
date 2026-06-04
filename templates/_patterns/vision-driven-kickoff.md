---
type: pattern
purpose: Any principal or orchestrator beginning a strategic planning session on autonomous AI architecture MUST use this kickoff structure before any design work starts -- firing at the start of sessions focused on the autonomous AI loop or proactive-vs-reactive operation -- because skipping it produces a brainstorm without grounding inputs (mission, goals, current metrics), causing the session to generate ideas that conflict with the owner's actual vision and rediscover problems already solved in prior sessions.
read_when: Before beginning any strategic brainstorm or planning session focused on autonomous AI architecture, proactive vs reactive operation, or the owner vision-to-AI-execution alignment loop.
tags: [vision-driven-ai, proactive-ai, brainstorm-kickoff, autonomous-execution, strategic-planning]
scope: public
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Brainstorm Kickoff: Vision-Driven Proactive AI

**Mode:** STRATEGY -- discussion / planning / discovery only. No code, no schema, no migrations. Output is a plan, not an artifact set.
**Suggested divergent setting:** ALWAYS for this session (force divergent thinking on every response).

---

## Why This Pattern Exists (the pain)

A common failure mode for teams using AI assistants:

> The owner sees a problem -> tells the AI what to do -> AI executes -> owner sees the next problem -> repeat.

This is **reactive operation**. The owner is the only one carrying vision; the AI is a high-throughput tactical executor.

Technical guardrails (budget gates, runaway kills, scoped polling) fix specific failure classes. They do **not** solve the cognitive runaway:

- AI never recommends what to work on -- waits to be told.
- AI never enforces alignment to the owner's vision -- because that vision is not written down anywhere AI can read.
- AI never proactively flags risk -- only reacts when the owner asks "why did X break."
- Owner spends scarce strategic cycles on tactical routing.

## What "Vision-Driven Proactive AI" Looks Like

The end state, said simply:

> Each morning AI reads the owner's mission, current-period goals, and recent metrics, surfaces the three highest-leverage things to work on today, recommends a starting point for each, and asks the owner to approve, redirect, or defer. Owner spends ten minutes setting direction; AI spends the day executing within that direction. Through the day, AI flags drift, risk-register triggers, and cost anomalies. Owner ends the day knowing what shipped, what blocked, and what tomorrow needs.

Translated into mechanics:

1. **AI knows what the owner cares about.** Mission, vision, goals, risk register -- all written, all loadable, all referenced on every strategic decision.
2. **AI knows what good looks like per workstream.** Explicit success criteria so AI can recommend "this is done, move on" or "this is drifting, pivot."
3. **AI watches metrics autonomously.** Cost, error rates, pipeline health -- AI checks; owner does not have to ask.
4. **AI runs a daily and weekly cadence.** Morning briefing, weekly retro, monthly strategy sync -- on schedule, AI initiates, owner reviews.
5. **AI escalates to the owner only when judgment is genuinely needed.** Tier 1: AI decides and logs. Tier 2: AI proposes and auto-applies after a veto window. Tier 3: AI asks and waits.
6. **Owner becomes the strategic conscience, not the tactical operator.** Approves, redirects, vetoes.

---

## Inputs That Should Already Exist (do not re-discover)

Before running this brainstorm, confirm whether each of these exists in your repo or knowledge base. If present, load as reference; do not recreate.

| Input | What it covers |
|---|---|
| Owner identity / operating principles doc | Core values, cognitive style, how the owner prefers to receive recommendations |
| Framework spec (if one exists) | The governing orchestration spec -- how the AI system is structured and authorized to act |
| Agent charters | Roles AI can adopt, their scope, and their authority limits |
| Workspace/service registry | Structured list of running services, credentials locations, and integration endpoints |
| Per-project deep-context files | What each active workstream is, its current state, and its success criteria |

---

## Pre-existing Owner Documents (scan before authoring)

Before writing new strategic docs, scan the repository and any linked document stores for files matching these patterns:

- Vision / mission / charter / constitution / values / principles
- Goals / OKRs / targets / roadmap / priorities
- Risk register / failure modes / incident history
- Operating rhythm / cadence / daily brief format
- Success metrics / dashboard config / KPIs

**Why:** Owners often have strategic material scattered across files. Scanning is cheap. Re-authoring from scratch produces docs that conflict with existing canonical material and wastes owner time on re-discovery.

Use this table format to record what you find:

| Document | Path | Purpose (one line) | Brainstorm need satisfied | Freshness |
|---|---|---|---|---|
| (fill in) | (fill in) | (fill in) | (fill in) | (fill in) |

Identify quick-wins (existing docs that cover 70-90% of a brainstorm need) and confirmed gaps (specific docs that truly do not exist and need authoring).

---

## Documents That Almost Always Need Authoring

Working hypothesis -- the brainstorm should validate, extend, or drop items in this list:

| Document | Purpose | Estimated owner-time to author |
|---|---|---|
| Mission + vision (one-pagers) | North star; never changes; AI cites in every strategic call | 30 min owner + AI-guided |
| Decision-routing rules (Tier 1 / 2 / 3) | What AI decides vs proposes-with-veto vs escalates synchronously | 1 hour owner + AI-drafted |
| Trade-off matrix | When optimizing X (e.g. revenue) costs Y (e.g. owner time), how do we trade | 1-2 hours owner-judged, AI-structured |
| Risk register | Failure modes AI guards against autonomously | AI-drafts initial; owner adds/edits |
| Success metrics dashboard config | What numbers AI watches; thresholds that trigger surfacing | AI-drafts based on goals; owner tunes |
| Operating rhythm doc | What artifact does the owner expect when (daily brief, weekly retro, monthly strategy) | 30 min owner + AI-structured |
| "What good looks like" per active workstream | Concrete success criteria so AI knows when to push vs pause | Per-workstream, ~15 min each |
| Capital and time budget envelope (per period) | Cost ceiling + owner-attention cap; AI plans within | 30 min owner |
| Idle-cycle scheduler config | When agents are idle, what does AI propose to advance against goals | AI-drafts; owner tunes |
| Proactive-cadence agent prompts | The actual prompts the morning briefer, cost watcher, and risk monitor agents run | AI-drafts after the rest is done |

---

## Skills and Patterns Available to Leverage

Existing capabilities a vision-driven AI system can compose:

- **Divergent thinking mode** -- for strategic decisions, force ALWAYS during this brainstorm.
- **Multi-persona patterns** -- architect, security reviewer, DBA, UX designer, and others. Each is a perspective AI can adopt for a recommendation.
- **Scheduled agents** -- AI can spawn timer-driven check-ins (cost watcher, briefing agent, risk monitor are natural fits).
- **MCP servers or equivalent** -- exposing tools to agents over a structured contract; could expose mission-doc reads, metric reads, and decision-routing reads to every agent.
- **Per-project context files** -- deep context that persists across sessions; could store "what AI learned about this workstream last week."
- **Hub / decision-queue patterns** -- proven format for surfacing decisions; can extend to "morning briefing" format.
- **Skills catalog** -- audit, health, learn, divergent, schedule; some are directly applicable to a strategic loop.

---

## Brainstorm Output (what this session should produce)

A plan, not artifacts. The plan should answer:

1. **What is the MVP "vision-driven AI" loop that ships in two weeks?** Concrete: which document gets drafted first, which agent gets built, what cadence runs first, what the owner does differently next Monday morning vs today.
2. **What is the full document set needed?** Validate, extend, or drop the table above. Order of authoring (which depends on which).
3. **What is the technical infrastructure?** Reuse existing (task queue, MCP, scheduled agents) vs net-new. Where does proactive-AI logic live -- a new server, a new repo, embedded in the orchestration layer?
4. **How does owner time scale down?** Quantify: today the owner spends N hours tactical. After MVP loop, target hours? After full system, target hours?
5. **What is the rollback plan?** If proactive AI surfaces wrong priorities for three days running, how do we catch and fix?
6. **What is the cost envelope?** Proactive AI runs cost money. What is acceptable spend per day for the "AI proactively watches owner's interests" function? Anchor to API pricing, not flat-subscription math.

---

## Constraints (binding for this brainstorm)

- **STRATEGY mode only.** No code. No schema. No migrations. Output = plan markdown.
- **Must respect the owner's UX constraints** -- the owner is the consumer of the output; cognitive-load and disability-aware design rules apply.
- **Must respect cost discipline** -- proactive AI cannot become a new runaway. A runaway-kill rule and a budget gate apply to any agents it spawns.
- **Must integrate with the existing task-execution layer.** Proactive AI is the layer ABOVE that execution layer (it decides what to release/execute; the execution layer does it).
- **Must work for a solo owner today, but be expandable to a small team later.**
- **Use divergent thinking** -- for every major design choice, surface two or three approaches and tradeoffs before recommending.
- **Cite the owner's existing docs** -- do not reinvent vocabulary or principles already in the framework spec, operating principles, or behavior rules.

---

## How to Run This Session

1. Open a new clean session, launched from the root of the repository that owns AI orchestration.
2. Load this file first (read it before loading any tactical context).
3. Set divergent mode to ALWAYS.
4. Walk through the brainstorm sections in order: pain -> end-state -> documents needed -> infrastructure -> MVP -> two-week ship plan.
5. Each section: AI presents two or three framings, owner picks or redirects.
6. Output: a plan doc saved to the patterns or playbooks folder, owner-approved.
7. Plan execution becomes its own workstream (tasks get added; pieces dispatch to agents per the current pattern).

---

## Companion Reading (load as needed, not all upfront)

- The orchestration framework spec (defines scope and authority for AI agents)
- The task-execution architecture doc (the layer below; proactive AI rides on top of this)
- The autonomous-execution rule (existing autonomy framing)
- The friction-detection rule (existing reactive-correction loop)
- The owner identity and core-principles doc

---

## Closing Frame

> "We have been reactive, forever. The owner has been telling AI what to do, to solve problems. We need to flip this so AI makes recommendations that follow the owner's vision."

The flip is the work. Everything else is just steps.
