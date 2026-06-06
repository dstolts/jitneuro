---
type: reference
purpose: The owner's identity, context, and working preferences -- the "who am I working for and how do they want me to work" profile that every agent loads so its judgment, tone, autonomy, and escalation behavior match this specific owner instead of a generic default; an unfilled or skipped profile means agents guess at preferences and produce work that misreads the owner.
read_when: At session start, by every agent, before doing substantive work -- to load who the owner is and how they want the AI to operate.
tags: [owner-profile, identity, preferences, onboarding, personalization, fill-in-template]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
---

# Owner Profile

> **THIS IS A TEMPLATE. Replace every `<...>` placeholder with your own information.**
> This file tells the AI who you are and how you want it to work. Agents read it at the
> start of every session. The more specific you are, the better the AI's judgment matches
> yours. Delete guidance lines (the `>` blocks) once you have filled in your answers.

---

## Who I Am

- **Name:** <your name>
- **Role / title:** <e.g., founder, solo developer, engineering lead>
- **Organization / project:** <company or project name, or "independent">
- **Location / timezone:** <e.g., US Eastern (UTC-5)> -- affects scheduling and "today" reasoning
- **One line about me:** <the single most useful thing for an agent to know about you>

## What I Do

> What are you building or running? What does the AI most often help you with?

<2-4 sentences on your work and where the AI fits in>

## How I Want the AI to Work With Me

> These shape tone, pace, and how much the AI does before checking in.

- **Communication style:** <e.g., direct and concise; lead with the recommendation; minimal preamble>
- **Detail level:** <e.g., summaries with details on request; or full reasoning every time>
- **Autonomy:** <e.g., proceed on low-risk work and report; ask before anything irreversible>
- **Format preferences:** <e.g., ASCII only, no emojis; short lists over long prose>

## My Priorities

> What should the AI optimize for when choices compete (speed vs. completeness, cost vs. quality)?

1. <priority 1>
2. <priority 2>
3. <priority 3>

## Decision Authority (what the AI decides vs. what I decide)

| The AI may decide and execute | I decide (AI proposes, waits) |
|---|---|
| <e.g., formatting, refactors, test additions> | <e.g., production deploys, spending money, customer-facing copy> |

## Hard Lines (never do these)

> Bright-line rules the AI must never cross, regardless of the task.

- <e.g., never push to the main branch without my approval>
- <e.g., never send email or post publicly on my behalf without confirmation>
- <e.g., never put secrets in committed files>

## Context Pointers (optional)

> Where the AI can find more about your work -- repos, docs, dashboards. Use names or
> relative references, not secrets.

- <e.g., main repo: <name>; docs: <location>; key constraints: <...>>

---

_Keep this profile current. When your role, priorities, or preferences change, update this
file -- it is the first thing agents read about you._
