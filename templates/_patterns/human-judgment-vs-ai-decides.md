---
type: pattern
purpose: Any AI agent considering whether to act autonomously or escalate to the owner MUST apply this 3-test heuristic before surfacing any question -- firing every time an agent reaches a decision point during autonomous operation -- because skipping it causes agents to escalate trivial reversible decisions that waste owner attention, or to act autonomously on irreversible, high-stakes decisions that should have been held for human judgment.
read_when: Every time an agent reaches a decision point and must choose between acting autonomously or escalating to the owner.
tags: [escalation, human-judgment, autonomous-execution, decision-routing, owner-attention]
scope: public
departments: [all]
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Human Judgment vs AI Decides

**Status:** Active
**Cadence:** Review quarterly + update whenever a new correction fires
**How AI uses this:** MANDATORY gate on EVERY candidate open-question-to-owner. Before surfacing anything, AI checks: HUMAN JUDGMENT or AI DECIDES?

> *If AI wouldn't ask the question to a senior engineer colleague, AI doesn't ask it to the owner.*

---

## The 3-Test Heuristic

**Human decides when ANY ONE of THREE conditions is MATERIALLY true. Otherwise AI decides + logs.**

1. **Reversibility (material):** materially hard to reverse once decided -- money committed, reputation affected, public statement made, permanent infrastructure change, customer relationship shipped. NOT every-day refactor, file rename, or standard GREEN-zone migration. **Threshold: if reversing the decision would cost more than 30 minutes plus real money, reputation, or time, count it.**

2. **Blast radius (cross-boundary):** affects more than one component, product area, or stakeholder. Customer-visible impact counts. Owner-calendar impact counts. **Single component, single file, or single workflow-internal change does NOT count.**

3. **Values / strategic / identity layer:** the answer reveals the owner's preferences, voice, priorities, or identity -- what the owner personally stands for. Examples: brand tone, pricing philosophy, product prioritization, anchor framings. **Engineering conventions, naming, architecture choices within reasonable options are NOT values-layer.**

**Default = AI decides.** Escalation is the exception, triggered by any one of these risk factors being materially true.

**Calibration note:** the conditions must be MATERIALLY true, not trivially true. Most technical implementation decisions have zero of three materially true. Most strategic, money, voice, or identity decisions have at least one materially true. The "materially" qualifier is what prevents ANY-triggering from over-escalating on every choice with a whiff of a risk factor.

---

## AI-DECIDES (if tempted to ask, STOP)

- **Naming conventions** -- file names, role IDs, column names, repo names, variable names, path layouts
- **Technical architecture where multiple reasonable options exist** -- integration approach, subdirectory structure, hybrid vs monolith, service boundary placement
- **Model selection within budget** -- Haiku / Sonnet / Opus per task-complexity heuristic (Haiku = research/lookup; Sonnet = drafts/synthesis; Opus = architecture/complex reasoning)
- **Output structure** -- doc format, spec sections, section ordering, table vs list
- **Tool adoption at free tier** or within a pre-approved domain
- **Scheduling tactics** -- agent dispatch concurrency, batch sizes, cron trigger timing, polling cadence
- **File organization** -- where a new doc lives, which subfolder, sitemap structure
- **Default thresholds (tune later from data)** -- metric yellow/red cutoffs, promotion counts, veto windows
- **Webhook configs / routing patterns** that match existing conventions
- **First-pass content the owner will review anyway** -- copy drafts, prompt templates, spec boilerplate
- **Cross-referencing between docs** -- which file mentions which
- **Agent role names / charter naming** -- new role vs reuse existing = AI decides based on charter boundary fit
- **Table naming conventions** -- snake_case vs camelCase, prefix schemes
- **Fact-checks** -- "is X already wired?" = AI verifies itself (grep, read config, test endpoint); do NOT ask the owner unless genuinely unreachable

---

## OWNER-JUDGMENT (legitimate escalations)

- **Money commitment** above a defined threshold for new recurring or one-time spend (paid subscriptions, purchases beyond approved planning budget)
- **External-facing content under the owner's name** -- public posts, pitch lines, voiceover, email signatures, customer-facing copy
- **Customer / client communications** -- emails, contracts, legal commitments, pricing changes visible to customers
- **Strategic prioritization** -- which product area gets dial lift beyond default range; anchor reprioritization; sub-vision changes
- **Values statements** -- what anchor, what hard line, identity ordering
- **Irreversible infrastructure** -- DB migrations affecting live tables (outside pre-approved GREEN-zone), push-to-main on protected repos, production deploys requiring explicit sign-off
- **Timing / cadence decisions shaping the owner's life** -- target hours per week, retirement date, vacation structure, stage-appearance rhythm
- **Hire vs automate decisions** -- organizational structure choices
- **Brand / product identity** -- renames, retiring products, brand pivots
- **Promo deadline decisions** -- accept or skip paid-tier discount windows with a hard expiry

