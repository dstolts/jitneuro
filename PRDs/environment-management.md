# User Story: Environment Management System

**Created:** 2026-03-27
**Priority:** 85/100
**Status:** Ready for execution
**Handoff:** Agent-ready -- all context needed to implement and document is in this file

## Background

JitNeuro manages credentials and service configuration through a JSON pointer registry (`workspace.json`) rather than environment variable substitution. This approach was chosen deliberately and differs significantly from other frameworks (e.g., openclaw's `${VAR}` substitution pattern).

The system exists and is in daily production use, but is not yet documented for open-source adopters or templated for new installs.

## Current State

### workspace.json (active, production)

Located at `.claude/workspace.json`. A centralized JSON registry that maps every credential, service, and integration to its storage location.

**Credential entry pattern:**
```json
"stripe": {
  "envFile": "D:\\Code\\AIFieldSupport-API\\.env.prod",
  "keyNames": ["STRIPE_SECRET_KEY", "STRIPE_PUBLISHABLE_KEY", "STRIPE_WEBHOOK_SECRET"],
  "purpose": "AIBM/AIFS payments, subscriptions, referral credits",
  "dashboard": "https://dashboard.stripe.com/...",
  "vaultTarget": "akv-jitai-prod",
  "migrated": false
}
```

**Service entry pattern:**
```json
"aifs-api": {
  "purpose": "AIFieldSupport API",
  "environments": {
    "local": { "url": "http://localhost:3005", "health": "/health" },
    "uat": { "url": "https://aifs-api-uat.azurewebsites.net", "health": "/health" },
    "prod": { "url": "https://aifs-api.azurewebsites.net", "health": "/health" }
  }
}
```

**Vault migration tracking:**
```json
"vaults": {
  "akv-jitai-prod": {
    "type": "azure-keyvault",
    "url": "https://kv-jitai-prod.vault.azure.net",
    "auth": "az CLI (DefaultAzureCredential)",
    "status": "planned"
  },
  "keeper-personal": {
    "type": "keeper",
    "auth": "Keeper Desktop/CLI",
    "status": "active"
  }
}
```

**Key sections in workspace.json:**
- `vaults` -- credential storage systems (Azure Key Vault, Keeper) with migration status
- `credentials` -- 20+ integrations with envFile paths, key names, purpose, vault targets
- `envFiles` -- maps .env file locations to their purpose
- `services` -- infrastructure definitions with per-environment URLs and health endpoints
- `domains` -- DNS/hosting configuration
- `sendingDomains` -- email delivery configuration
- `tools` -- custom scripts with paths and dependencies

### How Claude Uses It

1. Claude needs a Stripe API key
2. Claude reads workspace.json, finds `credentials.stripe.envFile` and `credentials.stripe.keyNames`
3. Claude reads the .env file at that path, extracts the key
4. Secret never enters workspace.json, conversation context, or any committed file

### Existing Rules

- `~/.claude/rules/workspace-data.md` -- tells Claude to read workspace.json FIRST for any credential lookup
- `~/.claude/rules/security-guardrails.md` -- secrets belong in .env files ONLY, never in .md, .json, or code

## How This Differs from Openclaw's Approach

### Openclaw: `${VAR}` Substitution

Openclaw uses a TypeScript engine (`src/config/env-substitution.ts`, 204 lines) that:
- Replaces `${VAR_NAME}` placeholders in config with actual env var values at load time
- Requires a round-trip preservation module (`env-preserve.ts`, 135 lines) to restore `${VAR}` references when writing config back
- Secrets temporarily exist in the resolved config object in memory
- Requires Node.js runtime for parsing

### JitNeuro: Pointer Registry

JitNeuro's workspace.json is a registry that POINTS TO where secrets live:
- Secrets never enter the config file, even as placeholders
- No substitution engine, no round-trip preservation, no parser
- Claude reads JSON natively -- zero code, zero dependencies
- workspace.json is safe to commit (contains no secrets, only pointers)
- Discovery built-in: "what integrations do we have?" is answered by reading the file

### Comparison Table

| Aspect | Openclaw (substitution) | JitNeuro (pointer registry) |
|--------|------------------------|---------------------------|
| Secrets in config | Yes (as ${VAR} placeholders, resolved at runtime) | Never -- config points to .env files |
| Runtime dependency | Node.js + TypeScript parser | None (Claude reads JSON) |
| Code required | 340 lines TypeScript | 0 lines |
| Round-trip safety | Needs env-preserve.ts module | Not needed -- no substitution to preserve |
| Secret leak risk | Possible if config cached post-resolve | None -- secrets stay in .env |
| Discovery | Developer must know env var names | workspace.json IS the discovery layer |
| Vault migration | Swap env var source | Explicit per-credential tracking (migrated flag + vault target) |
| Portability | Config portable (vars resolve per-machine) | Paths need adjustment per-machine (see Future State) |
| Committable | No (or only with placeholders) | Yes (safe, no secrets) |

### Why the Pointer Pattern is Better for AI-First Workflows

Traditional `${VAR}` substitution assumes code reads config. In JitNeuro, Claude reads config. Claude doesn't need variables resolved -- it can follow the pointer: "read this file, find this key." This is:
- **Safer** -- secret never leaves the .env file
- **Simpler** -- no parser, no round-trip, no edge cases
- **More informative** -- workspace.json describes every integration's purpose, dashboard URL, expiry, vault target
- **AI-native** -- Claude understands JSON pointers naturally; it doesn't need a substitution engine

## Future State

### Path Portability (the one gap)

Current workspace.json has hardcoded Windows paths (`D:\\Code\\...`). For open-source adoption, paths need to work across machines.

**Solution:** Install-time path substitution using `sed` or `envsubst` in the install script. Template uses `${WORKSPACE}` placeholder, install resolves to actual path. This happens ONCE at install, not at runtime.

Template:
```json
"envFile": "${WORKSPACE}/Automation/.env"
```

Installed:
```json
"envFile": "/home/user/code/Automation/.env"
```

### Vault Migration Path

workspace.json already tracks migration status per credential:
```json
"vaultTarget": "akv-jitai-prod",
"migrated": false
```

When vault migration happens:
1. Move secret from .env to Azure Key Vault
2. Update workspace.json: `"migrated": true`, add `"vaultKey": "stripe-secret-key"`
3. Claude reads workspace.json, sees migrated=true, uses `az keyvault secret show` instead of reading .env
4. No change to any other config, no code changes, no substitution engine

## Acceptance Criteria

### AC-1: Template for Open Source
- [ ] Create `templates/workspace.json` with generic structure (no real credentials)
- [ ] Include example entries for common integrations (Stripe, Ghost, GitHub, email)
- [ ] Use `${WORKSPACE}` placeholder for all paths
- [ ] Include vault section with `"status": "planned"` examples
- [ ] Include inline comments explaining each section (JSON5 or _description fields)

### AC-2: Install Script Path Resolution
- [ ] `install.sh` resolves `${WORKSPACE}` to actual workspace path during install
- [ ] `install.ps1` does the same for Windows
- [ ] Existing workspace.json is not overwritten (merge or skip if exists)

### AC-3: Documentation
- [ ] Add workspace.json to `docs/configuration-reference.md` with full schema
- [ ] Create `docs/environment-management.md` explaining the pointer registry pattern
- [ ] Include the openclaw comparison table (from this PRD)
- [ ] Document the vault migration path
- [ ] Document how Claude uses workspace.json at runtime

### AC-4: /health Integration
- [ ] /health checks workspace.json exists
- [ ] /health validates .env files referenced in workspace.json actually exist
- [ ] /health flags credentials with `"migrated": false` as INFO (not a problem, just visibility)
- [ ] /health flags expired credentials (check `"expires"` field)

### AC-5: Open Source Readiness
- [ ] No real credentials, paths, or personal data in the template
- [ ] Generic "Owner" references throughout
- [ ] Works on Windows, Mac, and Linux
