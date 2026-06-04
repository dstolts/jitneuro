---
type: rule
purpose: BINDING for every agent investigating authentication or login failures -- diagnose via logs and request/response inspection before touching any credential; Owner must explicitly request a change before any password reset, API key rotation, or .env auth value modification; skipping means a self-inflicted credential change creates a stale-env timing window that locks Owner out while curl falsely reports success.
trigger: any agent encountering a login failure, auth error, 401/403, or "invalid credentials" symptom during debugging or investigation
tags: [credentials, security, auth, debugging, owner-approval]
scope: public
read_when: Before diagnosing any login failure, 401/403 error, or "invalid credentials" symptom -- read before touching any credential value.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_never_change_creds.md) -- Knowledge session 2026-06-01
---

# Never Change Credentials Without an Explicit Request

## Rule

Do NOT reset passwords, rotate API keys, or modify auth configuration unless Owner
explicitly asks. Credential changes are never a diagnostic step -- they are a
deliberate, Owner-authorized action.

If login or auth is failing, diagnose first:

1. Add debug logging to see what credential is being checked.
2. Read the actual request/response to confirm which value is in play.
3. Check whether the running container or process has the correct env var loaded.
4. Present your diagnosis and a proposed fix to Owner before touching any credential.

## Why

A "helpful" password change caused a cascading failure: the container loaded a stale
env between the change and the restore attempt, so browser login failed while curl
succeeded (different container restart timing). The symptom looked like a bug but was
self-inflicted. Owner was locked out; debugging consumed over an hour.

The failure mode is insidious: the AI sees curl working and reports "it works for me"
while the Owner is stuck in the browser. The credential change introduced a timing
window that cannot be diagnosed without knowing the change was made.

## What violates this rule

- Changing a password as part of a "let me try resetting this" debugging loop.
- Rotating an API key to rule out staleness without Owner direction.
- Modifying `.env` auth values during an investigation without explicit Owner approval.
- Presenting a credential change as the first option before diagnosing root cause.

## Origin

2026-04-10: changed jit-dash password from Command26AI! to JitDash2026! as a fix
attempt, then tried to restore it. Stale container env caused browser login to fail
while curl worked. Owner unable to log in; hour lost. Rule: diagnose, never change.
