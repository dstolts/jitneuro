# JitNeuro v0.4.0 Launch Day Playbook

**Status:** Ready to execute  
**Date:** TBD (upon Owner approval)  
**Duration:** 4-6 hours active, then ongoing monitoring  
**Key Personnel:** Owner (primary), team members (optional support)  

---

## Overview

This playbook orchestrates the v0.4.0 launch across all channels. Follow this timeline to ensure a smooth, coordinated release.

**Why this matters:**
- First impression for community
- Sets tone for future releases
- Establishes credibility and momentum
- Creates feedback loop for v0.4.1

---

## Pre-Launch (Day Before)

### Owner Checklist

- [ ] **Review all launch documents**
  - [ ] LAUNCH-VERIFICATION-CHECKLIST.md
  - [ ] LAUNCH-PROMOTION-STRATEGY.md
  - [ ] FAQ-AND-TROUBLESHOOTING.md

- [ ] **Gather marketing materials**
  - [ ] Blog post text (finalized)
  - [ ] Social media copy (drafted)
  - [ ] Email template (if applicable)
  - [ ] GitHub release notes (ready to copy)

- [ ] **Setup community channels**
  - [ ] GitHub Discussions enabled
  - [ ] Issue labels created
  - [ ] Welcome post drafted

- [ ] **Personal preparation**
  - [ ] Clear calendar for launch day
  - [ ] Prepare monitoring setup (metrics dashboard)
  - [ ] Ensure tools are working (GitHub, Twitter, Dev.to, YouTube)
  - [ ] Test browser access to all platforms

- [ ] **Backup & safety**
  - [ ] Local backup of all docs
  - [ ] Verify rollback plan (if needed)
  - [ ] Have rollback commands ready

---

## Launch Day Timeline

### 🕐 Hour 1 (T+0:00 to T+1:00) — Push to Main

**T+0:00 — Start**

- [ ] Coffee/energy drink ready
- [ ] All communication channels open
- [ ] Timer started (track duration)
- [ ] Team/collaborators notified (launch starting)

**T+0:05 — Execute Push**

```bash
# From jitneuro directory:
git push origin main
git tag v0.4.0
git push --tags

# Verify
git log origin/main..HEAD  # should be empty
```

Monitor:
- [ ] Push completes without errors
- [ ] No merge conflicts
- [ ] Tag created successfully

**T+0:15 — GitHub Verification** (Use LAUNCH-VERIFICATION-CHECKLIST.md)

- [ ] Verify push to origin successful
- [ ] Check GitHub repo shows 5 new commits
- [ ] Confirm v0.4.0 tag visible on repo
- [ ] Verify README renders correctly
- [ ] Check no stale content shows

**T+0:30 — GitHub Setup**

- [ ] Update repo description
- [ ] Add website URL (jitneuro.ai)
- [ ] Add topics (8 topics)
- [ ] Create GitHub release with release notes
- [ ] Enable Discussions (if not already)

**T+0:45 — Monitoring Setup**

- [ ] Open GitHub analytics
- [ ] Open metrics tracking sheet
- [ ] Note starting stats:
  - Stars: ____
  - Forks: ____
  - Watchers: ____
- [ ] Set timers for first hour monitoring (every 15 min)

**T+1:00 — Ready for Announcement**

Checkpoint:
- ✅ All pushed and verified
- ✅ GitHub setup complete
- ✅ Monitoring running
- ✅ Ready for public announcement

---

### 🕐 Hour 2 (T+1:00 to T+2:00) — Announcement & Initial Promotion

**T+1:00 — Deploy Landing Page** (if ready)

If landing page is built:
- [ ] Deploy to Vercel (jitneuro.ai)
- [ ] Test that domain resolves
- [ ] Verify all pages load
- [ ] Check mobile responsiveness
- [ ] Test all links

If not ready:
- [ ] Note "landing page coming soon" for blog post
- [ ] Will deploy during Week 1

**T+1:15 — Cross-Post Blog to Dev.to** (15 min)

