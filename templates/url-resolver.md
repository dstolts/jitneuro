# URL Resolver

Maps GitHub repo URLs to local clone paths on THIS machine, so tools can reference
a repo by its stable GitHub URL while reading it at local-disk speed.

Machine-specific. Do NOT commit this file (the installer adds it to .gitignore).
Install scripts create it; update the paths whenever you move or re-clone a repo.

## Format

```
<GitHub URL>  ->  <absolute local path>
```

## Entries

Add one line per repo you work with locally. Examples (replace with your own):

```
https://github.com/your-org/your-repo   ->  /home/you/Code/your-repo
https://github.com/your-org/your-repo   ->  C:/Users/you/Code/your-repo
```

## How it is used

When a rule, engram, or command references a repo by GitHub URL, the consuming
system (Claude Code, Cursor, or another agent) reads this file first to resolve
the URL to a local path:

1. Read `~/.claude/url-resolver.md`
2. Find the entry matching the URL prefix
3. Replace the URL prefix with the local path
4. Read the local file

If no entry matches, the system falls back to fetching the file via the GitHub
API (slower, requires network access).

## Governance

- Do not commit this file. It is machine-specific.
- Update local paths after moving or re-cloning repositories.
- Use forward slashes (`/`) regardless of OS for cross-tool portability.
