---
type: skill
purpose: Post-install verification skill for any agent or Owner confirming all 9 JitNeuro components (CLAUDE.md, hooks, session-state, engram, help) are present and wired; skipping means broken installs go undetected and hooks silently fail to fire.
read_when: After running the JitNeuro installer or after any update to hooks, settings.json, or session-state infrastructure.
tags: [verify, installation, post-install, diagnostic, read-only]
scope: public
departments: [all]
status: canonical
graduation_target: skills/verify/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /verify

Post-install verification. Checks 9 components. READ-ONLY operation.

## Components checked

1. **CLAUDE.md** -- exists at repo root with required sections (Identity, Trust Zones, Key Paths)
2. **.claude/ folder** -- exists with commands/ subdirectory
3. **Workspace commands** -- workspace .claude/commands/ has the expected command files
4. **jitneuro.json** -- exists at `.jitneuro/jitneuro.json` with valid JSON structure
5. **Engram** -- workspace engram exists at `.claude/engrams/<repo>-context.md`
6. **Session state** -- `.claude/session-state/` folder exists and is writable
7. **Heartbeats** -- `.claude/session-state/heartbeats/` folder exists
8. **Hooks** -- `settings.json` has SessionStart and PostToolUse hooks registered
9. **Help file** -- `.claude/help.md` exists

## Output format

```
JITNEURO VERIFICATION
=====================
[OK] CLAUDE.md present
[OK] .claude/commands/ present (22 commands)
[OK] jitneuro.json valid
[WARN] Engram missing: project-context.md (run /learn to create)
[OK] session-state/ writable
[OK] heartbeats/ present
[OK] Hooks registered (SessionStart, PostToolUse)
[OK] help.md present

Status: 8/9 OK, 1 WARN
```

## What this does NOT do

Does not modify any files. Does not commit. Read-only verification.
