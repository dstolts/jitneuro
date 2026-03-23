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

### Step 2: Analyze the Repository (runs in subagent)

**CRITICAL:** Analyzing a repo reads 15-20 files. Dispatch to a subagent.

**Before dispatching**, write dashboard JSON:
```bash
RUN_ID="onboard--$(date -u +%Y-%m-%dT%H-%M-%S)"
DASH_DIR="${JITDASH_DIR:-$HOME/.claude/dashboard}"
mkdir -p "$DASH_DIR/runs/$RUN_ID/agents"
echo '{"session":"[current-session]","started":"[ISO-now]","wave":1}' > "$DASH_DIR/runs/$RUN_ID/meta.json"
echo '{"id":"onboard-001","name":"Onboard: [repo-name]","status":"running","repo":"[repo-path forward slashes]","started":"[ISO-now]"}' > "$DASH_DIR/runs/$RUN_ID/agents/onboard-001.json"
```
**After subagent returns**, update with `"status":"completed"`, `"finished":"[ISO]"`, `"result":"[summary]"`.

Launch a **general-purpose** Agent with this prompt:

```
You are analyzing a repository for JitNeuro onboarding. Read the repo and return a structured summary. Do NOT return raw file contents.

Repo path: [path]

Read these files (skip any that don't exist):
- package.json or Cargo.toml or pyproject.toml (name, version, key deps)
- README.md (project description, first 50 lines)
- tsconfig.json (TypeScript config presence)
- Dockerfile or docker-compose.yml (container setup)
- .github/workflows/ (CI/CD presence)
- vercel.json or hosting config
- Top-level directory listing (ls)
- src/ or app/ or pages/ structure (1 level deep)
- Key route files, entry points, config files

Git info:
- git remote -v
- git branch --show-current
- git log --oneline -5

Return format:

PROJECT_NAME: [name from package.json or directory name]
DESCRIPTION: [one line from README or package.json]
TECH_STACK: [framework, language, key deps -- comma separated]
KEY_FILES: [entry points, config, routes -- one per line with purpose]
SCRIPTS: [build, test, lint commands from package.json]
STRUCTURE: [brief architecture: monolith/microservice, key directories]
GIT_REMOTE: [remote URL]
GIT_BRANCH: [current branch]
RECENT_COMMITS: [last 5 commit messages, one per line]
INTEGRATIONS: [external services detected: databases, APIs, auth providers]
```

### Step 3: Generate Files (runs in master)

Using the subagent's summary, generate only files that are missing or that the user asked to refresh.

**Root CLAUDE.md** (project identity, ~20-30 lines):
```markdown
# [Project Name]
[One-line description]

## Tech Stack
[Framework, language, key dependencies]

## Key Files
[Entry points, config files, route files]

## Development
[Build, test, lint commands]
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

### Step 6: Verify

- Confirm all files written
- Check line counts are within limits
- Report: "Repo [name] onboarded. Run /verify to check full setup."

## Without arguments (`/onboard`) -- Workspace Scan

**CRITICAL:** Scanning the workspace checks 15+ directories. Dispatch to a subagent.

**Before dispatching**, write dashboard JSON (same pattern as Step 2 but with `"name":"Onboard: Workspace Scan"` and `"id":"onboard-scan-001"`). Update after subagent returns.

Launch a **general-purpose** Agent with this prompt:

```
You are scanning a workspace for JitNeuro onboarding status. Check each subdirectory and return ONLY a summary table.

Workspace root: [path]

For each subdirectory that contains a .git/ folder (1 level deep, skip .claude/ and node_modules/):
- Check if [repo]/CLAUDE.md exists
- Check if [repo]/.claude/CLAUDE.md exists
- Check if .claude/engrams/[repo-name]-context.md exists
- Get last commit date: git -C [repo] log -1 --format=%ci

Return format:

ONBOARD_TABLE:
| Repo | CLAUDE.md | Brainstem | Engram | Last Commit | Status |
|------|-----------|-----------|--------|-------------|--------|
(Status: Current / Needs onboarding / Stale)

Current = all 3 files exist and commits within 7 days
Stale = all 3 exist but last commit >30 days ago
Needs onboarding = any file missing

SUMMARY: [N] repos, [M] need onboarding, [X] stale
```

Present the table. Then: "Onboard a repo: `/onboard <repo-path>`"

## Important
- **Repo analysis and workspace scan run in subagents.** File generation and writing run in master.
- NEVER overwrite existing files without asking. Always show what would change.
- If CLAUDE.md already exists, show a diff of proposed changes and ask.
- Engram creation is always safe (new file) but still ask.
- Keep generated files minimal -- they grow organically via /learn.
- If the repo has no package.json (e.g., PowerShell, docs-only), adapt analysis.
