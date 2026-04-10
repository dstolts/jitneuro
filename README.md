# JitNeuro: JIT Memory Management for Claude Code

> This started because reloading context after every /clear got old.
> If it helps you, share what you learn.

**GitHub:** [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)

## Why

Claude Code forgets everything every time you clear context. Every `/clear` is amnesia. Every new terminal is a stranger. You re-explain your project, your stack, your sprint status -- every session.

You shouldn't be the memory. The system should remember, load what's relevant, and learn over time. That's what JitNeuro does.

JitNeuro implements the **DOE (Directive Orchestration Execution)** pattern: you give short directives, the AI orchestrates the approach, and agents execute the work. See [Technical Overview](docs/technical-overview.md) for the full framework context.

- **Do more, faster** -- stop re-explaining, start working in seconds. Multi-agent parallelism delivers 10x+ throughput on real workloads
- **Security without effort** -- trust zones and branch protection from install, rules created on the fly
- **Low risk** -- markdown files and bash scripts, nothing to break, remove it anytime
- **Compounds over time** -- /learn makes Claude better at YOUR work every day

## Simple But Powerful

JitNeuro has 16 commands, scheduled agents, sub-orchestrators, divergent thinking, 16 personas, and a configuration reference that's 300+ lines long.

You don't need any of that to start.

You install JitNeuro. You start working. That's it.

The system learns what you need by watching what you do. Features activate when you call for them, not before. No setup wizard. No config files to fill out. No "read the docs first."

### How It Grows With You

**Day 1** -- You install. You work. `/save` saves your session. `/load` restores it. `/learn` persists what Claude learned today. By end of day 1, Claude already knows your project better than it did this morning.

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

### Claude Learns to Think Like You

Every correction you make becomes a permanent rule. Every preference becomes a pattern. You say it once -- Claude follows it forever.

Say "don't mock the database in tests" and it becomes a testing rule. Say "blog posts need a FAQ section" and it becomes a content quality gate. Say "never deploy on Fridays" and it becomes a deployment guardrail. You didn't write config files. You had a conversation. `/learn` persisted it.

By day 30, Claude handles your code style, content voice, security posture, and team conventions -- all from corrections you made naturally while working. Your style guide writes itself.

## Quick Start

**Prerequisites:**
- Claude Code (CLI, desktop, or web) — latest version recommended
- Bash for hooks (macOS/Linux native; Windows needs Git Bash — auto-detected)

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
./install.sh user    # recommended -- works in any repo, any folder, even non-repos

# Windows (PowerShell)
.\install.ps1 -Mode user
```

**Close and reopen Claude Code after installing.** Then: `/save`, `/learn`, `/load`. That's it.

**Having trouble with the install?** Just tell Claude:

```
> "Clone https://github.com/dstolts/jitneuro.git and install at user level"
```

Claude reads the install script, copies the files, configures the hooks, and verifies it worked. You don't need to run shell commands yourself.

See [Setup Guide](docs/setup-guide.md) for other install modes and troubleshooting.

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
| [Setup Guide](docs/setup-guide.md) | Installation, post-install, troubleshooting |
| [Technical Overview](docs/technical-overview.md) | Architecture, file structure, full feature list, roadmap |
| [Commands Reference](docs/commands-reference.md) | All 15 commands + 5 shortcuts |
| [Configuration Reference](docs/configuration-reference.md) | Every config file and setting |
| [Scheduled Agents](docs/scheduled-agents.md) | Timer, enforcer, cron, batch agents + business automation |
| [Sub-Orchestrator Pattern](docs/sub-orchestrator-pattern.md) | Managing large-scale operations with worker pools |
| [Customization Guide](docs/customization-guide.md) | Personas, rules, cognitive identity |
| [Hooks Guide](docs/hooks-guide.md) | Lifecycle hooks and custom hooks |
| [Routing Weights vs Semantic Memory](docs/routing-vs-semantic-memory.md) | Why explicit routing beats vector search for AI context loading |
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
