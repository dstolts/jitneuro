---
type: skill
purpose: Toggle session logging to .logs/ directory; FIRST action is always to append the prompt before any other work.
tags: [conversation-log, logging, session, toggle]
scope: public
departments: [all]
status: canonical
graduation_target: skills/conversation-log/SKILL.md
read_when: When running the /conversation-log command to enable, disable, or query session logging state.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /conversation-log (alias: /convlog)

Toggle conversation logging to the `.logs/` directory.

## FIRST ACTION RULE

When convlog is ON, the FIRST action in every response is to append the user's prompt to the log file BEFORE doing any other work. This is non-negotiable.

## Trigger patterns

- `convlog on` -- enable logging
- `convlog off` -- disable logging
- `convlog status` -- show current state
- `/conversation-log` with no args -- toggle (on if off, off if on)

## Log file

Log path: `.logs/conversation-<date>.md`

Format per entry:
```markdown
## [timestamp] USER
<user prompt>

## [timestamp] ASSISTANT
<assistant response summary>

---
```

## State persistence

Store toggle state in `.claude/toggles.json` under key `"conversation_log"`:
- `true` = logging enabled
- `false` = logging disabled
- Default: `false`

## On enable

Display: `** Conversation logging ON -- log: .logs/conversation-<date>.md **`

## On disable

Display: `** Conversation logging OFF **`
