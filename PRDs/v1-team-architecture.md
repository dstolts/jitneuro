# v1.0 Architecture: Team-Aware JitNeuro

**Created:** 2026-03-27
**Priority:** 95/100
**Status:** Architecture approved, needs execution planning
**Handoff:** Agent-ready after sprint breakdown

## Desired State

JitNeuro becomes team-aware. A team of developers sharing a repo gets shared knowledge (rules, engrams, conventions) through git, with personal knowledge isolated per-developer. A TeamApprover curates what becomes team knowledge. No new infrastructure -- git push/pull is the sync.

## User Value

- **New dev cold start:** Clone, install JitNeuro, Claude knows the project architecture, conventions, and quality gates from the first prompt
- **Knowledge compounds across the team:** One dev's /learn insight benefits everyone after approval
- **Sr→Jr mentoring via AI:** Jr's Claude follows team rules the Sr established, without Sr being present
- **Team visibility:** Who's working on what, who's blocked, what's in progress -- all from committed files
- **AFK accountability:** Track what Claude accomplished during AFK periods, measure autonomous execution effectiveness
- **Future reporting:** Sprint velocity, knowledge growth, team utilization -- all from data that's already being written

## Architecture

### Folder Structure

```
<repo>/
  CLAUDE.md                    <-- team identity (committed, existing)
  .jitneuro/                   <-- COMMITTED (team + user spaces)
    rules/                     <-- team-approved rules
    engrams/                   <-- team project context
    bundles/                   <-- team domain knowledge
    cognition/                 <-- team personas, decisions
    context-manifest.md        <-- team routing weights
    TEAM.md                    <-- member list, roles, approvers
    users/
      <username>/
        active-work.md         <-- current task, branch, sprint, blockers (auto by /save)
        lessons.md             <-- /learn output, promotion staging
        rules/                 <-- personal repo rules (loaded for this user only)
        afk-log.md             <-- AFK session records (auto by session tracking)
  .claude/                     <-- GITIGNORED (personal, Anthropic namespace)
    session-state/             <-- session checkpoints, heartbeats
    hooks/                     <-- hook scripts
    settings.local.json        <-- Claude Code config
    jitneuro.json              <-- personal agent config
    workspace.json             <-- personal credentials (NEVER committed)
  ~/.claude/                   <-- USER GLOBAL (personal identity)
    rules/                     <-- personal global rules
    CLAUDE.md                  <-- personal cognitive identity
    MEMORY.md                  <-- personal brain
```

### What Claude Loads (per user)

```
Team (everyone):
  1. <repo>/CLAUDE.md
  2. .jitneuro/rules/
  3. .jitneuro/engrams/
  4. .jitneuro/bundles/ (on-demand via routing)
  5. .jitneuro/cognition/
  6. .jitneuro/context-manifest.md

Personal (you only):
  7. .jitneuro/users/<YOU>/rules/
  8. .claude/ (session state, local config)
  9. ~/.claude/rules/
  10. ~/.claude/CLAUDE.md
  11. MEMORY.md

NOT loaded: .jitneuro/users/<OTHER_PEOPLE>/rules/
NOT loaded: .jitneuro/users/<OTHER_PEOPLE>/lessons.md
VISIBLE in git: everything in .jitneuro/ (for review, not loading)
```

### User Identification

```bash
git config user.name  # already on every dev machine
```

Mapped in TEAM.md:
```markdown
## Team
| Username | Role | TeamApprover |
|----------|------|-------------|
| dev01 | Sr Architect | yes |
| dev02 | DevOps | yes |
| dev03 | Jr Developer | no |
```

### /learn Modes

| Command | Personal | Team queue | Team health | When |
|---------|----------|-----------|-------------|------|
| `/learn` | Yes | Yes (if TeamApprover) | Yes (if TeamApprover) | End of session |
| `/learn -q` | Yes | No | No | Quick capture |
| `/learn --team` | No | Yes | Yes | Team review |

**For anyone:**
```
| # | Scope | Target | Change |
|---|-------|--------|--------|
| 1 | TEAM (Rec) | .jitneuro/users/dev03/lessons.md | No DB mocking |
| 2 | PERSONAL | .jitneuro/users/dev03/rules/prefs.md | Prefer small PRs |
```

TEAM items go to YOUR lessons.md (staging). PERSONAL items go to YOUR rules/. No harm either way.

**For TeamApprover (auto-detected, no flag needed):**

