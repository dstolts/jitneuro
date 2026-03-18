# Sprint-JitNeuro-LandingPage-001

## Overview
Build the jitneuro.ai landing page using Lovable. Single-page marketing site
that positions JitNeuro as a game-changing productivity framework for Claude Code.

**Tool:** Lovable (AI website builder)
**Deploy:** Vercel (jitneuro.ai domain)
**Scope:** Landing page only. No backend, no auth, no dynamic content.

## Target Audience
Developers using Claude Code (or considering it) who manage multiple repos
and hit context limits. Technical but value-driven -- they want productivity,
not theory.

## Core Message
"Talk to your AI with full context and understanding -- every session, every time."

Supporting: "One developer managing 16+ repos is 3x more productive solo than
a 15-person dev team -- because the AI never loses context."

## Page Structure (Lovable Stories)

### US-001: Hero Section
**Priority:** P0
**Accept:** Hero visible above fold with headline, subheadline, CTA

- Opening message (above or near headline): "We are stronger together. With an army of developers helping each other, we can do amazing things TOGETHER."
- Headline: "Endless Auto-Recall Memory for Claude Code"
- Define JIT early: "JIT = Just In Time. Context loaded just in time -- not all the time."
- Subheadline: "Talk to your AI with full context and understanding -- every session, every time. No more re-explaining your codebase."
- CTA button: "Get Started" -> links to GitHub repo
- Secondary CTA: "Watch Demo" -> links to YouTube video (placeholder until recorded)
- Background: clean, dark theme, developer-friendly aesthetic
- JitNeuro logo/wordmark (text-based is fine for v1)

### US-002: Problem Section
**Priority:** P0
**Accept:** 3-4 pain points displayed clearly

- Header: "The Problem Every Developer Hits"
- Pain points (cards or list):
  1. "Context gets compressed. Claude forgets your conventions mid-session."
  2. "/clear wipes everything. You spend 5 minutes re-explaining after every reset."
  3. "One giant CLAUDE.md loads everything, every session. Most of it irrelevant."
  4. "Multiple repos? Good luck keeping context straight across projects."
- Tone: empathy, not fear. "You've hit this wall."

### US-003: Solution Section
**Priority:** P0
**Accept:** Framework overview with key features

- Header: "The Solution: Memory Management for AI"
- Brief intro: "JitNeuro adds a memory layer to Claude Code using its own primitives. No API keys, no server, no dependencies."
- Feature cards (4-6):
  1. Context Bundles -- "Domain knowledge, loaded only when needed"
  2. Engrams -- "Per-project deep context that strengthens over time"
  3. Save/Load -- "Checkpoint sessions. Survive /clear. Pick up where you left off."
  4. 15 Slash Commands -- "/gitstatus, /health, /dashboard, /audit, and more"
  5. 4 Safety Hooks -- "Branch protection, compaction alerts, auto-save"
  6. Rule of Lowest Context -- "Store rules where they apply. Zero cost when not relevant."

### US-004: Architecture Diagram
**Priority:** P1
**Accept:** Visual showing the memory hierarchy

- Show the 3-layer architecture from README:
  - Long-term memory (disk): MEMORY.md, bundles, engrams, specs
  - Working memory (context window): CLAUDE.md, active bundles, conversation
  - Short-term memory (checkpoints): session-state, active bundle list
- Neural network mapping table (simplified)
- Clean diagram, not a wall of text

### US-005: Productivity Proof Section
**Priority:** P0
**Accept:** The "3x more productive" narrative with supporting details

- Header: "3x More Productive Than a 15-Person Team"
- Quote/callout: "I manage 16+ repos solo. APIs, frontends, automation, docs, sales tools. I switch between them constantly. I never re-explain my codebase. The AI never loses context."
- Supporting stats:
  - 16+ repos managed from one workspace
  - 15 slash commands for every workflow
  - 4 safety hooks running automatically
  - 6 scoped rule templates included
  - Context budget: ~3-4% of context window for full infrastructure
- Attribution: Project author (see GitHub profile)

### US-006: How It Works Section
**Priority:** P1
**Accept:** Step-by-step flow showing the framework in action

- 3-4 steps with icons:
  1. Install (30 seconds): "Clone, run install script, done."
  2. Configure: "Slim your CLAUDE.md. Create bundles for your domains."
  3. Work: "Routing weights auto-load the right context. /save before /clear."
  4. Improve: "/learn evaluates each session. The system gets smarter over time."

### US-007: Context Budget Section
**Priority:** P1
**Accept:** Shows the lightweight cost of JitNeuro

- Header: "Costs ~3% of Your Context Window"
- Table from README: always loaded (~1-2%) + on-demand (~1-2%)
- Comparison: "A monolithic CLAUDE.md consumes 5-10%+ and scales worse."
- Key message: JitNeuro is lighter than the alternative.

### US-008: Get Started / CTA Section
**Priority:** P0
**Accept:** Clear installation path

- Header: "Get Started in 30 Seconds"
- Code block:
  ```
  git clone https://github.com/dstolts/jitneuro.git
  cd jitneuro
  ./install.sh workspace    # or .\install.ps1 -Mode workspace
  ```
- Links: GitHub repo, documentation, demo video
- Secondary CTA: "Star on GitHub"

### US-009: Footer
**Priority:** P1
**Accept:** Clean footer with links and attribution

- Links: GitHub, Documentation
- Copyright: "2025-2026 JitNeuro Contributors"
- Disclaimer: "JitNeuro is an independent open-source project. Not affiliated with Anthropic."
- MIT License badge

### US-010: SEO and Meta
**Priority:** P1
**Accept:** Proper meta tags and OG images

- Title: "JitNeuro - Endless Auto-Recall Memory for Claude Code"
- Description: "A memory management framework for Claude Code. 15 commands, 4 hooks, scoped rules. Manage 16+ repos without losing context."
- OG image: hero screenshot or branded card
- Keywords: Claude Code, AI memory, context management, developer productivity
- Favicon

## Design Notes for Lovable
- Dark theme preferred (developer audience)
- Clean, minimal, no clutter
- Monospace font for code blocks
- Responsive (mobile + desktop)
- Fast load (no heavy images, no video autoplay)
- ASCII aesthetic acceptable -- matches the "no emojis" brand

## Dependencies
- GitHub repo must be public (or about to be)
- Demo video URL (can be placeholder)
- jitneuro.ai domain pointed to Vercel

## Acceptance Criteria
- Page loads in under 2 seconds
- All CTAs link to correct destinations
- Mobile responsive
- SEO meta tags present
- No broken links
- Matches the messaging in README and DEMO-SCRIPT.md
