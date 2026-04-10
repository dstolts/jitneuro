# Content Cross-Post Guide — Dev.to & Video

**Status:** Ready to execute (blog post already published)  
**Platforms:** Dev.to, YouTube  
**Timeline:** Can start parallel to main push  

---

## Task 1: Cross-Post Blog to Dev.to

**Status:** Blog published (location TBD), ready to cross-post  
**Time:** 15-20 minutes  
**Tools:** Dev.to account + Markdown

### Process

1. **Log in to Dev.to** (https://dev.to)
2. **Create new post** (upper left "+ New Post")
3. **Copy content from original blog post**
4. **Adjust for Dev.to format:**
   - Add front matter (title, tags, cover image, canonical URL)
   - Ensure code syntax highlighting is set correctly
   - Links should point to jitneuro GitHub repo
   - Add canonical URL to original blog (SEO credit)

### Template Front Matter

```markdown
---
title: "JitNeuro: Endless Auto-Recall Memory for Claude Code"
description: "Stop re-explaining your project. Save once, Claude learns forever."
tags: claude, ai, memory, developer-tools
cover_image: https://jitneuro.ai/og-image.png
canonical_url: https://[your-blog-url]/jitneuro-launch
published: true
---
```

### Content Sections (from original blog)

- Problem: Claude Code amnesia after /clear
- Solution: JitNeuro's bundled memory system
- How it works: 30-second demo, then deeper dive
- Getting started: Link to QUICKSTART.md + GitHub
- Features: /save, /load, /learn, 22 commands, hooks
- Use cases: Teams, solo devs, multi-repo work
- Links: GitHub, landing page, docs

### Post-Publication Steps

- [ ] Share link in relevant communities:
  - Claude Code Discord (if applicable)
  - Dev.to community
  - Twitter/LinkedIn with #claude-code, #ai-memory
  - Hacker News (if appropriate)
- [ ] Monitor comments for Q&A
- [ ] Cross-link to original blog

---

## Task 2: Record & Upload Walkthrough Video

**Status:** Not started  
**Time:** 30-60 minutes (recording) + 15 min (editing) + 5 min (upload)  
**Tools:** Screen recorder + YouTube account  

### Video Spec

- **Title:** "JitNeuro Demo: Auto-Recall Memory for Claude Code"
- **Duration:** 5-8 minutes (walkthrough) + 2-3 min (Q&A tips)
- **Resolution:** 1080p or 4K
- **Format:** MP4 or WebM
- **Platform:** YouTube (public, unlisted initially, then public after landing page live)

### Script (from QUICKSTART.md walkthrough)

#### Part 1: Introduction (1 min)
- "Hey, I'm [name], this is JitNeuro"
- Show problem: Open Claude Code, explain context amnesia
- Show solution: `/save` and `/load` commands

#### Part 2: Installation (2 min)
- Clone repo
- Run `./install.sh user`
- Restart Claude Code
- Show commands loaded with `/help`

#### Part 3: Core Features Demo (3-4 min)

**Demo 1: /save and /load**
- Start working on a project
- Run `/save my-session`
- Run `/clear` (context reset)
- Run `/load my-session`
- Show context restored

**Demo 2: /learn**
- Run `/learn` to create a learning entry
- Show rule persistence

**Demo 3: /health**
- Run `/health` to verify system
- Show memory system status

**Demo 4: /sessions**
- Run `/sessions` to list all saved sessions
- Show historical context available

#### Part 4: Real-World Workflow (1-2 min)
- Show example: multi-repo sprint work
- Show how /save helps between context resets
- Show how /learn improves Claude's understanding over time

#### Part 5: Call to Action (30 sec)
- "Learn more at jitneuro.ai"
- "Get started: github.com/dstolts/jitneuro"
- "Questions? Check the docs or open an issue"

### Recording Tips

- **Record at 1080p** minimum (YouTube optimizes automatically)
- **Clear voice**, speak slowly and clearly
- **Show command output** clearly (enlarge terminal if needed)
- **Pause briefly** after each command runs (let output settle)
- **Use cursor highlighting** if available (helps follow along)
- **Background:** Simple background, no distractions

### Editing

- **Add intro/outro:** 5-10 sec each (jitneuro logo + title)
- **Add captions:** Auto-generated YouTube captions, but review manually
- **Add text overlays:** "Step 1: Clone", "Step 2: Install", etc.
- **Music:** Royalty-free background music (optional, subtle)
- **Thumbnail:** Screenshot of Claude Code with "/save" command visible

### Upload to YouTube

1. Go to YouTube Studio (https://studio.youtube.com)
2. Click "Create" → "Upload video"
3. Select MP4 file from export
4. Fill in:
   - **Title:** "JitNeuro Demo: Auto-Recall Memory for Claude Code"
   - **Description:** (see template below)
   - **Tags:** claude-code, ai, memory, developer-tools, tutorial
   - **Category:** Science & Technology
   - **Visibility:** Unlisted (until landing page is live, then set to Public)
5. **Thumbnail:** Upload custom thumbnail (see editing notes)
6. **Premiere settings:** Can schedule premiere if desired

### Video Description Template

```
JitNeuro Demo: Auto-Recall Memory for Claude Code

Learn how JitNeuro solves context amnesia in Claude Code. In this 
walkthrough, we'll install JitNeuro and demo:
- /save: Save your session context
- /load: Restore context after /clear
- /learn: Create learning rules that persist
- /health: Monitor memory system health
- /sessions: View saved sessions

⏱️ Timeline:
0:00 - Introduction
1:00 - Installation
3:00 - Demo: /save and /load
5:30 - Demo: /learn and /health
6:45 - Real-world workflow
8:15 - Call to action

📚 Resources:
- GitHub: https://github.com/dstolts/jitneuro
- QUICKSTART: https://github.com/dstolts/jitneuro/blob/main/QUICKSTART.md
- Docs: https://github.com/dstolts/jitneuro/tree/main/docs
- Landing Page: https://jitneuro.ai

#claude-code #ai #memory #developer-tools
```

### Post-Upload Steps

- [ ] Share video link in communities
- [ ] Add video URL to landing page
- [ ] Link video in GitHub README
- [ ] Share on social media (Twitter, LinkedIn)
- [ ] Embed video in blog post (if cross-posting)

---

## Content Calendar

**Week 1 (after main push):**
- [ ] Push main branch + tag v0.4.0
- [ ] Cross-post blog to Dev.to
- [ ] Record and upload walkthrough video
- [ ] Setup GitHub repository metadata

**Week 2:**
- [ ] Launch landing page (jitneuro.ai)
- [ ] Add video to landing page + README
- [ ] Promote across channels

---

## Success Metrics

**Blog Post:**
- Target: 200+ views in first week
- Track: Dev.to analytics

**Video:**
- Target: 100+ views in first week
- Metric: Watch time, click-through to GitHub

**Overall:**
- Target: 50+ GitHub stars in first month
- Engagement: Issues, discussions, PRs from community

---

## Notes

- Blog post is the primary vehicle; video is supplementary
- Cross-post timing: Can do same day as main push, or stagger by 1-2 days
- Video takes longer; consider recording while landing page is being built
- Both content pieces amplify each other (link in video description to blog, etc.)

---

**Status:** Ready to execute. No blockers other than main branch push approval.
