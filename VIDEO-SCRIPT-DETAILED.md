# JitNeuro Video Walkthrough — Detailed Script

**Duration:** 7-8 minutes (with pauses)  
**Format:** Screen recording + optional intro/outro  
**Resolution:** 1080p minimum  
**Platform:** YouTube  

---

## Pre-Production Checklist

### Recording Setup
- [ ] Terminal: 24pt font, dark theme (good contrast)
- [ ] Claude Code: Expanded sidebar, clean workspace
- [ ] Optional: Cursor highlighting enabled
- [ ] Microphone: Tested, background noise minimal
- [ ] Backup mic: Phone voice memo as fallback

### Test Run
- [ ] Run through script once (note timing)
- [ ] Check all commands work
- [ ] Verify output is legible on screen
- [ ] Test pause/play for smooth edits

---

## Script: JitNeuro Demo (7-8 min)

### INTRO (30 seconds) — 0:00-0:30

**Visuals:** Title card or Claude Code splash screen

**Audio:**
"Hi, I'm [Your Name]. I'm going to show you JitNeuro — a memory system for Claude Code that solves one of the biggest pain points developers face every day.

The problem: Every time you clear context in Claude Code, you lose everything. You have to re-explain your project, your architecture, your sprint status. Every single session.

JitNeuro fixes that. Once. That's it. Let me show you how."

---

### PROBLEM STATEMENT (1 min) — 0:30-1:30

**Visuals:** Claude Code with a project open

**Audio:**
"Imagine you're working on a project. You've explained your stack, your architecture, your codebase structure. Claude knows it all.

Then context gets full, or you need a fresh start, and you hit /clear. Amnesia.

[Pause for effect]

You're back to square one. You explain everything again. Tomorrow, it happens again. You explain it again."

**Visual Demo:**
1. Show Claude Code with conversation history
2. Run `/clear` command
3. Show context reset (conversation gone)
4. Talk through what's lost

**Audio continued:**
"Every time. Every session. For every developer. Multiply that by the number of repos you work on, the number of projects in a sprint, the number of context resets you do daily.

That's a lot of wasted time explaining."

---

### SOLUTION INTRO (30 seconds) — 1:30-2:00

**Visuals:** Transition to terminal/installation

**Audio:**
"JitNeuro solves this with a simple idea: Save your session context. Load it back anytime. That's it.

Let me install it and show you what that looks like."

---

### INSTALLATION (2 minutes) — 2:00-4:00

**Visuals:** Terminal with git commands

**Audio:**
"First, clone the repo."

**Commands (type clearly, pause between):**
```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
```

[Pause for typing to complete]

**Audio:**
"Now install it. I'm using user mode — this makes JitNeuro available in every project on my machine. You can also do workspace or project mode if you prefer."

```bash
./install.sh user
```

[Pause for script to complete — show output]

**Audio:**
"The installer:
- Copies all the commands
- Sets up hooks for automatic saving
- Configures everything automatically
- No manual JSON editing needed

Now we need to restart Claude Code for the new commands to load."

**Visuals:** Close and reopen Claude Code (or simulate with /verify command)

**Audio:**
"Fresh session. Let me verify everything is set up."

```bash
/verify
```

[Pause, show output]

**Audio:**
"All green. Good to go."

---

### CORE FEATURE DEMO 1: /save and /load (2 minutes) — 4:00-6:00

**Visuals:** Claude Code with a fictional project context

**Audio:**
"Now let's see it in action. Let's say I'm working on a project, and I explain what I'm building."

**Scenario:**
"I'm working on an API that needs authentication, error handling, and logging. I explain my requirements, my design choices, my tech stack."

[Simulate conversation with Claude — 5-10 exchanges]

**Audio:**
"Now I have context loaded. Claude understands my project. I'm ready to work.

But I know I'm going to need a context reset soon. So I save my session."

```
/save my-api-project
```

