# Routing Weights

Load context bundles based on task keywords. Each entry maps trigger phrases to one or more bundle names. When a user request matches a trigger, the listed bundles are loaded to provide domain-specific context.

## Pattern

```
- <trigger phrases>  -> [bundle-name]
- <trigger phrases>  -> [bundle-a, bundle-b]
```

## Example Routes

```
- Deploy / server / container / VM       -> [infrastructure]
- API / endpoint / route / auth          -> [api-patterns]
- Blog / post / publish / content        -> [content]
- Sprint / story / prd / backlog         -> [sprint-workflow]
- Test / spec / coverage / assertion     -> [testing]
- Bug / error / debug / investigate      -> [infrastructure, integrations]
```

## How It Works

1. AI scans the user's request for trigger keywords
2. Matching bundles are loaded from the bundles directory
3. Multiple bundles can load simultaneously for cross-domain tasks
4. Unmatched requests use base context only (no extra bundles)

## Tips

- Group related keywords on the same line (e.g., "deploy / server / container")
- Use multi-bundle routes for tasks that span domains (e.g., "cross-repo sprint -> [sprint-workflow, infrastructure]")
- Keep trigger phrases short -- 2-4 words per phrase is ideal
- Order routes from most specific to most general
- Add a "Full manifest" reference so AI can discover all available bundles

Full manifest: .claude/context-manifest.md