---

## T2 (AI proposes + auto-applies if no veto within N minutes)

- Dial adjustments within defined ranges (see your project's decision-routing document)
- Score-based routing at defined thresholds (e.g., quality-gate auto-publish)
- Tool adoption on pre-approved domain at free tier transitioning to paid
- Proposed nightly or weekly plan that the owner can veto before a set time; else default applies
- Periodic recommendations surfaced in a scheduled brief (owner reviews, no blocking required)

---

## Anti-Patterns: Questions That Should NOT Have Been Asked

These examples showed up in agent return summaries as "open questions for owner." They should not have been escalated:

- "New dedicated role vs reuse existing backend role?" -- technical, reversible, no values layer -> **AI decides** (pick based on charter boundary and cadence fit; log rationale)
- "Budget caps in DB config table or in a config file?" -- implementation detail -> **AI decides** (pick: DB config table per hard-line rule that prices/caps never live only in code; log rationale)
- "SQL table naming convention?" -- pure naming -> **AI decides** (pick: match existing project convention; log rationale)
- "Which repo for first new agent?" -- technical routing, reversible -> **AI decides** (pick based on delivery boundary fit; log rationale)
- "Incoming webhook vs bot registration for a messaging platform?" -- technical fit-to-use-case -> **AI decides IF cost and risk are comparable** (pick based on interaction pattern; log rationale) -- UNLESS cost or risk differ materially (e.g., one requires tenant-level admin registration = owner-domain decision). In that specific case, elevate to owner.

**Pattern to watch:** many "open questions" are fact-checks disguised as questions. Fact-checks are AI-verifies-itself, not owner-asks.

---

## Legitimate Escalations: Examples That WERE Real Owner Questions

- "Flip launch order of Product A ahead of Product B?" -- strategic priority, multi-product impact -> **Owner**
- "Accept a time-limited annual subscription promo before expiry?" -- money commitment + timing -> **Owner**
- "Retire a free offer in favor of a new paid tier?" -- strategic + customer-facing + identity -> **Owner**
- "Revenue working target for next year?" -- strategic values -> **Owner**
- "Compensation target at a future date?" -- life / values -> **Owner**
- "Per-product default settings beyond proposed ranges?" -- strategic priority -> **Owner**

---

## Process Change (apply immediately when adopting this pattern)

1. **Every agent prompt going forward** includes this clause:
   > *Only surface as "Open Q for Owner" if it passes ANY 1 of 3 tests (reversibility + blast radius + values layer) MATERIALLY. Otherwise pick the most defensible option, log the decision + 1-line rationale, and move on.*

2. **Master filters agent returns:** any open question that fails the 3-test gate gets downgraded to "AI decision logged" and summarized in a single line in the session brief -- not in the owner questions section.

3. **When AI is genuinely uncertain** whether a question passes the gate: AI picks the most defensible option, logs rationale + alternatives considered + reasoning, and flags for owner in a periodic "decisions-audit" section (informational, NOT blocking).

4. **Owner override:** the owner can override any AI decision with a natural-language command ("revert decision on X"; "I want to weigh in on Y category going forward"). AI updates this doc with the new escalation rule.

5. **Owner questions quality bar:** at most 4 items per brief, all passing the 3-test gate. If fewer than 4, leave fewer. Never pad with low-value questions.

---

## Related

- Your project's `decision-routing` document -- T1/T2/T3 tier assignments (more granular, per-capability)
- Your project's constitution or operating principles -- the principle that motivated this pattern: Minimize Escalations
- Your project's `rollback-guardrails` document -- demotion criteria when AI decides materially wrong

---

## Updates Log

- **2026-04-15** -- Doc created. Trigger: an agent surfaced a pure technical routing decision as an owner question when it was clearly in the AI-decides domain. This doc formalizes the gate so it does not recur.

- **2026-04-15 (logic fix)** -- Original rule said "Human decides when ALL three conditions true" -- this was backwards. Flipped to "Human decides when ANY ONE condition is materially true." Added "materially" qualifier + threshold guidance to prevent ANY-triggering from over-escalating. Any ONE material risk factor warrants human oversight; all three do not need to stack. The material calibration is the guard against over-asking.
