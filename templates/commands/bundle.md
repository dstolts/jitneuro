# Bundle

Load a specific context bundle on demand. Shortcut for when routing weights
don't auto-trigger and you know exactly what context you need.

## When to Use
- When you need domain context that wasn't auto-loaded
- To quickly switch mental context ("give me the blog workflow")
- When /orchestrate is overkill for a simple context load
- To inspect what's in a bundle before deciding to use it

## Instructions

When invoked as `/bundle <name>`:

### With a name argument:

1. Check if `.claude/bundles/<name>.md` exists
2. If yes: read and present the bundle content to the conversation
3. If no: list available bundles and suggest the closest match

### Without arguments (`/bundle`):

1. Read `.claude/context-manifest.md` for the full bundle index
2. List all available bundles with their descriptions and line counts:

```
Available bundles:
| Bundle | Lines | Description |
|--------|-------|-------------|
| active-work | 42 | Current sprints, blockers, NEEDS OWNER |
| product | 38 | Product details, sales, pricing |
| blog | 35 | Blog workflow, content state, sync script |
| infrastructure | 30 | Servers, VMs, ports, deploy patterns |
| integrations | 32 | API chains, auth, external services |

Load one: /bundle <name>
```

### Loading behavior:

When loading a bundle, read the file and output its contents prefixed with:
```
[Bundle loaded: <name>]
```

This makes the bundle content part of the current conversation context.

## Important
- This is READ-ONLY. Never modifies bundle files (that's /learn's job).
- Only loads from `.claude/bundles/` directory.
- One bundle at a time. To load multiple: `/bundle blog` then `/bundle infra`.
- If the user asks to edit a bundle, suggest using /learn instead.
