---
type: rule
purpose: Require maintaining a pending-questions queue for non-blocking decisions and surfacing it at the end of every response so no decision is lost in long conversations.
tags: [pending-questions, queue, decisions, non-blocking, session-state]
scope: public
read_when: At session start for every interactive session to establish the pending-questions queue before any substantive work begins.
last_evaluated: 2026-06-03
---
# Pending Questions Queue

Track unanswered questions for the user. Surface them at the end of every response so
nothing gets lost in long conversations.

## How It Works

Maintain an internal list of questions that need user input. When a question arises during
work but is not blocking, add it to the queue instead of stopping to ask immediately.

## Rules

1. **Add to queue:** When you encounter a decision that needs user input but is not blocking
   current work, add it to the queue silently and keep working.

2. **Surface every response:** At the end of every response, if the queue is non-empty, display it:
```
---
Pending questions:
  Q1. [question] (from: [context where it arose])
  Q2. [question] (from: [context])
Answer by number (e.g., "Q1: yes"), or "clear Q1" to dismiss.
```

3. **Remove when answered:** When the user answers a question (e.g., "Q1: use option A"),
   remove it from the queue and act on the answer.

4. **Dismiss stale questions:** If the user says "clear Q1" or "clear all", remove without
   answering. Some questions become irrelevant as work progresses.

5. **Persist on session save:** Write any unanswered questions to the active task list under
   a "PENDING QUESTIONS" section so they survive context reset. On session load, read them
   back and re-populate the queue.

6. **Do not duplicate:** Before adding a question, check if the same question (or close
   equivalent) is already in the queue.

7. **Keep it short:** Each question should be one line. If context is needed, put it in
   parentheses after the question.

## What Goes in the Queue

- Design decisions with multiple valid approaches
- User preferences not covered by existing rules
- Clarifications about requirements
- Approval needed for significant or destructive actions
- Questions from subagents that require human judgment

## What Does NOT Go in the Queue

- Blocking questions (cannot continue without the answer) -- ask immediately
- Questions already answered by rules or memory -- just follow the rule
- Rhetorical questions or status updates
