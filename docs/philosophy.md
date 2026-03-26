# Simple But Powerful

## Why JitNeuro Exists

Claude Code is the most capable AI coding assistant available. But it forgets everything every time you clear context. It loses track of what you were doing. It reloads the same instructions over and over. It doesn't learn from yesterday's session.

That's not a Claude Code problem -- it's a memory problem. Claude Code has no persistence layer between sessions. Every `/clear` is amnesia. Every new terminal is a stranger.

JitNeuro exists because the person using Claude Code shouldn't have to be the memory. You shouldn't re-explain your project, your tech stack, your conventions, your sprint status every time context resets. The system should remember. The system should load what's relevant. The system should learn over time.

## Why You Should Use It

**If you use Claude Code for more than one session, you need this.**

- You lose work when context compacts or you `/clear` -- JitNeuro saves and restores automatically
- You re-explain your project every session -- JitNeuro loads the right context before you ask
- You manage multiple repos and lose track of state -- JitNeuro tracks cross-repo sessions
- You forget to update docs, save state, sync task lists -- JitNeuro's agents enforce discipline
- You want Claude to get better at YOUR work over time -- /learn persists patterns across sessions

The alternative is doing all of this manually. Re-typing. Re-explaining. Re-loading. Every day.

## Simple But Powerful

JitNeuro has 15 commands, 4 agent types, bundles, engrams, routing weights, divergent thinking modes, sub-orchestrators, and a configuration reference that's 300+ lines long.

You don't need any of that to start.

## How It Actually Works

You install JitNeuro. You start working. That's it.

The system learns what you need by watching what you do. Features activate when you call for them, not before. There is no setup wizard, no 50-field config to fill out, no "configure your workspace before first use."

### Day 1

You install. You work. Claude saves your session when you say `/save`. Loads it when you say `/load`. That's the whole system on day 1.

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
