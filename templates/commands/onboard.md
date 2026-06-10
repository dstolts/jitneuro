# Onboard

Bootstrap a repo into the JitNeuro framework, or refresh an existing repo's
context if it's stale. Generates the canonical vendor-neutral standard (AGENTS.md),
a thin CLAUDE.md importer, an optional Cursor bridge, and an engram by analyzing
the repo's actual codebase. Also imports any AI knowledge sources the installer
staged (existing CLAUDE.md / AGENTS.md / .cursor rules / Copilot instructions /
agent charters) into their correct homes.

## Agent-Agnostic Output (single standard + thin importers)
JitNeuro emits ONE standard read by every tool, plus thin per-tool importers:
- **AGENTS.md** (repo root) -- the canonical, vendor-neutral instruction surface.
  Read by Cursor, Codex, Claude Code, and others. This is the source of truth.
- **CLAUDE.md** (repo root) -- a THIN IMPORTER of AGENTS.md. It uses an `@AGENTS.md`
  import where Claude Code supports it, otherwise an explicit "read AGENTS.md first"
  directive. It NEVER duplicates AGENTS.md content; it adds only Claude-Code adapter notes.
- **.cursor/rules/jitneuro-intents.mdc** (optional) -- a Cursor bridge that references
  the same AGENTS.md standard and maps intents (save/load/learn/guardrails).
The portable core (AGENTS.md + rules + skills + bundles + engrams + the KNOWLEDGE_ROOT
store) works on any agent. Claude Code hooks/commands are a layered adapter only where
supported -- do not assume hooks exist on non-Claude tools.

## When to Use
- Adding a new repo to the workspace
- Setting up a repo that was cloned but has no JitNeuro context
- Refreshing context after major changes (new framework, restructured code)
- After /audit flags a repo as missing AGENTS.md, CLAUDE.md, or engram
- On a second machine where repos exist but context hasn't been pulled
- Importing existing AI knowledge the installer staged (see Step 0)

## Instructions

When invoked as `/onboard <repo-path>`:

### Step 0: Read Staged Import Manifest (onboarding import)

The installer may have staged existing AI knowledge sources for import. Before
anything else, resolve KNOWLEDGE_ROOT and check for the staging manifest:

- Resolve KNOWLEDGE_ROOT: `KNOWLEDGE_ROOT` env var -> `jitneuro.json` `knowledgeRoot`
  -> the local `.knowledge/` store (always present).
- Read `KNOWLEDGE_ROOT/imports/onboarding-staging.md` if it exists.

If present, it lists detected sources (existing CLAUDE.md, AGENTS.md,
`.cursor/rules/*.mdc`, `.github/copilot-instructions.md`, existing `.claude/`
content, agent/charter files) and a suggested home for each. You will IMPORT
these in Step 3 and report the result in Step 4. SAFETY:
- This is surface-and-catalog, NOT blind-merge. Read each source, decide the
  correct home, and present conflicts for the user to reconcile -- do not
  silently overwrite an existing file.
- NEVER ingest secrets. Skip `.env`, `*.key`, `*.pem`, token/credential files
  entirely. If a staged source references a secret, catalog the reference, not
  the value.

If no manifest exists, skip the import path -- this is a fresh onboarding with
no prior sources.

### Step 1: Assess Current State

Before generating anything, check what already exists:

- Does `<repo>/AGENTS.md` exist? Read it. (This is the canonical standard.)
- Does `<repo>/CLAUDE.md` exist? Read it. (Should be a thin importer of AGENTS.md.)
- Does `<repo>/.claude/CLAUDE.md` exist? Read it.
- Does `.claude/engrams/<repo-name>-context.md` exist? Read it.
- Is the repo a git repo? Check remote, branch, last commit date.
- Is the repo behind its remote? (`git fetch --dry-run` -- if AGENTS.md/CLAUDE.md
  exists on remote but not locally, suggest pulling first.)

**If AGENTS.md + engram exist and are recent (commits within last 7 days match):**
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

### Step 3: Generate Files + Import Staged Sources (runs in master)

Using the subagent's summary, generate only files that are missing or that the user asked to refresh.

**AGENTS.md (CANONICAL standard, repo root, ~40-60 lines):**
Use the JitNeuro `templates/AGENTS-brainstem.md` as the template. This is the
vendor-neutral instruction surface every tool reads. Fill in project-specific
Identity, Critical Rules, JitNeuro Mode, and Key Paths. Keep the KNOWLEDGE_ROOT
and Tool Adapters sections intact -- they make the framework agent-agnostic.

**Root CLAUDE.md (THIN IMPORTER of AGENTS.md, repo root):**
Use the JitNeuro `templates/CLAUDE-brainstem.md` as the template. Do NOT duplicate
AGENTS.md. It must either `@AGENTS.md`-import (where Claude Code supports it) or
carry the explicit "read AGENTS.md first" directive, plus Claude-Code-only adapter
notes (slash commands, hooks). If a project-identity summary is wanted, keep it to
a few lines (name, tech stack, build/test/lint) -- the standard lives in AGENTS.md.

**.cursor/rules/jitneuro-intents.mdc (Cursor bridge, OPTIONAL):**
If the repo is used with Cursor (or the user asks), generate it from the JitNeuro
`templates/cursor/rules/jitneuro-intents.mdc`. It references the same AGENTS.md
standard and KNOWLEDGE_ROOT -- it does not duplicate them.

**Engram** (`.claude/engrams/[repo-name]-context.md`, ~50-180 lines):
Use the JitNeuro `templates/engrams/example.md` as the template.
Populate with discovered tech stack, key files, architecture, integrations.

