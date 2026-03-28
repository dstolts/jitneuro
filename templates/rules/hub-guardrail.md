# Hub.md Guardrail

## Rules
1. **Never version Hub.md.** Hub.md is the active task list -- updated in place, never copied to Hub-01.md, Hub-v030.md, or any variant. There is exactly ONE Hub.md per .HUB/ folder.
2. **Never delete Hub.md.** It is the durable record of task state. If tasks are complete, mark them done -- do not remove the file.
3. **Hub.md is local only.** .HUB/ is gitignored. Future tasks for public repos belong in issue trackers or feature request files, not Hub.md.

## Why
Hub.md is the single source of truth for session task state. Versioning it fragments the task list across files, causing tasks to be lost and work to be duplicated. Deleting it destroys the only durable record of in-progress work -- task lists and session memory are volatile.

## What violates this guardrail
- Creating Hub-01.md, Hub-v2.md, or any numbered/versioned variant
- Applying file-versioning rules to Hub.md (Hub.md is explicitly exempt)
- Deleting Hub.md or replacing it with a new file
- Moving Hub.md to .archive/
