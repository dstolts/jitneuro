# Simple But Powerful

## Why JitNeuro Exists

Claude Code is the most capable AI coding assistant available. But it forgets everything every time you clear context. It loses track of what you were doing. It reloads the same instructions over and over. It doesn't learn from yesterday's session.

That's not a Claude Code problem -- it's a memory problem. Claude Code has no persistence layer between sessions. Every `/clear` is amnesia. Every new terminal is a stranger.

JitNeuro exists because the person using Claude Code shouldn't have to be the memory. You shouldn't re-explain your project, your tech stack, your conventions, your sprint status every time context resets. The system should remember. The system should load what's relevant. The system should learn over time.

## Why You Should Use It

**If you use Claude Code for more than one session, you need this.**

- **Do more, faster.** Stop re-explaining your project every session. JitNeuro loads the right context before you ask. You start working in seconds, not minutes. Multi-agent orchestration runs 10+ tasks in parallel -- what takes one agent an hour, ten agents finish in minutes. Real-world users report 10x or higher throughput on batch operations.
- **Improve security without extra effort.** Trust zones, branch protection, and approval workflows are active from install. Rules are created on the fly -- tell Claude "never push to main without approval" and it becomes a permanent guardrail. No YAML to write. No CI config to maintain.
- **Low risk, high reward.** JitNeuro is markdown files and bash scripts. It doesn't modify Claude Code, doesn't require admin access, doesn't touch your production systems. Install it, try it, remove it if you don't like it. Nothing breaks.
- **Capture the opportunity.** Every session where Claude re-discovers your codebase from scratch is wasted time and tokens. JitNeuro compounds knowledge -- each session builds on the last. What Claude learns on Monday is available Tuesday without you doing anything.
- **Rules created on the fly.** Say "always use UTC timestamps in this repo" and it becomes a rule. Say "never use emojis in commit messages" and it's enforced. No config files. No PR to a shared linter config. Just tell Claude and it persists via /learn.
- **Claude gets better at YOUR work over time.** /learn evaluates each session and persists patterns, conventions, and decisions to long-term memory. Day 1 Claude knows nothing about your project. Day 30 Claude knows your stack, your patterns, your preferences, your team's quirks.

The alternative is doing all of this manually. Re-typing. Re-explaining. Re-loading. Every day.

## Simple But Powerful

JitNeuro has 15 commands, 4 agent types, bundles, engrams, routing weights, divergent thinking modes, sub-orchestrators, and a configuration reference that's 300+ lines long.

You don't need any of that to start.

## How It Actually Works

You install JitNeuro. You start working. That's it.

The system learns what you need by watching what you do. Features activate when you call for them, not before. There is no setup wizard, no 50-field config to fill out, no "configure your workspace before first use."

### Day 1

You install. You work. `/save` saves your session. `/load` restores it. `/learn` evaluates what happened and persists useful patterns to long-term memory. Three commands -- save, load, learn. That's the whole system on day 1. By the end of day 1, Claude already knows more about your project than it did this morning.

### Day 3

You forget to save before a context reset. You lose 20 minutes of work. You say "I wish this would auto-save." Claude sets up an autosave timer agent. Now it does. You didn't read the scheduled agents doc. You didn't edit jitneuro.json. You told Claude what you needed and it happened.

### Day 7

You're working across two repos. Context keeps getting stale. You say "keep Hub.md updated." Claude creates an enforcer agent. Now it syncs automatically. You still haven't opened jitneuro.json.

### Day 14

You say "show me what's happening across all my sessions." Claude runs `/sessions dashboard`. The dashboard components instantiate because you asked for them. They didn't exist until you needed them.

### Day 30

You're running nightly audits, monitoring Stripe, triaging support emails, and scoring content weekly. All configured through conversations, not config files. Each feature appeared exactly when you needed it.

## The Principle

**Features are activated by need, not by setup.**

| Traditional tool | JitNeuro |
|-----------------|----------|
| Read the docs, configure everything, then start working | Start working, features appear as you need them |
| Edit YAML/JSON config files to enable features | Tell Claude what you need in plain English |
| Break something because you misconfigured a field | Claude knows the config schema and writes it correctly |
| Features sit unused because nobody knew they existed | Features don't exist until you ask for them |

