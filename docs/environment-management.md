# Environment Management

How JitNeuro manages credentials, services, and integrations through a pointer registry pattern -- and why this is better than environment variable substitution for AI-first workflows.

---

## The Problem

AI coding agents need credentials. Traditional approaches either:
1. Store secrets in config files (dangerous -- config gets committed, cached, logged)
2. Use `${VAR}` placeholder substitution (requires a parser, round-trip preservation, and runtime code)

Both approaches were designed for code-reads-config workflows. In JitNeuro, Claude reads config. Claude doesn't need variables resolved -- it can follow a pointer.

---

## The Solution: Pointer Registry

JitNeuro uses `workspace.json` as a centralized registry that POINTS TO where secrets live, without ever containing them.

### Location

```
.claude/workspace.json
```

This file is safe to commit. It contains zero secrets -- only pointers to `.env` files and vault references.

### How It Works

1. Claude needs a Stripe API key
2. Claude reads `workspace.json`, finds `credentials.stripe.envFile` and `credentials.stripe.keyNames`
3. Claude reads the `.env` file at that path, extracts the key
4. The secret never enters `workspace.json`, conversation context, or any committed file

### What It Tracks

| Section | Purpose | Example |
|---------|---------|---------|
| `vaults` | Credential storage systems with migration status | Azure Key Vault, Keeper |
| `credentials` | Integration pointers: envFile path, key names, purpose, vault targets | Stripe, Ghost, GitHub |
| `envFiles` | Map of all `.env` file locations and their purpose | Central .env, per-repo .env files |
| `services` | Infrastructure with per-environment URLs and health endpoints | API servers, auth services |
| `domains` | DNS and hosting configuration | Primary domains, redirects |
| `sendingDomains` | Email delivery configuration | Sending domains per brand |
| `tools` | Custom scripts with paths and dependencies | OAuth listeners, token refreshers |

---

## Entry Patterns

### Credential Entry

Every credential entry points to where the secret lives. The secret itself is never in workspace.json.

```json
{
  "stripe": {
    "envFile": "${WORKSPACE}/ProjectRepo/.env.prod",
    "keyNames": ["STRIPE_SECRET_KEY", "STRIPE_PUBLISHABLE_KEY", "STRIPE_WEBHOOK_SECRET"],
    "purpose": "Payments and subscriptions",
    "dashboard": "https://dashboard.stripe.com/...",
    "vaultTarget": "akv-prod",
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
| `expires` | No | ISO date string for credential expiration. `/health` flags expired entries. |
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
    "akv-prod": {
      "type": "azure-keyvault",
      "url": "https://kv-prod.vault.azure.net",
      "auth": "az CLI (DefaultAzureCredential)",
      "purpose": "Production secrets",
      "status": "planned"
    },
    "keeper": {
      "type": "keeper",
      "auth": "Keeper Desktop/CLI",
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

workspace.json tracks migration status per credential, enabling a gradual migration from `.env` files to a secrets vault without changing any other config.

### Before Migration

```json
{
  "stripe": {
    "envFile": "${WORKSPACE}/Repo/.env.prod",
    "keyNames": ["STRIPE_SECRET_KEY"],
    "vaultTarget": "akv-prod",
    "migrated": false
  }
}
```

Claude reads the `.env` file to get the secret.

### After Migration

```json
{
  "stripe": {
    "envFile": "${WORKSPACE}/Repo/.env.prod",
    "keyNames": ["STRIPE_SECRET_KEY"],
    "vaultTarget": "akv-prod",
    "vaultKey": "stripe-secret-key",
    "migrated": true
  }
}
```

Claude sees `migrated: true`, uses `az keyvault secret show --vault-name kv-prod --name stripe-secret-key` instead of reading the `.env` file.

### Migration Steps

1. Move the secret from `.env` to the target vault
2. Update workspace.json: set `"migrated": true`, add `"vaultKey": "<vault-key-name>"`
3. Claude automatically reads the vault instead of `.env`
4. No code changes, no substitution engine, no config file edits beyond workspace.json

---

## How Claude Uses workspace.json

### Rules That Govern This

Two rules ensure Claude always uses the pointer registry:

- **workspace-data.md** -- instructs Claude to read workspace.json FIRST for any credential lookup, never ask the owner where a credential is stored
- **security-guardrails.md** -- secrets belong in `.env` files ONLY, never in `.md`, `.json`, or code

### Runtime Flow

```
Owner asks Claude to call Stripe API
    |
    v
Claude reads workspace.json
    |
    v
Finds: credentials.stripe.envFile = "/path/to/.env.prod"
       credentials.stripe.keyNames = ["STRIPE_SECRET_KEY"]
       credentials.stripe.migrated = false
    |
    v
Claude reads /path/to/.env.prod
    |
    v
Extracts STRIPE_SECRET_KEY value
    |
    v
