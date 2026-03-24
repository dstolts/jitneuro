# Memory System Maintenance

How JitNeuro's memory layers work, where things get stored, and how to keep them clean.

## Three Learning Systems

JitNeuro installations have three independent systems that create persistent knowledge.
They target different files and serve different purposes. Understanding the boundaries
prevents duplication and keeps context budgets healthy.

### 1. Rules (owner-authored governance)

**Location:** `~/.claude/rules/` (global) or `<repo>/.claude/rules/` (project-scoped)
**Loaded:** Every session, unconditionally
**Created by:** The project owner, manually
**Updated by:** The project owner (or via `/learn` promotion -- see below)

Rules are behavioral instructions: "always do X", "never do Y", "when Z happens, do W."
They load every session regardless of task, so they must be universal and worth the context cost.

Examples:
- Trust zones (what actions need approval)
- Code style requirements (ASCII only, no emojis)
- Process guardrails (approval workflows, sprint rules)

**Maintenance:** Rules rarely change. Review quarterly or when process changes.

### 2. Auto-memory (Claude Code built-in)

**Location:** `~/.claude/projects/<project>/memory/` (per project workspace)
**Loaded:** On-demand, via MEMORY.md index pointers
**Created by:** Claude Code's auto-memory system during conversations
**Updated by:** Claude Code automatically, or owner via explicit "remember this"

Auto-memory captures learned facts and behavioral feedback:
- `feedback_*` -- corrections and confirmed approaches ("don't mock the DB", "use upsert")
- `user_*` -- owner context (role, expertise, preferences)
- `project_*` -- business decisions, active initiatives
- `reference_*` -- pointers to external resources (API keys location, service URLs)

These load only when MEMORY.md references them, keeping context costs low.

