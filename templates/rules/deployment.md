---
paths:
  - "deploy/**"
  - "Dockerfile"
  - "docker-compose*"
  - ".github/workflows/**"
  - ".azure/**"
  - "vercel.json"
  - "netlify.toml"
---

# Deployment Rules (Only loaded when working with deployment files)

<!--
  This rule file only loads into context when Claude is working with
  files matching the paths above. This is automatic path-scoped loading --
  a lightweight alternative to bundles for rules that are file-type specific.

  Use rules/ for: coding standards, linting preferences, file-type conventions
  Use bundles/ for: domain knowledge, architecture, commands, workflows
-->

- Never deploy directly to production without staging verification
- All environment variables must be documented in .env.example
- Container images must have explicit version tags (never use :latest in production)
- Health check endpoints required for all services
- Rollback plan must exist before deploying breaking changes
- Log deployment timestamp, version, and deployer to audit trail
- Verify DNS/SSL certificates are valid before cutover
- Database migrations run BEFORE code deployment (not after)
