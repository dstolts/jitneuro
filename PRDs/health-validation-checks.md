# User Story: Add Config + Memory Validation to /health

**Created:** 2026-03-27
**Priority:** 70/100
**Status:** Ready for execution
**Handoff:** Agent-ready

## Summary

Extend /health to validate jitneuro.json schema and memory file frontmatter. Currently /health checks file existence and line counts. It should also catch invalid config values and malformed memory files before they cause silent failures.

## Problem

- Typo in jitneuro.json (`"preCompactBehavior": "blokc"`) silently breaks hooks
- Memory file missing frontmatter fields gets loaded but Claude can't classify it
- No feedback to user that something is wrong until a hook fails or /learn misroutes

## Acceptance Criteria

### AC-1: jitneuro.json Schema Validation
- [ ] Check required top-level fields exist: `version`, `hooks`
- [ ] Check `hooks.preCompactBehavior` is one of: `"block"`, `"warn"`
- [ ] Check `hooks.autosave` is boolean
- [ ] Check `hooks.protectedBranches` is array of strings
- [ ] Check `hooks.mainPushAllowed` is array of strings
- [ ] Check `hooks.hookEvents` is array, each entry has `event`, `script`, `timeout`
- [ ] Check `hooks.hookEvents[].event` is one of: `PreCompact`, `SessionStart`, `PreToolUse`, `PostToolUse`, `SessionEnd`
- [ ] If `scheduledAgents` exists: check each entry has `name`, `type`, `enabled`
- [ ] If `scheduledAgents[].type` is `timer`/`enforcer`: check `interval` exists
- [ ] If `scheduledAgents[].type` is `cron`/`batch`: check `schedule` exists
- [ ] Report: PASS (valid) or FAIL with specific field and expected value

### AC-2: Memory File Frontmatter Validation
- [ ] Scan all `memory/*.md` files (in the auto-memory directory)
- [ ] Check each file has YAML frontmatter (starts with `---`, ends with `---`)
- [ ] Check required fields present: `name`, `description`, `type`
- [ ] Check `type` is one of: `user`, `feedback`, `project`, `reference`
- [ ] Flag files with missing or invalid frontmatter
- [ ] Report: X files checked, Y valid, Z issues

### AC-3: Hook Script Existence
- [ ] For each entry in `hooks.hookEvents`, check that the script file exists in `.claude/hooks/`
- [ ] Flag missing scripts (hook registered but script file not found)

### AC-4: Implementation Constraints
- [ ] Bash only -- no Node.js, no jq dependency (use grep/sed/awk)
- [ ] If jq IS available, use it for JSON validation. If not, fall back to grep patterns.
- [ ] Add to existing /health subagent prompt (Step 0 in learn.md)
- [ ] Results appear in the HEALTH_TABLE alongside existing checks

### AC-5: Output Format
```
| Component | Status | Detail | Fix |
|-----------|--------|--------|-----|
| jitneuro.json schema | FAIL | preCompactBehavior="blokc" (expected: block or warn) | Fix value in .claude/jitneuro.json |
| Memory frontmatter | WARN | 2 files missing type field | Add type: feedback to frontmatter |
| Hook scripts | OK | All 9 scripts found | -- |
```

## Open Questions (evaluate during implementation)

### JIT Activation vs Install-Time Setup
JitNeuro creates assets just-in-time (dashboard components instantiate when `/dashboard` is first called, not at install). This is intentional -- features that aren't configured don't consume tokens. But some users may want everything set up at install.

**Evaluate:** Should install.sh accept a `--full` flag that pre-creates all assets (dashboard dirs, Hub.md structure, state files)? Default remains JIT. `--full` is for users who want deterministic state from day 1.

### Feature Toggles for Heavy Features
Heavy features (dashboard logging, divergent thinking, conversation logging) should follow the toggle pattern in toggles.json -- disabled by default, enabled when called for, toggleable off to cut token cost.

**Evaluate:** Add these to toggles.json:
```json
{
  "divergent": "auto",
  "dashboard": false,
  "conversationLog": false
}
```

When `dashboard: false`, /health skips dashboard checks, scheduled agents skip dashboard JSON writes, and no dashboard-related context loads. Same pattern as divergent -- the feature exists in the codebase but costs zero tokens until enabled.

**Config path resolution (#18 from openclaw evaluation):** The toggles.json repo->workspace fallback already implements this pattern. Extending to all config files may not be needed -- toggles.json IS the feature flag layer. New features get a toggle, not a new config file.

## Notes
- This is a /health enhancement, not a new command
- Validation runs in the health check subagent (isolated context)
- Do NOT auto-fix -- report only. User decides what to fix.
- toggles.json validation is optional (simple structure, low risk of typos)
