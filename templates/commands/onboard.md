# Onboard

Bootstrap a repo into the JitNeuro framework, or refresh an existing repo's
context if it's stale. Generates CLAUDE.md, brainstem, and engram by analyzing
the repo's actual codebase.

## When to Use
- Adding a new repo to the workspace
- Setting up a repo that was cloned but has no JitNeuro context
- Refreshing context after major changes (new framework, restructured code)
- After /audit flags a repo as missing CLAUDE.md or engram
- On a second machine where repos exist but context hasn't been pulled

## Instructions

When invoked as `/onboard <repo-path>`:

### Step 1: Assess Current State

Before generating anything, check what already exists:

- Does `<repo>/CLAUDE.md` exist? Read it.
- Does `<repo>/.claude/CLAUDE.md` exist? Read it.
- Does `.claude/engrams/<repo-name>-context.md` exist? Read it.
- Is the repo a git repo? Check remote, branch, last commit date.
- Is the repo behind its remote? (`git fetch --dry-run` -- if CLAUDE.md
  exists on remote but not locally, suggest pulling first.)

**If all 3 files exist and are recent (commits within last 7 days match):**
Report "Repo already onboarded. Context looks current." and offer to refresh
specific files if the user wants.

**If files exist but are stale (repo has significant commits since last update):**
Report what's stale and offer to refresh. Show what changed since files were
last updated (new deps, new routes, renamed files, etc).

**If files are missing:** Proceed to Step 2.

### Step 2: Analyze the Repository

Read these files (in parallel where possible) to understand the project:

**Identity:**
- `package.json` or `Cargo.toml` or `pyproject.toml` (name, version, deps)
- `README.md` (project description)

**Tech Stack:**
- `package.json` dependencies (React, Next.js, Express, etc.)
- `tsconfig.json` (TypeScript config)
- `Dockerfile` or `docker-compose.yml`
- `.github/workflows/` (CI/CD)
- `vercel.json` or hosting config

**Structure:**
- Top-level directory listing
- `src/` or `app/` or `pages/` structure
- Key route files, entry points, config files

**Git:**
- Remote URL
- Current branch
- Recent commit history (last 5-10)

### Step 3: Generate Files

Only generate files that are missing or that the user asked to refresh.

**Root CLAUDE.md** (project identity, ~20-30 lines):
```markdown
# [Project Name]
[One-line description from package.json or README]

## Tech Stack
[Framework, language, key dependencies]

## Key Files
[Entry points, config files, route files]

## Development
[Build, test, lint commands from package.json scripts]
```

**.claude/CLAUDE.md** (brainstem, ~30-40 lines):
Use the JitNeuro `templates/CLAUDE-brainstem.md` as the template.
Fill in project-specific values.

**Engram** (`.claude/engrams/[repo-name]-context.md`, ~50-180 lines):
Use the JitNeuro `templates/engrams/example.md` as the template.
Populate with discovered tech stack, key files, architecture, integrations.

### Step 4: Present for Approval

Show generated files to the user:
```
Onboarding: [repo-name]
Generated N files:

1. [repo]/CLAUDE.md (project identity, 25 lines) [NEW/REFRESH]
2. [repo]/.claude/CLAUDE.md (brainstem, 35 lines) [NEW/REFRESH]
3. .claude/engrams/[repo]-context.md (engram, 60 lines) [NEW/REFRESH]

Review and approve? (all / pick by number / edit first)
```

### Step 5: Execute (only after approval)

- Write approved files
- Add repo to MEMORY.md project table (if not already there)
- Add routing weight entry if the repo maps to a clear domain
- Update context-manifest.md if new bundles are needed
- Offer to create a bundle: "This repo covers [domain]. Create a bundle?
  Run /bundle [domain-name] to generate one."

### Step 6: Verify

- Confirm all files written
- Check line counts are within limits
- Report: "Repo [name] onboarded. Run /verify to check full setup."

## Without arguments (`/onboard`):

Scan the workspace for repos and show their JitNeuro status:

```
Workspace repos:
| Repo | CLAUDE.md | Brainstem | Engram | Status |
|------|-----------|-----------|--------|--------|
| my-api | Yes | Yes | Yes | Current |
| my-app | Yes | No | No | Needs onboarding |
| utils | No | No | No | Needs onboarding |
| old-thing | Yes | Yes | Yes | Stale (90 days) |

Onboard a repo: /onboard <repo-path>
```

This is the "what needs attention" view. Scan 1 level deep under workspace
root for directories with `.git/`. Skip `.claude/` and `jitneuro` itself.

## Important
- NEVER overwrite existing files without asking. Always show what would change.
- If CLAUDE.md already exists, show a diff of proposed changes and ask.
- Engram creation is always safe (new file) but still ask.
- Keep generated files minimal -- they grow organically via /learn.
- If the repo has no package.json (e.g., PowerShell, docs-only), adapt analysis.
- If git fetch reveals remote has context files, suggest pulling instead of regenerating.
