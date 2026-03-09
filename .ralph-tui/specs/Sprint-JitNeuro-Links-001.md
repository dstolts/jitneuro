# Sprint-JitNeuro-Links-001

## Overview
Add JitNeuro links and references across all owned properties. Separate from
the landing page sprint -- this is distribution, not creation.

**Scope:** Add links to jitneuro.ai and/or GitHub repo from existing sites,
profiles, and content. No new content creation (blog post is a separate sprint).

## Stories

### US-001: jitai.co Navigation
**Priority:** P0
**Accept:** JitNeuro link visible in site navigation or footer

- Add "JitNeuro" or "Open Source" link to jitai.co navigation
- Links to jitneuro.ai (or GitHub if landing page not ready)
- Location: footer links section or top nav "Products" dropdown
- Repo: D:\Code\jitai

### US-002: jitai.co About/Products Page
**Priority:** P0
**Accept:** JitNeuro mentioned on the about or products page

- Add JitNeuro section to products/tools page
- Brief description: "Open-source memory management framework for Claude Code"
- Link to jitneuro.ai and GitHub
- Repo: D:\Code\jitai

### US-003: LinkedIn Company Page
**Priority:** P0
**Accept:** JitNeuro mentioned in company description or featured section

- Update Just In Time AI LinkedIn page (https://www.linkedin.com/company/111952705/)
- Add JitNeuro to featured section or about description
- Link to jitneuro.ai

### US-004: LinkedIn Personal Profile
**Priority:** P1
**Accept:** JitNeuro in Dan's featured section or experience

- Add JitNeuro project to Dan's LinkedIn profile
- Featured section or Projects section
- Brief description + link

### US-005: GitHub Profile
**Priority:** P0
**Accept:** jitneuro repo pinned on Dan's GitHub profile

- Pin jitneuro repo on github.com/dstolts
- Verify repo description and topics are set
- Topics: claude-code, ai-memory, developer-tools, productivity, framework

### US-006: GitHub Repo Polish
**Priority:** P0
**Accept:** Repo looks professional for public visitors

- Description: "Endless Auto-Recall Memory for Claude Code"
- Topics/tags set (see US-005)
- License visible (MIT)
- README renders correctly on GitHub
- No sensitive data in committed files
- .gitignore covers .logs/, session-state/, settings.local.json

### US-007: FirstMover DIRECTORY.md
**Priority:** P1
**Accept:** JitNeuro entry committed and pushed

- Commit the existing DIRECTORY.md update in D:\Code\FirstMover
- Already has JitNeuro as entry #4 (just needs commit + push)

### US-008: jitai.co Blog Cross-Link
**Priority:** P1 (after blog post exists)
**Accept:** Blog post links to jitneuro.ai

- When FR-003 blog post is published, ensure it links to:
  - jitneuro.ai landing page
  - GitHub repo
  - Demo video
- This story is a placeholder -- executes after blog sprint

### US-009: diyaisupport.com Cross-Reference
**Priority:** P2
**Accept:** JitNeuro mentioned on DIY AI Support if relevant

- Evaluate if JitNeuro fits the diyaisupport.com messaging
- If yes, add a tools/resources link
- If no, skip this story
- Repo: D:\Code\diyaisupport

### US-010: ai-boat-mechanic Cross-Reference
**Priority:** P2
**Accept:** Evaluate if cross-link makes sense

- AIBM is a product, not a developer tool
- Probably no cross-link needed
- Skip unless Dan sees a connection
- Repo: D:\Code\ai-boat-mechanic

## Execution Notes

- Stories US-001 and US-002 require jitai repo changes (uat branch)
- US-003 and US-004 are LinkedIn manual updates (not code)
- US-005 and US-006 are GitHub settings (gh CLI or web UI)
- US-007 is a simple git commit
- US-008 depends on blog post sprint (FR-003)
- US-009 and US-010 are evaluate-and-skip unless Dan says otherwise

## Dependencies
- Landing page (Sprint-JitNeuro-LandingPage-001) should be live before most links go up
- GitHub repo must be pushed (RED -- needs Dan approval)
- Blog post sprint not yet planned

## Pass Criteria
- All P0 stories complete
- Links verified (no 404s)
- Consistent messaging across all properties
