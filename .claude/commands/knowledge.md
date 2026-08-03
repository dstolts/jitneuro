---
type: template
purpose: Force the current Claude Code session to re-run the full jit-knowledge bootstrap chain, print the mandatory preflight/attestation, and resume only after context is loaded.
read_when: When a session feels off-route, after context compaction, after Owner correction, or before continuing work from a handoff.
tags: [slash-command, bootstrap, knowledge, master-orchestrator, jit-knowledge]
scope: public
last_evaluated: 2026-06-21
---

# /knowledge

Re-anchor the current session to the current workspace and jit-knowledge context.
Use this when a session feels off-route, after compaction, after correction, or
before continuing work from a handoff.

## Procedure

1. Stop executable work during the bootstrap pass. Do not edit files, commit,
   open PRs, deploy, or dispatch agents until the preflight is printed.
2. Resolve `<CodeBasePath>` from the active project path or `$HOME/Code`.
3. Resolve `<KnowledgeRoot>` in this order:
   - `JIT_KNOWLEDGE_ROOT`
   - `$HOME/.claude/workspace.json` key `jit_knowledge_root`
   - `<CodeBasePath>/jit-knowledge`
4. Read the bootstrap chain in this order:
   - `<CodeBasePath>/AGENTS.md`
   - `<KnowledgeRoot>/AGENTS.md`
   - `<KnowledgeRoot>/COMPANY.md`
   - `<KnowledgeRoot>/README.md`
   - `<KnowledgeRoot>/INDEX.md` routing index
   - every binding rule named by `<CodeBasePath>/AGENTS.md`
   - active repo `AGENTS.md`, `CLAUDE.md`,
     `<active-hub-dir>/agent-inbox.md`,
     `<active-hub-dir>/agent-goals.md`,
     `<active-hub-dir>/agent-permissions.md`,
     `<active-hub-dir>/questions.md`, active Hub file, and
     `todo/backlog.md` where present; preserve the repo's existing hub
     directory and filename case
   - linked plan files named by active Hub or checkpoint rows when resuming
     from `/load`; do not read every plan directory
5. For master-orchestrator sessions on the Owner portfolio, also load the horizon
   auto-load unit required by `rules/bootstrap-attestation.md` when those files
   exist.
6. Apply `rules/session-working-tree-context.md`: read the active Hub/session
   working-tree context, compare it to the current working directory, and do
   not mutate files until the session is operating from the intended path or
   Owner explicitly retargets the work.
7. When invoked after `/load`, read back the checkpoint's validation state and
   preserve task authorization exactly (`approved` is not executable;
   `execute-authorized` still obeys trust-zone and verification gates).
8. Print the Mandatory Session Preflight block from `<CodeBasePath>/AGENTS.md`.
9. Print a Bootstrap Attestation: list every file actually read, state that
   `INDEX.md` was ingested as the routing index, and name any missing required
   file as a warning with the consequence.
10. If invoked as `/knowledge --stop`, stop after the status report. Otherwise,
   resume only work that is already authorized and executable under
   `rules/autonomous-execution.md`.

## Required Output Shape

```text
Role: master/orchestrator
Loaded: <files actually read; INDEX ingested>
Repo: <active repo path/name>
Working tree: <current path; matches Hub/session context yes/no>
Work type: <docs | API/backend | frontend UI | deploy | research | mixed>
Execution route: <direct code | PR/docs | deploy script | verification only | other>
Direct edits allowed: <yes/no and why>
Verification gate: <build/test/browser/API/deploy check required before saying testable>

Bootstrap Attestation:
- Files read:
  - <absolute path>
- Missing required files:
  - <path or none>
- Compliance: master stays thin, delegated work must be verified, worktrees are used for isolated mutating work, RED-zone actions require Owner approval.
```

If any required knowledge artifact is missing, surface it plainly. A missing
knowledge artifact is an alarm, not a no-op.
