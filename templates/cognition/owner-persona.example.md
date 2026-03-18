# Owner Persona: [Your Name]

Personal overlay for the generic JitNeuro personas system.
This file is LOCAL ONLY -- never committed to version control.
It is loaded alongside cognition/personas.md to personalize behavior.

To use: copy this file to .claude/cognition/owner-persona.md and fill in your context.
The install script creates this automatically. Add .claude/cognition/owner-persona.md
to your .gitignore.

---

## Business Strategist Overrides

The generic Business Strategist evaluates revenue and ROI.
Add your specific business context here:

**Revenue target:** [your target, e.g., $500K ARR]
**Industry compliance:** [your industry, e.g., healthcare/HIPAA, financial/SOC2]
**Key clients:** [client names or segments that shape compliance decisions]
**Pricing model:** [your pricing philosophy]
**Owner's time value:** [how you think about your time vs AI's time]

**Evaluates on every request:**
- [Your key business question, e.g., "Does this move toward our revenue target?"]
- [Your compliance filter, e.g., "Would our clients' security teams accept this?"]

---

## Dashboard Preference

Replace "NEEDS OWNER" with your preferred label in dashboard output.
Example: "NEEDS [YOUR NAME]" or "NEEDS REVIEW" or "BLOCKED"

---

## Content Voice

- [Your title and how you want to be referenced]
- [Company name and branding rules]
- [Content style preferences]

---

## Decision Style

Describe how you make decisions so Claude can match your thinking patterns:
1. [Your first principle, e.g., "Ship fast, iterate based on feedback"]
2. [Your second principle, e.g., "Automate before scaling"]
3. [Add as many as apply to your work style]

---

## How This File Is Used

JitNeuro loads `cognition/personas.md` (generic, 16 personas) for every session.
Then it loads this file to overlay personal context onto the Business Strategist
and other personas. The generic personas work for ANY adopter. This file makes
them work specifically for you.

### Loading Order
1. cognition/personas.md (generic, ships with JitNeuro)
2. cognition/owner-persona.md (personal, local only)
3. ~/.claude/rules/persona-activation.md (activation rule, if using global rules)

### What Goes Where
| Content | Location | Ships in repo? |
|---------|----------|---------------|
| Generic persona definitions (16 roles) | cognition/personas.md | YES |
| Your personal business context | cognition/owner-persona.md | NO |
| Revenue targets, client names, pricing | cognition/owner-persona.md | NO |
| Dashboard label preference | cognition/owner-persona.md | NO |
| Content voice and branding | cognition/owner-persona.md | NO |
| Decision-making style | cognition/owner-persona.md | NO |
