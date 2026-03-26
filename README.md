# JitNeuro: JIT Memory Management for Claude Code

> This started because reloading context after every /clear got old.
> If it helps you, share what you learn.

**GitHub:** [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)

## Why

Claude Code forgets everything every time you clear context. Every `/clear` is amnesia. Every new terminal is a stranger. You re-explain your project, your stack, your sprint status -- every session.

You shouldn't be the memory. The system should remember, load what's relevant, and learn over time. That's what JitNeuro does.

## Simple But Powerful

JitNeuro has 15 commands, scheduled agents, sub-orchestrators, divergent thinking, 16 personas, and a configuration reference that's 300+ lines long.

You don't need any of that to start.

You install JitNeuro. You start working. That's it.

The system learns what you need by watching what you do. Features activate when you call for them, not before. No setup wizard. No config files to fill out. No "read the docs first."

### How It Grows With You

**Day 1** -- You install. You work. `/save` saves your session. `/load` restores it. Three commands. That's enough.

**Day 3** -- You lose work after a context reset. You say "I wish this would auto-save." Claude sets up an autosave agent. Now it does. You didn't edit a config file. You told Claude what you needed.

**Day 7** -- You're working across two repos. You say "keep Hub.md updated." Claude creates an enforcer agent. It syncs automatically. You still haven't opened jitneuro.json.

**Day 14** -- You say "show me what's happening across all my sessions." The dashboard appears. It didn't exist until you needed it.

**Day 30** -- You're running nightly audits, monitoring Stripe, triaging support emails, and scoring content weekly. All configured through conversations, not config files.

### The Principle

**Features are activated by need, not by setup.**

| Traditional tool | JitNeuro |
|-----------------|----------|
| Read the docs, configure everything, then start | Start working, features appear as you need them |
| Edit YAML/JSON to enable features | Tell Claude what you need in plain English |
| Break something because you misconfigured a field | Claude knows the schema and writes it correctly |
| Features sit unused because nobody knew they existed | Features don't exist until you ask for them |

When you say "save my work every 30 minutes," Claude understands that means: add a scheduled agent, set the interval, start the agent, confirm it's running. You said one sentence. Claude did four things.

The complexity exists in the system so it doesn't have to exist in your head.

## Quick Start

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Install (pick your level)
./install.sh user        # global -- commands available in ALL repos (recommended)
./install.sh workspace   # parent directory only
./install.sh project     # current repo only

# Windows (PowerShell)
.\install.ps1 -Mode user
```

**Close and reopen Claude Code after installing.**

Then:
1. Run `/verify` to confirm installation
2. Start working -- JitNeuro grows with you
3. `/save` before `/clear`, `/load` after
4. Everything else activates when you need it

See [Setup Guide](docs/setup-guide.md) for detailed walkthrough.

## What's Under the Hood

JitNeuro adds a memory management layer inspired by neural network architecture:

- **Context Bundles** -- domain knowledge loaded on-demand (like network layers)
- **Engrams** -- per-project deep context, strengthened by /learn (like long-term potentiation)
- **Session State** -- save/load across /clear cycles (like working memory)
- **Routing Weights** -- learned patterns for which bundles to co-activate
- **Scheduled Agents** -- timer, enforcer, cron, and batch agents for automated work
- **Sub-Orchestrators** -- manage 30+ tasks with rolling worker pools
- **Divergent Thinking** -- toggle multi-path reasoning (auto/always/never)
- **16 Personas** -- expert roles that evaluate every request simultaneously
- **/learn** -- evaluate sessions and persist learnings to long-term memory

You don't configure these. They activate as you work. When you want to understand the details: [Technical Overview](docs/technical-overview.md).

## Blog & Articles

- [Deep Dive: Building a Brain for Your AI Coding Assistant](https://www.jitai.co/sage/jitneuro-deep-dive-ai-coding-assistant-brain/) -- how JitNeuro works and why it exists

## Docs

All docs are reference, not prerequisites. Read them when you're curious, not before you start.

| Doc | What it covers |
|-----|---------------|
| [Philosophy](docs/philosophy.md) | Design principles -- why JitNeuro works the way it does |
| [Setup Guide](docs/setup-guide.md) | Installation, post-install, troubleshooting |
| [Technical Overview](docs/technical-overview.md) | Architecture, file structure, full feature list, roadmap |
| [Commands Reference](docs/commands-reference.md) | All 15 commands + 5 shortcuts |
| [Configuration Reference](docs/configuration-reference.md) | Every config file and setting |
| [Scheduled Agents](docs/scheduled-agents.md) | Timer, enforcer, cron, batch agents + business automation |
| [Sub-Orchestrator Pattern](docs/sub-orchestrator-pattern.md) | Managing large-scale operations with worker pools |
| [Customization Guide](docs/customization-guide.md) | Personas, rules, cognitive identity |
| [Hooks Guide](docs/hooks-guide.md) | Lifecycle hooks and custom hooks |
| [Enterprise Security](docs/enterprise-security.md) | Trust model and securing hooks for teams |

## Disclaimer

JitNeuro is an independent open-source project. It is not affiliated with, endorsed by,
or officially connected to Anthropic, Claude, or Claude Code. "Claude Code" is a product
of Anthropic, PBC. JitNeuro uses Claude Code's publicly documented features and does not
modify or extend the Claude Code application itself.

This software is provided as-is, without warranty. See [LICENSE](LICENSE) for details.

## License

MIT -- see [LICENSE](LICENSE).

## Author

Dan Stolts - [jitai.co](https://jitai.co) | [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)
