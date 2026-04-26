# Verify

Post-install verification for JitNeuro. Checks all components and reports status.
Read-only -- does not modify any files.

## Instructions

When invoked as `/verify`:

1. **Determine install location:**
   - Check for `.claude/jitneuro.json` in current project, workspace parent, and user home
   - Use the first one found as the install root
   - If none found: "JitNeuro not installed. Run install.sh or install.ps1 first."

2. **Check these 9 components** and report status for each:

   | # | Component | Check | GREEN | YELLOW | RED |
   |---|-----------|-------|-------|--------|-----|
   | 1 | Install version | Read version from .claude/jitneuro.json | Version found | Pre-versioned install (no jitneuro.json) | Not installed |
   | 2 | Commands | Scan .claude/commands/*.md | All 17 commands present | Some commands missing | commands/ dir missing |
   | 3 | Hook scripts | Check .claude/hooks/*.sh exist | All 10 scripts present | Some missing | hooks/ dir missing |
   | 4 | Hooks config | Read settings.local.json, verify hooks section | All 9 hook events configured | Some events missing | No hooks config |
   | 5 | Hook paths | Each hook command path in settings.local.json points to existing file | All paths valid | -- | Script file not found |
   | 6 | Hook events | Event names match Claude Code events (PreCompact, SessionStart, PreToolUse, SessionEnd) | All valid | Unknown event name | -- |
   | 7 | Bundles | Check .claude/bundles/ has files | Has bundles | Only example.md | Empty |
   | 8 | Engrams | Check .claude/engrams/ has files | Has engrams | Only example.md | Empty |
   | 9 | Context manifest | Check .claude/context-manifest.md exists | Exists | -- | Missing |

3. **Check config values:**
   - If `preCompactBehavior` is "warn": flag as YELLOW ("block is recommended to prevent silent context loss")
   - If `autosave` is false: note it (informational, not a warning)
   - Show `protectedBranches` list

4. **Check current repo** (if inside a git repo):
   - CLAUDE.md exists at repo root
   - .claude/CLAUDE.md (brainstem) exists
   - Engram file exists for this repo name

5. **Report format:**
   ```
   JitNeuro Verify (v0.1.2)
   Install: .claude/ at [path relative to workspace]

   [1] Install version    GREEN  v0.1.2
   [2] Commands            GREEN  17/17 installed
[3] Hook scripts        GREEN  10/10 present
[4] Hooks config        GREEN  9 hook events configured (SessionStart has 4 hooks)
   [5] Hook paths          GREEN  All paths valid
   [6] Hook events         GREEN  All event names valid
   [7] Bundles             GREEN  3 bundles
   [8] Engrams             GREEN  5 engrams
   [9] Context manifest    GREEN  Present

   Config:
     preCompactBehavior: block
     autosave: true
     protectedBranches: main, master

   Current repo: [repo-name]
     CLAUDE.md:   YES
     Brainstem:   YES
     Engram:      YES

   Result: ALL GREEN
   Tip: Run /save to functionally test that hooks fire correctly.
   ```

6. **For any YELLOW or RED items**, include specific fix instructions:
   - RED hooks config: "Run install.sh/install.ps1 to auto-configure, or see .claude/jitneuro.json for manual setup"
   - YELLOW preCompact warn: "Edit .claude/jitneuro.json and set preCompactBehavior to block"
   - RED missing commands: "Re-run install.sh/install.ps1 to restore commands"

## Important
- Use relative paths in output (not full system paths with username)
- This command is READ-ONLY -- never modify files
- If settings.local.json has extra hooks beyond JitNeuro's 10 scripts (9 hook events), that's fine -- only check for JitNeuro's hooks
- Do not fail on extras, only on missing components
