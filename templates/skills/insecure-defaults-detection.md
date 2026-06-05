---
type: skill
purpose: Find fail-open patterns where missing or empty configuration causes the system to proceed insecurely; reports each finding with file path, exploitation scenario, and fix. Read this during security audits or any code review touching config, env vars, secrets, or auth.
tags: [skill, security, insecure-defaults, code-review, fail-open]
scope: public
departments: [engineering]
read_when: During a security audit or any code review touching config, env vars, secrets, auth, or feature flags to find fail-open patterns.
last_evaluated: 2026-06-03
---

# Insecure Defaults Detection

Find fail-open patterns where missing or empty configuration causes the system to proceed insecurely. Report with location, exploitation scenario, and fix. Do not flag test fixtures or build-time placeholders.

## When to Apply

- Security audit of a codebase
- Code review of any file touching config, env vars, secrets, auth, or feature flags
- Any PR that adds new environment variable reads or configuration paths

## Core Process

1. **Scan for fail-open patterns.** Common signatures:
   - `env.get('KEY') or 'default-value'` where default-value grants access or disables a check
   - `config.get('AUTH_REQUIRED', False)` where False disables authentication
   - `os.environ.get('SECRET_KEY', 'changeme')` where changeme is a real (weak) value
   - `if api_key:` without a hard failure when api_key is empty
   - Feature flags that default to enabled (e.g., `allow_all = os.getenv('RESTRICT') is None`)

2. **Verify execution paths.** Does this default actually reach production code, or is it only exercised in local dev? Trace the call path. If the default only fires when the env var is missing and the env var is always set in production, the risk is lower -- note that context.

3. **Confirm production reachability.** A default that only triggers in an offline test environment is not the same risk as one that triggers when a deployment misconfiguration occurs. State which scenario applies.

4. **Report format per finding:**
   - File path and line number
   - The insecure default (exact code)
   - Exploitation scenario: what an attacker gains when the default fires
   - Recommended fix: hard failure, no default, or a safe default (deny-by-default)

## Safe vs Unsafe Defaults

- Unsafe: missing key -> grant access, skip check, use weak credential
- Safe: missing key -> hard failure with clear error message, service refuses to start

## What NOT to Flag

- Test fixtures and test helper files (mock values are expected there)
- `.example` env files (these are templates, not runtime config)
- Build-time configuration replaced before the binary runs
- Development-only flags clearly scoped to `if NODE_ENV === 'development'`

## What to Avoid

- Flagging every env.get() without checking if the default is actually dangerous
- Reporting without an exploitation scenario (forces reviewer to imagine the risk themselves)
- Missing the indirect path: a safe-looking default that feeds an unsafe downstream function

## Integration

Used by: sys-security, security-developer, sys-code-reviewer, mssp-engineer, sys-compliance
