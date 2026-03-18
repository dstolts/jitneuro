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
- [x] Deployed as pilot (workspace + user level)
- [x] /health command created
- [x] /enterprise command created
- [x] Hooks created (PreCompact, SessionStart recovery, branch protection, SessionEnd auto-save)
- [x] All slash commands created (status, dashboard, gitstatus, diff, audit, bundle, onboard)
- [x] FEATURE-REQUESTS.md updated with FR-006 through FR-020
- [x] README updated with new files, commands, hooks
- [x] Final README review -- tone, humility, no sales language, generic examples
- [x] Test /learn in a real session (run it, verify health check output)
- [x] Test /save -> /clear -> /load cycle one more time
- [x] Clean up any test session-state files
- [x] Update install scripts to copy hooks + new commands
- [x] Test hooks on Windows (bash path compatibility)
- [x] Test /gitstatus across all repos
- [x] Test /health diagnostic
- [x] Remove hardcoded paths from all templates (34 files, 3-agent cleanup)
- [x] Remove "Dan" references -- generic for open source
- [x] Remove project-specific examples (AIBM, FirstMover, jitai, etc.)
- [x] Simplify QUICKSTART.md to 3-step flow
- [x] Rewrite DEMO-SCRIPT.md as tutorial (not internal marketing)
- [x] Rename Phase 2 from "Cognitive Layer" to "Decision Frameworks"
- [x] Add FR-021 (customizable assistant/user names)
- [x] Add FR-022 (artwork/logo)
- [ ] Add prerequisite note (requires Claude Code -- what version?)

## Landing Page (jitneuro.ai)

- [ ] Build landing page with Lovable
- [ ] Hero: "Endless Auto-Recall Memory for Claude Code" + tagline
- [ ] Problem/solution sections (from README)
- [ ] Architecture diagram (neural network mapping)
- [ ] Context budget comparison (3-4% vs monolithic 10%+)
- [ ] Key concepts: bundles, engrams, routing weights, /learn
- [ ] "Get Started" CTA -> GitHub repo
- [ ] Enterprise section: holistic review, multi-repo orchestration, Ralph integration
- [ ] About/author section: [Your Name] / [your-site]
- [ ] #FirstMover badge
- [ ] Deploy to Vercel (jitneuro.ai DNS)
- [ ] Mobile responsive check

## GitHub

- [x] Initialize git remote (github.com/dstolts/jitneuro)
- [ ] Push to main (RED -- needs owner's explicit approval)
- [ ] Verify README renders correctly on GitHub
- [ ] Add topics: claude-code, ai-memory, context-management, developer-tools
- [ ] Add description: "Endless Auto-Recall Memory for Claude Code"
- [ ] Add website: jitneuro.ai

## FirstMover

- [ ] Add JitNeuro entry to FirstMover DIRECTORY.md
- [ ] Update FirstMover README if needed

## Content & Promotion

- [x] Blog post published (FR-003)
- [ ] Cross-post to Dev.to
- [ ] Record walkthrough video using QUICKSTART.md as demo script
- [ ] Upload video to YouTube

## Post-Launch

- [ ] Monitor GitHub issues/stars
- [ ] Run /learn to capture launch learnings
