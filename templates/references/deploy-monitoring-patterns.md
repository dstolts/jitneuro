---
type: reference
purpose: Reference guide for auto-detecting and monitoring CI/CD deployment pipelines (GitHub Actions, Vercel, Azure, Jenkins, GitLab); agents that skip this fail to detect the active pipeline and either miss failures or report NO_PIPELINE incorrectly.
read_when: Before spawning a deploy-monitor subagent or writing any pipeline detection / monitoring logic after a git push.
tags: [deployment, ci-cd, monitoring, publishable-candidate]
scope: public
departments: [engineering]
status: canonical
graduation_target: references/deploy-monitoring-patterns.md
last_evaluated: 2026-06-03
source: backport from jitneuro docs/ 2026-05-28
---

# Deploy Monitoring Reference

Customization guide for auto-detecting and monitoring deployment pipelines across multiple CI/CD systems.

## Auto-Detect Deploy Method

The subagent auto-detects the deploy method -- no manual config needed. Detection order:

1. **Check CLAUDE.md first:** If the repo has a `## Deployment` section, use the documented method. Skip auto-detection.
2. **Check GitHub Actions:** `gh run list` -- if a run appears, monitor it.
3. **If NO_PIPELINE, check for Vercel:**
   - Look for `vercel.json` in the repo root
   - Or check the repo's CLAUDE.md / engram for "Vercel" in the tech stack
   - If Vercel detected: check deployment status via Vercel CLI or API
4. **If no Vercel, check for Azure Pipelines:**
   - Look for `azure-pipelines.yml` in the repo root
   - If found: use `az pipelines runs list` or note for the user
5. **If nothing detected:** Report NO_PIPELINE

## Common CI/CD Systems and Detection Patterns

| Provider | Config File | Status Check Command |
|----------|------------|---------------------|
| GitHub Actions | `.github/workflows/*.yml` | `gh run list --repo [org/repo] --branch [branch] --limit 1` |
| Vercel | `vercel.json` | `vercel ls` or Vercel API |
| Azure Pipelines | `azure-pipelines.yml` | `az pipelines runs list` |
| Jenkins | `Jenkinsfile` | `curl https://jenkins.url/job/[name]/lastBuild/api/json` |
| GitLab CI | `.gitlab-ci.yml` | `glab ci list` or GitLab API |
| CircleCI | `.circleci/config.yml` | `circleci pipeline list` or CircleCI API |
| AWS CodePipeline | `buildspec.yml` | `aws codepipeline get-pipeline-state --name [name]` |
| Netlify | `netlify.toml` | `netlify status` or Netlify API |
| Fly.io | `fly.toml` | `fly status` |

## Per-Repo Override

If a repo uses an unusual setup (e.g., a custom webhook trigger, a monorepo with multiple pipelines), document it in the repo's CLAUDE.md:

```markdown
## Deployment
- **Method:** Custom webhook to internal Jenkins
- **Trigger:** Push to main fires webhook via .github/workflows/notify-jenkins.yml
- **Monitor:** curl https://jenkins.internal/job/my-app/lastBuild/api/json
```

The deploy monitoring agent reads the repo's CLAUDE.md before falling back to auto-detection.

## Why Every Push

- **main:** Production deploy. Must validate.
- **uat:** Staging deploy. Must validate before promoting to main.
- **feature branches:** CI runs (tests, lint, build). Catching failures early saves time.
- **PR branches:** Same as feature. If CI fails, the PR is blocked anyway.

Skipping monitoring on non-main branches means test failures go unnoticed until the PR review.