**Import staged sources (only if Step 0 found a manifest):**
For each detected source in `KNOWLEDGE_ROOT/imports/onboarding-staging.md`, read it
and route it to the RIGHT home -- surface-and-catalog, never blind-merge:
- **Per-project context** (architecture notes, repo facts, "how this repo works")
  -> fold into the **engram** (`.claude/engrams/[repo-name]-context.md`).
- **Behavioral standard / rules** (existing CLAUDE.md/AGENTS.md directives, Copilot
  instructions, Cursor intent rules) -> fold into **AGENTS.md** (the standard) and/or
  `.claude/rules/`. Keep CLAUDE.md a thin importer.
- **Capabilities** (agent charters, playbooks, skills, reusable references that are
  not repo-specific) -> catalog under the **KNOWLEDGE_ROOT store** and add a routing
  entry to `KNOWLEDGE_ROOT/INDEX.md`.
- **Conflicts** (e.g., an existing CLAUDE.md that is NOT a thin importer, or two
  sources stating different rules) -> DO NOT auto-resolve. List them in the summary
  for the user to reconcile.
- **Secrets** -> never ingest. Skip `.env`, `*.key`, `*.pem`, and any token/credential
  file. Catalog a reference if needed, never the value.

### Step 4: Present for Approval

Show generated files AND the import plan to the user:
```
Onboarding: [repo-name]
Generated N files:

1. [repo]/AGENTS.md (canonical standard, 50 lines) [NEW/REFRESH]
2. [repo]/CLAUDE.md (thin importer of AGENTS.md, 20 lines) [NEW/REFRESH]
3. .claude/engrams/[repo]-context.md (engram, 60 lines) [NEW/REFRESH]
4. .cursor/rules/jitneuro-intents.mdc (Cursor bridge) [NEW/SKIP]   (only if Cursor in use)

Onboarding import (from KNOWLEDGE_ROOT/imports/onboarding-staging.md):
- [source] -> [engram | AGENTS.md/rules | KNOWLEDGE_ROOT store]   (per source)
- Conflicts to reconcile: [list, or "none"]
- Secrets skipped: [list, or "none"]

Review and approve? (all / pick by number / edit first)
```

### Step 5: Execute (only after approval)

- Write approved files (AGENTS.md is the canonical standard; CLAUDE.md stays thin)
- Apply the approved import routing (engram / AGENTS.md+rules / KNOWLEDGE_ROOT store)
- Add a routing entry to `KNOWLEDGE_ROOT/INDEX.md` for any cataloged capabilities
- Add repo to MEMORY.md project table (if not already there)
- Add bundle files to `.claude/bundles/` if new bundles are needed
- After importing, mark the staging manifest done: rename
  `KNOWLEDGE_ROOT/imports/onboarding-staging.md` to
  `KNOWLEDGE_ROOT/imports/onboarding-staging.done.md` so it is not re-imported.

### Step 6: Verify + Onboarding Summary

- Confirm all files written
- Check line counts are within limits
- Write a documented onboarding summary to
  `KNOWLEDGE_ROOT/imports/onboarding-summary-[repo-name].md` capturing:
  - What was FOUND (each staged source)
  - Where it LANDED (engram / AGENTS.md+rules / KNOWLEDGE_ROOT store)
  - CONFLICTS still to reconcile (so nothing is silently lost)
  - Secrets that were intentionally skipped
- Report: "Repo [name] onboarded. AGENTS.md is the standard; CLAUDE.md imports it.
  Summary: KNOWLEDGE_ROOT/imports/onboarding-summary-[repo-name].md. Run /verify."

## Without arguments (`/onboard`) -- Workspace Scan

**CRITICAL:** Scanning the workspace checks 15+ directories. Dispatch to a subagent.

**Before dispatching**, write dashboard JSON (same pattern as Step 2 but with `"name":"Onboard: Workspace Scan"` and `"id":"onboard-scan-001"`). Update after subagent returns.

Launch a **general-purpose** Agent with this prompt:

```
You are scanning a workspace for JitNeuro onboarding status. Check each subdirectory and return ONLY a summary table.

Workspace root: [path]

For each subdirectory that contains a .git/ folder (1 level deep, skip .claude/ and node_modules/):
- Check if [repo]/AGENTS.md exists (the canonical standard)
- Check if [repo]/CLAUDE.md exists (should be a thin importer of AGENTS.md)
- Check if .claude/engrams/[repo-name]-context.md exists
- Get last commit date: git -C [repo] log -1 --format=%ci

Return format:

ONBOARD_TABLE:
| Repo | AGENTS.md | CLAUDE.md | Engram | Last Commit | Status |
|------|-----------|-----------|--------|-------------|--------|
(Status: Current / Needs onboarding / Stale)

Current = AGENTS.md + engram exist and commits within 7 days
Stale = they exist but last commit >30 days ago
Needs onboarding = AGENTS.md or engram missing

SUMMARY: [N] repos, [M] need onboarding, [X] stale
```

Present the table. Then: "Onboard a repo: `/onboard <repo-path>`"

## Important
- **Repo analysis and workspace scan run in subagents.** File generation and writing run in master.
- NEVER overwrite existing files without asking. Always show what would change.
- AGENTS.md is the canonical standard; CLAUDE.md must stay a thin importer of it (never duplicate).
- If AGENTS.md or CLAUDE.md already exists, show a diff of proposed changes and ask.
- Imports are surface-and-catalog, never blind-merge; conflicts are surfaced, never auto-resolved.
- Never ingest secrets (.env, *.key, *.pem, credential files) during import.
- Engram creation is always safe (new file) but still ask.
- Keep generated files minimal -- they grow organically via /learn.
- If the repo has no package.json (e.g., PowerShell, docs-only), adapt analysis.
