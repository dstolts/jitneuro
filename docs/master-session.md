# Master Session Architecture

How JitNeuro manages multiple repos from a single orchestration session.

## The Pattern

One "master" Claude Code session runs from the workspace root (e.g., `~/Code/`).
It orchestrates work across any repo underneath. The master session stays thin --
it routes tasks, tracks state, and collects summaries. All heavy work happens in
subagent sessions scoped to individual repos.

```
MASTER SESSION (workspace root: ~/Code/)
  |-- Brainstem loaded: CLAUDE.md + MEMORY.md (routing weights)
  |-- Context: ~3-4% used for infrastructure
  |-- Role: route, delegate, summarize, checkpoint
  |
  |-- AGENT 1 (repo: ~/Code/my-api/)
  |     |-- Bundles: [api, sprint]
  |     |-- Engram: my-api.md
  |     |-- Does: execute API stories, run tests
  |     |-- Returns: summary + modified file list
  |
  |-- AGENT 2 (repo: ~/Code/my-frontend/)
  |     |-- Bundles: [frontend, sprint]
  |     |-- Engram: my-frontend.md
  |     |-- Does: execute FE stories, build check
  |     |-- Returns: summary + modified file list
  |
  |-- MASTER: merges summaries, updates session-state, reports to user
```

## Why This Works

**Without JitNeuro:** You open a terminal in each repo. Each has its own Claude
session. Context is duplicated (sprint protocol loaded 6 times). No session knows
what the others are doing. Cross-repo coordination is manual copy-paste.

**With JitNeuro:** One master session holds the full picture. It knows the sprint
spec, which repos are involved, what's done, what's next. Each agent gets exactly
the context it needs. Cross-repo dependencies are tracked in one place.

## Master Session Responsibilities

1. **Route tasks** to the right repo + bundles using routing weights
2. **Track cross-repo state** in session-state (which repos, which stories, which branch)
3. **Enforce ordering** -- API must deploy before FE can test against it
4. **Collect summaries** -- never load full code diffs into master context
5. **Checkpoint** -- /save captures the full cross-repo picture in one file

## Agent Session Responsibilities

1. **Read assigned bundles + engram** for the target repo
2. **Execute the task** within that repo (code, test, build)
3. **Return a concise summary** -- what changed, what passed, what failed
4. **Stay scoped** -- never read files from other repos unless explicitly told

## How to Launch

Start Claude Code from your workspace root:
```bash
cd ~/Code          # your workspace root
claude             # master session starts here
```

The master session has access to all repos underneath. Routing weights in MEMORY.md
tell it which bundles and engrams to load per task. Commands (/save, /load, /learn)
operate at workspace level, covering all repos.

## Cross-Repo Sprint Flow

This is the most common multi-repo pattern:

### 1. Sprint Kickoff
```
User: "Execute Sprint-Comments-001 -- API first, then frontend"

Master:
  - Reads sprint spec
  - Routing: cross-repo sprint -> [sprint, api, frontend]
  - Decides: API first (FE depends on it)
```

### 2. API Phase
```
Master:
  - Launches agent scoped to my-api
  - Agent gets: sprint.md + api.md + my-api engram + sprint spec
  - Agent: creates branch, executes stories, runs tests, commits
  - Returns: "4 stories done, all tests pass, on branch sprint-comments-001"
```

### 3. Deploy API to UAT
```
Master:
  - API stories done, need to deploy before FE can test
  - Launches agent with: deploy.md + my-api engram
  - Returns: "Deployed to uat. Endpoint live."
```

### 4. Frontend Phase
```
Master:
  - API on uat, FE can now test against it
  - Launches agent scoped to my-frontend
  - Agent gets: sprint.md + frontend.md + my-frontend engram + sprint spec + API summary
  - Agent: creates matching branch, executes FE stories, build check
  - Returns: "2 stories done, build passes, on branch sprint-comments-001"
```

### 5. Review + Checkpoint
```
Master:
  - Both phases done
  - /save sprint-comments-001
  - Session state captures: both repos, branch names, story status, next steps
  - /learn evaluates: any routing weight updates? engram changes? bundle gaps?
```

## Session State for Multi-Repo

A cross-repo session-state file looks like:

```markdown
# Session: sprint-comments-001
**Checkpointed:** 2026-03-09 14:30

## Current Task
Sprint-Comments-001 -- API complete, FE complete, needs review

## Repos Involved
- ~/Code/my-api -- branch sprint-comments-001, 4 stories done
- ~/Code/my-frontend -- branch sprint-comments-001, 2 stories done

## Active Bundles
- sprint.md -- sprint protocol
- api.md -- API conventions (used in API phase)
- frontend.md -- React patterns (used in FE phase)

## Next Steps
1. Project owner reviews output
2. Push to main (both repos, API first)
3. Deploy API to prod
4. Deploy FE to prod
```

## Key Principles

1. **Master never writes code** -- it delegates, tracks, and reports
2. **One session-state per task** -- not per repo. The task spans repos.
3. **Branch names match** across repos (e.g., `sprint-comments-001` in both)
4. **API before FE** -- always. FE can't test against undeployed API changes.
5. **Summaries flow up, context flows down** -- master gets summaries, agents get bundles

## Scaling Beyond Flat Dispatch

When the number of tasks exceeds what flat master->agent dispatch can handle (30+ tasks, complex batching, progress logging), master can delegate orchestration itself to a **sub-orchestrator** -- an agent whose job is to manage other agents.

See [sub-orchestrator-pattern.md](sub-orchestrator-pattern.md) for the full pattern, including:
- Batch management (groups of 10 workers)
- Progress log files for mid-run visibility
- Fix-and-retry cycles within batches
- Aggregate result reporting with category breakdowns
- Real-world example: scoring and fixing 77 blog posts across 6 business verticals
