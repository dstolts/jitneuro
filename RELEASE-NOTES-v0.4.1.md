# JitNeuro v0.4.1 Release Notes

**Release Date:** May 20, 2026
**Stability:** Stable
**Breaking Changes:** None
**Action Required:** YES -- all users must re-run the installer (see "How to update" below)

---

## Summary

v0.4.1 is a fix release. The installer (`install.sh` and `install.ps1`) was registering Claude Code hook commands in a form that fails at runtime on every recent Claude Code version. As a result, hooks installed by v0.4.0 (and earlier) produce an error on every tool call instead of running.

This release corrects the installer. Because the broken hook commands are already written into your `settings.local.json`, updating the repo is not enough on its own -- you must re-run the installer so the corrected commands replace the broken ones.

**Who should update:** Everyone who installed JitNeuro v0.4.0 or earlier.

---

## The bug

JitNeuro's installer wrote each hook `command` with a shell prefix:

- `install.sh` emitted: `bash "<path>/hook.sh"`
- `install.ps1` emitted: `"<git-bash-path>" "<path>/hook.sh"`

Claude Code runs each hook `command` through its OWN shell. A shell prefix makes that shell try to execute bash as bash's own script argument, so every hook fails at runtime with:

```
bash.exe: bash.exe: cannot execute binary file
```

Every hook event is affected -- `SessionStart`, `PreToolUse`, `PostToolUse`, `SessionEnd`, `PreCompact`. The visible result is an error banner on session start and on every tool call, and none of the hooks (heartbeat, branch protection, session write-id, auto-save, etc.) actually run.

## The fix

The installer now writes each hook `command` as a bare script path -- no shell prefix:

```
"command": "<path>/hook.sh"
```

Claude Code's own shell executes the script directly. Both `install.sh` and `install.ps1` are corrected, and both now carry a "HOW TO WRITE A HOOK COMMAND" instruction block above the hook configuration so the bug cannot silently reappear in future edits.

## How to recognize you are affected

If, since installing JitNeuro, you have seen any of these in Claude Code:

- `SessionStart:startup hook ... cannot execute binary file`
- Hook errors on every tool call
- `bash.exe: bash.exe: cannot execute binary file`

then your hooks are running the broken commands and you need this update.

---

## How to update

1. Pull the latest JitNeuro (v0.4.1 or later).
2. Re-run the installer for your platform, in the same mode you originally used:
   - macOS / Linux / Git Bash: `bash install.sh`
   - Windows PowerShell: `pwsh -File install.ps1`
3. The installer rewrites the hook entries in `settings.local.json` with the corrected commands.
4. Restart Claude Code. Hook configuration is loaded at session start, so the running session will not pick up the fix until you start a new one.

After restarting, session start and tool calls should be free of the `cannot execute binary file` error.

### If you do not want to re-run the installer

You can fix it by hand: open your `settings.local.json`, find every `hooks.*` entry, and change each `command` from `bash "<path>"` (or `"<bash-path>" "<path>"`) to just `<path>` -- the bare script path, nothing else. Then restart Claude Code.

---

## What changed in this release

- `install.sh` -- hook commands written as bare script paths; instruction block added.
- `install.ps1` -- hook commands written as bare script paths; instruction block added.
- No changes to hook scripts, hook events, matchers, or timeouts.
- No changes to commands, bundles, engrams, or any other JitNeuro feature.

## Notes

- This is a fix-only release. There are no new features and no breaking changes.
- The hook scripts themselves were always correct -- only the installer's registration of them was wrong.
- `pre-compact-save.sh` exiting with a blocking status before compaction is intended behavior (it asks you to `/save`), not part of this bug.
