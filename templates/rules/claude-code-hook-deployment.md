---
type: rule
purpose: MUST be consulted by any installer, script, or agent that writes a Claude Code `hooks.*` entry in settings.json or settings.local.json; defines the bare-script-path command format and hook exit-code semantics. Skipping it ships shell-prefixed hook commands that fail every tool call with "bash.exe: bash.exe: cannot execute binary file" and no hook runs.
read_when: Before writing or modifying any Claude Code hooks entry in settings.json or settings.local.json, or when diagnosing hook failures at tool-call time.
tags: [claude-code, hooks, settings-json, installer, deployment]
scope: public
departments: [all]
leak_allow: ["C:/Program", "C:/...", "C:/Users", "Users/..."]
last_evaluated: 2026-06-03
---

# Claude Code Hook Deployment

Rules for registering Claude Code hooks correctly in `settings.json` /
`settings.local.json`. Violating these produces error banners on every tool
call ("errors galore"). Applies to any installer, script, or manual edit that
writes a `hooks.*` entry.

## 1. The `command` is a bare command line -- never prefix it with a shell

Claude Code executes a hook `command` by running it THROUGH its own shell
(`bash -c "<command>"`; Git Bash on Windows). The `command` value is therefore
already a shell command line.

- WRONG: `"command": "C:/Program Files/Git/bin/bash.exe \"C:/.../hook.sh\""`
- WRONG: `"command": "bash \"/c/.../hook.sh\""`
- RIGHT: `"command": "C:/Users/<you>/.claude/hooks/hook.sh"`
- RIGHT (bash-native form, also fine): `"command": "/c/Users/<you>/.claude/hooks/hook.sh"`

Prefixing with `bash`/`bash.exe` makes the shell hand `bash` to `bash` as its
own script argument. Result: `bash.exe: bash.exe: cannot execute binary file`.
The hook never runs.

For a script hook, `command` is just the script path. Claude Code's shell
executes the script directly (the `#!/bin/bash` shebang is honored, or the
shell runs it). For an inline hook, `command` is the inline shell snippet.

## 2. Paths must have no spaces, or be a form the shell resolves

Hook script paths should live under a space-free directory
(`~/.claude/hooks/`, `<repo>/.claude/hooks/`). On Windows either `C:/Users/...`
or `/c/Users/...` works as a bare path; both are resolved by Git Bash. Do not
wrap the bare path in extra quotes inside the JSON string.

## 3. Exit codes carry meaning -- 0 for informational, 2 only to block

- `exit 0` -- success. stdout is consumed (for SessionStart, added to context).
- `exit 2` -- BLOCKING error. Claude Code surfaces it and, for blocking-capable
  events (PreToolUse, PreCompact), aborts the action. stderr is fed back.
- other non-zero -- non-blocking error, shown as a warning banner.

An informational/advisory hook MUST `exit 0`. Using `exit 2` for a message
that is not meant to block produces an error banner every time the hook fires.
Reserve `exit 2` for hooks that genuinely intend to block (e.g. branch-push
protection, compaction gating).

## 4. SessionStart hooks: prefer JSON output for user-visible messages

Plain stdout from a SessionStart hook becomes `additionalContext` (model-only).
To show a line to the USER at session start, emit JSON:

```json
{
  "systemMessage": "** visible to the user immediately **",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "injected into model context"
  }
}
```

Build the JSON with a real encoder (python `json.dumps`, `jq`) -- never string
concatenation -- so embedded newlines/quotes are escaped correctly.

## 5. Verify before declaring a hook deployed

After writing or editing any hook registration:

1. Validate the settings file is still valid JSON.
2. Run the hook the way Claude Code will:
   `bash -c "<command>"` with a sample stdin JSON
   (`{"session_id":"t","hook_event_name":"<Event>","cwd":"<path>"}`).
3. Confirm exit code is intended (0 for informational).
4. Hook config is loaded at session START -- changes do NOT hot-apply to the
   running session reliably. Test in a fresh session.

## 6. One hook, one registration

Do not register the same logical hook in both user `settings.json` and project
`settings.local.json` -- both fire, duplicating output (e.g. an identity rule
injected twice). Pick the correct scope: machine-wide -> user settings;
repo-specific -> project settings.

## Origin

2026-05-20. the knowledge catalog's `scripts/install.sh` and jitneuro `install.sh` /
`install.ps1` all wrote hook commands shell-prefixed -- `"<git-bash>" "<path>"`
or `bash "<path>"`. Claude Code 2.1.x runs each hook as `bash -c "<command>"`,
so every PreToolUse / PostToolUse / SessionStart hook failed with
`cannot execute binary file` and no hook ran. Fixed by emitting a bare script
path in all three installers. A redundant second master-orchestrator
SessionStart hook (one in user settings, one in project settings) was also
removed. `pre-compact-save.sh` exits 2 by design (blocks compaction) -- that
one is intentional, not a defect.

This rule was moved from a machine-local `~/.claude/rules/` file into
jitneuro as the canonical, portable home so installers and agents in any
clone can reference `rules/claude-code-hook-deployment.md`.
