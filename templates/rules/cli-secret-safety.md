---
type: rule
purpose: Prohibit passing secrets as CLI arguments and mandate stdin or heredoc or file-ref patterns to prevent secrets from appearing in shell history, process lists, or transcripts.
read_when: Before writing any shell command, script, or CI step that handles API keys, tokens, passwords, or other secret values.
tags: [security, secrets, cli, credentials, shell-safety]
scope: public
last_evaluated: 2026-06-03
---
# CLI Secret Safety

Never pass secrets (API keys, tokens, passwords, webhook signing secrets) as command-line arguments. Use stdin / heredoc / file-ref instead.

## Why

- Secrets leak in tool output, shell history, process lists (`ps`), and conversation transcripts
- PowerShell `-Args` parameter binding is fragile: quoting or escaping issues can silently replace the value with an empty string
- CLI args appear in `/proc/<pid>/cmdline`, cloud logging, CI logs

## Rules

### PowerShell
- NEVER: `pwsh -Command "... -Args $token"` -- fragile quoting
- NEVER: `az containerapp update --set-env-vars "KEY=$token"` -- visible in process list
- PREFER: Python heredoc with token inline + verify-after-write
- PREFER: Secret-file pattern: write token to temp file, pass file path, delete after

### Bash
- NEVER: `curl -H "Authorization: Bearer $(echo 'my-secret-token')" ...` where echo reveals value
- OK: `export VAR=$(grep '^KEY=' .env | cut -d= -f2-)` + use `$VAR` inline; unset after
- OK: `curl --data-binary @secret.json ...` where file is atomic + deleted

### Python heredoc (safest for one-shot updates)
```bash
python - <<'PYEOF'
tok = 'VALUE_HERE'  # already in session context so no additional leak
# edit file, verify, done
PYEOF
```

## Verify-after-write discipline

Always read the file back and validate the value landed correctly BEFORE running any downstream test. An empty or wrong value causes failures that look like unrelated errors -- diagnose immediately at the write step.
