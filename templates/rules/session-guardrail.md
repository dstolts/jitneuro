# Session Guardrail

At the start of every conversation, validate `.claude/session-state/.current` points to an existing file.
If `.current` is empty, missing, or points to a non-existent/archived session, auto-create a new session immediately based on the first request before doing any other work.
Claude NEVER operates under `[session: none]`. Every response requires an active session.
