# JitNeuro Launch TODO

Target: publish GitHub + blog + LinkedIn same day.

## Pre-Launch

- [x] Core framework complete (v0.1.0)
- [x] Commands: /save, /load, /learn, /sessions, /orchestrate, /conversation-log
- [x] Templates: brainstem, bundles, engrams, session-state, rules
- [x] Docs: setup guide, master session, ralph integration, holistic review
- [x] Examples: multi-repo sprint, solo developer
- [x] QUICKSTART.md with 6 test scenarios
- [x] Context budget documented
- [x] LICENSE (MIT)
- [x] Disclaimer (not affiliated with Anthropic)
- [x] Deployed to D:\Code\ as pilot (workspace + user level)
- [x] /health command created
- [x] /enterprise command created
- [x] Hooks created (PreCompact, SessionStart recovery, branch protection, SessionEnd auto-save)
- [x] All slash commands created (status, dashboard, gitstatus, diff, audit, bundle, onboard)
- [x] FEATURE-REQUESTS.md updated with FR-006 through FR-020
- [x] README updated with new files, commands, hooks
- [ ] Final README review -- read top to bottom, fix any gaps
- [ ] Test /learn in a real session (run it, verify health check output)
- [ ] Test /save -> /clear -> /load cycle one more time
- [ ] Clean up any test session-state files
- [ ] Update install scripts to copy hooks + new commands
- [ ] Test hooks on Windows (bash path compatibility)
- [ ] Test /gitstatus across all repos
- [ ] Test /health diagnostic

## Landing Page (jitneuro.ai)

- [ ] Build landing page with Lovable
- [ ] Hero: "Endless Auto-Recall Memory for Claude Code" + tagline
- [ ] Problem/solution sections (from README)
- [ ] Architecture diagram (neural network mapping)
- [ ] Context budget comparison (3-4% vs monolithic 10%+)
- [ ] Key concepts: bundles, engrams, routing weights, /learn
- [ ] "Get Started" CTA -> GitHub repo
- [ ] Enterprise section: holistic review, multi-repo orchestration, Ralph integration
- [ ] About/author section: Dan Stolts / jitai.co
- [ ] #FirstMover badge
- [ ] Deploy to Vercel (jitneuro.ai DNS)
- [ ] Mobile responsive check

## GitHub

- [x] Initialize git remote (github.com/dstolts/jitneuro)
- [ ] Push to main (RED -- needs Dan's explicit approval)
- [ ] Verify README renders correctly on GitHub
- [ ] Add topics: claude-code, ai-memory, context-management, developer-tools
- [ ] Add description: "Endless Auto-Recall Memory for Claude Code"
- [ ] Add website: jitneuro.ai

## FirstMover

- [ ] Add JitNeuro entry to FirstMover DIRECTORY.md
- [ ] Update FirstMover README if needed

## Blog Post (FR-003)

- [ ] Write "How to Get AI Coding Assistants to Actually Remember" on jitai.co
- [ ] Include JitNeuro repo link at end
- [ ] Publish on jitai.co
- [ ] Cross-post to Dev.to

## Video

- [ ] Record walkthrough using QUICKSTART.md as demo script
- [ ] Show: routing weights, /save, /clear, /load, /learn, multi-repo
- [ ] Upload to YouTube or embed on jitai.co

## LinkedIn

- [ ] Post announcing JitNeuro with video
- [ ] Link to blog post + GitHub repo
- [ ] Tag relevant AI/dev communities

## Post-Launch

- [ ] Monitor GitHub issues/stars
- [ ] Update active-work bundle (jitneuro status -> launched)
- [ ] Run /learn to capture launch learnings
