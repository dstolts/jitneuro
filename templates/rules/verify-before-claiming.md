# Verify Before Claiming Missing or Broken

Before claiming anything is missing or broken:
- Grep the ENTIRE codebase for multiple patterns (not just one folder)
- Check inline definitions in main files, route files, microservices, and handlers
- Read actual file content to confirm, not just grep results
- Provide file paths, line numbers, and grep output as evidence
- NEVER claim "missing" based on assumptions or partial searches
- False alarms waste significant time and create duplicate code

## Why

AI assistants frequently claim something is "missing" after a shallow search.
This leads to unnecessary rewrites, duplicate implementations, and wasted
Owner time investigating a non-problem. The cost of a false alarm is high:
context switching, debugging the "fix," and cleaning up duplicates.

## Search Protocol

1. Grep for the symbol/function/config name across the full codebase
2. Try alternate naming conventions (camelCase, snake_case, kebab-case)
3. Check index files, barrel exports, and re-exports
4. Check environment variables and runtime configuration
5. Read the actual file content of any potential match to confirm

Only after exhausting all search strategies, state what you searched and
where, then report the item as genuinely missing.

## External UI Navigation

Before giving navigation instructions for external UIs (portals, admin panels, SaaS dashboards):
- NEVER state menu paths, breadcrumbs, or settings URLs as fact unless verified (fetched docs, saw screenshot, or confirmed from official source)
- Say "I cannot verify the exact path -- look for [keyword]" when unsure
- Ask Owner for a screenshot rather than guessing the navigation
- External UIs change layouts frequently -- cached knowledge is unreliable
