# Team Rules

Rules in this directory are loaded for every team member, every session.
They represent team-approved conventions, guardrails, and quality standards.

## How Rules Get Here

1. A developer captures a lesson during work (auto or via `/learn`)
2. The lesson is written to their `users/<name>/lessons.md` as PENDING
3. A TeamApprover reviews pending lessons via `/learn` or `/learn --team`
4. Approved lessons are promoted to this directory as team rules
5. Commit + push -- the whole team gets the rule on next pull

## Guidelines

- One rule per file, named by topic (e.g., `testing.md`, `api-conventions.md`)
- Keep rules concise -- under 30 lines each
- Rules should be actionable, not aspirational
- Include a "Why" section so developers understand the reasoning
- Use the same format as personal rules (see templates/rules/ for examples)