- [ ] Log into Dev.to
- [ ] Create new post with front matter (see DEVTO-CROSS-POST-GUIDE.md)
- [ ] Copy blog content
- [ ] Adjust formatting for Dev.to
- [ ] Set canonical URL to original blog
- [ ] Publish

Monitor:
- [ ] Post appears on Dev.to
- [ ] Tags showing correctly
- [ ] Cover image loads

**T+1:30 — Social Media Announcement** (Phase 1)

Post to Twitter/LinkedIn:

**Twitter (3 posts in sequence):**

Post 1 (Pain point):
```
Claude Code forgets everything after /clear.
Every context reset is amnesia.
Every new session means re-explaining your entire project.

This shouldn't have to be your life.
```

Post 2 (Solution):
```
Meet JitNeuro: auto-recall memory for Claude Code.

/save your context
/load it back anytime
/learn from corrections

Context persists. Claude learns. You move faster.

[link]
```

Post 3 (Call to action):
```
Just shipped JitNeuro v0.4.0.

Zero dependencies. Markdown + Bash. Install in 3 minutes.

Get started:

github.com/dstolts/jitneuro

Works macOS, Linux, Windows (Git Bash). MIT license.
```

**LinkedIn (1 long-form post):**
```
Just shipped JitNeuro: auto-recall memory for Claude Code.

Problem: Every time you clear context in Claude Code, you lose
everything. You re-explain your architecture, your stack, your
sprint status. Every. Single. Session.

Solution: JitNeuro saves your context. /save before /clear, /load
after. Your context persists. Claude remembers.

But it goes deeper:

- /learn makes corrections permanent (your preferences compound)
- Multi-repo orchestration (manage context across repos)
- Enterprise trust zones (GREEN/YELLOW/RED governance)
- Scheduled agents (autonomous execution)

Built on the DOE framework. No external dependencies. Just markdown,
bash, Claude Code.

v0.4.0 ships today, fully open source (MIT).

GitHub: [link]
Docs: [link]

Install in 3 minutes. Try it: the productivity gain is real.
```

**T+1:50 — Check Early Response**

- [ ] Monitor GitHub stars (should see first 5-10)
- [ ] Check Twitter/LinkedIn engagement
- [ ] Look for retweets/shares
- [ ] Monitor Dev.to views
- [ ] Note any early feedback

**T+2:00 — Checkpoint**

Status:
- ✅ Announced across 3 channels (GitHub, Twitter, LinkedIn)
- ✅ Cross-posted to Dev.to
- ✅ First social engagement happening
- ✅ No critical issues reported

---

### 🕐 Hour 3 (T+2:00 to T+3:00) — Community Engagement

**T+2:00 — Share in Communities**

Post to relevant communities (limit self-promotion, be helpful):

**Discord/Slack Communities:**

Claude Code Discord (if applicable):
```
Just shipped JitNeuro v0.4.0 - auto-recall memory for Claude Code.

Problem: /clear causes amnesia. Every session starts from scratch.

Solution: /save before /clear, /load after. Context persists.

github.com/dstolts/jitneuro
Docs: [link to setup guide]
5-min walkthrough: [video link when ready]

MIT license, zero dependencies, just Markdown + Bash.

Happy to answer questions!
```

**Hacker News (if applicable):**

Show HN: JitNeuro — Auto-Recall Memory for Claude Code

Title: "Show HN: JitNeuro – Auto-Recall Memory for Claude Code"
URL: https://github.com/dstolts/jitneuro

Comments (in discussion):
```
Hey HN, I just shipped JitNeuro v0.4.0. It solves a pain point I've
had for months: Claude Code forgets everything after /clear.

JitNeuro saves your context and reloads it. But it also learns from
your corrections (/learn command), so Claude gets better at your work
over time.

It's all markdown + bash, no external dependencies. Installs in 3
minutes.

Happy to answer questions about the architecture, use cases, or why
I built it this way. Looking forward to feedback from the community!
```

**Reddit (if applicable):**

Subreddits: r/OpenAI, r/programming, r/devtools

