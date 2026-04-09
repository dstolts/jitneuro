# User Story: Document Routing Weights vs Semantic Memory

**Created:** 2026-03-27
**Priority:** 55/100
**Status:** Ready for execution
**Handoff:** Agent-ready

## Summary

Create `docs/routing-vs-semantic-memory.md` explaining why JitNeuro uses explicit routing weights instead of vector/semantic search for context loading, and why this is the better architecture for AI-first workflows.

This matters because semantic memory/RAG is the industry default. People will ask "why doesn't JitNeuro use embeddings?" The doc should answer that definitively.

## Context

JitNeuro loads context via routing weights -- keyword patterns in MEMORY.md that map to bundles. Example:
```
- Deploy / server / VM / container -> [infrastructure]
- Blog / post / publish / sync     -> [blog-content]
```

The alternative (used by openclaw and most RAG systems) is vector embeddings: convert context files to vectors, query by semantic similarity, load top-N matches.

Both solve the same problem: "given a user request, which context should Claude have?" They solve it very differently.

## Acceptance Criteria

### AC-1: Create docs/routing-vs-semantic-memory.md

Cover these sections:

**How routing weights work:**
- Keyword -> bundle mapping in MEMORY.md
- /learn updates weights from session corrections
- Explicit, auditable, one-line-per-rule
- Claude reads the rules file, loads matching bundles

**How semantic memory works:**
- Embedding API converts context files to vectors
- User query converted to vector, nearest neighbors returned
- Black box -- similarity scores, not readable rules
- Requires vector DB (LanceDB, Pinecone, etc.) + embedding provider

**Comparison table:**

| Aspect | Routing Weights | Semantic Search |
|--------|----------------|-----------------|
| Dependencies | None (markdown file) | Node.js + vector DB + embedding API |
| Security | No external calls | Content sent to embedding API |
| Portability | File travels with repo | Binary DB files, platform-specific |
| Auditability | Read the file, see every rule | Opaque similarity scores |
| Correctability | Edit one line, instant fix | Re-embed? Adjust threshold? No clear path |
| Precision vs Recall | High precision (loads exactly what's needed) | High recall (loads anything that might be relevant) |
| Token efficiency | Only relevant context loaded | May load similar-but-wrong context |
| Learning loop | /learn adds rules from corrections | No equivalent correction mechanism |
| Cold start | Needs routing weights built up (via /learn) | Works immediately on any content |
| Failure mode | Missing route = context not loaded (visible, fixable) | Wrong similarity = wrong context loaded (subtle, hard to detect) |

**Why precision beats recall in token-limited windows:**
- Context window is finite. Every wrong bundle loaded wastes tokens.
- Wrong context doesn't just waste space -- it actively misleads Claude.
- Loading blog-content when debugging an API bug makes Claude less effective.
- Routing weights guarantee: if the rule matches, you get exactly that bundle. If it doesn't match, you get nothing (and can add a rule).

**When semantic search makes sense (and when it doesn't):**
- Makes sense: large document corpus, new users with no routing history, general-purpose search across thousands of files
- Doesn't make sense: curated context bundles (small set, high quality), power users with tuned weights, token-limited AI assistants

**The /learn feedback loop (routing weights' secret weapon):**
- User corrects Claude: "you should have loaded the deploy bundle"
- /learn captures: add "deploy" keyword to infrastructure routing
- Next session: Claude loads infrastructure automatically for deploy tasks
- Over time: routing weights become precisely tuned to THIS user's work
- Semantic search has no equivalent -- there's no "teach the embeddings" step

**Cold start problem and how JitNeuro solves it:**
- Day 1: few routing weights, user loads bundles manually with /bundle
- /learn captures each manual load as a new routing rule
- By day 7: most common task patterns are auto-routed
- By day 30: routing is comprehensive -- almost nothing needs manual loading
- Semantic search solves cold start immediately but never gets more precise

**Could they work together?**
- A semantic search layer could SUGGEST new routing weight entries
- "I noticed you always load [infrastructure] when the prompt mentions containers. Add a routing rule?"
- The routing weights remain the source of truth. Semantic search is advisory, not authoritative.
- This preserves auditability while helping with cold start

### AC-2: Tone and Audience
- Written for developers evaluating JitNeuro vs RAG-based alternatives
- Honest about tradeoffs (semantic search wins on cold start, routing weights win everywhere else)
- Not a sales pitch -- a technical comparison
- Reference openclaw as a concrete example of the semantic approach

### AC-3: Link from README and technical-overview
- Add one line to README docs table referencing this doc
- Add to technical-overview.md related docs section
