# Routing Weights vs Semantic Memory

Why JitNeuro uses explicit routing weights instead of vector embeddings for context loading, and what that means for precision, auditability, and token efficiency.

## The Problem Both Solve

Given a user request, which context should the AI assistant have?

A developer says "deploy the API to staging." The assistant needs infrastructure knowledge, not blog content guidelines. Both routing weights and semantic memory try to solve this selection problem. They solve it very differently.

## How Routing Weights Work

JitNeuro stores routing rules as keyword-to-bundle mappings in a plain markdown file (MEMORY.md or a dedicated rules file):

```
- Deploy / server / VM / container   -> [infrastructure]
- Blog / post / publish / sync       -> [blog-content]
- Sprint / ralph / prd / story       -> [ralph-workflow]
- API chain / auth / integration     -> [integrations]
```

When a user message arrives, Claude reads the routing rules and loads the matching bundles. The rules are explicit, one-per-line, and human-readable. There is no inference layer, no similarity scoring, no probability threshold.

Rules can map to multiple bundles when tasks span domains:

```
- Cross-repo sprint                  -> [ralph-workflow, infrastructure]
- N8N / workflow / credentials       -> [inbound-agency, integrations, infrastructure]
```

The `/learn` command updates routing weights from session corrections. If Claude should have loaded a bundle but didn't, the owner corrects it, and `/learn` adds the missing keyword mapping. Next session, Claude loads that bundle automatically.

## How Semantic Memory Works

Semantic memory (used by OpenClaw and most RAG systems) works differently:

1. **Indexing:** Context files are converted to vector embeddings via an embedding API (e.g., embeddinggemma-300m, OpenAI ada-002, or similar). Each file becomes a point in high-dimensional space.
2. **Query:** The user's message is also converted to a vector. A nearest-neighbor search finds the N most "similar" context files by cosine distance.
3. **Loading:** The top-N results are injected into the context window.

This is powerful for general-purpose search across large, unstructured document collections. It requires no manual rule writing -- similarity is computed, not declared.

## Comparison

| Aspect | Routing Weights | Semantic Search |
|--------|----------------|-----------------|
| **Dependencies** | None (markdown file) | Node.js + vector DB + embedding API |
| **Security** | No external calls | Content sent to embedding API |
| **Portability** | File travels with the repo | Binary DB files, platform-specific |
| **Auditability** | Read the file, see every rule | Opaque similarity scores |
| **Correctability** | Edit one line, instant fix | Re-embed? Adjust threshold? No clear path |
| **Precision** | High (loads exactly what matches) | Moderate (loads anything semantically close) |
| **Recall** | Moderate (misses unmapped keywords) | High (finds anything similar) |
| **Token efficiency** | Only matched bundles loaded | May load similar-but-wrong context |
| **Learning loop** | /learn adds rules from corrections | No equivalent correction mechanism |
| **Cold start** | Needs routing weights built up | Works immediately on any content |
| **Failure mode** | Missing route = nothing loaded (visible, fixable) | Wrong similarity = wrong context loaded (subtle, hard to detect) |

## Why Precision Beats Recall in Token-Limited Windows

This is the core argument. Context windows are finite. Every token spent on wrong context is a token unavailable for right context.

Semantic search optimizes for recall -- it would rather load something potentially relevant than miss something that might be needed. This is the correct tradeoff for a search engine, where showing 10 results costs nothing and the user filters visually.

It is the wrong tradeoff for an AI coding assistant.

When Claude loads the `blog-content` bundle while debugging an API authentication bug, three things go wrong:

1. **Token waste.** The blog content guidelines consume context window space that could hold the actual integrations bundle.
2. **Active misdirection.** Claude now has content-writing instructions in context. It may start applying content quality gates to error messages, or suggest blog-post-style formatting in API responses. Wrong context doesn't just waste space -- it changes behavior.
3. **Silent failure.** The developer doesn't see what was loaded. They see Claude giving slightly off answers and don't know why. There is no "wrong bundle loaded" error message.

Routing weights avoid all three. If the keyword doesn't match, nothing loads. The developer sees Claude operating without the expected context and says "you should have loaded the infrastructure bundle." That correction is visible, immediate, and becomes a permanent routing rule via `/learn`.

The failure mode matters as much as the success mode. Routing weights fail loudly (missing context is obvious). Semantic search fails quietly (wrong context is subtle).

## When Semantic Search Makes Sense

Semantic search is the better choice when:

- **Large, unstructured corpus.** Thousands of documents with no clear categorization. Routing weights don't scale to thousands of rules.
- **New users with no history.** Day-one experience with zero routing rules. Semantic search works immediately.
- **General-purpose search.** "Find anything related to X" across a broad knowledge base where precision matters less than coverage.
- **Discovery workflows.** Exploring a codebase or document collection where you don't know what you're looking for.

Semantic search is the wrong choice when:

- **Curated context bundles.** A small set of high-quality bundles (10-50) where each one is purpose-built. Routing weights are simpler and more precise.
- **Power users with tuned weights.** After a few weeks of `/learn`, routing weights are precisely tuned to this specific user's work patterns. Semantic search never gets more precise.
- **Token-limited AI assistants.** Every wrong bundle loaded degrades performance. Precision matters more than recall.
- **Auditability requirements.** Enterprise environments where you need to explain why specific context was loaded. "The routing rule on line 14 matched the keyword 'deploy'" is auditable. "The cosine similarity score was 0.73" is not.

