---
type: template
purpose: Read-only post-install check that confirms jit-knowledge commands, hooks, settings, skills, repo bootstrap surfaces, and reboot resume surfaces are present for the active Claude Code session.
read_when: After running the jit-knowledge installer, after updating command/hook templates, or when a fresh Claude Code session cannot see expected slash commands.
tags: [slash-command, verify, install, bootstrap, jit-knowledge]
scope: public
last_evaluated: 2026-06-21
---

# /verify

Run a read-only installation health check. Do not edit files.

## Checks

1. User-level Claude files:
   - `$HOME/.claude/settings.json` exists.
   - `hooks.SessionStart` includes either `jit-knowledge-session-start.sh` or
     `session-start-master-orchestrator-rule.sh`.
   - `hooks.PreCompact` includes either `jit-knowledge-pre-compact.sh` or
     `pre-compact-knowledge-rebootstrap.sh`.
   - `$HOME/.claude/hooks/jit-knowledge-session-start.sh` OR
     `$HOME/.claude/hooks/session-start-master-orchestrator-rule.sh` exists.
   - `$HOME/.claude/hooks/jit-knowledge-pre-compact.sh` OR
     `$HOME/.claude/hooks/pre-compact-knowledge-rebootstrap.sh` exists.
   - `$HOME/.claude/hooks/session-lane-resolve.sh` exists (WS6, Epic #4526 --
     the shared session-identity-first lane resolver sourced by
     `stop-continue-queue.sh` and `agent-spawn-log.sh`; absence is a WARN,
     not a FAIL, since both hooks have a guarded inline fallback).
   - `$HOME/.claude/commands/knowledge.md` exists.
   - `$HOME/.claude/commands/verify.md` exists.
   - `$HOME/.claude/commands/afk.md` exists.
   - `$HOME/.claude/commands/save.md` exists.
   - `$HOME/.claude/rules/jit-knowledge-load.md` exists.
2. Knowledge root:
   - Resolve `<KnowledgeRoot>` by `JIT_KNOWLEDGE_ROOT`, then
     `$HOME/.claude/workspace.json`, then `$HOME/Code/jit-knowledge`.
   - Confirm `<KnowledgeRoot>/AGENTS.md`, `COMPANY.md`, `README.md`, and
     `INDEX.md` exist.
3. Active repo/root:
   - Report whether `AGENTS.md`, `CLAUDE.md`, `.knowledge/index.md`,
     `.jitneuro/engrams/context.md`, the active Hub file,
     `<active-hub-dir>/questions.md`, `<active-hub-dir>/agent-inbox.md`,
     `<active-hub-dir>/agent-goals.md`, `<active-hub-dir>/agent-permissions.md`,
     and `todo/backlog.md` exist.
   - If the active root has `CLAUDE.md` but no `AGENTS.md`, warn that Claude may
     load context while Codex may not.
   - If the active Hub exists, report whether it has `WORKING TREE CONTEXT`
     with `active_path` and `continue_from`.
   - If `.sessions/` has checkpoints, report whether the latest
     checkpoint names the active Hub, questions file, agent-inbox file,
     agent-goals file, `continue_from`, and validation state.
4. Skills:
   - Confirm `$HOME/.claude/skills/knowledge/SKILL.md` exists.
   - Confirm `$HOME/.claude/skills/verify/SKILL.md` exists.

## Output

Print a concise report:

```text
JIT-KNOWLEDGE VERIFY
Status: PASS | WARN | FAIL
KnowledgeRoot: <path or missing>
User commands: knowledge=<ok/missing>, verify=<ok/missing>, afk=<ok/missing>, save=<ok/missing>
Hooks: SessionStart=<ok/missing>, PreCompact=<ok/missing>, LaneResolve=<ok/missing>
Active root: <path>
Active surfaces: AGENTS=<ok/missing>, CLAUDE=<ok/missing>, .knowledge=<ok/missing>, engram=<ok/missing>, Hub=<ok/missing>, questions=<ok/missing>, agent-inbox=<ok/missing>, agent-goals=<ok/missing>, agent-permissions=<ok/missing>, backlog=<ok/missing>
Reboot surfaces: working_tree_context=<ok/missing/n/a>, latest_checkpoint=<ok/missing/n/a>, validation_state=<ok/missing/n/a>
Warnings:
- <warning or none>
```

Use `PASS` only when the command and hook surfaces are present. Use `WARN` for
repo-local surface gaps. Use `FAIL` when the knowledge root or core commands/hooks
are missing.
