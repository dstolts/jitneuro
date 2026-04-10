# Dev.to Cross-Posting Guide — JitNeuro Launch

**Status:** Ready to execute  
**Time to complete:** 15-20 minutes  
**Platform:** Dev.to (https://dev.to)  

---

## Why Dev.to?

- 2M+ monthly active developers
- High SEO value (impacts Google ranking)
- Community-driven (upvotes = visibility)
- Tag-based discovery (#claude-code, #ai-memory)
- Good for long-form technical content

---

## Step-by-Step Cross-Posting

### Step 1: Prepare Content

**Source:** Original blog post or markdown file  
**Required changes for Dev.to:**
- Add Dev.to-specific front matter
- Adjust formatting (Dev.to renders markdown differently)
- Add `#discuss` tag for community interaction
- Link back to original blog (SEO credit)

### Step 2: Login to Dev.to

1. Go to https://dev.to/new
2. Login with GitHub or email
3. You're now in the post editor

### Step 3: Create Post with Front Matter

**Template (copy this exactly):**

```markdown
---
title: "JitNeuro: Endless Auto-Recall Memory for Claude Code"
description: "Stop re-explaining your project. Save sessions, load them later. Claude learns your patterns."
tags: claude, ai, memory, developer-tools
cover_image: https://jitneuro.ai/og-image.png
canonical_url: https://your-blog-url.com/jitneuro-launch
published: false
---

# JitNeuro: Endless Auto-Recall Memory for Claude Code

[Rest of blog content goes here]
```

**Front Matter Details:**

| Field | Value | Notes |
|-------|-------|-------|
| **title** | "JitNeuro: Endless Auto-Recall Memory for Claude Code" | Keep under 80 chars for social preview |
| **description** | "Stop re-explaining your project..." | Shows in preview, max 200 chars |
| **tags** | claude, ai, memory, developer-tools, ai-agents | 4-5 tags, lowercase, no spaces |
| **cover_image** | https://jitneuro.ai/og-image.png | 1200x630px recommended, PNG/JPG |
| **canonical_url** | https://your-blog.com/jitneuro-launch | Links back to original (SEO) |
| **published** | false | Set to false until ready to publish |

---

### Step 4: Format Content for Dev.to

**Markdown rules on Dev.to:**

```markdown
# Heading 1 (title, auto-filled)

## Heading 2 (section)

### Heading 3 (subsection)

**Bold text**

*Italic text*

[Link text](https://example.com)

```bash
# Code blocks (include language)
code here
```

> Quoted text (appears as italicized)

---

**Image syntax:**
```markdown
![alt text](https://image-url.com/image.png)
```

**Video embed:**
```markdown
{% embed https://www.youtube.com/watch?v=video_id %}
```
```

### Step 5: Structure Content

**Recommended sections for JitNeuro post:**

```markdown
---
title: "JitNeuro: Endless Auto-Recall Memory for Claude Code"
description: "..."
tags: claude, ai, memory, developer-tools
cover_image: https://jitneuro.ai/og-image.png
canonical_url: [your-blog-url]
published: false
---

## Introduction

[Hook: Why this matters]

## The Problem: Context Amnesia

[Explain pain point]

## The Solution: JitNeuro

[What it does]

## How It Works

### 1. Save Your Session

[Explain /save]

### 2. Load It Back Anytime

[Explain /load]

### 3. Learn from Corrections

[Explain /learn]

## Getting Started

[Installation steps]

## Real-World Examples

[Use cases]

## What's Next

[Call to action]

## Resources

[Links to GitHub, docs, video]
```

---

### Step 6: Add Dev.to-Specific Enhancements

**Dev.to-exclusive markdown features:**

#### Liquid Tags (Dev.to special syntax)

**YouTube embed:**
```markdown
{% youtube video_id_here %}
```

**GitHub gist:**
```markdown
{% gist gist_url_here %}
```

**Code pen:**
```markdown
{% codepen user_name pen_id %}
```

**Stack overflow:**
```markdown
{% stackoverflow question_number %}
```

#### Emphasis boxes

```markdown
{% callout %}
**Important:** This is a callout box
{% endcallout %}
```

---

### Step 7: Pre-Publish Checklist

Before clicking "Publish":

- [ ] Title is clear and compelling (under 80 chars)
- [ ] Description (meta) is set (max 200 chars)
- [ ] Tags are present (4-5 tags, including #claude-code)
- [ ] Cover image is set and visible in preview
- [ ] Canonical URL points to original blog
- [ ] All links work (test in preview mode)
- [ ] Code blocks have syntax highlighting
- [ ] Images are embedded correctly
- [ ] No broken markdown formatting
- [ ] "Published" is set to "false" (review draft first)

### Step 8: Preview & Edit

1. Click "Preview" (top right)
2. Read through as a reader would
3. Check:
   - Formatting looks good
   - Links are clickable
   - Images display
   - Spacing is readable
4. Go back to editor if changes needed
5. Repeat until satisfied

### Step 9: Publish

1. Make sure "Published" is still set to "false" (allows edits later)
2. Click "Save draft"
3. Wait a few seconds
4. Click "Publish" (or "Update" if re-publishing)
5. Post goes live!

---

## Tags to Use

**Required tags:**
- `#claude-code` (primary)
- `#ai` (broad category)

**Recommended tags (pick 2-3):**
- `#memory` (core feature)
- `#developer-tools` (category)
- `#productivity` (benefit)
- `#ai-agents` (related topic)
- `#automation` (related topic)
- `#open-source` (project type)

**Do NOT use:**
- Tags unrelated to content (gaming, politics, etc.)
- Spam tags
- Brand names as tags (Claude, Anthropic are OK, but use judiciously)

---

## Post-Publication Steps

### Immediate (Same day)

1. **Monitor comments** for the first 24 hours
   - Set aside 30 min to respond to early comments
   - Answer questions thoughtfully
   - Don't be defensive
   - Link to docs when relevant

2. **Share on social**
   - Twitter: "Just published on Dev.to: [link]"
   - LinkedIn: Longer commentary + link
   - Share in Discord/Slack communities

3. **Monitor upvotes/comments**
   - Check back every few hours
   - Engage with early readers
   - Thank people who share

### Week 1

- [ ] Respond to all comments (maintain 24h SLA)
- [ ] Create a "Part 2" or "Advanced JitNeuro" post
- [ ] Share link in relevant communities (Reddit, HN, etc.)
- [ ] Update with feedback from comments

### Week 2-4

- [ ] Monitor for trending (Dev.to shows trending posts)
- [ ] Pin useful comments
- [ ] Create follow-up post if demand exists
- [ ] Link this post to new releases/updates

---

## Common Dev.to Features

### Add a Series

If you plan multiple JitNeuro posts:

1. Edit post
2. Find "Series" field
3. Create new series: "JitNeuro Deep Dives"
4. Add all related posts to series
5. Readers can follow entire series

### Reading Time

Dev.to auto-calculates reading time. Target: 5-10 min reads.
- If your post is >15 min, consider splitting into series
- Shorter posts (3-5 min) get more engagement initially

### Reactions

Readers can react with:
- ❤️ (love)
- 🦄 (unicorn — very popular)
- 🔥 (fire — hot topic)
- 🍌 (silly)

Don't worry about reactions — focus on meaningful engagement.

---

## SEO Tips for Dev.to

**Dev.to SEO best practices:**

1. **Title:** Include primary keyword (claude-code)
   - Good: "JitNeuro: Claude Code Memory System"
   - Bad: "My Awesome Project"

2. **Description:** Include secondary keywords
   - Good: "Save and restore Claude Code sessions with auto-recall memory"
   - Bad: "Cool new tool"

3. **Tags:** Use what people search for
   - Good: #claude-code, #memory, #developer-tools
   - Bad: #mycoolproject, #awesome

4. **Canonical URL:** Always include (credits original, prevents duplicate content)

5. **Links:** Link to your blog, GitHub, landing page
   - Helps with SEO and drives traffic
   - Use descriptive anchor text

6. **Headings:** Use proper H2/H3 structure
   - Good: ## Getting Started
   - Bad: Getting Started (bold text)

---

## Engagement Strategy

### Commenting Best Practices

**When someone comments:**

1. **Read carefully** — understand their point/question
2. **Respond within 24h** (better engagement)
3. **Be helpful, not promotional**
   - Good: "Great question! This is covered in [doc link]"
   - Bad: "Check out our landing page!"
4. **Ask follow-up questions** (keeps conversation alive)
   - "How are you using this in your workflow?"
5. **Acknowledge corrections** (builds trust)
   - "You're absolutely right, I should have mentioned that"

### Handling Criticism

**If someone criticizes (respectfully):**

1. **Don't take it personally**
2. **Acknowledge valid points**
3. **Explain tradeoffs** (if applicable)
4. **Invite discussion** ("Let's chat more about this")
5. **Update post** if feedback is valid

**If criticism is invalid/rude:**

1. **Don't engage** in the moment
2. **Flag if abusive** (Dev.to mods handle)
3. **Move on** — not every comment deserves a response

---

## Example Dev.to Post (Structure)

Here's a template structure to follow:

```markdown
---
title: "JitNeuro: Stop Re-Explaining Your Project to Claude Code"
description: "Save sessions, load them back, and watch Claude learn your patterns over time."
tags: claude-code, ai, memory, developer-tools
cover_image: https://jitneuro.ai/og-image.png
canonical_url: https://your-blog.com/jitneuro-launch
published: false
---

## The Daily Frustration

[Personal anecdote about context amnesia]

## The JitNeuro Solution

[What it does, why it matters]

## How It Actually Works

### /save: Checkpoint Your Context

[Explain with example]

### /load: Resume Where You Left Off

[Explain with example]

### /learn: Make Changes Permanent

[Explain with example]

## Installation (30 seconds)

[Installation steps]

## Real-World Workflow

[Concrete use case]

## What Makes This Different

[Comparison to alternatives]

## Try It Yourself

[Call to action with link]

## Questions?

[Engagement prompt]

---

**Canonical URL:** [original blog]
**GitHub:** github.com/dstolts/jitneuro
**Video:** [YouTube link]
```

---

## Timing Recommendations

**Best time to post (Dev.to):**
- **Tuesday-Thursday**: Higher engagement
- **9-10 AM ET**: Good morning for European users
- **Avoid Mondays/Fridays**: Lower engagement

**Promote for:**
- 24-48 hours maximum (after that, declining engagement)
- Use this window to share on Twitter, Reddit, Discord

---

## Tools & Resources

**Dev.to documentation:**
- https://dev.to/docs

**Markdown cheatsheet:**
- https://dev.to/p/editor_guide

**SEO tools:**
- Google Search Console (add your blog for cross-posting tracking)
- Ahrefs or Semrush (if you have access)

---

## Success Metrics (Dev.to)

**Week 1 targets:**
- Views: 200+
- Comments: 5-10
- Reactions: 10+
- Shares: 5+

**Week 2-4 targets:**
- Views: 500-1000
- Comments: 20-30
- Reactions: 30+
- Shares: 15+

**Month 1 targets:**
- Views: 1000+
- Comments: 50+
- Reactions: 100+
- Followers gained: 20+

---

**Status:** Guide complete. Ready to execute upon main branch push and blog availability.
