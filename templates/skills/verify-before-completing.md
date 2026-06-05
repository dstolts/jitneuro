---
type: skill
purpose: Require external confirmation that a change actually works before reporting it done; defines the fix-one-verify-one-scale discipline and the investigation-first rule when something breaks. Read this before marking any task complete when the output can be externally verified.
tags: [skill, verification, quality, definition-of-done, agent-behavior]
scope: public
departments: [all]
read_when: Before marking any task complete when the output can be externally verified (code deployed, file written, endpoint changed, content published).
last_evaluated: 2026-06-03
---

# Verify Before Completing

Never report a task done until you have externally confirmed it works. Owner reviews finished work -- not work in progress.

## When to Apply

Every time a task produces an output that can be verified: code deployed, API endpoint changed, file written, config updated, content published.

## Core Process

1. **Make the change.**
2. **Verify it yourself** -- fetch the page, call the endpoint (curl), read the written file, test the function. Use real external verification, not re-reading the code you just wrote.
3. If verification fails: fix it, re-verify. Do NOT present broken work.
4. If you cannot verify (no access to the system): say so explicitly. Do not disguise it as "check this for me."
5. If you have failed to fix the same issue 2+ times: STOP. Investigate root cause before trying again. Do not keep guessing.

## Before Scaling to Multiple Items

Fix ONE. Verify ONE. Present ONE to Owner for approval. Only after approval: scale to all.

This prevents batch failures -- a bug in the first item becomes a bug in all 50 items if you scale before verifying.

## When Something Breaks

1. Investigate first: read the actual code, config, rendering pipeline, or logs.
2. Understand WHY before attempting a fix.
3. Never guess-and-push.

## What to Avoid

- Saying "I updated the endpoint" without calling it
- Saying "the file was written" without reading it back
- Asking Owner to check if it worked -- that is the agent's job
- Scaling a bulk change before confirming the first item is correct
- Retrying the same broken approach more than twice without changing the investigation strategy

## Integration

Used by: backend, frontend, devops, SRE, QA, security, and repo-steward roles
