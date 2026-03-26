# Divergent

Toggle divergent thinking mode. Controls whether Claude evaluates multiple approaches before committing to one.

## Commands

Trigger on these patterns (case-insensitive):
- `divergent` -- show current mode and source
- `divergent auto` -- set to auto (smart routing based on task type)
- `divergent always` -- force divergent on every response
- `divergent never` -- force serial on every response
- `divergent repo auto|always|never` -- set at repo level (overrides workspace)
- `divergent workspace auto|always|never` -- set at workspace level
- `divergent repo clear` -- remove repo override (fall back to workspace)

## How It Works

Divergent thinking is like `effortLevel` but for reasoning breadth:
- `effortLevel` controls how HARD Claude thinks (depth)
- `divergent` controls how WIDE Claude thinks (breadth -- multiple approaches vs first-fit)

**Subagents inherit divergent mode based on task type.** Planning, discovery, analysis, and design agents diverge. Explore, lookup, and monitor agents stay serial. See the divergent-thinking rule for the full classification.

## Modes

| Mode | Reasoning (master + qualifying agents) | When to Use |
|------|----------------------------------------|-------------|
| `auto` | Smart routing -- diverge on production code, architecture, new features, tradeoffs, cross-repo. Serial on research, exploration, fixes, docs, vibe coding. | Default. Works for most repos. |
| `always` | Force diverge every response and all qualifying agents. FRAME -> DIVERGE -> EVALUATE -> CONVERGE -> EXECUTE on everything. | High-stakes repos (production APIs, security, financial services). |
| `never` | Force serial every response and all agents. First reasonable path, full commitment. | Content repos, docs, templates, exploration-heavy work. |

## Config Hierarchy

Repo-level overrides workspace-level. Workspace-level is the default.

```
Workspace: D:\Code\.claude\toggles.json         -> "divergent": "auto"
Repo:      D:\Code\<repo>\.claude\toggles.json  -> "divergent": "always"
```

**Resolution order:**
1. Check `<current-repo>/.claude/toggles.json` for `"divergent"` key
2. If not found or repo has no toggles.json: check `D:\Code\.claude\toggles.json`
3. If not found anywhere: default to `"auto"`

## Instructions

### divergent (default) -- show current mode

1. **Resolve current mode:**
   - Determine the current repo (from working directory or session context)
   - Read `<repo>/.claude/toggles.json` if it exists -- check for `"divergent"` key
   - Read `D:\Code\.claude\toggles.json` -- check for `"divergent"` key
   - Apply resolution order (repo wins over workspace wins over default)
2. **Display:**

```
Divergent Thinking: AUTO
  Source: workspace (D:\Code\.claude\toggles.json)
  Repo override: none

  auto = diverge on production/arch/features, serial on research/fixes/docs
  Agents: plan/discovery/analysis inherit mode; explore/lookup/monitor stay serial
```

Or if repo override exists:

```
Divergent Thinking: ALWAYS
  Source: repo (D:\Code\AIFieldSupport-API\.claude\toggles.json)
  Workspace default: auto

  always = evaluate multiple approaches on every response
  Agents: plan/discovery/analysis inherit mode; explore/lookup/monitor stay serial
```

### divergent <mode> -- set mode (infer level)

1. If currently inside a repo (git root detected): set at repo level
2. If at workspace root (D:\Code): set at workspace level
3. Read the target `toggles.json`, update or create `"divergent"` key
4. Display confirmation with the tag format:

```
Divergent Thinking: ALWAYS (set at repo level)
[session: <name> | DIV: ALWAYS]
```

### divergent repo <mode> -- set at repo level

1. Determine current repo from working directory
2. Read or create `<repo>/.claude/toggles.json`
3. Set `"divergent": "<mode>"`
4. Confirm with resolved mode display

### divergent workspace <mode> -- set at workspace level

1. Read `D:\Code\.claude\toggles.json`
2. Set `"divergent": "<mode>"`
3. Confirm with resolved mode display (note if repo override still wins)

### divergent repo clear -- remove repo override

1. Read `<repo>/.claude/toggles.json`
2. Remove the `"divergent"` key (leave other keys intact)
3. If file is now empty (`{}`), delete it
4. Confirm with new resolved mode (now falls back to workspace)

## Session Tag Integration

The divergent mode MUST appear on the session tag line at the end of every response:

```
[session: <name> | DIV: <MODE>]
```

Where `<MODE>` is the resolved mode in uppercase: `AUTO`, `ALWAYS`, or `NEVER`.

This is non-negotiable -- it provides constant visibility into the reasoning mode, just like the session tag prevents context confusion.

**Resolution for the tag:** Follow the same hierarchy as the show command. The tag reflects the RESOLVED mode (after repo overrides workspace).

## Important
- Qualifying subagents (plan, discovery, analysis, design) inherit the divergent mode
- Tool agents (Explore, lookup, monitor) always stay serial
- When spawning a qualifying agent, include `DIVERGENT MODE: <MODE>` in the prompt
- The tag appears on EVERY response, not just when /divergent is run
- Mode survives /clear because it's stored in toggles.json on disk
- When mode changes, the tag immediately reflects the new mode
- `auto` is the intelligent default -- it already knows WHEN to diverge based on task context
- Always end every response with `[session: <name> | DIV: <MODE>]`