## The /learn Feedback Loop

This is routing weights' most significant advantage over semantic search, and it compounds over time.

The loop:

1. Owner works on a task. Claude loads context based on routing weights.
2. Claude misses a bundle. Owner corrects: "You should have loaded the infrastructure bundle for this."
3. Owner runs `/learn`. The system captures the correction and adds a new routing rule: `container app -> [infrastructure]`.
4. Next session, when the owner mentions "container app," Claude loads the infrastructure bundle automatically.
5. Over time, routing weights become precisely tuned to THIS owner's vocabulary and work patterns.

Semantic search has no equivalent mechanism. There is no "teach the embeddings" step. If the embedding model thinks "container app" is more similar to "mobile application" than to "server infrastructure," there is no user-facing correction path. You could re-embed with different chunking, adjust similarity thresholds, or add metadata filters -- but none of these are one-line fixes, and none of them learn from user corrections.

The `/learn` loop means routing weights get better every day. Semantic search stays the same quality forever (unless you swap embedding models or re-architect your indexing pipeline).

## Cold Start and How JitNeuro Solves It

Cold start is routing weights' original weakness -- but JitNeuro solves it without semantic search.

### Auto-Discovery at Install (FR-108)

`/onboard` scans the repo and auto-generates initial routing weights from signals already in your code:

| Source | What it reveals | Routing generated |
|--------|----------------|-------------------|
| `.env` files | Service dependencies | `AUTH_API_URL` -> links to auth service bundle |
| `package.json` | Tech stack | `express`, `stripe`, `firebase-admin` -> API, payments, auth bundles |
| Import statements | Cross-repo references | `import { auth } from '../AuthFirebase'` -> repo dependency mapping |
| `docker-compose.yml` | Service graph | `depends_on: [api, redis]` -> infrastructure bundle |
| `CLAUDE.md` / `README.md` | Project identity | Tech stack, purpose, key paths -> engram |

For workspace installs, scanning ACROSS repos reveals the integration graph automatically. Repo A's .env references Repo B's URL -- that's a dependency Claude should know about.

### Progressive Refinement

| Timeline | Experience |
|----------|-----------|
| **Day 0** | `/onboard` scans code, generates initial routing weights and engram. Claude knows your tech stack, dependencies, and service graph from the first prompt. |
| **Day 3** | `/learn` refines from corrections. "When I say deploy, I mean Azure not AWS." |
| **Day 7** | Most daily patterns auto-routed. Manual bundle loading is rare. |
| **Day 30** | Routing is comprehensive. The system knows your vocabulary and patterns better than any embedding model could infer. |

Semantic search solves cold start immediately -- but it never gets more precise than day one. The embedding model's understanding is static. It doesn't learn that when YOU say "pub" you mean "publish to Ghost" not "public access."

JitNeuro solves cold start at install AND gets more precise every day. No embeddings required.

## Could They Work Together?

Yes, but with a clear hierarchy: routing weights are authoritative, semantic search is advisory.

A hybrid approach could work like this:

1. Routing weights remain the source of truth for context loading. Matched rules load bundles as they do today.
2. A semantic search layer runs in parallel, comparing the user's message against all available bundles.
3. When semantic search finds a high-confidence match that has NO routing weight, it suggests a new rule: "I noticed you frequently discuss containers in the context of deployment. Add routing rule: `container -> [infrastructure]`?"
4. The owner reviews and approves. `/learn` persists the rule.

This preserves auditability (every loaded bundle traces to a readable rule) while using semantic search to accelerate the cold start period and catch gaps in routing coverage.

What this hybrid should NOT do:

- **Semantic search should never load bundles directly.** If it bypasses routing weights, you lose auditability and gain the wrong-context-loaded problem.
- **Semantic search should never override routing weights.** If a routing rule says "deploy -> [infrastructure]" and semantic search says "deploy is similar to blog-content," the routing rule wins. Always.
- **The suggestion mechanism should be lightweight.** It runs periodically (not every message), proposes rules to `/learn`, and the owner has final say.

This keeps routing weights as the deterministic, auditable core while using semantic search as a training signal for new rules. The best of both approaches without the downsides of either.

## Summary

Routing weights and semantic memory are different tools optimized for different constraints.

Semantic memory optimizes for recall in unbounded search spaces. It works immediately, handles any content, and finds things you didn't know to look for. It requires external dependencies, sends content to embedding APIs, produces opaque similarity scores, and has no user-facing correction mechanism.

Routing weights optimize for precision in token-limited windows. They load exactly what matches, fail visibly when coverage is missing, improve with every `/learn` cycle, require zero external dependencies, and produce auditable one-line rules that any developer can read and edit. They require upfront investment that compounds into a precisely tuned system.

For AI coding assistants operating in fixed-size context windows where wrong context actively degrades performance, precision wins. JitNeuro chose routing weights because the failure mode -- missing context that you can see and fix -- is strictly better than the alternative: wrong context that you can't detect and can't correct.

## Related Docs

- [Technical Overview](technical-overview.md) -- JitNeuro architecture and routing weight mechanics
- [Concepts](concepts.md) -- Core concepts including bundles, engrams, and routing
- [Comparison: JitNeuro vs OpenClaw](comparison-openclaw.md) -- Full feature comparison including semantic memory discussion
- [Configuration Reference](configuration-reference.md) -- Routing weight configuration details
