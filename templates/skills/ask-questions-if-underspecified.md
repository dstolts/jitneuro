---
type: skill
purpose: When a task has multiple plausible interpretations or critical details are missing, surface focused questions before executing so wrong assumptions do not waste implementation effort. Read this when an agent needs guidance on when and how to ask clarifying questions.
tags: [skill, clarification, requirements, ambiguity, agent-behavior]
scope: public
departments: [all]
read_when: Before executing any task that has multiple plausible interpretations or is missing critical details required to avoid rework.
last_evaluated: 2026-06-03
---

# Ask Questions If Underspecified

When a task has multiple plausible interpretations or critical details are missing, surface the ambiguity with focused questions before executing. Wrong assumptions waste more time than the questions cost.

## When to Apply

- Task has two or more legitimate interpretations that would lead to different implementations
- A required input (target environment, auth method, data schema, scope boundary) is absent
- The stated goal conflicts with an existing pattern or constraint in the codebase
- Do NOT apply when the answer can be found by reading existing code or config files -- search first

## Core Process

1. **Assess ambiguity** across four dimensions:
   - Objectives: what outcome is the requester actually after?
   - Scope: which files, services, or users are affected?
   - Constraints: are there performance, security, or compatibility limits?
   - Environment: dev, uat, or production? Which repo or branch?

2. **Route answerable ambiguity before asking Owner.** If the ambiguity is
   technical, domain-specific, wording, design, documentation, security, or
   architecture judgment, dispatch or load the correct specialist charter first.
   Proceed with the specialist verdict unless it triggers a RED-zone action,
   budget increase, irreversible decision, or values/business tradeoff.

3. **Ask 1-5 focused questions.** No more. Prioritize by impact -- a wrong assumption on the auth model matters more than a wrong assumption on error message wording.

4. **Format for fast answers.** Number each question. Provide options where applicable, with a recommended default labeled. Include a compact reply hint so the requester can answer in seconds:

   ```
   1. Target environment for this change?
      a) dev only  b) uat  c) production  (default: uat)
   2. Auth model to use?
      a) existing JWT middleware  b) new API key header  (default: a)
   Reply: 1b 2a
   ```

5. **Fast-path option.** Offer: "Reply 'defaults' to proceed with all recommended options."

6. **After receiving answers:** confirm the interpretation in one line, then execute.

## What to Avoid

- Asking questions answerable by reading the codebase (search first)
- Asking Owner to answer technical or domain-specialist questions that an
  appropriate chartered role can decide
- Treating "underspecified" as permission to interrupt before searching docs,
  code, memory, and specialist charters
- Asking more than 5 questions -- rank by impact and cut the rest
- Open-ended questions ("what do you want?") instead of structured options
- Proceeding with a guess when the ambiguity is high-stakes (auth, data model, scope)
- Asking one question at a time when multiple unknowns exist

## Integration

Used by: sys-architect, sys-backend, sys-frontend, sys-security, sys-qa, mssp-engineer, security-developer
