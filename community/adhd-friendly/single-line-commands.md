# Single-Line Commands

Never give multi-line shell commands. Each step must be a separate single-line command.

## Rules

- Every shell command must fit on one line. No line continuations or backslash wrapping.
- If a task requires multiple steps, present each as its own standalone command.
- Do not combine unrelated operations into a single piped command chain.
- When showing a sequence of commands, number them so the order is clear.

## Why

Wrapped and multi-line commands break when pasted into many terminals (especially PowerShell). Single-line commands are easier to read, copy, and debug. Each step is independently verifiable.
