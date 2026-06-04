---
type: skill
purpose: Display JitNeuro quick reference from static help file at zero token cost.
tags: [help, reference, read-only, quick-reference]
scope: public
status: canonical
graduation_target: skills/help/SKILL.md
read_when: When a user or agent invokes /help to display the JitNeuro quick reference at zero token cost.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /help

Display JitNeuro quick reference. Zero token cost -- reads static file.

## Steps

1. Read `.claude/help.md` (repo-level) or workspace `.claude/help.md`
2. Display contents verbatim

## What the help file contains

- List of all available slash commands with one-line descriptions
- Session tag format reminder
- Trust zone summary
- Key paths (engrams, bundles, session-state)
- Common workflows (save/load/pulse pattern)

## Notes

- If `.claude/help.md` is missing, display a brief inline list of core commands
- This command intentionally does NOT dispatch agents or read other files
- Designed to be the fastest possible reference (one file read, no analysis)
