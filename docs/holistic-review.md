# Holistic Review: Enterprise-Grade AI Code Quality

JitNeuro includes a two-gate review system that evaluates AI-generated code from
multiple expert perspectives before it ships. This is what separates "AI wrote some
code" from "AI wrote production-ready code that passed a multi-persona review."

## The Problem with AI-Generated Code

AI coding assistants generate code fast. But speed without review creates:
- Security vulnerabilities (auth bypass, SQL injection, input validation gaps)
- Maintenance nightmares (inconsistent patterns, dead code, naming confusion)
- Silent failures (missing null checks, swallowed errors, broken edge cases)
- Architecture drift (each sprint diverges further from established patterns)

Human code review catches some of this. But reviewers are biased toward their
own expertise -- a frontend dev misses API auth issues, a backend dev misses
accessibility problems.

## The Solution: Multi-Persona Review Gates

JitNeuro defines two review gates, each evaluating from 4 mandatory perspectives:

### Gate 1: Holistic Preview (Pre-Execution)

Runs AFTER sprint planning, BEFORE code execution. Evaluates the plan, not the code.

**When:** After prd.json is created but before Ralph executes
**Input:** Sprint spec, user stories, acceptance criteria, current codebase state
**Question:** "Will this plan produce good code if executed as written?"

The preview uses JitNeuro context (engrams + bundles) to check things an AI
executor would miss:
- Does story US-003 say "create auth middleware" when one already exists?
- Does the sprint assume a database table that hasn't been migrated yet?
- Are two stories going to modify the same file with conflicting changes?
- Does the AC test something the current test framework can't verify?

### Gate 2: Holistic Execution Review (Post-Execution, US-HER)

Runs AFTER code execution, BEFORE push/deploy. Evaluates the actual code.

**When:** After Ralph completes all stories
**Input:** Git diff, modified files, test results, sprint spec
**Question:** "Is this code safe to ship?"

## The 4 Personas

Every review evaluates from all four perspectives. No exceptions.

### 1. Sr Software Architect (Ralph AFK)
**Focus:** Patterns, abstractions, plan fidelity, existing code alignment
**Checks:**
- Does the code follow established project patterns? (from engram)
- Are abstractions at the right level? (not over-engineered, not copy-pasted)
- Does the implementation match the spec? (story AC vs actual behavior)
- Are there existing utilities being duplicated instead of reused?

### 2. Maintenance Engineer
**Focus:** Readability, naming, consistency, future developer experience
**Checks:**
- Will a new developer understand this code in 6 months?
- Are names consistent with the rest of the codebase?
- Is the code self-documenting or does it need comments?
- Are there magic numbers, unclear abbreviations, or misleading names?

### 3. Reliability Engineer (Fail-Fast)
**Focus:** Edge cases, error handling, degradation paths, null safety
**Checks:**
- What happens when the database is down?
- What happens with null/undefined inputs?
- Are errors caught, logged, and surfaced (not swallowed)?
- Is there a graceful degradation path or does one failure cascade?
- Are timeouts and retries configured for external calls?

### 4. Security Engineer
**Focus:** Auth, input validation, data leaks, injection, rate limiting
**Checks:**
- Are all new routes protected by appropriate auth middleware?
- Is user input validated and sanitized before use?
- Are SQL queries parameterized (no string concatenation)?
- Are sensitive fields excluded from API responses?
- Are admin routes properly gated?
- Is rate limiting applied to public endpoints?

## Output Format

Both gates produce the same output structure:

### Preview Output (Pre-Execution)
```
Ralph Preview: Sprint-BlogComments-001
| Story | Name | Risk | Est. Time | Verdict |
|-------|------|------|-----------|---------|
| US-001 | Create comments table | Low | 5 min | Go |
| US-002 | POST /comments endpoint | Med | 10 min | Enhance -- add rate limiting to AC |
| US-003 | GET /comments endpoint | Low | 5 min | Go |
| US-004 | Delete comment (admin) | High | 10 min | Go -- verify admin middleware exists |
| US-HER | Holistic review | -- | 15 min | Go |

Prerequisites:
- [ ] Database migration for comments table (project owner must run)
- [ ] API deployed to uat (needed for FE testing)

Blockers: None
```

### Execution Review Output (Post-Execution)
```
US-HER Review: Sprint-BlogComments-001
| Story | Name | Risk | Status | Verdict |
|-------|------|------|--------|---------|
| US-001 | Create comments table | Low | Implemented | Success |
| US-002 | POST /comments | Med | Implemented | Issues -- no rate limiting |
| US-003 | GET /comments | Low | Implemented | Success |
| US-004 | Delete comment | High | Implemented | Issues -- missing admin check |

Security Findings:
- US-002: POST endpoint has no rate limiting (add before prod)
- US-004: Delete route missing isAdmin middleware (CRITICAL)

Dead Code:
- None found

Spec Deviations:
- US-002: Returns 201 instead of spec'd 200 (minor, 201 is more correct)

Recommendation: Fix US-004 admin check before push. US-002 rate limiting
can be a follow-up story if the project owner approves.
```

## How JitNeuro Context Improves Reviews

Without JitNeuro, the review only sees the code diff. With JitNeuro:

| JitNeuro Context | Review Improvement |
|------------------|-------------------|
| Engram (project) | Knows existing auth patterns -- catches inconsistencies |
| Engram (project) | Knows existing file structure -- catches duplicated utilities |
| Bundle (api) | Knows API conventions -- catches pattern violations |
| Bundle (sprint) | Knows story format -- catches ambiguous AC before execution |
| Routing weights | Auto-loads the right context -- reviewer doesn't start cold |
| /learn | Previous review findings inform future reviews |

## Integration with JitNeuro Workflow

```
1. /orchestrate -> Claude plans sprint with bundles + engrams loaded
2. Ralph Preview -> 4-persona pre-execution review
3. User approves -> Ralph executes in separate terminal
4. US-HER Review -> 4-persona post-execution review
5. User approves -> Push to uat/main
6. /learn -> Capture review findings for next sprint
```

The reviews are not separate tools -- they're part of the JitNeuro context cycle.
Each review uses the same bundles and engrams that informed planning. Findings
from /learn feed back into future reviews, making them smarter over time.

## Why This Matters for Enterprise

1. **Audit trail** -- every sprint has a documented review with specific findings
2. **Consistent quality** -- 4 personas catch what any single reviewer would miss
3. **AI accountability** -- AI doesn't just generate code, it reviews its own work
4. **Scalable** -- runs the same whether you have 1 sprint or 20 in parallel
5. **Improvable** -- /learn captures review patterns, so reviews get better over time
6. **No additional tooling** -- uses Claude Code's existing subagent + command primitives
