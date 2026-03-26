# Feedback Classification: Personal vs Publishable

When /learn detects a correction, confirmed approach, or new pattern, it must classify it before persisting. This guide defines the decision boundary.

## Decision Tree

```
Is this feedback specific to MY business, credentials, or project?
  YES -> Personal feedback (memory/)
  NO  -> Could any Claude Code user benefit from this?
           YES -> Publishable (jitneuro feature request)
           NO  -> Personal feedback (memory/)
```

## Personal Feedback (stays in memory/)

Feedback that references your specific:
- **Business context:** pricing, clients, revenue targets, company names
- **Credentials/services:** API keys, server names, .env paths, account IDs
- **Project quirks:** specific API limitations, edition-specific bugs, vendor workarounds
- **Personal preferences:** formatting style, communication tone, workflow habits
- **Tool-specific gotchas:** your N8N instance, your Salesforce edition, your Ghost setup

Examples:
- "SF Composite API limited to 25 ops/request" -- your SF edition, personal
- "Never publish to Ghost without approval" -- your workflow, personal
- "N8N httpRequest truncates at 17K chars" -- N8N gotcha, personal (unless it's a universal N8N limitation)
- "Owner is Founder & Chief Innovation Officer" -- personal identity

## Publishable Patterns (jitneuro feature request)

Feedback that describes a universal pattern any Claude Code user would benefit from:
- **Runtime guardrails:** memory exhaustion prevention, context budget management
- **Security patterns:** secrets in docs, credential handling, .mcp.json protection
- **Quality patterns:** proactive issue catching, end-to-end verification, code reuse
- **Structural patterns:** MEMORY.md index pattern, bundle organization, engram conventions
- **Process patterns:** multi-agent batching, sprint safety, file versioning

Examples:
- "Never scan more than 25 files in one response" -- universal Claude Code guardrail
- "Never put secrets in markdown files" -- universal security pattern
- "Verify changes end-to-end, not just syntactically" -- universal quality pattern
- "MEMORY.md should use an index, not one line per file" -- structural improvement

## Gray Areas

Some feedback starts personal but reveals a universal pattern:
- "Ghost API ignores html field in PUT" -- starts as a Ghost gotcha, but the pattern "verify API actually uses the field you set" is universal
- "Model IDs must stay current" -- starts as your app's bug, but "validate external dependency versions" is universal

**Rule:** If the underlying principle is universal, submit the principle (not the specific instance) as a feature request. Keep the specific instance as personal feedback.

## Auto-Submit Flow (Future)

When /learn classifies feedback as publishable:
1. /learn presents the finding with classification: "This looks publishable. Submit as jitneuro feature request?"
2. User approves -> Claude creates a GitHub issue on the jitneuro repo
3. Issue includes: proposed rule content, why it's universal, which session discovered it
4. Labels: `rule-proposal`, `template-proposal`, or `guardrail`
5. User reviews the issue at their pace, merges when ready
6. Next install picks up the new template

**Gate:** Never auto-submit without explicit user approval. The classification is a suggestion, not an action.

## Issue Template

When submitting a publishable pattern as a GitHub issue:

```markdown
## Proposed Rule: [name]

### What
[One-line description of the rule]

### Why
[What went wrong without this rule, or what pattern was discovered]

### Proposed Content
[The genericized rule text, ready to drop into templates/rules/]

### Classification
- [ ] Runtime guardrail
- [ ] Security pattern
- [ ] Quality pattern
- [ ] Structural pattern
- [ ] Process pattern

### Origin
Discovered in session: [session name], date: [date]
```
