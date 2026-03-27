# Team

## Members

| Username | Role | TeamApprover | Added |
|----------|------|-------------|-------|
| <!-- git config user.name --> | <!-- role --> | yes | <!-- date --> |

## How It Works

- **Username** matches `git config user.name` on each developer's machine
- **Role** is informational (e.g., Sr Architect, DevOps, Jr Developer)
- **TeamApprover** controls who can promote lessons to team rules via `/learn`
- If this file is missing, everyone is treated as a TeamApprover (small team mode)

## Roles

TeamApprovers can:
- Promote lessons from any user's `lessons.md` to `.jitneuro/rules/`
- See team health metrics in `/learn` output
- Review and reject proposed team rules

Non-approvers can:
- Capture lessons to their own `users/<name>/lessons.md`
- Write personal rules to their own `users/<name>/rules/`
- See their own lessons and personal health metrics

## Adding a Team Member

1. Add a row to the table above with their `git config user.name`
2. Commit and push -- they get team context on next pull
3. Their `users/<username>/` folder is auto-created on first `/save` or `/learn`
