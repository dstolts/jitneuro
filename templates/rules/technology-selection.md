# Technology Selection

Before adding any new dependency, service, or tool:

1. Check your project's tech-stack documentation (bundle, engram, or CLAUDE.md) for existing technologies.
2. Determine if an existing technology already covers the need.
3. If it does, use it and reference the repo or project where it is already configured.
4. If introducing something new, document WHY the existing option does not work in the spec or decision log.
5. Never introduce a duplicate when an existing tool covers 80%+ of the need.

## Why

Technology sprawl increases maintenance burden, onboarding friction, and security surface area.
Every new dependency is a long-term commitment -- updates, vulnerabilities, compatibility.
Reusing what already works is almost always cheaper than adopting something new.

## Decision Template

When proposing a new technology, answer these questions:

- **What need does this address?**
- **What existing tool was evaluated?**
- **Why does the existing tool fall short?** (must be specific, not "I prefer X")
- **What is the maintenance cost of adding this?**
- **Who owns updates and security patches?**

Log the decision in your project's decision log with date and reasoning.
