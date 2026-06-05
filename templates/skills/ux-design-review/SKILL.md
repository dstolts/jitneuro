---
type: skill
name: ux-design-review
description: Review a UX mockup or design artifact for pattern-justification quality, Stolts UX Constraints (a.k.a. Owner-UX-constraints) compliance, and Stolts Adversarial / Krug / Apple HIG alignment; invoke before any mockup reaches Owner or before any frontend PR merges.
purpose: BINDING quality gate for ux-designer outputs; MUST be run by an INDEPENDENT Opus agent (not the authoring designer) before mockups reach Owner; skipping means structurally wrong patterns ship undetected, as proven in a 2026-05-23/24 dashboard-design attempt (#4) where the QA skill approved 7 of 8 mockups Owner subsequently rejected.
tags: [skill, ux-design, design-review, quality-gate, stolts-critique, opus-required, independent-dispatch]
scope: public
departments: [operations]
leak_allow: ["Dan Stolts"]
owner_role: ux-designer
read_when: Before any ux-designer mockup reaches Owner review or before any frontend PR merges; dispatch as an independent Opus agent.
last_evaluated: 2026-06-03
---

# UX Design Review Skill

Independent quality gate for ux-designer mockup outputs. Evaluates WHY a pattern fits,
not just WHETHER fields are populated. Must be run by a separate Opus agent from the
one that authored the mockup.

## Operating Principle

This skill applies JUDGMENT, not checklist presence. Row-presence checks ("does the
spec include a pattern name?") are insufficient and have caused production failures.
The skill asks: "Does the pattern CHOICE make sense for this surface, and is it
justified against the right baselines?"

**Stolts UX Constraints** (canonical at `rules/owner-ux-constraints.md` -- authored by
Dan Stolts; the 7 BINDING rules) are non-negotiable. Everything else is taste applied
against the **Stolts Adversarial Baseline** / Krug / Apple HIG.

**Self-grading is banned.** The agent that authored the mockup cannot run this skill
on its own output. Stolts critique requires a separate Opus dispatch with different
context -- adversarial by design.

## Run Logging (evaluate-as-we-go) -- BINDING

This skill is CLEARED for use on production mockups. The earlier pre-production
gate (run 3 eval scenarios before first production use) is LIFTED: a quality gate
cannot be validated without being run, so the skill ships and is evaluated from
its real runs instead of blocked indefinitely.

**Every run MUST append one row to `skills/ux-design-review/run-log.md`**, capturing:
date, surface reviewed, EVAL-STATUS returned, blocker count, flag count, reviewer
model, and -- filled in AFTER Owner reviews the same mockup -- whether Owner agreed
with the skill's verdict.

The run-log is the evaluation substrate. After the skill has run on several real
mockups (~5-8), review the log to decide whether its judgment is reliable, needs
tuning, or should be re-gated. The "Owner agreed?" column is what makes the skill
self-correcting: it is the direct comparison the 2026-05-23/24 design miss lacked
(skill approved 7 of 8 mockups Owner then rejected).

If `run-log.md` does not exist, create it from the template header before logging
the first run. Skipping the log entry is a process failure -- without it there is no
data to evaluate the skill against.

## When to Use This Skill

- After a ux-designer agent completes a DEFINE cycle (spec + mockup produced)
- Before any mockup is presented to Owner for approval
- Before a sys-frontend PR that introduces new layout patterns merges to UAT
- When Owner reports that a mockup "feels wrong" and asks for a structured diagnosis

## Evaluation Dimensions (judgment checks, not row presence)

### 1. Pattern Justification Quality

Does the mockup justify its pattern selection with reasoning?

- Does the spec/mockup name the chosen pattern AND explain WHY it fits this specific surface?
- Is the justification grounded in Stolts / Krug / Apple HIG, not "because we used this elsewhere"?
- Does the spec cite a reference implementation (Things 3, Linear, Notion, Apple Mail, Todoist, etc.)?
- Reject: "sidecar" named without justification. Require: "sidecar chosen because this is a review-heavy surface where users need context alongside the list; reference: Apple Mail conversation + message pane."

**Red flag:** Universal pattern applied identically to all surfaces (e.g., "list + sidecar" across triage, execution, planning, monitoring, ritual, library modes). Different work-modes require different patterns. Uniform application is a design failure signal.

### 2. Stolts UX Constraints Compliance (BINDING -- not taste)

Canonical: `rules/owner-ux-constraints.md` ("Stolts Rules" / "Stolts UX Constraints", authored by Dan Stolts).

These are non-negotiable. A single failure here is a BLOCKER. The 7 Stolts Rules:

1. **ADHD as a design constraint** -- disability not preference; no hidden actionable state
2. **Minimize noise** -- every element earns its place; no duplicate status, decorative badges, redundant labels
3. **Maximize 1-click discoverable context** -- no hunting, no menus inside menus, consequences + prerequisites 1-click reachable from any action button
4. **Fast decision + move-on** -- intelligent defaults, safe single-click, undo/redo always available
5. **System logs AND remembers** -- the system IS the user's memory; proactive recall, not just audit logging
6. **Expand or fly-out -- never popup + hide where I am** (NARROW exception: modals for ERRORS that warrant disruption -- auth-expired, destructive-confirm, network-down, permission-denied, data-loss-risk)
7. **Resizable, persistent side drawer / fly-out + expandable notes fields** (per-panel width persisted, not global)

Quick visual check on the mockup:

- No modal popups that overlay and block surrounding UI (except the error-warrant cases in rule 6)
- Expand or fly-out patterns (NOT full-view replacements that hide context)
- Resizable, persistent side drawer when a drawer is used (per-panel width)
- 1-click reachable context for anything currently actionable
- System logs and proactively surfaces relevant state (no "go find it yourself")
- No hidden state for ADHD users
- Notes/description fields must be expandable (drag handle minimum)

### 3. Anti-Pattern: Universal Sidecar

Does the mockup avoid applying "list + sidecar" universally?

Per work-mode guidance (pattern is JUDGMENT per surface, not a rule):
- **Triage** (inbox, review queue): consider inline-expand or sidecar wizard -- user scans + acts on items rapidly; reference: Superhuman, Hey email
- **Execution** (next actions, active tasks): consider inline-expand -- user is in the item, not comparing items; reference: Things 3 Today view, Linear "My Issues"
- **Monitoring** (dashboards, status boards): consider two-pane or grid -- user scans state across many items; reference: Linear board, Notion databases
- **Planning** (backlog, roadmap): consider master-detail or two-pane -- user moves between context and list; reference: Jira backlog, Notion calendar
- **Ritual** (weekly review, retrospective): consider guided wizard or step-by-step -- user follows a process; reference: Things 3 Review mode
- **Library** (reference, knowledge base): consider grid or document view -- user browses, not acts; reference: Notion wiki, Apple Notes

A designer who applies sidecar to ALL of these without per-surface justification has not exercised judgment. Flag it.

### 4. Capability Coverage (BINDING foundations, pattern-agnostic)

The mockup must support these capabilities WITHOUT prescribing the specific affordance:

- Decisions revisitable (edit after save -- how is not prescribed)
- Archive + filter toggle visible (where is the owner's judgment)
- Drag-and-drop bucket moves (bucket triage -- how is not prescribed)
- Popout / focus mode for deep work (which surfaces need it is judgment)
- Mobile degradation path stated (not necessarily designed in full)
- Screen real-estate scaling: wide viewport surfaces full fields without horizontal scroll

Reject if capability is MISSING. Do not reject if the AFFORDANCE chosen is different from a brief suggestion -- the designer's affordance judgment is what this charter grants.

### 5. Details Surface -- Pattern-Agnostic Language

The mockup must NOT prescribe "sidecar" as the canonical details pattern across the board.

- "Details" is correct -- the pattern (sidecar, inline-expand, popout, separate page) is the designer's per-surface choice
- Reject: spec that says "details panel = right sidecar" as a universal rule
- Accept: spec that says "details surface for [X] view uses inline-expand because [justification]"

### 6. Stolts Adversarial Baseline -- Would a Practitioner Ship This?

(Distinct from dimension #2 "Stolts UX Constraints" -- this is the adversarial
question set Dan Stolts applies as an independent critic; the constraints in
dimension #2 are binding rules, these are taste-level baseline questions.)

Run the adversarial Stolts questions:

- "Would I show this to a paying customer today, as-is?"
- "Does the minimal-click flow actually minimize clicks, or does it add steps compared to the simplest possible design?"
- "Is this fast and obvious, or does it require learning?"
- "Does any element exist for its own sake (decoration, redundant label, duplicate status indicator)?"
- "Would Krug say 'don't make me think' -- or would Krug say 'this makes me think'?"
- "Does any menu, button, or quick-action hide what it will reveal until clicked?" (Krug 'don't make me click to find out' -- examples: ellipsis menu listing "Open attachments" with no count or type preview; quick-action buttons that don't preview the resulting state)

### 7. In-Context Placement of Secondary Surfaces (BINDING)

Secondary surfaces (wizards, drawers, popovers, Clarify forms, side-flow editors) MUST be shown ATTACHED to the surface that triggered them, not as standalone pages.

A wizard rendered as a standalone page leaves the reviewer unable to judge where it lands relative to the row, list, or context that invoked it. The mockup author must show the secondary surface IN CONTEXT (overlay relationship, push/squish behavior, anchor to the triggering element).

- Reject: Clarify form mockup shown as a separate page with no visible relationship to the inbox row that triggered it.
- Reject: Help drawer mockup shown as a thin column with no indication of how it lands against the underlying screen (push? overlay? squish?).
- Accept: Secondary surface shown as a side-by-side composite with the parent surface visible behind/beside it, OR an annotated overlay diagram showing the placement relationship.

**Red flag:** Any secondary surface authored as its own standalone HTML/page artifact without a companion artifact showing in-context placement.

### 8. Navigation Chrome Hygiene (FLAG)

Sidebar, top nav, and persistent shell chrome must render with intentional spacing. Visual defects in the chrome are a credibility signal: if the shell looks broken, the reviewer cannot judge the content.

Check the mockup's DOM/CSS for:

- Sidebar nav-group spacing: compact and intentional, not arbitrary gaps between groups
- Alignment: items in a group share consistent left edge, padding, and item height
- No "dead air" pockets: full-page whitespace blocks in nav columns are a defect
- Active/hover/selected states render consistently

This is a FLAG-level check unless the chrome defect is so severe it blocks comprehension of the mockup -- in which case escalate to BLOCKER.

### 9. Save Discipline on Execution Surfaces (BINDING for execution work mode)

Surfaces classified as EXECUTION work mode (Next Actions, active tasks, in-flow editing) MUST use realtime / debounced save (~300ms blur), NOT form-submit-style save with explicit Save button.

The user is IN THE ITEM during execution; a Save button breaks flow, risks lost edits, and is a workflow anti-pattern documented in Things 3, Linear, Notion, TickTick.

For other work modes:

- Triage: save semantics depend on Clarify pattern (wizard commits at end OR inline-decision saves immediately)
- Planning: save semantics are surface-specific; both inline and form-submit can be appropriate
- Library / Reference: editing is rare; form-submit acceptable for occasional updates

A mockup that targets an EXECUTION surface with a form-submit save pattern is a BLOCKER. The fix: realtime-save inputs (debounced 300ms, no Save button required) with visible save-state indicator (saved/saving/error).

## Procedure

1. **Receive the artifact set:** spec file path + mockup file path + surface description (which nav surface / work-mode)
2. **Read the spec** -- look for pattern justification section. If missing, that alone is a finding.
3. **Read the mockup** -- visually trace the interaction flow. What does the user do first? Second? What is hidden?
4. **Run evaluation dimensions 1-9** above. For each dimension, produce a finding:
   - PASS: one sentence why
   - BLOCKER: what is wrong, which principle it violates, what the fix looks like
   - FLAG: enhancement or taste concern that does not block but should be surfaced
5. **Cross-check Stolts UX Constraints** (all 7 rules from `rules/owner-ux-constraints.md`) against the mockup DOM structure (expand/fly-out compliance, no modals except error-warrant cases, resizable panels)
6. **Run Stolts Adversarial questions** and record answers
7. **Produce review output** (see Return Format below)

## Return Format

```
UX-DESIGN-REVIEW: <surface-name>
EVAL-STATUS: PASS | BLOCKED | FLAG-ONLY
BLOCKER-COUNT: <N>
FLAG-COUNT: <N>

PATTERN-JUSTIFICATION: PASS | BLOCKER | FLAG
  Finding: <one sentence>
  Fix (if BLOCKER): <concrete fix description>

STOLTS-UX-CONSTRAINTS: PASS | BLOCKER
  Finding: <one sentence per of the 7 Stolts Rules checked>
  Fix (if BLOCKER): <which of the 7 Stolts Rules failed and what to change>

ANTI-PATTERN-SIDECAR: PASS | FLAG | BLOCKER
  Finding: <did universal sidecar pattern appear? per-surface justification present?>

CAPABILITY-COVERAGE: PASS | FLAG | BLOCKER
  Missing: <list any missing binding capabilities>

DETAILS-SURFACE-LANGUAGE: PASS | FLAG
  Finding: <is "sidecar" prescribed universally, or is pattern-agnostic language used?>

STOLTS-ADVERSARIAL: PASS | FLAG | BLOCKER
  Finding: <would a practitioner ship this? what would Krug flag?>

IN-CONTEXT-PLACEMENT: PASS | BLOCKER
  Finding: <are secondary surfaces shown attached to their trigger, or as standalone pages?>
  Fix (if BLOCKER): <which surface needs in-context companion artifact>

NAV-CHROME-HYGIENE: PASS | FLAG | BLOCKER
  Finding: <is the sidebar/nav rendering clean, or are there dead-air gaps and alignment defects?>

SAVE-DISCIPLINE: PASS | BLOCKER | N/A
  Finding: <on an execution surface, is realtime/debounced save used or is a form-submit Save button present?>
  Fix (if BLOCKER): <switch to debounced inputs with visible save-state indicator>

RECOMMENDATION:
  <1-3 sentences: ship as-is / revise per blockers / reject and redesign>
```

## QA Gates

Reject (BLOCKER) the output if any of these are true:

- Stolts UX Constraints violated (no expand/fly-out, modal overlay present where not error-warrant, non-resizable panels, hidden actionable state) -- see `rules/owner-ux-constraints.md` 7 rules
- Pattern applied with no justification and no reference implementation cited
- Universal "list + sidecar" across all surfaces with no per-surface reasoning
- Binding capability missing (decisions not revisitable, no archive toggle, no drag-drop path, no popout path)
- "Sidecar" prescribed as universal details pattern in the spec
- Secondary surface (wizard, drawer, popover) shown as standalone page with no in-context placement artifact
- Navigation chrome with broken alignment, dead-air whitespace, or visibly defective sidebar/nav rendering (escalate to BLOCKER when severe; FLAG otherwise)
- Quick-action / menu affordance that hides its result until click (ellipsis menus, opaque buttons without state preview)
- Form-submit save pattern on an EXECUTION work mode surface (realtime/debounced required)

Flag (non-blocking) if:

- Pattern justification is thin (name present but reasoning could be stronger)
- Reference implementation cited is obscure or a poor match for the pattern
- Details surface language prescribes an affordance without a strong reason
- Stolts questions raise concerns that do not rise to BLOCKER level

## Origin and Rationale

**2026-05-23/24 dashboard-design session, attempt #4.** The ux-design-review skill was authored
AND first used on its first production run in the same session, with no eval scenarios run
and no independent critique gate. The Sonnet-based designer produced 8 GTD mockups. The
skill approved 7 of 8. Owner rejected the batch on visual inspection: "pathetic." All 8
were rejected.

Root cause diagnosis:
- Sonnet (not Opus) wearing ux-designer charter hat -- model gap was a root cause
- Skill performed row-presence checks ("is a pattern named?") not judgment checks ("does the pattern fit?")
- Designer self-graded (Stolts Adversarial critique was embedded in the designer's own pre-handoff, not an independent dispatch)
- Skill was used on production artifacts without any prior eval validation

This version of the skill encodes the lessons. Rather than block all production use
until pre-validated -- a gate that could never clear, since the skill cannot be
evaluated without running -- the skill now ships with mandatory Run Logging (above):
every run is recorded so the skill's judgment can be compared against Owner outcomes
after a handful of real runs, then tuned or re-gated based on evidence.

## Cross-References

- `org/cpo/managers/ux-designer/CHARTER.md` -- designer charter; Opus-default, Stolts independent dispatch, per-surface pattern justification requirements
- `rules/design-judgment-over-rules.md` -- portfolio principle: patterns are IDEAS; judgment over rules for taste decisions
- `rules/judgment-over-compliance.md` -- broader principle; design is a judgment domain, not a compliance domain
- `rules/owner-ux-constraints.md` -- canonical "Stolts UX Constraints" / "Stolts Rules" (authored by Dan Stolts); BINDING UX constraints for Owner as end-user; 7 rules including modal-for-errors exception
