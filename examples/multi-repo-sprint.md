# Example: Multi-Repo Sprint with Context Switching

This example shows Neuro-Context managing a sprint that touches an API repo
and a frontend repo, with task switching mid-session.

## Setup

### Bundles created:
- `.claude/bundles/api.md` -- API conventions, routes, auth, error handling
- `.claude/bundles/frontend.md` -- React patterns, state management, components
- `.claude/bundles/sprint.md` -- Sprint protocol, task format, commit conventions
- `.claude/bundles/deploy.md` -- CI/CD, containers, environment configs

### Routing weights in MEMORY.md:
```
- Sprint execution   -> bundles: [sprint]
- API development    -> bundles: [api, sprint]
- Frontend work      -> bundles: [frontend, sprint]
- Deploy/release     -> bundles: [deploy]
- Cross-repo sprint  -> bundles: [sprint, api, frontend]
```

## Session Flow

### Phase 1: Sprint Kickoff

```
User: "Start Sprint-UserAuth-001 -- 3 API stories then 2 frontend stories"

Claude (orchestrator):
  - Reads context-manifest.md
  - Routing weight: "Cross-repo sprint" -> [sprint, api, frontend]
  - But API stories come first, so start lean
  - Launches Agent with: sprint.md + api.md + sprint spec
  - Agent executes API stories 1-3 in isolated context
  - Returns: "Stories 1-3 complete. Files modified: auth.ts, routes.ts, middleware.ts"
  - Main context receives summary only (3 lines, not 3 files of code)
```

### Phase 2: Context Switch to Frontend

```
Claude (orchestrator):
  - API agent done, need frontend now
  - Launches NEW agent with: sprint.md + frontend.md + sprint spec + API summary
  - Agent executes frontend stories 4-5 in isolated context
  - Returns: "Stories 4-5 complete. Files modified: LoginForm.tsx, AuthContext.tsx"
  - Main context still thin -- just summaries from both agents
```

### Phase 3: Interruption -- Production Bug

```
User: "Hold on -- production bug in the payment service"

Claude (orchestrator):
  - Checkpoint current sprint state to session-state.md:
    active_bundles: [sprint, api, frontend]
    current_task: Sprint-UserAuth-001 (3/5 stories complete)
    next_steps: test frontend stories, run integration tests

  - New task: production bug
  - Routing weight: not a sprint -- this is debugging
  - Launches Agent with: api.md + deploy.md (payment context)
  - Agent investigates, finds root cause, returns fix
  - Main context: still thin, just bug summary

User: "Good, deploy the fix"
  - Launches Agent with: deploy.md
  - Agent deploys, returns: "Fix deployed to production"
```

### Phase 4: Resume Sprint

```
User: "Back to the sprint"

Claude (orchestrator):
  - Reads session-state.md
  - Resumes: Sprint-UserAuth-001, stories 4-5 complete, need testing
  - Launches Agent with: sprint.md + frontend.md + api.md
  - Agent runs integration tests
  - Returns: "All tests passing. Sprint complete."
```

### End State

Main context consumed: ~20 lines of summaries across 4 agent calls.
Without Neuro-Context: would have loaded all bundle content into main context,
filled up, needed manual /clear, lost sprint state, reloaded manually.

## Key Takeaways

1. **Main context never loaded code** -- agents did all the heavy lifting
2. **Task switch was seamless** -- checkpoint preserved sprint state
3. **Each agent got exactly what it needed** -- no wasted context
4. **Parallel execution possible** -- API and frontend agents could run simultaneously
5. **Production interrupt didn't destroy sprint context** -- session-state.md preserved it
