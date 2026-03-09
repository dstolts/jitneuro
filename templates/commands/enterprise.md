# Enterprise

Display the enterprise governance rules, quality gates, and holistic review framework.
This is a quick-reference overlay -- not a command that modifies anything.

## When to Use
- Before a sprint to review governance requirements
- When onboarding a new project to DOE framework
- When planning cross-repo changes that need review gates
- To remind yourself of trust zones, approval workflows, and quality standards

## Instructions

When invoked as `/enterprise`:

### Step 1: Load Governance Sources

Read these files (in parallel where possible):
- `C:\Users\dstolts\.claude\CLAUDE.md` -- global DOE guardrails (trust zones, approval workflow)
- `D:\Code\.claude\CLAUDE.md` -- workspace rules (cross-repo protocol, write access)
- `D:\Code\jitneuro\docs\holistic-review.md` -- 4-persona review gates
- `D:\Code\jitneuro\docs\enterprise-isolation.md` -- single-repo isolation mode
- `D:\Code\jitneuro\docs\master-session.md` -- multi-repo orchestration

### Step 2: Present Holistic View

Display a consolidated enterprise governance summary:

```
== DOE Enterprise Governance ==

TRUST ZONES
| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze | Execute freely |
| YELLOW | Schema, dependencies, API contracts, .env | Execute, report at checkpoint |
| RED | Push main, prod deploy, delete, DB migrations | Stop and ask Dan |

APPROVAL WORKFLOW
- Strategy Mode: .MD files only, no code until explicit approval
- Development Mode: TodoWrite + plan before execute, explicit approval required
- Approval phrases: "Go ahead", "Approved", "Plan accepted"
- Answering a question is NOT approval

QUALITY GATES (Pre-Execution)
Holistic Plan Review -- 4 personas evaluate before execution:
1. Sr Software Architect (Ralph AFK experience)
2. Maintenance & Maintainability
3. Reliability (fail-fast patterns)
4. Security

Output: story table with risk, time estimate, verdict (go/enhance/skip)

QUALITY GATES (Post-Execution)
Holistic Execution Review -- validate what was actually done:
- Plan executed correctly?
- Bugs introduced?
- Dead code created/discovered?
- Decisions made during execution?

Output: story table with status, verdict (Success/Issues/Dead Code)

CROSS-REPO PROTOCOL
- Feature branch or uat only (never main without approval)
- API contract in spec FIRST, both sides implement to it
- Per-repo commits (never mix repos in one commit)
- Build + tsc --noEmit + tests must pass before commit
- Never proceed to next repo if current fails

BRANCH RULES
- Sprint: sprint-<feature>-<number> (e.g., sprint-blog-001)
- Ralph: feature branch or uat
- Hotfix to main: only with Dan's explicit approval

FILE VERSIONING
- Search first, ask user, then version (Name-01.md -> Name-02.md)
- Never modify existing files directly -- copy first
- Exception: CLAUDE.md files are not versioned

RULE OF LOWEST CONTEXT
Store rules at the lowest level possible, closest to where they apply.
- CLAUDE.md: universal rules only (30-40 lines)
- .claude/rules/*.md: path-scoped rules (load automatically per file type)
- .claude/bundles/*.md: domain knowledge (load on demand by task)
- .claude/engrams/*.md: project context (load on demand per repo)
- MEMORY.md: routing weights + index (first 200 lines)
Don't put schema rules in CLAUDE.md. Put them in rules/schema.md.
Don't put deploy commands in CLAUDE.md. Put them in rules/deployment.md.
```

### Step 3: Optional Deep Dive

After displaying the summary, ask:
"Want details on any section? Options:"
1. Holistic Plan Review (full 4-persona framework)
2. Holistic Execution Review (post-sprint validation)
3. Cross-Repo Sprint Protocol (step-by-step)
4. Enterprise Isolation Mode (single-repo setup)
5. Multi-Repo Orchestration (master session)

If user picks one, read and present the relevant doc.

## Important
- This command is READ-ONLY. It never modifies any files.
- It consolidates rules from multiple sources into one view.
- Keep the summary concise -- detail is available on request.
- If docs are missing (e.g., jitneuro not installed), show what's available and note gaps.
