---
type: skill
purpose: Binding rules for handling secrets -- they belong in .env files only, never in code, docs, specs, or source control -- and the process for verifying before committing. Read this when writing or reviewing any code, doc, or config that touches credentials, API keys, or tokens.
tags: [skill, security, secrets, credentials, guardrails]
scope: public
departments: [engineering]
read_when: When writing or reviewing any code, doc, or configuration that touches credentials, API keys, tokens, or secrets.
last_evaluated: 2026-06-03
---

# Security Guardrails

Secrets belong in .env files. Never in code, docs, specs, or configuration files checked into source control.

## When to Apply

Any time you are writing or reviewing code, documentation, specs, or configuration that touches credentials, API keys, tokens, passwords, or connection strings.

## Core Process

1. **Before writing any value that looks like a secret:** stop. Put it in the .env file. Reference the variable name in code.
2. **In docs and specs:** write the variable name and .env path, never the value. Example: "RESEND_API_KEY in <CodeBasePath>\Automation\.env -- not the actual key.
3. **In code:** use environment variable reads (os.getenv, process.env). Never hardcode. Never default to a real key value.
4. **In .mcp.json:** secrets belong in the env block (protected by global gitignore). Never strip them -- the file is gitignored for this reason.
5. **When looking for a key:** check the central .env first (<CodeBasePath>\Automation\.env), then per-repo .env.prod files. Do not ask Owner where it is -- find it.
6. **Before committing:** grep the diff for patterns matching API keys (long hex strings, "sk-", "Bearer ", base64 blobs). If found, remove and move to .env before the commit.

## .env File Hierarchy

- Central: <CodeBasePath>\Automation\.env (check here first)
- Per-repo: [repo]/.env.prod (for repo-specific overrides)
- Example files: [repo]/.env.example or .mcp.example.json (placeholder values, safe to commit)

## What to Avoid

- Writing an actual API key anywhere except a .env file
- Putting connection strings in CLAUDE.md, specs, or PRDs
- Defaulting env vars to real credentials in code: `api_key = os.getenv('KEY') or 'real-key-here'`
- Committing .mcp.json (it is gitignored globally -- do not override this)
- Asking Owner for a key when it is already in the .env file

## Integration

Used by: all engineering roles -- security-developer, mssp-engineer, sys-security, sys-backend, sys-devops, sys-architect, repo-* agents