[Pause, show output confirmation]

**Audio:**
"Done. My session is saved.

Now I work for a bit, context fills up, I hit /clear."

```
/clear
```

[Pause, show context reset]

**Audio:**
"Amnesia. Context is gone.

But watch what happens when I load my session back."

```
/load my-api-project
```

[Pause, show context restored]

**Audio:**
"There it is. My context is back. Claude remembers my API design, my stack choices, my requirements. I can pick up where I left off immediately.

No re-explaining. No starting from scratch."

---

### CORE FEATURE DEMO 2: /learn (1 minute) — 6:00-7:00

**Visuals:** Claude Code with correction scenario

**Audio:**
"There's one more command that makes this system powerful: /learn.

Every correction I make becomes a permanent rule. Watch."

**Scenario:**
"Let's say I have a preference about my code: I don't want mocked databases in tests. I want integration tests that hit the real DB."

[Make a test suggestion that uses mocks]

**Audio:**
"Claude suggests a mock. I correct it and say /learn."

```
/learn don't mock the database in tests
```

[Pause, show output]

**Audio:**
"Done. That's now a permanent rule. Every time I write tests going forward, Claude remembers: integration tests, not mocks.

This compounds over time. Every correction you make becomes part of how Claude works with you. Your style, your preferences, your best practices — they all become permanent patterns."

---

### REAL-WORLD EXAMPLE (1 minute) — 7:00-8:00

**Visuals:** List multiple saved sessions

**Audio:**
"Let me show you a more realistic scenario. I'm working on a sprint with multiple repos. I have different contexts for different projects."

```
/sessions
```

[Show list of saved sessions:]
```
- my-api-project (saved yesterday)
- ml-pipeline-work (saved 2 days ago)  
- frontend-ui-fixes (saved today)
- infra-migration (saved 1 week ago)
```

**Audio:**
"This is me in the real world. I switch between repos, switch between projects. Every time I switch, I load the relevant context.

I don't have to rebuild the mental model. Claude remembers the architecture, the decisions, the sprint status — everything.

That's JitNeuro."

---

### CALL TO ACTION (30 seconds) — 8:00-8:30

**Visuals:** GitHub repo page or landing page

**Audio:**
"Want to try it? It takes 3 minutes to install.

Go to github.com/dstolts/jitneuro. Clone it, run the installer, restart Claude Code.

That's it. You'll never re-explain your project the same way again.

Questions? Check the docs on GitHub or open an issue. The community's pretty active.

Thanks for watching. See you in the next one."

---

## Filming Notes

### Pacing & Pauses
- Pause 2-3 seconds after each command before showing output
- Pause 3-5 seconds on each major discovery/output (let viewer read)
- Speak slowly (1-2% slower than natural)
- Clear voice, annunciate

### Screen Management
- Keep terminal/Claude Code maximized and centered
- No distracting browser tabs or notifications
- Close Slack, Discord, etc. before recording
- If using multiple windows, use smooth transitions

### Recording Order (Pro Tip)
Record sections in this order (not in script order):
1. Installation (good warm-up)
2. /save and /load demo (main content)
3. /learn demo (shorter, easier)
4. /sessions list (quick)
5. Intro/outro voice-over separately

This way you can re-do problem sections without re-recording the whole thing.

### Common Mistakes to Avoid
- ❌ Typing too fast (hard to read)
- ❌ Not pausing after commands (output rushes)
- ❌ Showing errors without explanation (confusing)
- ❌ Jumping between windows too fast (disorienting)
- ❌ Background noise (loud fans, notifications)

---

## Editing Checklist

After recording:

### Video Editing
- [ ] Cut intro/outro transitions (fade in/out)
- [ ] Speed up pauses between commands (1.5-2x speed is OK)
- [ ] Remove false starts, "ums", "likes"
- [ ] Add text overlays:
  - "Step 1: Clone"
  - "Step 2: Install"
  - "Step 3: Verify"
  - "Step 4: Save"
  - "Step 5: Load"
