# Security Guardrails

## Secrets in Documentation
Never put API keys, secrets, tokens, or passwords in markdown files, specs, plans, or documentation. Always reference the .env file location.
- In docs: write "API_KEY_NAME in path/to/.env" not the actual value
- Keys belong in .env files ONLY, never in .md, .json, or code
- .mcp.json MUST contain secrets in its env block (protected by global gitignore) -- never strip secrets from it
- .mcp.example.json should have placeholder values and is safe to commit
- Ensure .mcp.json is in your global gitignore to prevent accidental commits
