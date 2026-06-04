---
type: rule
purpose: BINDING for every backend/API agent writing error handlers and analysis endpoints in production or UAT -- HTTP responses MUST use a safeErrorResponse helper that sends only a stable code and generic message to the client while logging full detail server-side; skipping exposes stack traces, SQL schema, and proprietary LLM prompt content to any caller who triggers an error.
trigger: any agent writing or reviewing an HTTP error response, catch block that calls res.json, or an analysis/LLM endpoint response in a non-local environment
tags: [security, moat-protection, api, error-handling, trade-secrets]
scope: public
read_when: Before writing any HTTP error response, catch block that calls res.json, or analysis/LLM endpoint response in a non-local environment.
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_moat_no_internals_or_prompts_to_client.md) -- Knowledge session 2026-06-01
---

# No Internals or Prompts to Client

## Rule

In production and UAT, HTTP responses must contain only a stable error code and a short safe message. Never include:

- Full stack traces
- Internal file paths
- Raw SQL text
- Executed LLM/backend prompt or template content

Server logs (console.error): full error + stack + context -- always, every environment. This is the complement to the never-suppress-errors rule: the split is by DESTINATION, not by verbosity.

Use a single `safeErrorResponse(res, status, error)` helper:
- Always `console.error` the full error server-side.
- Client body: `{error: <label>, code: <stable code>, message: <generic in prod, verbose in dev>}`.
- Never put `error.stack`, SQL, paths, or prompt content in any client body field in any non-local environment.

Analysis / LLM endpoints: return only the result. The executed prompt/template/system-prompt is internal. It never reaches `res.json` or SSE stream body.

## Why

- Stack traces and file paths expose architecture to attackers.
- SQL text reveals schema, table names, and query patterns -- direct attack surface.
- LLM prompt content is a trade secret: it discloses proprietary methodology and enables prompt-injection cloning.
- Leaking any of these through a public API is a moat hole that cannot be unrung once exploited.

## What violates this rule

- `res.json({ error: error.message })` in a prod route -- message may contain SQL or path.
- `details: error.stack` in any non-local response body.
- An analysis endpoint whose response includes the `system_prompt` or `prompt` field that was sent to the LLM.
- Error responses that differ only in verbosity between environments without a structural `safeErrorResponse` pattern enforcing the boundary.

## Origin

2026-06-01 -- a settings handler returned `details: error.message` unconditionally as a first error-surfacing pass. Owner: production API responses must never carry stack traces, SQL, or prompt content to the client. Resolved via a `safeErrorResponse` helper.
