---
type: rule
purpose: BINDING for every backend/API agent writing or reviewing catch blocks and error handlers -- every catch MUST console.error the full stack and context in all environments, never gated behind NODE_ENV; skipping means production errors are invisible exactly when they matter, allowing broken behavior to ship and persist undiagnosed.
trigger: any agent writing, reviewing, or modifying a catch block, error-handling path, or HTTP error response in a backend service
tags: [error-handling, logging, debugging, observability, production]
scope: public
read_when: Before writing or reviewing any catch block, error handler, or HTTP error response in a backend service.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_never_suppress_errors_surface_on_console.md) -- Knowledge session 2026-06-01
---

# Never Suppress Errors -- Surface Them on the Console

## Rule

Every `catch` block must `console.error` (or the project logger) the full error -- including stack trace and relevant safe context (userId, route, operation) -- in ALL environments.

- Do NOT gate error visibility behind `process.env.NODE_ENV === 'development'`. Server logs are not customer-facing; hide nothing from them.
- No empty `catch {}`. No catch that only `return`s without logging.
- A catch that continues execution (non-fatal path, e.g. quota-check blip) may continue -- but it MUST log the full error first. "Don't throw" does not mean "don't log."
- When a 500 cannot be diagnosed, the first fix is to stop suppressing the error, not to add a temporary debug flag.

HTTP responses: return a stable error code and short safe message to the client (see no-internals-or-prompts-to-client rule for the client-side boundary). Server logs always get the full stack.

## Why

- Hidden errors are undiagnosable production bugs. An error visible only in development is invisible exactly when it matters: real customer traffic in UAT or prod.
- Suppressing an error to make a response look clean is a form of bypassing root cause -- it ships broken behavior and prevents diagnosis.
- Multiple real customer-facing breakages in this session were masked by suppressed errors that let tests pass while production failed.

## What violates this rule

- `catch (e) {}` -- swallowed without logging.
- `details: process.env.NODE_ENV === 'development' ? error.message : undefined` -- stack hidden in prod.
- Any catch that sets a flag or returns an error code without also logging the full error.
- Adding a "temp expose" flag to debug a production issue instead of making full logging the permanent default.

## Origin

2026-06-01 -- a PUT /settings handler returned 500 in UAT with no visible stack because the handler gated `error.message` behind `NODE_ENV === 'development'`. Owner directive: "DO NOT SUPPRESS ERRORS, SURFACE THEM ON THE CONSOLE. This is how buggy code gets shipped."
