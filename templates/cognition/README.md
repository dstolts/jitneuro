# Cognition Layer (Phase 2)

The cognition layer extends JitNeuro from memory management (what to know) to
cognitive architecture (how to decide).

## Files

| File | Purpose | Ships in repo? |
|------|---------|---------------|
| personas.md | 16 expert personas that evaluate every request | YES (generic) |
| owner-persona.md | Your personal business context overlay | NO (local only) |
| owner-persona.example.md | Template for creating your owner-persona.md | YES |
| decisions/*.md | Decision frameworks for common scenarios | YES |
| anti-patterns.md | Learned constraints from past mistakes | NO (built by /learn) |

## How It Works

1. **Personas** -- 16 specialist roles (Security Engineer, DBA, Business Strategist, etc.)
   evaluate every request simultaneously. Primary personas drive the approach.
   Secondary personas flag issues inline. Silent personas stay quiet.

2. **Owner Persona** -- Your personal overlay adds business context to the generic
   personas. Revenue targets, compliance requirements, client names, and decision
   style go here -- not in the generic personas file.

3. **Decision Models** -- Structured frameworks in decisions/ that guide specific
   scenarios (debugging, architecture choices, build-vs-buy). Updated by /learn
   when the owner overrides recommendations.

4. **Anti-Patterns** -- Learned constraints built over time by /learn. When the
   owner corrects a mistake, /learn proposes an anti-pattern entry so the same
   mistake is never repeated. This file starts empty and grows with use.

## Customization

Copy `owner-persona.example.md` to `.claude/cognition/owner-persona.md` and fill
in your business context. The install script does this automatically.

Add decision models to `decisions/` for scenarios specific to your workflow.
The root-cause-analysis.md model ships as an example.