- [ ] Add section markers/timestamps in description

### Audio
- [ ] Normalize audio level (consistent volume)
- [ ] Remove background hum if present
- [ ] Add subtle royalty-free background music (optional, keep low)
- [ ] Fade music under dialogue, up during pauses

### Thumbnail Design
- [ ] Screenshot of Claude Code with /save command visible
- [ ] Add text overlay: "JitNeuro Demo" or "Auto-Recall Memory"
- [ ] Use high contrast (white text on dark background)
- [ ] Brand color accent (indigo/purple)
- [ ] File size: <200KB, PNG format

### Final Check
- [ ] Video renders at 1080p or 4K
- [ ] Audio is clear and synced
- [ ] No glitches or artifacts
- [ ] Timeline accurate (7-8 minutes)
- [ ] Ready for YouTube

---

## YouTube Upload Details

### Title (Good for SEO)
"JitNeuro Demo: Auto-Recall Memory for Claude Code (Save & Load Walkthrough)"

### Description (Include Links)
```
Learn how JitNeuro gives Claude Code memory that persists across context resets.

In this walkthrough, we install JitNeuro and demo the three key features:
- /save: Save your session context
- /load: Restore context after /clear  
- /learn: Create permanent rules from corrections

⏱️ TIMESTAMPS:
0:00 - Problem: Context Amnesia
1:30 - Solution: JitNeuro
2:00 - Installation (3 minutes)
4:00 - /save & /load Demo
6:00 - /learn Command Demo
7:00 - Real-World Multi-Repo Example
8:00 - Call to Action

📚 RESOURCES:
- GitHub: https://github.com/dstolts/jitneuro
- QUICKSTART Guide: https://github.com/dstolts/jitneuro/blob/main/QUICKSTART.md
- Full Docs: https://github.com/dstolts/jitneuro/tree/main/docs
- Landing Page: https://jitneuro.ai

🔗 RELATED:
- Follow for more Claude Code tutorials
- Subscribe for updates on JitNeuro

#claude-code #ai #memory #developer-tools #tutorial
```

### Tags
claude, claude-code, ai, memory, developer-tools, tutorial, howto, coding, ai-agents, context-management

### Category
Science & Technology

### Visibility
Set to "Unlisted" until landing page is live, then switch to "Public"

### Premiere Settings (Optional)
- Can schedule a live premiere if you want community interaction
- Premiere time: Coincide with landing page launch
- Enable chat/comments during premiere

---

## Alternate Approaches (If You Prefer)

### Option A: Shorter (5 min)
- Skip real-world example
- Combine /learn and /sessions into one demo
- Focus on /save and /load only

### Option B: Longer Deep Dive (12 min)
- Add section on installation options (workspace vs project vs user)
- Show customization (editing rules, bundles)
- Include Q&A tips at the end

### Option C: Series (3-5 shorter videos)
- Part 1: Installation (2 min)
- Part 2: /save & /load (2 min)
- Part 3: /learn & permanence (2 min)
- Part 4: Real-world workflows (3 min)
- Part 5: Advanced features (3 min)

---

## Distribution Plan

After upload:

1. **Wait for YouTube processing** (5-15 minutes)
2. **Share in communities:**
   - Claude Code Discord (if available)
   - Hacker News (Show HN thread)
   - Reddit (r/OpenAI, r/programming, r/devtools)
   - Twitter/LinkedIn with #claude-code #ai-memory
3. **Add to landing page** (embed or link)
4. **Add to GitHub README** (top of Docs section)
5. **Monitor comments** for Q&A (respond within 24h)

---

**Status:** Script complete, ready for recording.

**Recording time estimate:** 30-45 minutes (including retakes)  
**Editing time:** 30-60 minutes  
**Total:** 1.5-2 hours for finished video
