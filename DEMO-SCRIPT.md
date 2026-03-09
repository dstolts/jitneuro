# JitNeuro Demo Script

**Format:** Screen recording with voiceover
**Length:** 5-7 minutes
**Audience:** Developers using Claude Code (or considering it)
**Setup:** Terminal open to D:\Code, Claude Code running, 2-3 repos with real work

---

## Scene 1: The Problem (0:00 - 0:45)

**NARRATION:**
"If you use Claude Code, you've hit this wall. You're deep into a task --
maybe 30 minutes in -- and Claude starts forgetting things. Your conventions,
your file structure, decisions you made 10 minutes ago. Context gets compressed.
You run /clear to switch tasks and everything is gone. You spend the next
5 minutes re-explaining your codebase. Every. Single. Time.

Now multiply that across 16 repos. That's my daily life. I manage all of
them solo. And I'm 3x more productive by myself than when I was running
a 15-person dev team -- because I built a framework that solves this."

**ON SCREEN:**
- Show a Claude Code session hitting context limits
- Show the "context compressed" message
- Show manually re-typing context after /clear

---

## Scene 2: What Is JitNeuro (0:45 - 1:30)

**NARRATION:**
"JitNeuro is a memory management framework for Claude Code. It uses Claude's
own primitives -- CLAUDE.md, MEMORY.md, custom commands, hooks -- and adds
structure. Think of it like a neural network for your AI's memory.

Your AI loads a minimal brainstem every session -- just the core rules.
Domain knowledge lives in bundles, loaded only when needed. Each project
has an engram -- a compressed representation of everything important about
that repo. Routing weights learn which bundles to co-activate for which tasks.

The result: your AI talks to you with full context and understanding.
Every session. Every time. No re-explaining."

**ON SCREEN:**
- Show the architecture diagram from README
- Quick scroll through .claude/ directory structure
- Show MEMORY.md (compact, ~90 lines)
- Show a bundle file (50-80 lines)
- Show an engram file

---

## Scene 3: Install (1:30 - 2:00)

**NARRATION:**
"Installation takes 30 seconds."

**ON SCREEN -- RUN THESE COMMANDS:**
```
cd D:\Code\jitneuro
```
```
.\install.ps1 -Mode workspace
```

**NARRATION:**
"That copies commands, hooks, and templates to your workspace. 15 slash
commands, 4 hooks, all ready to go. Let me show you what they do."

---

## Scene 4: /gitstatus -- Cross-Repo Visibility (2:00 - 2:45)

**NARRATION:**
"First problem: I have 16 repos. Which ones have uncommitted work?
Which branches am I on? What's ahead of main?"

**ON SCREEN -- RUN:**
```
/gitstatus
```

**NARRATION:**
"One command. Every repo. Current branch, dirty files, local vs uat vs main.
I can see jitai has 239 dirty files -- that's a .gitignore issue I know about.
AIFS-API is on a sprint branch, 9 commits ahead. Everything in one table."

**ON SCREEN:**
- Show the full gitstatus table output
- Point out the flags section

---

## Scene 5: /save and /load -- Surviving /clear (2:45 - 3:45)

**NARRATION:**
"The killer feature. I'm working on a blog comments API. I need to switch
to a different task. Before, I'd /clear and lose everything. Now:"

**ON SCREEN -- RUN:**
```
/save blog-comments-api
```

**NARRATION:**
"That checkpoints my entire session state to disk -- task, repos, bundles,
modified files, next steps. Now I /clear."

**ON SCREEN -- RUN:**
```
/clear
```

**NARRATION:**
"Context is gone. But my state is on disk. When I come back:"

**ON SCREEN -- RUN:**
```
/load blog-comments-api
```

**NARRATION:**
"Everything is back. Claude knows what I was working on, which files I changed,
what the next steps are. It loaded the right bundles automatically.
No re-explaining. No manual reloading. Just pick up where I left off."

