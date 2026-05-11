# URL Resolver (per-machine)

**Location:** `~/.claude/url-resolver.md` (one per machine; NOT committed to any canonical repo)

This file maps GitHub repo URLs to local filesystem paths so that consumers reading `jit-knowledge/INDEX.md` (which uses GitHub URLs as canonical sources) can resolve them to local clones without network round-trips.

## How loaders use it

1. Read INDEX.md row -> get GitHub URL (e.g., `https://github.com/dstolts/dash-api/blob/uat/.jitneuro/engrams/context.md`)
2. Extract repo URL prefix: `https://github.com/dstolts/dash-api`
3. Lookup in table below -> get local path: `D:/Code/dash-api`
4. Construct full local path: `D:/Code/dash-api/.jitneuro/engrams/context.md`
5. Read from disk

**Fallback when no entry:** fetch `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path>` directly (read-only).

## Resolver table

| Repo URL | Local Path |
|---|---|
| https://github.com/dstolts/jit-knowledge | C:/Users/dstolts/Code/jit-knowledge |
| https://github.com/dstolts/jitai-openclaw | C:/Users/dstolts/Code/jitai-openclaw |
| https://github.com/dstolts/dash-api | C:/Users/dstolts/Code/dash-api |
| https://github.com/dstolts/dash | (TBD -- add when cloned locally) |
| https://github.com/dstolts/jitneuro | D:/Code/jitneuro |
| https://github.com/dstolts/jitai-www | D:/Code/jitai-www |
| https://github.com/dstolts/scanner-platform | D:/Code/scanner-platform |
| https://github.com/dstolts/AIFieldSupport-App | D:/Code/AIFS |
| https://github.com/dstolts/jITSecure | D:/Code/jITSecure |
| https://github.com/dstolts/CoWork | D:/Code/CoWork |
| https://github.com/dstolts/agent-showcase | D:/Code/agent-showcase |
| https://github.com/dstolts/jitai-api | D:/Code/jitai-api |
| https://github.com/dstolts/Paperclip | D:/Code/Paperclip |
| https://github.com/dstolts/TaskManager | D:/Code/Tools/TaskManager |

**Note:** On DEVINFRAVM the `D:/Code/` and `C:/Users/dstolts/Code/` paths are the same physical location (verified by sentinel file test). Pick whichever style you prefer.

## Setup on a new machine

1. Copy this file to `~/.claude/url-resolver.md` (PowerShell: `~` is `$env:USERPROFILE`)
2. Edit the table to match your local clone locations
3. For repos you don't have cloned: leave the row out, loaders fall back to raw.githubusercontent.com fetch
4. Re-edit whenever you clone a new repo or move an existing one

## Conventions

- Use forward slashes (`/`) regardless of OS for portability with Bash tools
- Keep entries alphabetical by repo URL for diff readability
- Avoid mapping the same repo URL to multiple paths (loaders pick the first match)