**Maintenance:** Auto-memory grows fastest. Run `/learn` periodically to check for:
- Duplicates (same guidance in memory/ and rules/)
- Promotions (a feedback that should be a rule because it's universal)
- Stale entries (projects completed, decisions reversed)

### 3. JitNeuro /learn (bundles, engrams, routing)

**Location:** `.claude/bundles/`, `.claude/engrams/`, MEMORY.md routing section
**Loaded:** On-demand by routing weights or manual bundle load
**Created by:** `/learn` command evaluation
**Updated by:** `/learn` (with owner approval)

/learn captures domain knowledge and project context:
- **Bundles** -- cross-project domain knowledge ("how to deploy", "API patterns")
- **Engrams** -- per-project deep context ("what this repo is, how it works")
- **Routing weights** -- patterns mapping task types to bundle combinations

**Maintenance:** `/learn` includes a health check that flags oversized bundles (280+ lines),
missing engrams, stale sessions, and broken routing weights. Run it at session boundaries.

## Where Things Go (Decision Tree)

```
Is this a universal behavioral instruction?
  YES -> ~/.claude/rules/ (loads every session)
  NO  -> continue

Is this a fact about a specific project's architecture or tech stack?
  YES -> .claude/engrams/<project>.md (updated by /learn)
  NO  -> continue

Is this domain knowledge that applies across projects?
  YES -> .claude/bundles/<domain>.md (updated by /learn)
  NO  -> continue

Is this a business fact, credential location, or external reference?
  YES -> MEMORY.md or memory/<type>_<topic>.md (auto-memory)
  NO  -> continue

Is this a behavioral correction from the owner?
  YES -> memory/feedback_<topic>.md (auto-memory)
  BUT: if it applies universally and should load every session -> rules/
```

## Common Misplacements

| Symptom | Problem | Fix |
|---------|---------|-----|
| Same guidance in feedback_* and rules/ | Auto-memory saved what was already a rule | Delete the feedback_* file |
| A feedback_* that says "always" or "never" | Universal instruction stored as situational memory | Promote to rules/, delete feedback_* |
| MEMORY.md has "how to deploy" instructions | Domain knowledge in the index file | Extract to a bundle, replace with routing pointer |
| A bundle has owner-specific names or preferences | Project-specific content in a cross-project file | Move to the project's engram or rules/ |
| An engram has process instructions | Behavioral rule stored as project context | Move to rules/ (global) or .claude/rules/ (project) |

## Upgrade Safety

When JitNeuro releases updates, the install script touches:
- `<repo>/.claude/commands/` -- slash command templates (overwritten)
- `<repo>/.claude/CLAUDE.md` -- project guardrails template (overwritten if using template)
- Templates in `.claude/` workspace -- bundles, engrams, context manifest

The install script does NOT touch:
- `~/.claude/rules/` -- owner's global rules (never overwritten)
- `~/.claude/projects/*/memory/` -- auto-memory (never overwritten)
- MEMORY.md -- routing weights and index (never overwritten)
- `.claude/jitneuro-settings.json` -- runtime settings (never overwritten)

**Safe upgrade pattern:**
1. Run `jitneuro install` (overwrites templates only)
2. Run `/learn` or `/health` to verify memory system health after upgrade
3. If new commands or conventions were added, /learn will flag missing routing weights

## MEMORY.md Remediation (When It Gets Too Big)

MEMORY.md has a hard 200-line limit. Beyond that, Claude Code silently truncates -- content is lost with no warning.

**Fastest fix:** Ask Claude Code to optimize it for you:
```
> "My MEMORY.md is getting large. Analyze it and apply the best remediation strategy.
   Offload detail files, extract bundles, or consolidate -- whatever saves the most lines."
```

Claude Code will read MEMORY.md, pick the right strategy, create any new files, and verify the result is under the limit.

**The strategies below** explain what Claude Code does under the hood, or you can apply them manually.

### Strategy 1: Offload detail lines to an index file

**When:** MEMORY.md has a table listing individual files (feedback, project, reference). Each row is a line consumed. 50+ detail files = 50+ lines wasted on an index.

**Fix:** Replace the table with one pointer line. Move the full table to `detail-index.md`.

Before (50+ lines in MEMORY.md):
```
## Feedback
| File | Description |
| feedback_foo.md | ... |
| feedback_bar.md | ... |
(50 more rows)
```

After (1 line in MEMORY.md):
```
## Detail Files
Read [detail-index.md](detail-index.md) for all feedback, project, and reference files by topic.
```

See `templates/memory/detail-index.md` for the template. Group entries by domain (N8N, Salesforce, content, etc.) so Claude can scan the index efficiently.

### Strategy 2: Extract domain sections to bundles

**When:** MEMORY.md has paragraphs of domain knowledge (infrastructure details, deployment procedures, API patterns). These are facts that don't need to load every session.

**Fix:** Move the section to a bundle (`.claude/bundles/<domain>.md`). Replace in MEMORY.md with a routing weight entry so it loads on-demand when the topic comes up.

Before (20 lines in MEMORY.md):
```
## Infrastructure
- VM1 is at 10.0.0.5, runs Docker, ports 8080 and 5678...
- Cloudflare is configured with...
- Deployment steps are...
```

After (1 line in MEMORY.md routing weights):
```
- Deploy / server / VM / container -> [infrastructure]
```

The bundle holds the full detail. Routing weights ensure it loads when relevant.

### Strategy 3: Extract project detail to engrams

**When:** MEMORY.md has paragraphs about specific projects (architecture, tech stack, key files). These should be in per-project engrams, loaded only when working on that project.

**Fix:** Move project-specific detail to `.claude/engrams/<project>-context.md`. Keep only a one-line entry in the project table in MEMORY.md.

Before (10 lines per project in MEMORY.md):
```
## AIFieldSupport-API
Node/Express, Azure SQL, Firebase Auth. Uses analysis engine v2.5 with
config-driven calls, dual-agent wiring, cost calculation. Key files:
routes/analysis.js, services/analysis-engine/index.js...
```

After (1 row in project table):
```
| AIFieldSupport-API | Node/Express, Azure SQL, Firebase | Prod v2.4.5 | aifs-core-context.md |
```

### Strategy 4: Split codebase into smaller workspaces

**When:** A single workspace has 15+ repos, each generating feedback, each needing routing weights, each with integrations to track. MEMORY.md is structurally too small for the scope.

**Fix:** Split into focused workspaces. Each workspace gets its own MEMORY.md with a smaller, relevant scope.

Example -- a monolithic workspace:
```
~/Projects/                 <-- one workspace, one MEMORY.md for 20 repos
  ├── frontend-app/
  ├── backend-api/
  ├── auth-service/
  ├── marketing-site/
  ├── automation/
  ├── crm-integration/
  └── ... (14 more repos)
```

Split into work areas:
```
~/Projects/Product/         <-- workspace 1: MEMORY.md covers 5 repos
  ├── frontend-app/
  ├── backend-api/
  └── auth-service/

~/Projects/Marketing/       <-- workspace 2: MEMORY.md covers 4 repos
  ├── marketing-site/
  ├── blog/
  └── crm-integration/

~/Projects/Infrastructure/  <-- workspace 3: MEMORY.md covers 3 repos
  ├── automation/
  ├── deploy-scripts/
  └── monitoring/
```

Each workspace has:
- Its own `.claude/` with MEMORY.md, bundles, engrams
- Its own routing weights scoped to relevant domains
- Smaller, focused context that fits within 200 lines
- Cross-workspace facts go in `~/.claude/rules/` (loads everywhere)

**Trade-off:** Cross-workspace operations (sprints touching multiple areas) require loading context from another workspace's engrams. Use `~/.claude/rules/` for truly cross-cutting facts and `~/.claude/docs/` for operational reference that spans workspaces.

### Strategy 5: Compress the project table

**When:** The project table has 20+ rows with columns that could be shorter.

**Fix:** Use abbreviations, drop obvious columns, or split into active vs archived tables.

Before:
```
| AIFieldSupport-API | Node/Express, Azure SQL, Firebase | Production v2.4.5, HE+cost on uat | aifs-core-context.md |
```

After:
```
| AIFS-API | Node/Express/SQL/Firebase | Prod 2.4.5 | aifs-core |
```

Or split:
```
## Active Projects (10 repos)
[compact table]

## Maintenance Projects (8 repos)
See engrams/ -- not loaded unless working on them.
```

### Choosing a Strategy

| MEMORY.md Lines | Strategy | Effort |
|-----------------|----------|--------|
| 130-170 | Compress tables, trim stale entries | Low |
| 170-190 | Offload detail index + extract one domain bundle | Medium |
| 190-200 | Multiple extractions + consider workspace split | High |
| 200+ (truncating) | Emergency: extract everything non-essential NOW, plan workspace split | Urgent |

These strategies compound. A workspace that offloads its detail index (Strategy 1), extracts two domain bundles (Strategy 2), and compresses its project table (Strategy 5) can go from 190 lines to under 80.

## Periodic Cleanup Checklist

Run these when memory feels heavy or after a major sprint:

1. `/health` -- quick system diagnostic (line counts, stale sessions, missing engrams)
2. `/learn` -- full evaluation (session learnings + health check + proposed changes)
3. Manual scan -- grep memory/ for files that duplicate rules/ content
4. Archive old sessions -- `/sessions stale` then `/sessions archive <name>`

## Line Limits

| Component | Soft Limit | Hard Limit | What Happens Over Limit |
|-----------|-----------|------------|------------------------|
| MEMORY.md | 170 lines | 200 lines | Claude Code silently truncates beyond 200 -- content lost |
| Bundles | 230 lines | 280 lines | Content gets skimmed or partially read |
| Engrams | 230 lines | 280 lines | Diminishing returns, stale content persists |
| Rules (total) | No fixed limit | -- | Every file loads every session -- cost scales linearly |

The `/learn` command monitors these limits and flags violations before they cause problems.