**ON SCREEN:**
- Show the load output (session name, task, repos, bundles, next steps)

---

## Scene 6: /health -- Memory System Diagnostic (3:45 - 4:15)

**NARRATION:**
"How do I know the memory system itself is healthy? MEMORY.md has a hard
200-line limit. Bundles should stay under 80 lines. Engrams under 150.
Stale sessions pile up."

**ON SCREEN -- RUN:**
```
/health
```

**NARRATION:**
"One command audits the entire memory system. Line counts, stale sessions,
missing engrams, broken routing weights. If something is wrong, it tells
me exactly what to fix."

**ON SCREEN:**
- Show the health table output
- Point out any WARN or MISS items

---

## Scene 7: Hooks -- Automatic Safety Nets (4:15 - 4:45)

**NARRATION:**
"Hooks fire automatically on Claude Code lifecycle events. I have four
installed. The most important: when context is about to be compacted,
a hook fires and Claude asks me if I want to /save first. No more
silent context loss.

Another hook blocks git push to main. I have a rule: never push to main
without my explicit approval. The hook enforces it programmatically.
Claude literally cannot push to main even if it tries."

**ON SCREEN:**
- Show settings.local.json hooks section
- Optionally: trigger the branch protection hook by asking Claude to push to main
- Show the blocked message

---

## Scene 8: /learn -- The System Improves Itself (4:45 - 5:30)

**NARRATION:**
"This is where it gets interesting. At the end of a session, I run /learn.
It evaluates the session for knowledge worth persisting. Did I correct Claude
on something? That correction gets saved so it never happens again. Did a
new routing pattern emerge? It gets added to the weights.

The system literally improves itself over time. Like backpropagation in a
neural network -- each session makes the next one better."

**ON SCREEN -- RUN:**
```
/learn
```

**NARRATION:**
"It scans the session, proposes updates, and I approve. Memory health check
included. Nothing is written without my permission."

**ON SCREEN:**
- Show the health table
- Show the proposed updates table
- Show the approval prompt

---

## Scene 9: The Result (5:30 - 6:00)

**NARRATION:**
"Here's what this adds up to. I manage 16 repos across multiple products.
API, frontend, automation, docs, sales tools. I switch between them
constantly. I never re-explain my codebase. I never lose context. The AI
knows my conventions, my architecture, my decisions.

I'm one developer. I'm 3x more productive than when I was running a
15-person dev team a few years ago. Not because I work harder. Because
the AI never loses context.

JitNeuro is open source. Link in the description. It works with Claude Code
today, using features that already exist. No API keys, no server, no
dependencies. Just structured files that teach your AI how to remember."

**ON SCREEN:**
- Show the GitHub repo
- Show the README hero section
- Show the jitneuro.ai landing page (if built)

---

## Scene 10: Call to Action (6:00 - 6:15)

**NARRATION:**
"Clone it. Install it. Run /health to see your memory system. Run /gitstatus
to see your repos. Run /save before your next /clear. You'll never go back."

**ON SCREEN:**
```
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
.\install.ps1 -Mode workspace
```

---

## Pre-Recording Checklist

Before recording, verify:
- [ ] Claude Code running in D:\Code with JitNeuro installed
- [ ] At least 3 repos with real uncommitted work (for gitstatus demo)
- [ ] A named session saved (blog-comments-api or similar) for /load demo
- [ ] Terminal font size large enough for video (16-18pt)
- [ ] Screen resolution set for recording (1920x1080 recommended)
- [ ] No sensitive data visible (.env files, API keys, passwords)
- [ ] Test each command once before recording to verify output looks clean
- [ ] hooks registered in settings.local.json

## Post-Recording

- Upload to YouTube (unlisted or public)
- Embed in jitneuro.ai landing page
- Share on LinkedIn with summary + link
- Add link to README.md
- Cross-reference in blog post (FR-003)
