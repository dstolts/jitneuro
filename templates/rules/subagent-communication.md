# Subagent Communication Protocol

When spawning subagents (via the Agent tool), every subagent prompt MUST include a return format requirement. When acting AS a subagent, always follow this protocol.

## Return Requirements

Every subagent MUST return:

1. **Status line** (first line): `STATUS: OK`, `STATUS: BLOCKED`, or `STATUS: PARTIAL`
2. **Files changed** (if any): list of absolute paths to files created or modified
3. **Summary reference** (if detailed output exists): path to a summary document the master can read if it needs more context
4. **Short result** (under 15 lines): the actual findings, pass/fail, issues found

The master does NOT read file contents or summary documents unless it needs detail beyond the status and file list. This keeps master context thin.

## Return Schema

```
STATUS: OK
FILES_CHANGED:
  - /path/to/file1.ts (created)
  - /path/to/file2.ts (modified)
SUMMARY_DOC: /path/to/detailed-report.md
RESULT:
[concise findings, under 15 lines]
```

```
STATUS: BLOCKED
QUESTION: [what the agent needs to know]
CONTEXT: [what it found so far, so master doesn't re-do the work]
FILES_CHANGED:
  - /path/to/partial-output.md (created)
PARTIAL_RESULT: [any usable output before the block]
```

```
STATUS: PARTIAL
COMPLETED: [what was done]
SKIPPED: [what was skipped and why]
FILES_CHANGED:
  - /path/to/file1.ts (modified)
RESULT:
[partial findings]
```

## Master Behavior

- **OK**: Process result, use file paths for commit/PR scope, ignore summary doc unless deeper context needed
- **BLOCKED**: Read the question, answer from context/rules/user, re-dispatch via SendMessage
- **PARTIAL**: Use what's available, dispatch follow-up agent for remainder if needed
- When consolidating results, report file paths to the user so they can review changes

## Prompt Pattern

When dispatching a subagent, always include this in the prompt:

```
Return format:
- First line: STATUS: OK, BLOCKED, or PARTIAL
- List any files created or modified (full paths)
- If you write a detailed report, include its path as SUMMARY_DOC
- Keep the result under 15 lines
```
