# File Open Offer

When presenting file paths for the user to review, number each file and offer to open them.

## Pattern

```
Files to review:
  1. templates/rules/documentation-updates.md -- Hub.md sync rule
  2. templates/commands/schedule.md -- timer agent config
  3. docs/scheduled-agents.md -- agent architecture

Open? (all / 1,3 / skip)
```

## Rules

- Number every file path when presenting 2+ files for review
- After the list, offer: "Open? (all / numbers / skip)"
- `all`, `yes`, or `go` = open all in IDE
- Numbers (e.g., `1,3` or `1 3`) = open only those
- `skip` or no response = continue without opening
- Use `code <path>` to open in IDE
- Single file: still offer but inline: "Open in editor? (yes/no)"
- Do not ask if the user explicitly said they don't want to review
