---
type: rule
purpose: BINDING for ALL ux-designer dispatches and ANY creative-output agent (content, video, brand); establishes that the named design authorities (Stolts/Krug/Apple HIG) are the BASELINE applied with judgment -- not a checklist -- and that patterns in briefs are IDEAS, not requirements; skipping means pattern-mechanical designs ship that fail the owner's taste bar, as proven in a 2026-05 design attempt (#4).
read_when: Before dispatching any ux-designer, content, video, or brand creative-output agent, and before reviewing their output against the design brief.
tags: [design-judgment, ux-designer, model-tier, opus-required, stolts-critique, stolts-ux-constraints, pattern-ideas, owner-ux-constraints, rule-sprawl-avoidance]
scope: public
leak_allow: ["Dan Stolts"]
last_evaluated: 2026-06-03
---

# Design Judgment Over Rules

UX work requires design JUDGMENT, not rule enumeration. This rule is the portfolio-level
binding contract for all creative-output agents dispatches (ux-designer, content writer,
video producer, brand). It is NOT a replacement for engineering discipline rules (security
gates, promotion criteria, WIP lifecycle, etc.) -- those remain ruled territory.

## The principle

- Owner cannot enumerate every UX requirement. Trying to enumerate everything makes agents
  more rigidly bad, not better.
- Established usability authorities (Stolts persona, Krug "Don't Make Me Think", Apple HIG)
  are the design BASELINE a competent designer APPLIES with judgment.
- A designer trained on those baselines knows per surface: "this is execution-heavy, use
  inline-expand; this is triage, use sidecar wizard; this is deep-planning, use popout" --
  WITHOUT being told per-surface.
- Forcing uniform patterns ("list + sidecar everywhere") is bad design. This charter
  explicitly rejects it.

## Model tier for UX work (BINDING)

Pick model by LEVERAGE, not volume.

- UX = customer-facing, ripple-effect leverage
- Therefore: **Opus for all ux-designer dispatches**
- Sonnet wearing ux-designer hat = template-following without design taste (proven failure)
- Opus wearing ux-designer hat with Krug / Apple HIG / Stolts as BASELINE = actual design judgment
- Sonnet is acceptable ONLY when Owner explicitly authorizes it for a named surface (e.g., a trivial copy update)

## Patterns are IDEAS, not requirements (Owner directive 2026-05-24, BINDING)

> "Tell ux-designer that sidecar and other stipulations are ideas, not requirements.
> The design should dictate how it is implemented, not some static arbitrary rule that
> worked in some other application."

When briefing any creative-output agent, patterns mentioned in the brief are IDEAS to
consider, NOT requirements to satisfy. The design / content / video dictates the
implementation. Arbitrary static rules from other applications do not.

### The distinction

| Category | Examples | Treatment |
|---|---|---|
| **BINDING rules** | Stolts UX Constraints (`rules/owner-ux-constraints.md`, 7 rules by Dan Stolts -- ADHD, no modals except error-warrant, expand-or-fly-out, resizable+persistent panels) | Non-negotiable; designer must comply |
| **IDEAS in briefs** | Sidecar, drawer, popout, inline-expand, grid, two-pane, master-detail | Designer chooses what fits THIS problem |
| **Inspiration** | Things 3, Linear, Notion, Apple Mail, Todoist (cited as reference impls) | Study and adapt; do NOT copy mechanically |

### Brief template paragraph (use verbatim in dispatch prompts)

> "Patterns mentioned in this brief (sidecar, drawer, popout, inline-expand, grid, etc.)
> are IDEAS to consider, not requirements. The design dictates the implementation. Apply
> Stolts / Krug / Apple HIG as DESIGN BASELINE with judgment. Justify your pattern
> selection per surface against those baselines and cite a reference implementation for
> any non-obvious choice. Do NOT apply patterns mechanically because they worked elsewhere;
> apply them because they fit THIS design problem. Stolts UX Constraints (`rules/owner-ux-constraints.md`)
> are BINDING rules; everything else is taste applied with judgment."

## Wrong fix vs right fix

| Wrong | Right |
|---|---|
| Add more rules / longer checklist to UX skill | Upgrade model tier (Opus for UX work) |
| Force uniform pattern across nav surfaces | Per-surface judgment, justified against Krug/Apple HIG |
| Enumerate sidecar max-width, notes height, etc. | Bar = "would Krug ship this; would Apple ship this" |
| Stolts as one-line self-grading inside designer's own pre-handoff | Stolts as INDEPENDENT critic dispatch (separate Opus agent, separate context) |
| Expand skill checklist in response to a taste failure | Identify whether it was a MODEL problem or a RULES problem; most taste failures are model problems |

