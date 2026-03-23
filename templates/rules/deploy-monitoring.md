# Deploy Monitoring

After ANY `git push` (any branch, any repo), automatically monitor the triggered pipeline. This is non-negotiable -- every push must be validated.

## Trigger
Any successful `git push` command. All branches, all repos.

## Action
Immediately after the push succeeds, spawn a **background subagent** (`run_in_background: true`) with this prompt:

```
You are monitoring a deployment pipeline triggered by a git push.

Repo: [repo path]
Branch: [branch that was pushed]
Remote: [remote URL -- extract org/repo for gh commands]

Steps:
1. Check [repo path]/CLAUDE.md for a "## Deployment" section. If found, use that method. If not, auto-detect.
2. Wait 10 seconds for the pipeline to register.
3. gh run list --repo [org/repo] --branch [branch] --limit 1 --json databaseId,status,conclusion,name,createdAt
4. If no run after 30 seconds (3 attempts): check vercel.json, azure-pipelines.yml. If none found, return NO_PIPELINE.
5. Monitor: gh run watch [run-id] --repo [org/repo] --exit-status (or poll every 15s)
6. On failure: gh run view [run-id] --repo [org/repo] --log-failed (last 30 lines)
7. Return: DEPLOY_STATUS (SUCCESS/FAILURE/NO_PIPELINE), REPO, BRANCH, PIPELINE, DURATION, RUN_URL, ERROR_SUMMARY (if failed)
```

## Display
Show result in an ASCII box so it stands out:
```
+----------------------------------------------------------+
|  DEPLOY SUCCESS                                          |
|  Repo: org/repo  Branch: main  Duration: 2m 34s         |
|  Run: https://github.com/org/repo/actions/runs/123      |
+----------------------------------------------------------+
```
```
+----------------------------------------------------------+
|  *** DEPLOY FAILURE ***                                  |
|  Repo: org/repo  Branch: main  Duration: 1m 12s         |
|  Error: tsc found 3 errors in src/routes/api.ts         |
|  Run: https://github.com/org/repo/actions/runs/123      |
+----------------------------------------------------------+
```
```
+----------------------------------------------------------+
|  DEPLOY: NO PIPELINE DETECTED                            |
|  Repo: org/repo  Branch: feature/new-thing               |
|  No CI/CD found (checked GH Actions, Vercel, Azure).     |
+----------------------------------------------------------+
```

## Non-blocking
Subagent runs in background. Master continues working. Deploy failures are high priority -- display the ASCII box immediately when the subagent returns.

## Customization
To add CI/CD providers, configure per-repo overrides, or see the full detection cascade, see **docs/deploy-monitoring-reference.md**.
