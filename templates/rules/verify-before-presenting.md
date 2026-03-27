# Verify Before Presenting

NEVER tell Owner to check, refresh, or look at something until you have verified it yourself first.

## Before presenting ANY work to Owner:
1. Make the change
2. Verify it works by checking the actual output yourself (fetch page, read image, test API, curl endpoint)
3. If verification fails, fix it and re-verify -- do NOT present broken work
4. If you can't verify (no access to the page/system), say so explicitly -- don't disguise it as "check this for me"
5. If you've failed 2+ times on the same issue, STOP and investigate root cause before trying again -- don't keep guessing

## Before scaling ANY change to multiple items:
1. Fix ONE item
2. Verify ONE item yourself
3. Present ONE item to Owner for approval
4. Only after Owner approves, scale to all

## When something breaks:
1. Investigate first -- read the actual code, CSS, theme, rendering pipeline
2. Understand WHY before attempting a fix
3. Never guess-and-push

Owner is not your debugger. Owner reviews finished work, not work-in-progress.