Same personal output PLUS:

```
== Team Lessons Queue ==
| # | Author | Date | Proposed Rule |
|---|--------|------|---------------|
| T1 | dev03 | 2026-03-27 | No DB mocking in integration tests |
| T2 | dev02 | 2026-03-26 | Always use UTC timestamps |

Promote to team? (all / pick by # / skip)

== Team Health ==
| Component | Status | Detail |
|-----------|--------|--------|
| Team rules (12) | OK | No conflicts |
| Team engrams (3) | WARN | aifs-context.md 160 lines (cap 150) |
| Active devs (3) | OK | dev01: active, dev02: AFK 2h, dev03: active |
| Stale lessons | INFO | 2 lessons >7 days without review |
| Conflicts | OK | No file overlap between active branches |
```

Team health runs automatically when reviewing team lessons. Same context window, zero extra cost.

### Promotion Flow

```
1. TeamApprover: "promote T1"
2. Claude reads T1 from users/dev03/lessons.md
3. Writes to .jitneuro/rules/testing.md
4. Marks T1 as PROMOTED in dev03/lessons.md
5. Commit + push → team gets it on next pull
```

### lessons.md Lifecycle

```markdown
# dev03 lessons

## Pending
- No DB mocking in integration tests (2026-03-27)
- Never deploy on Fridays (2026-03-27)

## Promoted
- Always use UTC timestamps (2026-03-26) → .jitneuro/rules/conventions.md

## Rejected
- Always use var instead of const (2026-03-25) -- Sr: we use const per team standard
```

### active-work.md (auto-updated by /save)

```markdown
# dev01
**Updated:** 2026-03-27T14:30:00Z
**Session:** jitneuro
**Branch:** feat/divergent-thinking-command
**Status:** active

## Current Task
Implementing watcher agent architecture

## In Progress
- [ ] PRD: watcher-agent-architecture.md
- [x] /divergent command shipped
- [x] /help command shipped

## Blockers
(none)

## Files Touched
- docs/scheduled-agents.md
- PRDs/watcher-agent-architecture.md
```

### afk-log.md (auto-updated by session tracking)

```markdown
# dev01 AFK Log

## 2026-03-27 14:00-15:30 (1h30m)
**Session:** jitneuro
**Tasks before AFK:** 6 pending
**Tasks after AFK:** 2 pending (4 completed)
**Completed:**
- [x] Wire RESUME_TASKS instruction to scheduled-agent-interrupts.md
- [x] Update /schedule command for enforcer type
- [x] Create task-watcher agent config
- [x] Test watcher enforcement loop
**Blocked:** (none)
**Files changed:** 4

## 2026-03-26 09:00-11:45 (2h45m)
**Session:** content-scoring
**Tasks before AFK:** 12 pending
**Tasks after AFK:** 0 pending (12 completed)
**Completed:**
- [x] Score 12 blog posts against quality rubric
- ... (10 more)
**Files changed:** 12
```

**How AFK tracking works:**
1. User signals AFK (says "AFK" or steps away)
2. Claude snapshots: current tasks, status, timestamp
3. Claude works autonomously (per autonomous-execution rule)
4. When user returns (or session ends): Claude writes the AFK record
5. Record shows: duration, tasks before/after, what was accomplished, files changed

**Future reporting value:**
- Autonomous execution effectiveness: what % of AFK tasks completed vs blocked?
- Task throughput: tasks/hour during AFK vs interactive
- Blocker patterns: what blocks Claude most during AFK?
- ROI metric: "Claude completed 47 tasks during 12 AFK hours this week"

### Team Monitoring (future cron agents)

```
.jitneuro/users/*/active-work.md → who's doing what right now
.jitneuro/users/*/afk-log.md → autonomous execution history
.jitneuro/users/*/lessons.md → knowledge growth per dev
```

| Capability | Agent | Schedule | Reads |
|-----------|-------|----------|-------|
| Team standup | Cron | 8am daily | all active-work.md |
| Conflict detection | Cron | Every 2h | all active-work.md (branches + files) |
| AFK effectiveness report | Cron | Weekly | all afk-log.md |
| Knowledge growth | Cron | Weekly | all lessons.md |
| Sprint velocity | Cron | End of sprint | all active-work.md + afk-log.md |
| Stale lesson alert | Enforcer | Daily | all lessons.md (>7 days pending) |

All agents just READ committed files. The data is already there from normal /save and /learn usage.

