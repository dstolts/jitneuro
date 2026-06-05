---
type: rule
purpose: Prohibit asking reviewers to check or validate anything until the agent has verified it independently, including read-after-write confirmation and root-cause investigation before retry.
tags: [verification, quality, read-after-write, review-hygiene, presentment]
scope: public
departments: [all]
read_when: Before presenting any completed work, change, or fix to a reviewer or Owner for evaluation.
last_evaluated: 2026-06-03
---
# Verify Before Presenting

NEVER tell a reviewer to check, refresh, or look at something until you have verified it yourself first.

## Before presenting ANY work:
1. Make the change
2. Verify it works by checking the actual output yourself (fetch page, read image, test API, curl endpoint)
3. If verification fails, fix it and re-verify -- do NOT present broken work
4. If you cannot verify (no access to the page/system), say so explicitly -- don't disguise it as "check this for me"
5. If you've failed 2+ times on the same issue, STOP and investigate root cause before trying again -- don't keep guessing

## Before scaling ANY change to multiple items:
1. Fix ONE item
2. Verify ONE item yourself
3. Present ONE item for approval
4. Only after approval, scale to all

## When something breaks:
1. Investigate first -- read the actual code, rendering pipeline, or service response
2. Understand WHY before attempting a fix
3. Never guess-and-push

Reviewers review finished work, not work-in-progress.

## Read-after-write discipline
Always verify file state AFTER a write (read + validate non-empty) before testing downstream. An empty or partially written config causes downstream failures that look like unrelated errors.
