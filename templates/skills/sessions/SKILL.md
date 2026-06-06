---
type: skill
purpose: List and manage all session checkpoints with numbered output, stale detection, archiving, and deletion; skipping means session sprawl accumulates silently and stale sessions waste context on load.
read_when: When auditing active sessions, identifying stale or archived sessions, or cleaning up session sprawl.
tags: [sessions, session-management, archive, stale, cleanup]
scope: public
departments: [all]
status: canonical
graduation_target: skills/sessions/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /sessions

List and manage all session checkpoints.

## Operations

### `/sessions` (default: numbered list)
List all session checkpoints in numbered format:
```
Active sessions:
  1. sprint-day2       (saved 2h ago)   [IN PROGRESS: fix login bug]
  2. content-pipeline  (saved 1d ago)   [BLOCKED: waiting for Owner review]
  3. content-review    (saved 3d ago)   [STALE]
```

Uses sessions.json (never scans heartbeat files directly).

### `/sessions show <name|#>`
Display full checkpoint content for a session.

### `/sessions stale`
List sessions not updated in 7+ days.

### `/sessions clean`
Offer to archive all stale sessions (>14 days). Presents list before acting.

### `/sessions archive <name|#>`
Archive a specific session to `.archive/` within session-state.

### `/sessions archived`
List archived sessions.

### `/sessions restore <name|#>`
Restore an archived session to active.

### `/sessions delete <name|#>`
Delete a session checkpoint (requires confirmation). Archived sessions only.

### `/sessions dashboard`
Cross-session blockers view. Shows NEEDS OWNER items across all active sessions.

## Implementation notes

- NEVER scan heartbeats/ directory to enumerate sessions
- All session listing goes through sessions.json via the bundled deterministic runner:
  `scripts/sessions.sh` (POSIX / Git-Bash) or the workspace `show-sessions.ps1` (Windows-native).
  Prefer the runner over ad-hoc parsing, per the Runners-Over-Tokens principle.
- Numbered references (#) resolve via the last-displayed numbered list
