# JitNeuro: JIT Memory Management for Claude Code

> Built by an operator running a large multi-repo AI portfolio to solve a real
> production problem: making AI agents reliable, consistent, and teachable across
> thousands of sessions. Open-sourced so every developer can benefit.

**GitHub:** [github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)

## The Problem

Claude Code forgets everything every time you clear context. Every `/clear` is
amnesia. Every new terminal is a stranger. You re-explain your project, your stack,
your sprint status -- every session.

You should not be the memory. The system should remember, load what's relevant,
and learn over time. That is what JitNeuro does.

JitNeuro implements the **DOE (Directive Orchestration Execution)** pattern: you
give short directives, the AI orchestrates the approach, and agents execute the
work. See [Technical Overview](docs/technical-overview.md) for the full framework
context.

## Why This Is Different From Other AI Setups

Most developers rely on a single-path reasoning loop: one model, one pass, one
perspective. JitNeuro ships with a three-tier reasoning ladder that you can climb
as your needs grow.

### Tier 1 -- Persistent Memory + Rules (Ships Day 1)

Session state, engrams, bundles, and rules that make Claude consistent across
every session. Stop re-explaining your stack, your conventions, and your
preferences. The system learns from corrections and applies them permanently.

### Tier 2 -- Divergent Thinking (Ships Free, No Config)

Toggle with `/divergent always` and every response runs the
**FRAME -> DIVERGE -> EVALUATE -> CONVERGE -> EXECUTE** cycle:

- FRAME: understand what is actually being asked
- DIVERGE: generate 2-4 distinct approaches from different specialist perspectives
- EVALUATE: pros/cons across all paths -- speed, safety, maintainability, cost
- CONVERGE: pick the best path or merge the strongest elements into a hybrid
- EXECUTE: full commitment to the converged answer

Single-session, no extra infrastructure, accessible immediately. This is the most
powerful reasoning upgrade most developers will ever need.

### Tier 3 -- Multi-Agent Orchestration (For Large-Scale Operations)

Parallel sub-orchestrators with rolling worker pools, adversarial cross-verification,
and concurrent task execution. Manages 30+ tasks across multiple repos. See
[Sub-Orchestrator Pattern](docs/sub-orchestrator-pattern.md) and
[Multi-Agent Orchestration](docs/multi-agent-orchestration-01.md).

---

## The Persona System -- Your AI Engineering Team

This is where JitNeuro goes beyond memory management. Every request is evaluated
simultaneously by **16 specialist personas**. They are always on -- not activated
by command, not triggered by keywords -- running as parallel evaluation lenses on
every response.

### The Engineering Personas

| Persona | Role |
|---------|------|
| Sr Software Architect | System stability, component boundaries, long-term maintenance burden |
| Backend Engineer | API design, data correctness, transaction boundaries |
| Security Engineer | Auth gaps, input validation, secrets exposure -- on EVERY request |
| UI/UX Designer | User flow, error states, accessibility, friction reduction |
| DevOps Engineer | Deployment, cost, infrastructure reproducibility |
| Maintenance Engineer | Pattern consistency, readability, dead code -- on EVERY code change |
| Reliability Engineer (SRE) | Failure modes, null safety, timeouts, graceful degradation |
| Database Administrator | Schema correctness, query performance, migration safety |
| QA / Tester | Test coverage, acceptance criteria, regression risk |
| Automation Engineer | Manual steps to eliminate, idempotency, retry logic |
| Content Strategist | Audience alignment, SEO, CTA, voice |
| Scrum Lead | Story scope, acceptance criteria, dependency ordering |
| Business Strategist | Revenue alignment, ROI, owner time cost |
| Prompt Engineer | Instruction quality, output format control, token efficiency |
| Technical Writer | Documentation clarity, reader-appropriate explanation |
| Vibe Coder | (Explicit activation only) Fast prototyping on feature branches |

### How It Works in Practice

A Backend Engineer and Security Engineer are both primary on an API endpoint change.
The DBA interjects when it sees a query with no covering index. The Maintenance
Engineer flags a pattern mismatch before the code ships. The Reliability Engineer
notes that the external call has no timeout. None of these are separate prompts or
separate conversations -- they are simultaneous lenses on a single response.

Example: a request to "add a bulk delete endpoint" produces:

```
[Backend Engineer + Security Engineer]

Endpoint design here...

[Security] Re-authenticate before bulk delete -- this is a destructive operation.
[UX] That adds friction on every bulk action.
Resolution: Re-auth only when selection exceeds 10 items or includes admin records.
[DBA] Add a partial index on deleted_at for the soft-delete scan -- full table scan at scale.
[Reliability] Wrap the delete loop in a transaction with explicit rollback on partial failure.
```

