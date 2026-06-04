# Horizon Layer -- Strategic Context for AI Sessions

## What This Is

The horizon layer is a small set of plain-text files that capture your durable
strategic context: who you are, where your venture is going, what you are trying to
achieve right now, how you make decisions, and how you want to work with an AI
assistant.

Every AI session that follows the DOE (Directive Orchestration Execution) framework
reads these files at startup. That gives every session a consistent north star so
that output, recommendations, and autonomous work align with your actual goals --
not with generic defaults.

## Why It Matters

Without a horizon layer, every AI session starts blind. The assistant has to
re-infer your context from conversation history, or it makes assumptions that do not
match your situation. Over time that creates drift: the AI optimizes for the wrong
things.

With a horizon layer, the assistant knows your vision before you type the first word.
It can prioritize correctly, escalate the right decisions, and skip asking questions
you have already answered.

## What These Files Are NOT

These are not operational task lists. They are not session logs or sprint plans.
They change infrequently -- roughly when your strategy changes, not when your to-do
list changes. Think of them as the briefing document you would give a new executive
assistant on day one.

## Files in This Layer

| File | Purpose |
|---|---|
| vision.md | Where you are going (3-5 year horizon) |
| mission.md | What you do, for whom, and why |
| goals.md | Current top priorities and measurable targets |
| operating-rhythm.md | Your daily/weekly cadence and how you want the AI to work with you |
| decision-routing.md | What the AI handles autonomously vs. what it escalates to you |
| owner-profile.md | Your working style, expertise, and communication preferences |

## How to Fill These In

Run the onboarding interview described in POPULATE-HORIZON.md. A Claude session
will ask you questions one topic at a time and write your answers directly into
these files. You do not need to edit raw markdown.

See: templates/horizon/POPULATE-HORIZON.md

## How the Framework Loads These Files

The DOE framework references this directory from your AGENTS.md or CLAUDE.md
bootstrap chain. When a new session starts, it reads these files before any
task work begins. You can also trigger a re-read with the /bootstrap command.

## Updating

Edit any file directly, or ask a Claude session to update it based on new
direction you describe in conversation. After major strategy changes, re-run
the POPULATE-HORIZON interview to refresh all files at once.
