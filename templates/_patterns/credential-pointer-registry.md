---
type: pattern
purpose: Any AI coding agent or framework installer managing credentials MUST consult this before writing service configuration -- firing at the moment a new integration is wired or a credential reference is added to any config file -- because omitting the pointer pattern causes agents to embed or cache raw secret values in committed configuration, producing a credential leak that persists in git history even after the value is rotated.
read_when: Before wiring any new integration or adding a credential reference to any configuration file.
last_evaluated: 2026-06-03
tags: [environment-management, credentials, security, ai-agent-patterns]
scope: public
status: canonical
community_reviewed: 2026-06-02
---

# Credential Pointer Registry

How to manage credentials, services, and integrations through a pointer registry pattern -- and why this is better than environment variable substitution for AI-first workflows.

---

## The Problem

AI coding agents need credentials. Traditional approaches either:
1. Store secrets in config files (dangerous -- config gets committed, cached, logged)
2. Use `${VAR}` placeholder substitution (requires a parser, round-trip preservation, and runtime code)

Both approaches were designed for code-reads-config workflows. In an AI-agent workflow, the agent reads config. The agent does not need variables resolved -- it can follow a pointer.

---

## The Solution: Pointer Registry

Use a centralized registry file that POINTS TO where secrets live, without ever containing them.

> **Secrets are NEVER stored in the registry/config file (`workspace.json` or equivalent).**
> The registry holds pointers only. Actual credential values live exclusively in an
> approved secret store: a cloud key vault (e.g., Azure Key Vault), a dedicated secrets
> manager / password manager (e.g., Keeper, 1Password, HashiCorp Vault), or a gitignored
> `.env` file. If a secret value ever appears in the registry, that is a leak -- rotate it
> and remove it.

### Location

```
.agent/workspace.json
```

(Or any committed JSON file accessible to the agent -- the key constraint is that it contains zero secrets, only pointers.)

This file is safe to commit. It contains zero secrets -- only pointers to `.env` files and vault references.

### How It Works

1. The agent needs a Stripe API key
2. The agent reads `workspace.json`, finds `credentials.stripe.envFile` and `credentials.stripe.keyNames`
3. The agent reads the `.env` file at that path, extracts the key
4. The secret never enters `workspace.json`, conversation context, or any committed file

### What It Tracks

| Section | Purpose | Example |
|---------|---------|---------|
| `vaults` | Credential storage systems with migration status | Azure Key Vault, HashiCorp Vault, 1Password |
| `credentials` | Integration pointers: envFile path, key names, purpose, vault targets | Stripe, GitHub, any third-party API |
| `envFiles` | Map of all `.env` file locations and their purpose | Central .env, per-repo .env files |
| `services` | Infrastructure with per-environment URLs and health endpoints | API servers, auth services |
| `domains` | DNS and hosting configuration | Primary domains, redirects |
| `sendingDomains` | Email delivery configuration | Sending domains per brand |
| `tools` | Custom scripts with paths and dependencies | OAuth listeners, token refreshers |

---

## Entry Patterns

### Credential Entry

Every credential entry points to where the secret lives. The secret itself is never in the registry file.

```json
{
  "stripe": {
    "envFile": "${WORKSPACE}/ProjectRepo/.env.prod",
    "keyNames": ["STRIPE_SECRET_KEY", "STRIPE_PUBLISHABLE_KEY", "STRIPE_WEBHOOK_SECRET"],
    "purpose": "Payments and subscriptions",
    "dashboard": "https://dashboard.stripe.com/...",
    "vaultTarget": "vault-prod",
    "migrated": false
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `envFile` | Yes (unless vault-migrated) | Absolute path to the `.env` file containing the secret |
| `keyNames` | Yes | Array of environment variable names to look for in that file |
| `keyName` | Alt | Single key name (use `keyNames` array for multiple) |
| `purpose` | Yes | What this credential is for (human + AI readable) |
| `dashboard` | No | URL to the service's management console |
| `vaultTarget` | No | Which vault this credential should migrate to |
| `migrated` | No | Whether the credential has been moved to a vault (default: false) |
| `expires` | No | ISO date string for credential expiration. Health checks can flag expired entries. |
| `notes` | No | Freeform notes about the credential |

### Service Entry

Services track per-environment URLs and health check endpoints.

```json
{
  "my-api": {
    "purpose": "Main application API",
    "environments": {
      "local": { "url": "http://localhost:3005", "health": "/health" },
      "uat": { "url": "https://my-api-uat.example.com", "health": "/health" },
      "prod": { "url": "https://my-api.example.com", "health": "/health" }
    }
  }
}
```

### Vault Entry

Vaults represent credential storage systems. Each has a status indicating migration progress.

```json
{
  "vaults": {
    "vault-prod": {
      "type": "azure-keyvault",
      "url": "https://kv-prod.vault.azure.net",
      "auth": "az CLI (DefaultAzureCredential)",
      "purpose": "Production secrets",
      "status": "planned"
    },
    "local-vault": {
      "type": "1password",
      "auth": "op CLI",
      "status": "active"
    }
  }
}
```

Vault status values:
- `"active"` -- in use today
- `"planned"` -- target for migration, not yet active
- `"migrating"` -- migration in progress

---

## Vault Migration Path

The registry tracks migration status per credential, enabling a gradual migration from `.env` files to a secrets vault without changing any other config.

### Before Migration

```json
{
  "stripe": {
    "envFile": "${WORKSPACE}/Repo/.env.prod",
    "keyNames": ["STRIPE_SECRET_KEY"],
    "vaultTarget": "vault-prod",
    "migrated": false
  }
}
```

The agent reads the `.env` file to get the secret.

### After Migration

```json
{
  "stripe": {
    "envFile": "${WORKSPACE}/Repo/.env.prod",
    "keyNames": ["STRIPE_SECRET_KEY"],
    "vaultTarget": "vault-prod",
    "vaultKey": "stripe-secret-key",
    "migrated": true
  }
}
```

The agent sees `migrated: true` and fetches from the vault instead of reading the `.env` file. For example, with Azure Key Vault: `az keyvault secret show --vault-name kv-prod --name stripe-secret-key`.

### Migration Steps

1. Move the secret from `.env` to the target vault
2. Update the registry: set `"migrated": true`, add `"vaultKey": "<vault-key-name>"`
3. The agent automatically reads the vault instead of `.env`
4. No code changes, no substitution engine, no config file edits beyond the registry

---

## How an AI Agent Uses the Registry

### Rules That Govern This

Two rules ensure the agent always uses the pointer registry:

- A workspace-data rule instructs the agent to read the registry FIRST for any credential lookup, never ask the operator where a credential is stored
- A security-guardrails rule states that secrets belong in `.env` files ONLY, never in `.md`, `.json`, or code

### Runtime Flow

```
Operator asks agent to call an external API
    |
    v
Agent reads workspace.json (the pointer registry)
    |
    v
Finds: credentials.stripe.envFile = "/path/to/.env.prod"
       credentials.stripe.keyNames = ["STRIPE_SECRET_KEY"]
       credentials.stripe.migrated = false
    |
    v
Agent reads /path/to/.env.prod
    |
    v
Extracts STRIPE_SECRET_KEY value
    |
    v
Uses secret for API call; secret never written to any config or log
```