That is five specialist perspectives surfaced in one response, with conflicts
resolved inline, before any code is written. This is what expert engineering
review looks like at AI speed.

---

## What You Get Out of the Box

- **Do more, faster** -- stop re-explaining, start working in seconds
- **Security without effort** -- trust zones and branch protection from install
- **Low risk** -- markdown files and bash scripts, remove it anytime
- **Compounds over time** -- `/learn` makes Claude better at YOUR work every day

JitNeuro has 17 commands, scheduled agents, sub-orchestrators, divergent thinking,
16 personas, and a configuration reference that is 300+ lines long.

You do not need any of that to start.

### How It Grows With You

**Day 1** -- You install. You work. `/save` saves your session. `/load` restores
it. `/learn` persists what Claude learned today. By end of day 1, Claude already
knows your project better than it did this morning.

**Day 3** -- You lose work after a context reset. You say "I wish this would
auto-save." Claude sets up an autosave agent. Now it does. You did not edit a
config file. You told Claude what you needed.

**Day 7** -- You are working across two repos. You say "keep Hub.md updated."
Claude creates an enforcer agent. It syncs automatically. You still have not
opened jitneuro.json.

**Day 14** -- You say "show me what is happening across all my sessions." The
dashboard appears. It did not exist until you needed it.

**Day 30** -- You are running nightly audits, monitoring external services,
triaging emails, and scoring content weekly. All configured through conversations,
not config files.

### The Principle

**Features are activated by need, not by setup.**

| Traditional tool | JitNeuro |
|-----------------|----------|
| Read the docs, configure everything, then start | Start working, features appear as you need them |
| Edit YAML/JSON to enable features | Tell Claude what you need in plain English |
| Break something because you misconfigured a field | Claude knows the schema and writes it correctly |
| Features sit unused because nobody knew they existed | Features do not exist until you ask for them |

When you say "save my work every 30 minutes," Claude understands that means: add
a scheduled agent, set the interval, start the agent, confirm it is running. You
said one sentence. Claude did four things.

The complexity exists in the system so it does not have to exist in your head.

### Claude Learns to Think Like You

Every correction you make becomes a permanent rule. Every preference becomes a
pattern. You say it once -- Claude follows it forever.

Say "do not mock the database in tests" and it becomes a testing rule. Say "blog
posts need a FAQ section" and it becomes a content quality gate. Say "never deploy
on Fridays" and it becomes a deployment guardrail. You did not write config files.
You had a conversation. `/learn` persisted it.

By day 30, Claude handles your code style, content voice, security posture, and
team conventions -- all from corrections you made naturally while working. Your
style guide writes itself.

---

## Quick Start

**Prerequisites:**
- Claude Code (CLI, desktop, or web) -- latest version recommended
- Bash for hooks (macOS/Linux native; Windows needs Git Bash -- auto-detected)

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
./install.sh user    # recommended -- works in any repo, any folder, even non-repos

