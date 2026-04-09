# User Story: Disableable Rules with Restore Instructions

**Created:** 2026-03-27
**Priority:** 88/100
**Status:** Ready for execution
**Handoff:** Agent-ready

## Problem

JitNeuro ships rule templates that encode best practices (autonomous execution, task-as-user-story, divergent thinking, etc.). Users need to be able to:

1. **Disable a rule** without losing the ability to restore it
2. **Not pay token cost** for disabled rules (Claude shouldn't load 60 lines of a rule it's not following)
3. **Survive upgrades** -- install script must not re-enable a rule the user explicitly disabled
4. **Discover disabled rules** -- user should know what's available but turned off

Current options are bad:
- **Delete the file:** Rule is gone. User forgets it existed. Install script recreates it.
- **Comment it out:** Claude still reads the file and burns tokens on commented markdown.
- **toggles.json:** Works for engrams and divergent. Could work for rules but 40+ toggle entries gets unwieldy.

## Solution: Disabled File Pattern

When a rule is disabled, replace its content with a short stub that:
1. Tells Claude the rule is disabled (don't follow it)
2. Tells the user where to find the full rule
3. Costs minimal tokens (~3 lines)
4. Signals the install script to skip updates

### Disabled rule file format

```markdown
# [Rule Name] (DISABLED)

This rule is disabled. To re-enable, copy the full rule from:
https://github.com/dstolts/jitneuro/blob/main/templates/rules/[filename]

Or ask Claude: "Re-enable the [rule name] rule from jitneuro templates"
```

### How it works

**Disabling a rule:**
User says "disable the autonomous-execution rule" or "I don't want divergent thinking."
Claude:
1. Reads the current rule file
2. Replaces content with the disabled stub (3 lines)
3. Confirms: "Disabled autonomous-execution.md. Re-enable anytime by asking."

**Re-enabling a rule:**
User says "re-enable autonomous execution" or "turn divergent thinking back on."
Claude:
1. Reads the disabled stub, sees the source URL
2. Fetches or reads the full rule from jitneuro templates
3. Replaces the stub with the full rule content
4. Confirms: "Re-enabled autonomous-execution.md."

**Install script behavior:**
1. For each template rule, check if target file exists
2. If file exists AND first line contains `(DISABLED)`: SKIP. Do not overwrite.
3. Log: "Skipped [filename] (disabled by user). Run /help to see disabled rules."
4. If file exists AND is NOT disabled: compare with template, update if stale
5. If file doesn't exist: install from template

**Claude's behavior when loading rules:**
1. Claude reads all files in `~/.claude/rules/` at session start
2. If a file contains `(DISABLED)` in the title: skip it, do not follow the rule
3. Token cost: ~30 tokens per disabled file (vs 200-600 for a full rule)

## Detection

A disabled rule is detected by checking the first line:
```
# [anything] (DISABLED)
```

This is a simple grep: `head -1 file | grep -q "(DISABLED)"`

## /help Integration

/help should show disabled rules so users know what's available:

```
## Disabled Rules
These rules are installed but disabled. Ask Claude to re-enable any of them.
  - autonomous-execution.md (DISABLED) -- keep working while tasks exist
  - session-closure.md (DISABLED) -- never close without permission
```

The help.md file can't dynamically list disabled rules (it's static). Instead, add a note:
```
Run: "show me disabled rules" -- Claude scans rules/ for (DISABLED) files
```

## /health Integration

/health should report disabled rules as INFO (not a problem, just visibility):
```
| Rules (disabled) | INFO | 2 rules disabled: autonomous-execution, session-closure | Re-enable with "enable [name] rule" |
```

## Acceptance Criteria

### AC-1: Disable/enable commands
- [ ] Claude understands "disable [rule name]" -- replaces content with stub
- [ ] Claude understands "enable [rule name]" or "re-enable [rule name]" -- restores from template
- [ ] Stub includes: rule name, DISABLED marker, restore instructions with GitHub URL
- [ ] No slash command needed -- natural language works

### AC-2: Install script respects disabled rules
- [ ] `install.sh` checks first line for `(DISABLED)` before overwriting
- [ ] If disabled: skip update, log message
- [ ] If not disabled: update if template is newer
- [ ] If file missing: install from template
- [ ] `install.ps1` same behavior

### AC-3: Token cost
- [ ] Disabled rule stub is under 5 lines / 50 tokens
- [ ] Claude reads the stub, recognizes DISABLED, does not process as active rule
- [ ] Full rule content is NOT in the file (zero overhead beyond stub)

### AC-4: Discoverability
- [ ] "Show me disabled rules" triggers a scan of rules/ for (DISABLED) files
- [ ] /health reports disabled rules as INFO
- [ ] help.md mentions the capability

### AC-5: Ship rule templates
Port these patterns from private rules to jitneuro templates:
- [ ] `templates/rules/autonomous-execution.md` -- keep working while tasks exist
- [ ] `templates/rules/session-closure.md` -- never close without permission
- [ ] `templates/rules/task-as-user-story.md` -- PRD .md file before TodoWrite
- [ ] `templates/rules/lessons-capture.md` -- write learn candidates to Hub.md in real-time
- [ ] All genericized (Owner, not Dan)
- [ ] All installed as ENABLED by default (user disables if unwanted)

## Example: Disabled File

```markdown
# Autonomous Execution (DISABLED)

This rule is disabled. To re-enable, copy the full rule from:
https://github.com/dstolts/jitneuro/blob/main/templates/rules/autonomous-execution.md

Or ask Claude: "Re-enable the autonomous execution rule"
```

## Example: Install Script Logic

```bash
for template in templates/rules/*.md; do
  name=$(basename "$template")
  target="$RULES_DIR/$name"

  if [ -f "$target" ]; then
    if head -1 "$target" | grep -q "(DISABLED)"; then
      echo "SKIP: $name (disabled by user)"
      continue
    fi
    # Update if template is newer
    if ! diff -q "$template" "$target" > /dev/null 2>&1; then
      cp "$template" "$target"
      echo "UPDATED: $name"
    fi
  else
    cp "$template" "$target"
    echo "INSTALLED: $name"
  fi
done
```
