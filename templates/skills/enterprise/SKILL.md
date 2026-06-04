---
type: skill
purpose: Display consolidated DOE governance rules, trust zones, approval workflow, quality gates, and branch rules.
tags: [enterprise, governance, doe, trust-zones, read-only]
scope: public
status: canonical
graduation_target: skills/enterprise/SKILL.md
read_when: When an agent or Owner needs a consolidated view of trust zones, approval workflow, quality gates, and branch rules.
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /enterprise

Display consolidated governance rules. READ-ONLY operation.

## Output sections

### Trust Zones
| Zone | Actions | Behavior |
|------|---------|----------|
| GREEN | Read/write/edit code+docs, search, test, analyze, research | Execute freely |
| YELLOW | Schema changes, new dependencies, API contracts, .env writes | Execute, report at checkpoint |
| RED | Push to main, production deploy, delete files/branches, DB migrations | Stop and ask Owner |

### Approval Workflow
- Strategy Mode: plan/discuss/brainstorm -- .MD only, wait for explicit approval
- Approval phrases: "Go ahead", "You can proceed", "Please execute", "Approved", "Plan accepted"
- Answering a question is NOT approval

### Quality Gates
- ASCII only (no emojis, no special characters)
- Fix root cause (never skip, disable, or bypass functionality)
- Test before commit (build + type check)
- For-profit business context (consider ROI, cost, time, value)

### Branch Rules
- Sprint work on feature branch or uat ONLY
- Never commit directly to main
- Push to main requires explicit Owner permission
- Force push always blocked

### File Versioning
- Search first, ask to update or create new
- Version: copy -01 to -02, archive -01, edit -02
- Hub.md is NEVER versioned (exception)
- Never delete files -- always archive

## What this does NOT do

Does not modify any files. Read-only reference display.
