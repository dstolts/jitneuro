# Dev Shop Pack

Portable, tool-neutral role contracts for an AI-assisted engineering team. The
pack uses the [AGENTS.md standard](https://agents.md/) so an AGENTS-aware tool
can discover the nearest role instructions without a proprietary runtime.

## Install and route

Copy `dev-shop-pack/` into a repository, then point the repository's root
`AGENTS.md` at `dev-shop-pack/AGENTS.md`. Dispatch work by naming one role and
loading that role's `AGENTS.md`:

- `tech-lead-architect`: architecture and final engineering review
- `backend-developer`: APIs, server logic, and data access
- `frontend-developer`: UI, client state, and accessibility
- `qa-engineer`: test strategy and functional verification
- `devops-engineer`: CI/CD, containers, and deployment configuration
- `site-reliability-engineer`: SLOs, observability, and incident readiness
- `security-engineer`: threat analysis and security verification
- `code-reviewer`: independent correctness and maintainability review
- `ux-designer`: interaction specifications and reference mockups
- `product-manager`: scope, acceptance criteria, and product evidence

Roles may read broadly but write only within their stated domain. Findings
outside a role's domain are reported to the owning role, not fixed opportunistically.
Use [validation-chain.md](validation-chain.md) for sequential review gates.

## Deliberate boundary

This public pack contains reusable engineering contracts only. It does not
include private organizational structure, model-selection policy, budgets,
customer data, credentials, internal tooling, or proprietary orchestration.