# Windows (PowerShell)
.\install.ps1 -Mode user
```

**Close and reopen Claude Code after installing.** Then: `/save`, `/learn`,
`/load`. That is it.

**Set your north star (optional, 5 minutes).** The installer drops strategic-context
templates in `.claude/horizon/`. Tell Claude `"populate my horizon files"` (or open
`.claude/horizon/POPULATE-HORIZON.md`) and Claude interviews you -- one topic at a
time -- to fill in your vision, mission, goals, operating rhythm, and owner profile.
Every future session then aligns to your actual goals instead of guessing.

**Having trouble with the install?** Just tell Claude:

```
> "Clone https://github.com/dstolts/jitneuro.git and install at user level"
```

Claude reads the install script, copies the files, configures the hooks, and
verifies it worked. You do not need to run shell commands yourself.

See [Setup Guide](docs/setup-guide.md) for other install modes and troubleshooting.

### Add an AI engineering team

The optional [Dev Shop Pack](templates/dev-shop-pack/README.md) provides ten
portable engineering role contracts, AGENTS.md-based routing, and an independent
validation chain. Copy the pack into a project and reference its router from the
project's root `AGENTS.md`; no runtime-specific adapter is required.

---

## What's Under the Hood

JitNeuro adds a memory management layer inspired by neural network architecture:

- **Master-orchestrator identity** -- a SessionStart hook injects your master/
  orchestrator role into every session, so Claude coordinates and delegates by
  default instead of acting as a generic coding agent
- **Horizon layer** -- vision / mission / goals / operating-rhythm / owner-profile
  templates plus a guided interview (POPULATE-HORIZON) so every session aligns to
  your north star
- **Rule library** -- a curated, install-ready set of behavioral rules (testing
  discipline, trust zones, verification gates, security guardrails) you can keep,
  disable, or extend
- **Context Bundles** -- domain knowledge loaded on-demand (like network layers)
- **Engrams** -- per-project deep context, strengthened by /learn (like long-term
  potentiation)
- **Session State** -- save/load across /clear cycles (like working memory)
- **Post-compact recovery** -- a PreCompact hook checkpoints state and tells the
  next turn to /load and re-read context, so a context reset never loses your place
- **Upgrade-safe** -- a manifest separates framework files from yours; `git pull`
  + re-install updates the framework and never clobbers your rules, bundles,
  horizon, or learnings (edited framework files are backed up). See the Setup Guide.
- **Routing Weights** -- learned patterns for which bundles to co-activate
- **Scheduled Agents** -- timer, enforcer, cron, and batch agents for automated work
- **Sub-Orchestrators** -- manage 30+ tasks with rolling worker pools
- **Divergent Thinking** -- toggle multi-path reasoning (auto/always/never)
- **16 Personas** -- specialist lenses that evaluate every request simultaneously
- **/learn** -- evaluate sessions and persist learnings to long-term memory

You do not configure these. They activate as you work. When you want to understand
the details: [Technical Overview](docs/technical-overview.md).

---

## Docs

All docs are reference, not prerequisites. Read them when you are curious, not
before you start.

| Doc | What it covers |
|-----|---------------|
| [Setup Guide](docs/setup-guide.md) | Installation, post-install, troubleshooting |
| [Technical Overview](docs/technical-overview.md) | Architecture, file structure, full feature list, roadmap |
| [Commands Reference](docs/commands-reference.md) | All 17 commands + 5 shortcuts |
| [Dev Shop Pack](templates/dev-shop-pack/README.md) | Portable engineering roles, routing, and validation gates |
| [Configuration Reference](docs/configuration-reference.md) | Every config file and setting |
| [Scheduled Agents](docs/scheduled-agents.md) | Timer, enforcer, cron, batch agents + business automation |
| [Sub-Orchestrator Pattern](docs/sub-orchestrator-pattern.md) | Managing large-scale operations with worker pools |
| [Multi-Agent Orchestration](docs/multi-agent-orchestration-01.md) | Parallel orchestration patterns |
| [Customization Guide](docs/customization-guide.md) | Personas, rules, cognitive identity |
| [Hooks Guide](docs/hooks-guide.md) | Lifecycle hooks and custom hooks |
| [Enterprise Security](docs/enterprise-security.md) | Trust model and securing hooks for teams |

---

## Built and Maintained by Just In Time AI

JitNeuro is the open-source foundation of a production AI engineering system
used to run a large multi-repo software portfolio. It is maintained by
[Just In Time AI](https://jitai.co) -- a firm that designs and operates
enterprise-grade AI automation for engineering teams.

If you want the advanced tiers -- custom persona libraries tuned to your
engineering culture, multi-agent orchestration for your specific tech stack,
or a done-for-you AI engineering setup -- book a 20-minute discovery call:

**[Book a discovery call](https://cal.com/dan-stolts-jit/20-min-discovery)**

We help teams move from "we use AI sometimes" to "AI does the $10/hr work while
engineers do the $10k/hr work."

---

## Disclaimer

JitNeuro is an independent open-source project. It is not affiliated with,
endorsed by, or officially connected to Anthropic, Claude, or Claude Code.
"Claude Code" is a product of Anthropic, PBC. JitNeuro uses Claude Code's
publicly documented features and does not modify or extend the Claude Code
application itself.

This software is provided as-is, without warranty. See [LICENSE](LICENSE) for
details.

## License

JitNeuro is fully open-source under a split license -- both parts require
attribution:

- **Code** (scripts, hooks, installers): [Apache-2.0](LICENSE), with
  attribution terms detailed in [NOTICE](NOTICE).
- **Documentation and content** (`*.md` files, `docs/`, `templates/*.md`,
  and other non-executable content): [CC BY 4.0](LICENSE-docs).

Both licenses are OSI-approved / Creative Commons and require crediting
"Just In Time AI INC" (project homepage: [jitneuro.ai](https://jitneuro.ai))
in any redistribution or derivative work. Prior releases of this repository
were licensed under MIT; see [CHANGELOG.md](CHANGELOG.md) for the
relicensing note.

## Author

[github.com/dstolts/jitneuro](https://github.com/dstolts/jitneuro)
