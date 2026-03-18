# Decision Model: Technology Selection

When adding any new dependency, service, or tool to a project.

## Principle

Never introduce a duplicate when an existing technology covers 80%+ of the need.
Every new dependency adds maintenance burden, security surface, and cognitive load.

## Process

1. **Identify the need** -- what specific capability is required?
2. **Check existing stack** -- does a technology already in use cover this need?
3. **Evaluate coverage** -- if existing covers 80%+, use it. Document the 20% gap.
4. **Justify if new** -- if introducing something new, document WHY the existing option doesn't work
5. **Evaluate total cost** -- licensing, maintenance, learning curve, security exposure
6. **Check team familiarity** -- can the team operate this without a specialist?
7. **Decide:**
   - Existing covers 80%+ -> use it, accept the gap
   - Existing covers less than 80% -> introduce new, document justification
   - Two options are close -> prefer the one already in the stack

## Rules

- Document every new dependency decision with reasoning
- Prefer widely-adopted, well-maintained tools over niche alternatives
- If a tool requires a specialist to operate, that's a hidden cost -- factor it in
- Re-evaluate periodically -- tools that were best-fit 6 months ago may not be today
