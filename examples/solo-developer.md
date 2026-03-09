# Example: Solo Developer with Multiple Projects

This example shows a solo developer using JitNeuro to manage context
across 3 different projects in one session without manual /clear or reload.

## Setup

Global bundles (in ~/.claude/bundles/ or a shared location):
- `node-api.md` -- Node/Express conventions, common packages
- `react-app.md` -- React patterns, hooks, component structure
- `devops.md` -- Docker, CI/CD, environment management
- `database.md` -- SQL patterns, migrations, query optimization

Project-specific bundles:
- Project A: `.claude/bundles/project-a.md` -- business logic, domain model
- Project B: `.claude/bundles/project-b.md` -- business logic, domain model
- Project C: `.claude/bundles/project-c.md` -- business logic, domain model

## Session Flow

### Task 1: Fix bug in Project A (API)

```
User: "Fix the auth token expiry bug in Project A"

Claude (orchestrator):
  - Task type: bug fix + API
  - Routing: [node-api, project-a]
  - Launches agent:
    "Read .claude/bundles/node-api.md and .claude/bundles/project-a.md.
     Fix the auth token expiry bug. Check token refresh logic in auth middleware."
  - Agent returns: "Fixed. Token refresh now checks expiry with 5-min buffer.
    Modified: src/middleware/auth.ts:42-58"
  - Main context: 2 lines of summary
```

### Task 2: Add feature to Project B (React)

```
User: "Add dark mode toggle to Project B settings page"

Claude (orchestrator):
  - Task type: feature + frontend
  - Routing: [react-app, project-b]
  - Launches agent:
    "Read .claude/bundles/react-app.md and .claude/bundles/project-b.md.
     Add dark mode toggle to the settings page. Use existing theme context."
  - Agent returns: "Added. Toggle in SettingsPage.tsx, theme persisted to localStorage.
    Modified: SettingsPage.tsx, ThemeContext.tsx, globals.css"
  - Main context: 3 lines of summary
```

### Task 3: Deploy Project C

```
User: "Deploy Project C to staging"

Claude (orchestrator):
  - Task type: deploy
  - Routing: [devops, project-c]
  - Launches agent:
    "Read .claude/bundles/devops.md and .claude/bundles/project-c.md.
     Deploy to staging environment. Run pre-deploy checks first."
  - Agent returns: "Deployed to staging. Build passed. Health check green.
    URL: https://staging.project-c.example.com"
  - Main context: 2 lines of summary
```

### End State

Three projects, three different domains, zero context bleed between them.
Main context used: ~10 lines of summaries. Each agent had exactly the
context it needed and nothing more.

Without JitNeuro: developer would have loaded all 3 project contexts
at session start, filled context window by task 2, needed manual /clear,
lost task 1 results, reloaded manually for task 3.
