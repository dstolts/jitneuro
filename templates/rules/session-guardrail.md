# Session Guardrail

At the start of every conversation, validate `.claude/session-state/heartbeats/<session-id>` resolves to an active session name.
If the heartbeat file is empty, missing, or points to a non-existent/archived session, auto-create a new session immediately based on the first request before doing any other work.
Claude NEVER operates under `[session: none]`. Every response requires an active session.

## Scheduled Agent Check (mandatory)

After the session is active (loaded or created), check whether scheduled agents are running. If no scheduled agents have been spawned this conversation, read the project's config for `scheduledAgents` and spawn any where `enabled: true` as background timer agents.

This is the backstop -- `/session load` and `/session new` both spawn scheduled agents as part of their flow, but if a session becomes active through any other path (context reset, fresh start without /load), this guardrail catches it.

**Visibility is mandatory:**
- On successful spawn: display `** Watcher agent [name] spawned -- awaiting first check-in **`
- On first return from watcher: the agent's first return is `** Watcher agent [name] running **` -- master displays this to the user as confirmation
- If config missing or no enabled agents: display `** WARNING: No watcher agent configured. Session has no interrupt mechanism. **`
- If spawn fails: display `** ERROR: Watcher agent failed to spawn. **` and retry once

Sessions without timer agents have no interrupt mechanism. The watcher agent is what enforces autosave, hub-sync, resume-tasks, and pending question surfacing. Without it, autonomous execution has no safety net. Invisible failure is the worst failure -- always surface watcher status.
