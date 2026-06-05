---
type: rule
purpose: Require verification that a file path exists before presenting it, and mandate that every file reference includes a human-readable description of what the file contains.
read_when: Before presenting any file path or responding to a request for "where is X" -- broken or description-free links waste context-switching time.
tags: [file-references, verification, documentation, links, completeness]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# File References

## Verification (before every path presented)

- ALWAYS verify the file exists before presenting any path to a requester
- Never guess paths. If unsure, use search tools to find the actual file first
- A broken link wastes significant context-switching time. Verify every time.

## Delivery (when a requester asks "where is X")

- ALWAYS include a brief description of what each file contains, in the requester's language.
  File names alone do not tell what is inside -- especially when naming uses different
  terminology than the requester's mental model.
- Prefer fewer paths. If one file answers the question, give one. If multiple files are all
  relevant, list them but describe each.
- Treat file requests as delivery (hand the exact thing), not recall (list what was created).

## Format

- In chat responses: use absolute paths with line numbers when relevant
- In markdown files: use relative paths from the file's location

## Completeness Rule

When presenting a PR, document, dashboard action, or file to a requester, ALWAYS include
the clickable URL or full file path in the same bullet as the description. Never require
the requester to ask a follow-up question to get the link.

This applies to: status summaries, task handoffs, completion reports, everywhere.
