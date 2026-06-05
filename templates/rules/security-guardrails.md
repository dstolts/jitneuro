---
type: rule
purpose: Prohibit secrets and PII in source code and documentation and prohibit live infrastructure identifiers in committed files, with mandatory env-file-only storage for credentials.
read_when: Before committing any file that may contain credentials, PII, live service IDs, or environment-specific secrets.
tags: [security, secrets, pii, credentials, infrastructure-identifiers]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---
# Security Guardrails

## Secrets in Documentation
Never put API keys, secrets, tokens, or passwords in markdown files, specs, plans, or documentation. Always reference the .env file location.
- In docs: write "API_KEY_NAME in path/to/.env" not the actual value
- Keys belong in .env files ONLY, never in .md, .json, or code
- .mcp.json MUST contain secrets in its env block (protected by global gitignore) -- never strip secrets from it
- .mcp.example.json should have placeholder values and is safe to commit
- Ensure .mcp.json is in your global gitignore to prevent accidental commits

## PII in Source Code
Never hardcode real-person emails, phone numbers, or addresses in committed code -- not in tests, not in fixtures, not in narrative comments.

WHY: Persistent personal-data exposure in source control is recoverable forever, even after deletion.

HOW TO APPLY:
- Use synthetic values per RFC 2606 (`test-pro@example.com`, `user@example.com`, `+1-555-000-0000`) for unit tests
- Use env vars (e.g., `E2E_PRO_TEST_EMAIL`) for tests that need a real account tied to live infra
- Never commit real identity emails as test fixtures or doc owner fields

## Infrastructure Identifiers
Never commit live service IDs (Stripe webhook IDs, cloud revision strings, WAF zone IDs, container-app names referencing prod, or internal DB schema names) in source code.

WHY: They uniquely identify live infrastructure and combine into discoverable threat intelligence even though they are not "secrets" in the API-key sense.

HOW TO APPLY: Parameterize via `.env.local` (gitignored) and reference the env var by name. In comments and docs, describe pipeline behavior abstractly ("the live-mode webhook") rather than naming the specific identifier.
