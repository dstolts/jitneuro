---
type: skill
purpose: Backpropagation command that evaluates session for long-term knowledge and runs memory health check; skipping means corrections and discoveries are lost at session end and repeat across sessions.
read_when: At session end, after any major correction or discovery, or when Owner triggers /learn to persist knowledge to long-term memory.
tags: [learn, memory, backpropagation, engrams, bundles, routing-weights, knowledge-management]
scope: public
departments: [all]
status: canonical
graduation_target: skills/learn/SKILL.md
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /learn

Evaluate session for long-term knowledge and persist to correct memory locations.

## 5 Knowledge Categories

1. **Routing weights** -- new trigger-to-bundle mappings discovered this session
2. **Bundle updates** -- domain knowledge to add to existing bundles
3. **Engram updates** -- project context changes (architecture, key files, conventions)
4. **New knowledge** -- facts, decisions, and patterns not fitting existing categories
5. **Corrections** -- anti-patterns and friction-detected mistakes to persist

## Phases

### Phase 1: Parallel gather

Dispatch subagents in parallel to scan:
- Session Hub.md `## Lessons Learned` section
- Recent conversation for friction-detection triggers
- New decisions or architectural changes discussed
- Owner corrections or preference updates

### Phase 2: Merge and present

Merge findings into a proposed update table:

| Category | Item | Proposed destination | Action |
|----------|------|---------------------|--------|
| routing | "deploy / ACA" -> [infrastructure] | context-manifest.md | ADD |
| engram | jitai-api now on Azure Container Apps | jitai-context.md:L47 | UPDATE |

Present the table. Ask: "Write these? (all / numbers / changes needed)"

### Phase 3: Write on explicit approval

Write ONLY after explicit approval. Use the WS4 save-router to classify destination:
- Facts -> MEMORY.md
- Instructions/rules -> rules/ file
- Domain knowledge -> bundles/
- Project context -> engrams/
- Routing -> context-manifest.md / INDEX.md

## Memory health check

After writing, run a quick /health to surface any thresholds exceeded by the new content.

## --team flag

`/learn --team` promotes the update to `.jitneuro/` (team-shared) instead of `.claude/` (personal).
Requires Owner confirmation before writing team-shared files.
