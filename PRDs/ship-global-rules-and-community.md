# User Story: Ship 22 Global Rule Templates + Community Folder

**Created:** 2026-03-27
**Priority:** 90/100
**Status:** Ready for execution
**Handoff:** Agent-ready (batch operation, use sub-orchestrator with 14 workers)

## Desired State

JitNeuro ships 22 curated rule templates that any adopter gets on install. A `community/` folder lets users contribute optional rule packs. The first community pack is "ADHD-Friendly" -- extracted from real production rules that help neurodivergent developers work more effectively with AI.

## User Value

- **Day 1 quality gates** -- install JitNeuro, immediately get trust zones, security guardrails, verify-before-presenting, definition-of-done
- **Community knowledge** -- browse what other teams have built, copy what fits
- **Neurodivergent inclusion** -- ADHD-Friendly pack is a concrete, useful starting point that shows JitNeuro cares about different working styles

## Structure

```
templates/
  rules/                    <-- installed by default (22 curated rules)
    approval-workflow.md     NEW
    autonomous-execution.md  NEW
    code-reuse.md            EXISTS (verify)
    context-safety.md        EXISTS (verify)
    cross-project.md         NEW
    definition-of-done.md    EXISTS (verify)
    deploy-monitoring.md     EXISTS (verify)
    documentation-updates.md NEW
    emergency-procedures.md  NEW
    file-references.md       NEW
    file-versioning.md       EXISTS (verify + update)
    friction-detection.md    NEW
    gap-analysis.md          NEW
    output-formatting.md     NEW
    pending-questions.md     EXISTS (verify)
    proactive-quality.md     EXISTS (verify)
    routing-weights.md       NEW (jitneuro example entries only, strip all business data)
    security-guardrails.md   EXISTS (verify)
    session-awareness.md     NEW
    session-closure.md       NEW
    session-guardrail.md     NEW
    sprint-planning.md       NEW
    technology-selection.md  NEW
    testing-critical-path.md NEW
    trust-zones.md           EXISTS (verify)
    verify-before-claiming.md  NEW
    verify-before-presenting.md NEW

community/                  <-- NOT installed by default (browse and copy)
  README.md                 <-- how to contribute, how to use
  adhd-friendly/
    README.md               <-- what this pack does, who it's for
    minimize-sprawl.md       <-- version files, single HUB, .archive pattern
    ascii-only.md            <-- no emojis, no special chars (reduces visual noise)
    drive-velocity.md        <-- push pace, present next action, batch decisions
    highest-value-first.md   <-- always recommend highest-leverage work
    single-line-commands.md  <-- never multi-line (breaks in PowerShell, hard to scan)
    context-switching.md     <-- minimize file sprawl, verify paths (broken links waste 30s of context switching)
    ship-over-perfect.md     <-- 75+ = publish, perfect is the enemy of done
  security-first/            <-- future pack
    README.md
  content-creator/           <-- future pack
    README.md
```

## Acceptance Criteria

### AC-1: Create 14 new rule templates
- [ ] Read each private rule from ~/.claude/rules/
- [ ] Genericize: "Dan" -> "Owner", remove personal specifics, keep universal pattern
- [ ] Write to templates/rules/ with same filename
- [ ] Each rule should work standalone (no dependencies on other rules)
- [ ] Each rule under 60 lines

### AC-2: Verify 8 existing templates
- [ ] Compare each template against current private rule
- [ ] Update if private rule has evolved (new sections, better wording)
- [ ] Ensure no "Dan" references in any existing template

### AC-3: Create community/ folder
- [ ] community/README.md -- explains: what community rules are, how to browse, how to copy, how to contribute
- [ ] Rules here are NOT installed by default
- [ ] Users browse on GitHub or locally, copy what they want to their rules/
- [ ] Contributing: fork, add your pack as a subfolder, PR

### AC-4: Create ADHD-Friendly pack
- [ ] community/adhd-friendly/README.md -- what it does, who benefits, how to install
- [ ] Extract from owner-preferences.md, file-versioning.md, output-formatting.md, standing-preferences.md
- [ ] Genericize completely (no personal details, no specific tools)
- [ ] 5-7 focused rules, each under 30 lines
- [ ] Tone: practical, not clinical. "This helps you stay focused" not "for people with ADHD"

### AC-5: Install script updates
- [ ] install.sh copies templates/rules/ to target rules/ directory
- [ ] install.sh does NOT copy community/ (it's browse-only)
- [ ] Existing rules not overwritten if DISABLED marker present (per rule-disable-pattern.md)
- [ ] install.ps1 same behavior

### AC-6: Documentation
- [ ] Update help.md with note about community rules
- [ ] Update README docs table with community folder link
- [ ] Update technical-overview.md "What's Included" with rule count

### AC-7: Genericization
- [ ] Zero "Dan" references in any template or community file
- [ ] Zero personal tool preferences (PowerShell, specific editors)
- [ ] Zero business-specific content (revenue targets, client names, domain names)
- [ ] Use "Owner" throughout

## ADHD-Friendly Pack Detail

Source material from private rules (genericized):

**minimize-sprawl.md:**
- Version files (-01, -02) with .archive on old
- Use HUB.md as single source of truth for tasks
- One file per concern, not sprawling docs

**ascii-only.md:**
- No emojis, no special characters in output
- Reduces visual noise and cognitive load
- Consistent, scannable output

**drive-velocity.md:**
- Push pace, keep momentum
- After completing a task, immediately present next action
- Batch decisions for multi-item approval
- Default to action over deliberation

**highest-value-first.md:**
- Always recommend highest-leverage work
- Architecture/automation/pipeline > content drafting > manual data entry
- Order next steps by business impact, not ease

**single-line-commands.md:**
- Never give multi-line shell commands
- Each step as a separate single-line command
- Wrapped lines break in terminals and are hard to scan

**context-switching.md:**
- Always verify file paths before presenting (broken links waste context-switching time)
- Minimize file references -- fewer is better
- Include brief description of what each file contains (filenames alone don't help)

**ship-over-perfect.md:**
- Better to go live with flaws than wait forever
- Define quality bar (e.g., 75+ = ship), enforce it, then ship
- Owner approves, never creates -- maximize AI value, minimize owner effort

## Execution Strategy

Batch operation -- use sub-orchestrator:
1. Worker per new rule (14 workers): read private rule, genericize, write template
2. Worker per existing rule (8 workers): compare, update if stale
3. Single worker: create community/ structure + ADHD-Friendly pack
4. Single worker: update install scripts, help.md, README, technical-overview

Rolling pool of 10, should complete in one pass.

## Test Plan
- [ ] grep -r "\bDan\b" templates/rules/ -- zero results
- [ ] grep -r "\bDan\b" community/ -- zero results
- [ ] Each rule file is valid markdown with no broken references
- [ ] install.sh --dry-run shows all 22 rules would be installed
- [ ] DISABLED pattern works: disable a rule, re-run install, rule stays disabled
