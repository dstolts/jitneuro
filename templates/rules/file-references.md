# File References

## Verification (before every path presented)
- ALWAYS verify the file exists (Read tool) before presenting any path to Owner
- Never guess paths. If unsure, use Glob or Grep to find the actual file first
- A broken link wastes Owner's context switching time. Verify every time.

## Delivery (when Owner asks "where is X")
- ALWAYS include a brief description of what each file contains, in the user's language. File names alone do not tell the user what is inside -- especially when naming uses different terminology than the user's mental model.
- Prefer fewer paths. If one file answers the question, give one. If multiple files are all relevant, list them but describe each.
- Treat file requests as delivery (hand the exact thing), not recall (list what was created).

## Format
- In chat responses: Use absolute paths with line numbers when relevant
- In markdown files: Use relative paths from the file's location
