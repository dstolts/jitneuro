# Onboard

Bootstrap a new repo into the DOE/JitNeuro framework. Generates CLAUDE.md,
engram, and brainstem by analyzing the repo's actual codebase.

## When to Use
- Adding a new repo to the workspace
- Setting up DOE compliance for an existing project
- After cloning a new project that needs JitNeuro integration
- When /audit flags a repo as missing CLAUDE.md or engram

## Instructions

When invoked as `/onboard <repo-path>`:

### Step 1: Analyze the Repository

Read these files (in parallel where possible) to understand the project:

**Identity:**
- `package.json` or `Cargo.toml` or `pyproject.toml` (name, version, deps)
- `README.md` (project description)
- Existing `CLAUDE.md` or `.claude/CLAUDE.md` (don't overwrite if exists)

**Tech Stack:**
- `package.json` dependencies (React, Next.js, Express, etc.)
- `tsconfig.json` (TypeScript config)
- `Dockerfile` or `docker-compose.yml` (containerization)
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

### Step 2: Generate Files

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

**Engram** (`.claude/engrams/[repo-name]-context.md`, ~50-80 lines):
Use the JitNeuro `templates/engrams/example.md` as the template.
Populate with discovered tech stack, key files, architecture, integrations.

### Step 3: Present for Approval

Show generated files to the user:
```
Onboarding: [repo-name]
Generated 3 files:

1. [repo]/CLAUDE.md (project identity, 25 lines)
2. [repo]/.claude/CLAUDE.md (brainstem, 35 lines)
3. .claude/engrams/[repo]-context.md (engram, 60 lines)

Review and approve? (all / pick by number / edit first)
```

### Step 4: Execute

- Write approved files
- Add repo to MEMORY.md project table (if not already there)
- Add routing weight entry if the repo maps to a clear domain
- Update context-manifest.md if new bundles are needed

### Step 5: Verify

- Confirm all files written
- Run `/health` equivalent check on the new files (line counts within limits)
- Report: "Repo [name] onboarded. Run `/audit [name]` to verify compliance."

## Important
- NEVER overwrite existing CLAUDE.md files without asking.
- If CLAUDE.md already exists, show a diff of what would change and ask.
- Engram creation is always safe (new file).
- Keep generated files minimal -- they'll grow organically via /learn.
- If the repo has no package.json (e.g., PowerShell, docs-only), adapt analysis accordingly.