When you say "save my work every 30 minutes," Claude understands that means:
1. Add a scheduled agent to jitneuro.json
2. Set the type, interval, and instruction
3. Start the agent
4. Confirm it's running

You said one sentence. Claude did four things. That's the design.

## Claude Learns to Think Like You

The most powerful part of JitNeuro isn't saving sessions or loading bundles. It's that Claude stops being a generic assistant and starts thinking the way you think.

### How It Happens

Every correction you make is a lesson. Every preference you express becomes permanent. JitNeuro captures these through `/learn` and turns them into durable rules, not just memories.

**You say it once. Claude follows it forever.**

| What you say | What JitNeuro creates | Where it lives |
|-------------|----------------------|----------------|
| "Don't mock the database in tests" | Rule: integration tests hit real DB | `.claude/rules/testing.md` |
| "Always use UTC timestamps" | Rule: UTC in all date handling | `.claude/rules/conventions.md` |
| "Blog posts need a FAQ section" | Content quality gate | `.claude/rules/content.md` or bundle |
| "Security review before any API change" | Approval workflow gate | `.claude/rules/api.md` |
| "I prefer one bundled PR over many small ones" | Style preference | MEMORY.md (feedback) |
| "Never deploy on Fridays" | Deployment guardrail | `.claude/rules/deploy.md` |

You didn't write those rules. You said something in conversation. `/learn` evaluated the session, identified the pattern, and persisted it to the right place. Next session, Claude already knows.

### The Learning Loop

```
Day 1:  You correct Claude -- "no, use snake_case in this repo"
        /learn captures it as a rule
Day 2:  Claude uses snake_case without being told
Day 5:  You say "blog posts should lead with reader value, not what I built"
        /learn captures it as a content style guide rule
Day 10: Claude drafts a post. It leads with reader value. You didn't remind it.
Day 30: Claude has 20+ rules, all from natural conversation. It handles your
        code style, content voice, security posture, deployment preferences,
        and team conventions -- without a single config file you wrote by hand.
```

### Style Guides Without Writing Style Guides

Traditional approach: spend a day writing a style guide, hope everyone reads it, enforce it in PR reviews.

JitNeuro approach: work normally. When Claude does something wrong, correct it. `/learn` turns the correction into a rule. Next time, Claude follows the rule AND enforces it in code review. Your style guide writes itself from your actual preferences, not from what you think you should document.

This works for:
- **Code style** -- naming, patterns, error handling, test structure
- **Content voice** -- tone, structure, audience targeting, quality bars
- **Security posture** -- what needs auth, what needs approval, what's blocked
- **Workflow preferences** -- PR size, commit style, branch strategy, deploy cadence
- **Priorities** -- what matters most, what can wait, what gets skipped

### No More Repeating Yourself

The #1 frustration with AI assistants: you tell it something, it forgets, you tell it again. And again. And again.

JitNeuro breaks that cycle. Rules persist in `.claude/rules/`. Patterns persist in MEMORY.md. Engrams persist project-specific context. Bundles persist domain knowledge. None of it lives in the conversation context that gets wiped on `/clear`.

When Claude follows a rule you set three weeks ago without being reminded -- that's JitNeuro working. When Claude applies your content style guide to a new post without you referencing it -- that's `/learn` having done its job.

## The Docs Are Reference, Not Prerequisites

The 300-line configuration reference exists so that when you WANT to understand what's under the hood, you can. The scheduled agents doc exists so that when you're ready to build complex automation, the patterns are documented.

But nobody needs to read them to use JitNeuro. The system meets you where you are:

- **Beginner:** `/save`, `/load`, `/status`. Three commands. That's enough.
- **Intermediate:** Bundles load automatically based on what you're working on. Sessions track cross-repo work. You notice it's helping but you didn't configure anything.
- **Advanced:** You're designing sub-orchestrators, running batch agents, building business automation. The docs are your reference now because you chose to go deep.

## Why This Works

Claude is the configuration layer. It reads jitneuro.json, understands the schema, and writes valid config. It reads the docs (they're in the repo), understands the patterns, and applies them. You never need to be the expert on your own tooling -- Claude already is.

The complexity exists in the system so it doesn't have to exist in your head.

## One Rule

If a feature requires the owner to read a doc before it works, the feature is designed wrong. Claude should be able to set it up from a plain English request. The docs are for understanding, not for prerequisites.
