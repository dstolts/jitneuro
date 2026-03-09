# JitNeuro Feature Requests

## FR-001: Scheduled Task Agent
**Priority:** High
**Status:** Idea

Light local agent (Node or PowerShell) that:
- Reads a todo list (markdown or JSON)
- Kicks off Claude Code sessions via JitNeuro with the right bundles
- Runs on a schedule (cron/Task Scheduler)
- Each task gets its own session-state checkpoint
- Reports results back to the todo list (pass/fail/needs-Dan)

Use cases:
- Nightly code reviews across repos
- Scheduled blog drafts from content calendar
- Automated context file refresh (DOE spec freshness check)
- Sprint story pre-validation before Ralph runs
- Morning briefing: scan all active-work, summarize what needs attention

Architecture: minimal -- reads list, shells out to `claude` CLI with bundled context, captures output, updates list. No server, no API, no database.

## FR-002: Blog Post -- "How to Get AI Coding Assistants to Actually Remember"
**Priority:** High (launch day)
**Status:** Planned

Thought leadership piece on jitai.co. Not a product announcement -- a problem statement every developer relates to.

Outline:
- The universal problem: context limits, memory loss, /clear kills everything
- The journey: months of iteration since Claude Code and Cursor first launched
- What doesn't work: giant CLAUDE.md files, manual reload, hoping for the best
- The framework: neural network metaphor (weights, layers, attention, checkpoints)
- The solution: JitNeuro -- bundles, routing weights, checkpoint/resume, sessions
- Live example: managing 16 repos, 6 concurrent sessions
- Link to GitHub repo at the end

Publish on jitai.co, cross-post to Dev.to, share on LinkedIn with video.
Record walkthrough video using QUICKSTART.md as the demo script.
