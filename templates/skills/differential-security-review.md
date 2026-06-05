---
type: skill
purpose: Risk-first analysis of a PR or diff that classifies changes by blast radius and reviews HIGH items first; produces per-finding reports with file, line, attack scenario, and fix. Read this when performing a security-focused PR review or auditing any change touching auth, crypto, or external integrations.
tags: [skill, security, code-review, risk-classification, pr-review]
scope: public
departments: [engineering]
read_when: Before performing a security-focused PR review or auditing any change touching auth, crypto, or external integrations.
last_evaluated: 2026-06-03
finding_tracker: ignore
---

# Differential Security Review

Risk-first analysis of a PR, commit, or diff. Classify changes by blast radius, then review in priority order. Always cite specific line numbers.

## When to Apply

Any PR or diff review where security impact must be assessed. Mandatory for PRs touching auth, crypto, external integrations, or privilege boundaries.

## Risk Classification (Triage First)

Before deep analysis, label every changed file or function:

- **HIGH** -- authentication, authorization, cryptography, session management, external API calls, file system access, command execution, deserialization
- **MEDIUM** -- business logic with financial or access implications, state machines, data validation, error handling paths
- **LOW** -- documentation, UI labels, logging (non-sensitive), test fixtures, build scripts

Review HIGH items first and in full. Review MEDIUM selectively. Skim or skip LOW unless they touch a sensitive adjacent area.

## Six-Phase Review

1. **Triage** -- classify all changes by HIGH/MEDIUM/LOW. Note the overall risk profile in one line.
2. **Code analysis** -- read HIGH-risk changes line by line. Look for: injection points, missing input validation, privilege escalation paths, insecure defaults, hardcoded secrets.
3. **Test coverage** -- does the PR include tests for the new HIGH-risk paths? Absence of tests on auth or crypto changes is a blocking finding.
4. **Blast radius** -- if this code is exploited, what is the maximum impact? Scope it: single user, all users, data exfil, service disruption, RCE.
5. **Deep context** -- does this change interact with existing security controls (rate limiting, CSRF tokens, audit logging)? Does it disable or weaken any of them?
6. **Adversarial modeling** -- how would an attacker exploit this? Write one concrete attack scenario for each HIGH finding.

## Output Format

Every finding must include:
- Severity: [BLOCKING] or [ADVISORY]
- File and line number
- What the issue is (one sentence)
- Attack scenario (one sentence)
- Recommended fix (one sentence or a code snippet)

## What to Avoid

- Reviewing LOW-risk changes first because they are easier
- Reporting findings without line numbers
- Generic findings ("input is not validated") without specifying which input and what the exploit looks like
- Approving a PR with unaddressed BLOCKING findings

## Integration

Used by: sys-security, sys-code-reviewer, sys-architect, security-developer, mssp-engineer