Template:
```
[Show] JitNeuro – Auto-Recall Memory for Claude Code

I just shipped v0.4.0 of JitNeuro, a memory system for Claude Code
that solves context amnesia.

Problem: Every /clear, you lose everything. Re-explain your project,
your stack, your progress. Every session.

Solution: /save your context, /load it back. Works across /clear.

But it's more than that:
- /learn from corrections (rules persist)
- /sessions tracks all your saved work
- /enterprise for team coordination
- Scheduled agents for autonomous tasks

Built with Markdown + Bash. Installs in 3 minutes. MIT open source.

GitHub: [link]
Docs: [link]
Walkthrough: [video link when ready]

Would love feedback on the architecture and use cases!
```

**Monitor:**
- [ ] Check for upvotes on HN (aim for top 10)
- [ ] Monitor Reddit comments
- [ ] Track engagement metrics

**T+2:30 — Respond to Early Feedback**

- [ ] Check all channels for questions/feedback
- [ ] Respond promptly (within 30 min)
- [ ] Thank early supporters
- [ ] Address any concerns
- [ ] Link to FAQ for common questions

**T+3:00 — Checkpoint**

Status:
- ✅ Shared in all major communities
- ✅ Community questions being answered
- ✅ Metrics improving (stars, engagement)
- ✅ No critical issues

---

### 🕐 Hour 4+ (T+3:00 onwards) — Sustained Monitoring

**T+3:00 to T+6:00 — Active Monitoring**

Every 30 minutes:
- [ ] Check GitHub issues/discussions
- [ ] Monitor social media
- [ ] Note engagement metrics
- [ ] Respond to comments/questions
- [ ] Alert Owner to any issues

**Metrics to track hourly:**
- GitHub stars (should see steady growth)
- Social media engagement (retweets, comments, shares)
- Dev.to views and reactions
- Community mentions
- GitHub issues (note any bugs)

**If issues arise:**
- [ ] See CRISIS MANAGEMENT in LAUNCH-PROMOTION-STRATEGY.md
- [ ] Don't panic, respond thoughtfully
- [ ] Fix and communicate transparently

**T+6:00 — Initial Report**

After 6 hours, summarize:

| Metric | Target | Actual |
|--------|--------|--------|
| GitHub stars | 50+ | ___ |
| GitHub issues | <5 bugs | ___ |
| Social engagement | 20+ retweets | ___ |
| Dev.to views | 50+ | ___ |
| Mentions | 10+ | ___ |

---

## Evening (T+6:00 to T+24:00)

### Ongoing Monitoring