Uses key in API call -- secret never in config, never in conversation
```

If `migrated: true`:

```
Claude reads workspace.json
    |
    v
Finds: credentials.stripe.migrated = true
       credentials.stripe.vaultTarget = "akv-prod"
       credentials.stripe.vaultKey = "stripe-secret-key"
    |
    v
Looks up vault: vaults["akv-prod"].url = "https://kv-prod.vault.azure.net"
    |
    v
Runs: az keyvault secret show --vault-name kv-prod --name stripe-secret-key
    |
    v
Uses key in API call
```

---

## Comparison: Substitution vs Pointer Registry

Some frameworks (e.g., openclaw) use `${VAR}` substitution to inject secrets into config at runtime. JitNeuro takes a fundamentally different approach.

### How Substitution Works

A TypeScript engine replaces `${VAR_NAME}` placeholders in config with actual environment variable values at load time. A separate round-trip preservation module restores `${VAR}` references when writing config back. Secrets temporarily exist in the resolved config object in memory.

### How the Pointer Registry Works

workspace.json is a registry that points to where secrets live. Secrets never enter the config file, not even as placeholders. No substitution engine, no round-trip preservation, no parser. Claude reads JSON natively.

### Comparison Table

| Aspect | Substitution (e.g., openclaw) | Pointer Registry (JitNeuro) |
|--------|-------------------------------|---------------------------|
| Secrets in config | Yes (as `${VAR}` placeholders, resolved at runtime) | Never -- config points to .env files |
| Runtime dependency | Node.js + TypeScript parser | None (Claude reads JSON) |
| Code required | ~340 lines TypeScript (substitution + round-trip) | 0 lines |
| Round-trip safety | Needs preservation module to avoid losing `${VAR}` refs | Not needed -- no substitution to preserve |
| Secret leak risk | Possible if config cached post-resolve | None -- secrets stay in .env |
| Discovery | Developer must know env var names | workspace.json IS the discovery layer |
| Vault migration | Swap env var source | Explicit per-credential tracking (migrated flag + vault target) |
| Portability | Config portable (vars resolve per-machine) | Paths need adjustment per-machine (see [Path Portability](#path-portability)) |
| Committable | No (or only with placeholders) | Yes (safe, no secrets) |

### Why the Pointer Pattern is Better for AI-First Workflows

Traditional `${VAR}` substitution assumes **code** reads config. In JitNeuro, **Claude** reads config. Claude doesn't need variables resolved -- it can follow the pointer: "read this file, find this key." This is:

- **Safer** -- the secret never leaves the .env file until the moment it's used
- **Simpler** -- no parser, no round-trip, no edge cases
- **More informative** -- workspace.json describes every integration's purpose, dashboard URL, expiry, vault target
- **AI-native** -- Claude understands JSON pointers naturally; it doesn't need a substitution engine

---

## Path Portability

### The Gap

workspace.json paths are absolute (e.g., `/home/user/code/Automation/.env`). For open-source adoption, paths need to work across machines.

### The Solution

The template (`templates/workspace.json`) uses `${WORKSPACE}` as a placeholder for the workspace root path. The install script resolves this placeholder to the actual path at install time using `sed` or PowerShell string replacement.

Template:
```json
"envFile": "${WORKSPACE}/Automation/.env"
```

After install on Linux:
```json
"envFile": "/home/user/code/Automation/.env"
```

After install on Windows:
```json
"envFile": "D:\\Code\\Automation\\.env"
```

This happens ONCE at install time, not at runtime. No substitution engine needed after that.

---

## /health Integration

The `/health` command validates workspace.json as part of its diagnostic checks:

| Check | Severity | Description |
|-------|----------|-------------|
| workspace.json exists | WARN | File missing -- credential lookups will fail |
| .env files exist | WARN | Referenced .env file not found at path |
| Expired credentials | WARN | Credential has `expires` date in the past |
| Unmigrated credentials | INFO | Credential has `migrated: false` (not a problem, just visibility) |

---

## Template

A generic workspace.json template is available at `templates/workspace.json`. It includes:

- Example entries for common integrations (Stripe, Ghost, GitHub, email)
- `${WORKSPACE}` placeholders for all paths
- Vault section with `"status": "planned"` examples
- `_description` fields explaining each section

See [templates/workspace.json](../templates/workspace.json) for the full template.

---

## Quick Reference

| Question | Answer |
|----------|--------|
| Where are secrets stored? | In `.env` files. Never in workspace.json. |
| Where does Claude look first? | workspace.json -- it's the discovery layer |
| Is workspace.json safe to commit? | Yes -- it contains pointers, not secrets |
| How do I add a new integration? | Add an entry to `credentials` with `envFile`, `keyNames`, `purpose` |
| How do I migrate to a vault? | Set `migrated: true` and add `vaultKey`. See [Vault Migration Path](#vault-migration-path). |
| How do I make paths portable? | Use `${WORKSPACE}` in the template. Install script resolves it. |