## Stolts critique -- independent dispatch, not self-grade

The same agent that authors mockups MUST NOT run the Stolts critique on them.
Self-grading is banned.

Stolts critique is a SEPARATE Opus dispatch with adversarial context, asking:
- "Would I show this to a paying customer today?"
- "Does every pattern choice have a justified reason, or was it applied mechanically?"
- "Would Krug say 'don't make me think' -- or does this make me think?"

## Per-surface pattern justification (BINDING for every design artifact)

For every nav surface or major component, the spec and mockup MUST include:

1. Which pattern was chosen (sidecar, inline-expand, popout, two-pane, master-detail, grid, agenda, etc.)
2. Why it fits THIS surface (grounded in Stolts / Krug / Apple HIG -- not "used elsewhere")
3. A reference-implementation citation (Things 3, Linear, Notion, Apple Mail, Todoist, etc.)

Pattern selection is the designer's judgment per surface. A designer may:
- Propose patterns not mentioned in the brief (if they fit better)
- Reject patterns mentioned in the brief (if they do not fit)
- Rank candidate patterns with trade-offs before choosing

## Scope: design taste vs engineering discipline

This principle applies to DESIGN TASTE, not engineering discipline. At dispatch time,
ask: "Is this a discipline question (rule it) or a taste question (judge it)?"

**Still RULE territory (do NOT replace with judgment):**
- Frontmatter schema
- Security gates
- Promotion criteria
- WIP-drafts lifecycle
- Pull-before-PR
- Trust-zones
- Stolts UX Constraints (`rules/owner-ux-constraints.md` -- 7 binding rules by Dan Stolts: ADHD, minimize noise, 1-click context, fast decision, system remembers, no modals except error-warrant, resizable+persistent panels)

**TASTE territory (apply judgment + baseline, not rules):**
- When to use sidecar vs inline-expand vs popout vs modal
- Sidecar width, notes editor height, drag-drop affordance presence
- Visual hierarchy details
- Copy tone (within voice baseline)
- Which work-mode pattern fits which surface

## Concrete surface-pattern example (Owner's diagnostic, 2026-05-24)

Inbox and Next should use INLINE-EXPAND-IN-LIST, not sidecar. The "normalized list +
sidecar" pattern applied to every GTD nav was bad design. A Krug-trained designer picks
inline expand for execution-heavy surfaces because:

- Inline expand keeps the user in the list context (no shift to a side panel)
- Realtime edit happens in the same visual location
- Minimal click flow (click row -> edit; not click row -> sidecar opens -> edit)
- Reference implementations: Things 3, Linear, Notion, Todoist all use inline expand for execution surfaces

The right charter encodes the JUDGMENT to pick the right pattern per surface, citing
reference implementations. It does NOT enumerate "use sidecar here, use expand there."

## Origin

2026-05-24, a dashboard-tool design session, attempt #4. The ux-designer agent (Sonnet wearing ux-designer
hat) produced 8 mockups that the owner judged "pathetic." The ux-design-review skill
(authored same session) approved 7 of 8 with a checklist that missed every structural failure
Owner found.

Master's first instinct: "add more gates to the skill checklist." Owner correction:

> "I have to call BS. Maybe we need opus to do design work? I cannot possibly be expected
> to give every little thing a rule. Following Stolts, Krug, Apple rules should be enough
> to build a useful, quick flow and appealing screen with proper minimal click flow. I think
> the rules are already too strict. Example: next and inbox would be better if they were
> locally expanded in the list rather than a sidecar. This 'normalized' behavior actually
> made it worse, now you are telling me I have to be even more strict, how wide the sidecar
> should be, how big the notes files should be. Not acceptable."

The lesson: less rule sprawl, more model judgment + design-authority baseline.

## Related

- `org/cpo/managers/ux-designer/CHARTER.md` -- the charter that applies this principle in role context; Opus default, Stolts independent dispatch, per-surface pattern justification
- `skills/ux-design-review/SKILL.md` -- quality gate skill; tightened to judgment checks, independent critique, pre-production validation gate
- `rules/judgment-over-compliance.md` -- the broader principle: apply baselines with taste, not rules to satisfy; design is a judgment domain
- Owner memory: `feedback_design_judgment_over_rules.md` -- session-specific framing of this principle
- Owner memory: `feedback_no_haiku_for_high_leverage_governance.md` -- sibling principle: model tier by leverage, not volume
