# URL Resolver

This file maps canonical GitHub URLs to local clone paths on this machine.
It is machine-specific and MUST NOT be committed to git (add to .gitignore).

The resolver lets consuming systems (Claude Code, Cursor, future agents) reference
canonical artifacts by their stable GitHub URL while reading them at local filesystem
speed. Install scripts create this file. Update the paths if you move clones.

## Format

```
<GitHub URL>  ->  <absolute local path>
```

## Entries

https://github.com/dstolts/jit-knowledge  ->  REPLACE_WITH_LOCAL_PATH

<!-- Example entries:
https://github.com/dstolts/jit-knowledge  ->  /home/user/Code/jit-knowledge
https://github.com/dstolts/jit-knowledge  ->  C:/Users/user/Code/jit-knowledge
-->

## How it is used

When a rule, engram, or command references a jit-knowledge artifact by GitHub URL,
the consuming system reads this file first to resolve the URL to a local path:

1. Read `~/.claude/url-resolver.md`
2. Find the entry matching the URL prefix
3. Replace the URL prefix with the local path
4. Read the local file

If no entry is found for a URL, the system falls back to fetching the file via
the GitHub API (slower, requires network access).

## Routing entry

The canonical routing table lives at:
  https://github.com/dstolts/jit-knowledge/blob/main/INDEX.md

With a valid entry above, it resolves to:
  <local path>/INDEX.md

## Governance

- Do not commit this file. It is machine-specific.
- Update local paths after moving or re-cloning repositories.
- Add entries for every jit-knowledge artifact your workflow reads.
