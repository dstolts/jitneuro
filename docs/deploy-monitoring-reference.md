# Deploy Monitoring Reference

Customization guide for the deploy-monitoring rule. The rule auto-detects GitHub Actions, Vercel, and Azure Pipelines. This doc covers adding other CI/CD systems and per-repo overrides.

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

### Vercel Detection

```
# Check if Vercel project
test -f [repo]/vercel.json && echo "VERCEL"

# Get latest deployment (if Vercel CLI available)
vercel ls --token $VERCEL_TOKEN | head -5

# Or via API (if token in .env)
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v6/deployments?projectId=[id]&limit=1"
```

### Azure Detection

```
# Check if Azure Pipelines project
test -f [repo]/azure-pipelines.yml && echo "AZURE"

# Or check for .github/workflows referencing Azure
grep -l "azure" [repo]/.github/workflows/*.yml 2>/dev/null
```

## Adding a CI/CD Provider

Edit the rule file and this reference doc. Add your provider to both the subagent prompt detection and this reference.

**In the rule's subagent prompt** (the `For no pipeline` section), add:
```
e. Check if [repo path]/Jenkinsfile exists. If yes, check Jenkins build status.
   curl -s "https://jenkins.example.com/job/[repo]/lastBuild/api/json"
```

**In the Auto-Detect section above**, add:
```
5. **If no Azure, check for Jenkins:**
   - Look for `Jenkinsfile` in the repo root
   - If found: query Jenkins API for latest build status
```

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
| Bitbucket Pipelines | `bitbucket-pipelines.yml` | Bitbucket API |
| Netlify | `netlify.toml` | `netlify status` or Netlify API |
| Railway | `railway.toml` | Railway API |
| Render | `render.yaml` | Render API |
| Fly.io | `fly.toml` | `fly status` |

## Per-Repo Override

If a repo uses an unusual setup (e.g., a custom webhook trigger, a monorepo with multiple pipelines), document it in the repo's CLAUDE.md:

```markdown
## Deployment
- **Method:** Custom webhook to internal Jenkins
- **Trigger:** Push to main fires webhook via .github/workflows/notify-jenkins.yml
- **Monitor:** curl https://jenkins.internal/job/my-app/lastBuild/api/json
```

The deploy monitoring subagent reads the repo's CLAUDE.md before falling back to auto-detection. If CLAUDE.md has a `## Deployment` section, use that method instead of guessing.

## Why Every Push

- **main:** Production deploy. Must validate.
- **uat:** Staging deploy. Must validate before promoting to main.
- **feature branches:** CI runs (tests, lint, build). Catching failures early saves time.
- **PR branches:** Same as feature. If CI fails, the PR is blocked anyway -- surface it.

Skipping monitoring on non-main branches means test failures go unnoticed until the PR review.