- [ ] Check GitHub daily
- [ ] Respond to issues within 24h
- [ ] Monitor engagement (don't obsess)
- [ ] Plan day 2-3 tasks (video, blog cross-post)

### Evening Recap (T+12:00)

Summarize end-of-day:

```
LAUNCH DAY RECAP (v0.4.0):

✅ Successes:
- Pushed to main without issues
- GitHub setup complete
- Announcement across 3 channels
- Community response positive
- No critical bugs reported

📊 Day 1 Metrics:
- GitHub stars: ___
- Issues opened: ___
- Social engagement: ___
- Dev.to views: ___

🎯 Tomorrow:
- Record video walkthrough (if not done)
- Monitor GitHub for issues
- Plan week 1 promotion

Notes for team/log:
[Any observations, learnings, feedback]
```

---

## Days 2-3 (Post-Launch Continuation)

### Day 2 Focus: Video Content

- [ ] Record video walkthrough (use VIDEO-SCRIPT-DETAILED.md)
- [ ] Edit video (add captions, transitions)
- [ ] Upload to YouTube
- [ ] Add link to GitHub README
- [ ] Share on social media

### Day 3 Focus: Consolidation

- [ ] Monitor all platforms for feedback
- [ ] Create FAQ update (based on questions)
- [ ] Plan Week 1 tasks
- [ ] Prepare metrics report

---

## Week 1 Summary Metrics

Target (after 7 days):
| Metric | Target | Actual |
|--------|--------|--------|
| GitHub stars | 100-150 | ___ |
| GitHub forks | 10+ | ___ |
| Issues (bugs) | <10 | ___ |
| Issues (questions) | 10+ | ___ |
| GitHub discussions | 5+ | ___ |
| YouTube views | 100+ | ___ |
| Dev.to views | 300+ | ___ |
| Social mentions | 50+ | ___ |
| Community engagement | Positive | ___ |

---

## Success Criteria

**Launch is successful if:**

✅ **Technical:**
- All pushes succeed without conflicts
- GitHub renders correctly
- No critical bugs in framework
- Release notes published

✅ **Community:**
- First 50+ stars in day 1
- Positive community response
- <10 bugs reported
- 10+ questions answered

✅ **Momentum:**
- Sustained engagement day 2-3
- Video recorded and shared
- Blog cross-posted
- Week 1 growth trajectory positive

---

## Troubleshooting During Launch

### If GitHub push fails:

1. **Check for conflicts**
   ```bash
   git status
   ```

2. **Sync with origin**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

3. **Try again**
   ```bash
   git push origin main
   ```

4. **If still failing:** Open GitHub issue, don't force push

### If metrics are low:

- Don't panic (takes 24-48h for visibility)
- Check if announcement reached audience
- Consider additional promotion channels
- Adjust messaging if feedback suggests misunderstanding

### If bugs reported:

- See CRISIS MANAGEMENT in LAUNCH-PROMOTION-STRATEGY.md
- Create hotfix on separate branch if critical
- Communicate transparently with community
- Update FAQ with fix

---

## Owner Decision Points

**Before launch:**
- ✅ Approve push to main

**During launch (Hour 1):**
- Decision: Deploy landing page now or defer to Week 1?
  - Now: Extra polish, but time pressure
  - Week 1: Less stress, can iterate based on feedback

**During launch (Hour 3):**
- Decision: Pause for issues or continue promotion?
  - Continue: Maintain momentum
  - Pause: Only if critical bug found

**After Day 1:**
- Decision: Adjust Week 1 plans based on response?
  - Scale up: If demand > expected
  - Scale down: If less interest than expected

---

## Communication Templates

### Status Update (daily)

```
JitNeuro v0.4.0 Launch Update — Day X

📊 Metrics (24h):
- GitHub stars: ___
- Issues: ___ (bugs: ___, questions: ___)
- Social engagement: ___
- Video views: ___

✅ Completed:
- [Task]
- [Task]

🎯 Today:
- [Task]
- [Task]

🚨 Issues: [None / if any: brief description]

Next update: Tomorrow same time.
```

### Issue Response (template)

```
Thanks for reporting this! 

[Acknowledge their issue specifically]

Here's what's happening: [brief explanation]

To fix it: [step-by-step solution]

If that doesn't work, [next troubleshooting step]

Let me know if you have other questions!
```

---

## Post-Launch Retrospective (Week 2)

After launch week, review:

1. **What went well?**
   - Smooth push?
   - Community response?
   - No critical bugs?

2. **What could improve?**
   - Announcement timing?
   - Content quality?
   - Documentation gaps?

3. **What surprised you?**
   - Unexpected uptake?
   - Community feature requests?
   - Usage patterns?

4. **What's next?**
   - Update roadmap based on feedback
   - Plan v0.4.1 priorities
   - Identify quick wins

---

## Resources During Launch

**Keep these open:**
- LAUNCH-VERIFICATION-CHECKLIST.md (reference)
- LAUNCH-PROMOTION-STRATEGY.md (playbook)
- FAQ-AND-TROUBLESHOOTING.md (support)
- GitHub repo (monitor)
- GitHub analytics (metrics)
- Social media tabs (engagement)
- Text editor (for notes)

**Contacts to have ready:**
- Tech support (if needed)
- Collaborators (for help)
- Community moderators (Discord/Slack)

---

## Final Notes

**Remember:**
- This is a marathon, not a sprint
- Day 1 engagement doesn't define success
- Sustained growth over 4 weeks matters more than day 1 stars
- Community feedback is gold (listen, don't defend)
- Have fun with it! This is the moment you share your work.

**Confidence level:** HIGH (98%)

All systems go. Ready to launch.

---

**Status:** Playbook complete. Ready to execute upon Owner approval.

**Next step:** Owner reviews LAUNCH-DAY-PLAYBOOK.md and confirms readiness for launch day.