### Progressive Enhancement

```
Solo mode:     No .jitneuro/ → current behavior, nothing changes
Small team:    .jitneuro/ without users/ → everyone is TeamApprover
Full team:     .jitneuro/ with users/ → roles, lessons queue, promotion
Enterprise:    + branch protection CODEOWNERS on .jitneuro/rules/
Reporting:     + cron agents reading users/*/ for dashboards and metrics
```

Each step adds capability. Nothing is removed. Solo mode is always supported.

### Migration from v0.x

```
1. User runs /onboard --team on a repo
2. JitNeuro creates .jitneuro/ structure
3. Classifies existing .claude/ knowledge: team vs personal
4. Copies team artifacts to .jitneuro/ (engrams, domain bundles, shared rules)
5. Creates users/<username>/ with active-work.md
6. Leaves personal artifacts in .claude/ (session state, workspace.json, personal rules)
7. First commit of .jitneuro/ → team knowledge is now in git
```

## Acceptance Criteria

### AC-1: .jitneuro/ folder structure
- [ ] Structure supports: rules/, engrams/, bundles/, cognition/, users/<name>/, TEAM.md, context-manifest.md
- [ ] Committed to git (not gitignored)
- [ ] users/<name>/ auto-created on first /save or /learn for that user

### AC-2: Context loading cascade
- [ ] Claude loads team context first, then personal (team baseline + personal override)
- [ ] Only loads YOUR users/<name>/rules/, not other users'
- [ ] Falls back gracefully: no .jitneuro/ = solo mode, no users/ = all-approver mode

### AC-3: /learn with team support
- [ ] `/learn` shows personal + team queue + team health (if TeamApprover)
- [ ] `/learn -q` shows personal only (no team, no health)
- [ ] `/learn --team` shows team queue + team health only
- [ ] TEAM-classified lessons write to users/<you>/lessons.md
- [ ] PERSONAL lessons write to users/<you>/rules/
- [ ] TeamApprover can promote lessons to .jitneuro/rules/

### AC-4: active-work.md auto-sync
- [ ] /save writes users/<you>/active-work.md alongside session checkpoint
- [ ] Contains: session name, branch, status, current task, in-progress items, blockers, files touched
- [ ] Updated timestamp on every /save

### AC-5: afk-log.md tracking
- [ ] When user signals AFK: snapshot task state
- [ ] When user returns: write AFK record with duration, tasks completed, files changed
- [ ] Append-only log, one section per AFK period

### AC-6: TEAM.md and roles
- [ ] User identified via git config user.name
- [ ] TEAM.md maps usernames to roles and TeamApprover flag
- [ ] /learn auto-detects TeamApprover from TEAM.md
- [ ] Missing TEAM.md = everyone is TeamApprover (small team mode)

### AC-7: Solo mode compatibility
- [ ] No .jitneuro/ = current v0.x behavior, zero changes
- [ ] All existing commands work without .jitneuro/
- [ ] /onboard --team creates the structure; without --team, current behavior

### AC-8: Team health in /learn --team
- [ ] Team rules: count, conflicts, stale
- [ ] Team engrams: line counts, missing for active projects
- [ ] Active devs: status from active-work.md timestamps
- [ ] Stale lessons: pending >7 days without review
- [ ] Branch conflicts: overlapping file changes across active branches

### AC-9: Repo-specific watcher agent
- [ ] `.jitneuro/jitneuro.json` can define repo-level scheduled agents (separate from personal `.claude/jitneuro.json`)
- [ ] Repo watcher checks: git status, CI/CD health, branch drift, deploy status
- [ ] Repo agents auto-start when working in that repo (SessionStart detects .jitneuro/jitneuro.json)
- [ ] Repo agents are team-shared (committed, everyone gets them)
- [ ] Personal agents in `.claude/jitneuro.json` run alongside repo agents (no conflict)

## Resolved Questions

1. active-work.md updates on /save only (not heartbeat). Resolved 2026-03-27.
2. AFK log in .jitneuro/users/ (team-visible). Resolved 2026-03-27.
3. Cross-repo team knowledge deferred -- depends on v1.0 adoption. Resolved 2026-03-27.
4. jitneuro.json stays in .claude/ for v1.0 (hooks find it there). Team config goes to .jitneuro/jitneuro.json. Resolved 2026-03-27.
5. Git noise: default squash, configurable. Resolved 2026-03-27.
