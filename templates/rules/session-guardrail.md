# Session Guardrail

At the start of every conversation, validate `.claude/session-state/heartbeats/<session-id>` resolves to an active session name.
If the heartbeat file is empty, missing, or points to a non-existent/archived session, auto-create a new session immediately based on the first request. **Auto-create MUST write the heartbeat with the session name as its FIRST action, before doing any other work:**

```bash
echo -n "<name>" > ".claude/session-state/heartbeats/<session-id>"
```

Generate `<name>` from the first request (lowercase, hyphenated, task-descriptive). Use Bash echo only, never Write/Edit (the PostToolUse hook races those). **Appended-task trap:** if a task or question rode in with the first message, write the heartbeat FIRST, then address the task -- the request never cancels the heartbeat write. A skipped heartbeat is the new-session form of the load bug: the statusline shows `none` and the session tag drops.
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
