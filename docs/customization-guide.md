# Customization Guide

JitNeuro ships with opinionated defaults designed for professional software engineering.
After installing, review and modify everything to match your team's engineering style,
business context, and workflow preferences.

Nothing is sacred. Keep what works. Change what doesn't. Delete what's irrelevant.

---

## What to Review (Priority Order)

### 1. Cognitive Identity (`.claude/CLAUDE-brainstem.md`)

The Cognitive Identity section defines how Claude approaches ALL work before any
persona activates. It ships with 10 engineering principles:

```
- Fails fast over failing silently
- Handles the unhappy path before the happy path
- Never writes an endpoint without auth
- Never trusts client input
- Follows existing patterns before inventing new ones
- Writes code a junior can read in 30 seconds
- Never patches symptoms -- traces to root cause
- Never introduces a second way to do the same thing
- Verifies outcomes before claiming done
- Evaluates highest-leverage action before starting work
```

**Review these.** If your team values different principles (move fast and break things,
optimize for performance over readability, etc.), change them. These are the foundation
everything else builds on.

### 2. Personas (`.claude/cognition/personas.md`)

16 expert personas evaluate every request. Each has:
- **Primary triggers** -- when this persona drives the approach
- **"Thinks about"** -- checklist items this persona always evaluates
- **Bias** -- this persona's default leaning when there's a tradeoff

**Easiest way to customize:** Ask Claude Code:
```
> "Review my personas and remove the ones that don't apply to my work.
   I focus on [your domain]. Suggest domain-specific additions."
```

Claude Code will read personas.md, identify irrelevant entries, suggest additions based on your domain, and make the edits.

**Manual customization options:**
- **Remove personas you don't need.** If you never write content, remove Content Strategist.
  If you don't use sprint automation, simplify Scrum Lead.
- **Adjust biases.** The Security Engineer defaults to "deny by default." If your context
  is internal tooling with no external users, you might relax this.
- **Add domain-specific checks.** If you work in healthcare, add HIPAA checks to the
  Security Engineer. If you use GraphQL, add schema validation to Backend Engineer.
- **Add personas.** If your team has a specialist role (ML Engineer, Data Engineer,
  Accessibility Specialist), add a persona for it following the existing format.

### 3. Owner Persona (`.claude/cognition/owner-persona.md`)

This is YOUR personal overlay -- business context that's too specific for the generic
personas but shapes every decision. The install script creates a template from
`owner-persona.example.md`.

**What goes here:**
- Revenue targets and business metrics
- Industry compliance requirements (HIPAA, SOC2, PCI-DSS, financial services)
- Key client names that shape compliance decisions
- Your personal decision-making style
- Dashboard label preference ("NEEDS [YOUR NAME]" vs "NEEDS REVIEW")
- Content voice and branding rules

**This file is gitignored.** It never ships with the repo. It stays on your machine.

### 4. Anti-Patterns (`.claude/cognition/anti-patterns.md`)

Ships with seed entries -- universal "never do this" patterns learned from real
engineering mistakes:

- Never put secrets in documentation
- Never use private IPs in external configs
- Never claim done without e2e verification
- E2E tests must verify visual output, not just DOM
- Autonomous agents must be scoped to one repo
- Always strip markdown fences from LLM API JSON
- Don't re-verify configs that already passed

**Easiest way to customize:** Ask Claude Code:
```
> "Review my anti-patterns and remove entries that don't apply to my stack.
   Add anti-patterns based on our codebase patterns and past issues."
```

**Manual customization:**
- **Remove entries that don't apply.** If you don't use LLM APIs, remove the JSON fence entry.
- **Add your own.** Every team has hard-won lessons. Add them here.
- **Let /learn grow it.** Over time, when you correct Claude's behavior, `/learn`
  proposes new anti-pattern entries automatically. Review and approve them.

### 5. Decision Models (`.claude/cognition/decisions/`)

Structured frameworks for decisions you make repeatedly. Ships with:
- `root-cause-analysis.md` -- debugging workflow (research, evaluate, execute, test)
- `api-first-design.md` -- platform design evaluation (API-first vs GUI-first)

**What to customize:**
- **Add models for YOUR recurring decisions.** Examples:
  - `build-vs-buy.md` -- when to build custom vs use a service
  - `tech-selection.md` -- how to evaluate new dependencies
  - `incident-response.md` -- steps when production breaks
  - `code-review.md` -- what to look for in reviews
- **Format:** Each model has a Goal, Process (numbered steps), and Rules section.
  Follow the root-cause-analysis.md pattern.

### 6. Divergent Thinking (`.claude/CLAUDE-brainstem.md`)

The brainstem includes a 5-step divergent thinking process (FRAME, DIVERGE, EVALUATE,
CONVERGE, EXECUTE) that activates for production code and architecture decisions.

**What to customize:**
- **Change when it activates.** Default: production code, architecture, cross-repo changes.
  You might want it for all code, or only for architecture.
- **Change the process.** Some teams prefer 3-option evaluation, others want 2.
  Some want formal ADR documents, others want inline reasoning.

### 7. Rules Templates (`.claude/rules/`)

Path-scoped rules that apply only to specific file types or directories. Ships with
templates for components, deployment, schema, and tests.

**What to customize:**
- **Add rules for your patterns.** If you have a `src/api/` directory, create a rule
  for API endpoint conventions. If you have a `migrations/` directory, add migration rules.
- **Scope them tightly.** Rules load for every request in their scope. Keep them short
  (10-20 lines) and specific.

### 8. Hook Configuration (`.claude/jitneuro.json`)

Hooks run automatically on Claude Code lifecycle events. Ships with:
- PreCompact save prompt (block or warn)
- Session start/end hooks (recovery, autosave)
- Branch protection (blocks push to main)

**What to customize:**
- **preCompactBehavior:** "block" (default, safer) or "warn" (less intrusive)
- **protectedBranches:** default is main + master. Add release branches if needed.
- **mainPushAllowed:** URLs of repos where push to main is OK (low-risk repos).
- **autosave:** true (default) or false to disable session-end breadcrumbs.

---

## The Golden Rule

**Your system, your rules.** JitNeuro is a framework, not a religion. The defaults
are a starting point based on patterns that work well for professional software
engineering. But your team, your codebase, and your business context are unique.

Review everything. Keep what resonates. Change what doesn't. The best configuration
is the one your team actually uses.
