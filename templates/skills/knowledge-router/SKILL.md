---
type: skill
name: knowledge-router
description: 'Route a captured finding (lesson, rule, pattern) to its correct durable home and deploy it -- a jit-knowledge branch+PR, a local file write, or a Hub.md append -- then audit-log it and POST it to the WS8 dashboard. Use after the master or /learn has classified a finding''s type, destination, and risk tier and needs it routed.'
purpose: BINDING for every master agent or /learn invocation routing a captured finding to its correct durable home; MUST be invoked after the master classifies a finding's breadth and destination -- skipping means the lesson lands in local volatile memory and dies there, never reaching jit-knowledge canonical or the WS8 audit dashboard.
tags: [knowledge-router, recursive-improvement, skill, routing, jit-knowledge, audit-log, learn]
scope: public
departments: [all]
read_when: After the master or /learn classifies a finding and needs to deploy it to its correct durable home in jit-knowledge, local memory, or Hub.md.
last_evaluated: 2026-06-03
---

# knowledge-router

Deterministic deploy runner for the recursive-improvement loop (WS4).

Receives a knowledge manifest from the master (or `/learn`) and deploys the finding
to its correct home: a jit-knowledge branch+PR, a local direct write, or a Hub.md
append. Appends an audit row to `knowledge-audit.log.md` and POSTs the same row to
dashboard-API `/api/knowledge` for the WS8 dashboard.

## Operating Principle

- **Master classifies; runner deploys.** The master (or `/learn`) provides ALL
  judgment: `type`, `destination`, `risk_tier`, `content`, `reason`, `source_session`.
  The runner is a pure function -- manifest in, deterministic deploy out. Zero judgment
  in the runner. A missing or unrecognized parameter causes an immediate error, never
  a guess.
- **jit-knowledge is PR-gated.** For `destination: jit-knowledge`, the runner opens
  a pull request via `gh`. It NEVER self-merges, NEVER force-pushes, NEVER touches
  main. Owner merges.
- **Idempotent.** Every manifest is hashed (SHA-256 of `destination + type + content`).
  The runner skips and reports "already deployed" if the hash is found EITHER in
  `knowledge-audit.log.md` OR in any commit message across all git branches (every
  deploy commit carries `Content hash: <hash>`). The git-history check catches
  deploys whose PR is still open and unmerged -- without it, re-routing the same
  finding before its PR merged would open a duplicate PR. No duplicate PRs, no
  duplicate audit rows.
- **Frontmatter VALIDATED, never scaffolded.** For `destination: jit-knowledge` and
  `destination: local`, the runner validates the frontmatter in `content` against
  `governance/FRONTMATTER-SCHEMA.md` (required fields: `type`, `purpose`, `tags`,
  `scope`, `last_evaluated`). If validation fails, the runner rejects. Authoring
  frontmatter belongs to the agent that knows the content -- the runner is not that
  agent.
- **Hub destination skips frontmatter.** `destination: hub` appends raw text to
  `Hub.md`'s `## Lessons Learned` section; no frontmatter is required or checked.
- **Audit log is append-only + committed.** `knowledge-audit.log.md` at the
  jit-knowledge repo root is the durable, version-controlled audit trail. For
  `destination: jit-knowledge` the audit row is appended and committed IN-BRANCH --
  it rides inside the same deploy PR as the artifact, so the committed log builds
  cleanly on merge instead of leaving uncommitted rows on `main`. The in-branch
  row's `destination` field is the target file path (the PR URL is not known at
  commit time); the dashboard-API POST records the PR URL. For `destination: local` and
  `hub` (no PR), the row is appended to the log directly. The dashboard-API POST is the
  database copy.
- **ENV vars for secrets.** The dashboard-API endpoint URL and auth token are read from
  `KNOWLEDGE_API_URL` and `KNOWLEDGE_API_TOKEN` environment variables. If absent,
  the runner logs a warning and continues -- the POST is best-effort; the local audit
  log is authoritative. `KNOWLEDGE_API_URL` MUST be the INTERNAL dashboard-API address
  (e.g. `http://localhost:3033` when the runner and dashboard-API share a host) -- NOT
  the public `dashboard-API.jitai.co`. The public hostname is Cloudflare-proxied and its
  WAF returns HTTP 403 (error 1010) to non-browser clients. Same-host service calls
  bypass the public edge (see the internal-service-to-service-bypass-edge rule).
  `KNOWLEDGE_API_TOKEN` is a JWT signed with dashboard-API's `JWT_SECRET`; dashboard-API has
  no dedicated service-token mechanism, so a long-expiry (e.g. 1-year) JWT is the
  current interim.
- **Fully deterministic, zero model.** The runner is pure code -- no step invokes an
  LLM. All judgment is upstream in the master's classification; the runner only
  executes. This is the Runners-over-tokens tenet in its purest form.
- **Invocability.** Model- and user-invocable (Anthropic skill defaults, no flags
  set). The master and `/learn` invoke it programmatically; a human may invoke it
  directly too. It is NOT model-disabled despite writing files and opening PRs,
  because every jit-knowledge deploy is PR-gated (Owner merges) and local writes are
  reversible -- the side effects are bounded and safe.

## Destination Table

| Destination | Deploy mechanism | Frontmatter required |
|---|---|---|
| `jit-knowledge` | branch + commit + PR via `gh` (Owner merges) | Yes -- validated, rejected if invalid |
| `local` | direct write to the resolved local path | Yes -- validated, rejected if invalid |
| `hub` | append to `.HUB/Hub.md` `## Lessons Learned` section | No |

Path resolution:
- `destination: jit-knowledge` -- `slug` is the repo-relative file path (e.g.,
  `rules/my-rule` -> `rules/my-rule.md`; `.md` appended if absent).
- `destination: local` -- `slug` is an absolute or `~/`-prefixed path; runner
  expands `~` to the user home dir (e.g.,
  `memory/feedback_foo` -> `~/.claude/memory/feedback_foo.md`).
- `destination: hub` -- `slug` is used as the lesson entry label only; the file
  path is always `.HUB/Hub.md` in the current working directory.

## Manifest Fields

The master assembles this JSON manifest and passes its path as the CLI argument.

### Required fields

| Field | Required | Type | Description |
|---|---|---|---|
| `type` | yes | string | Finding type: `feedback`, `project`, `reference`, `rule`, `persona`, `lesson` |
| `destination` | yes | string | One of: `jit-knowledge`, `local`, `hub` |
| `risk_tier` | yes | int | 1 (T1 auto), 2 (T2 veto-window), 3 (T3 approval) |
| `slug` | yes | string | Repo-relative path for jit-knowledge; `~/`-path for local; label for hub |
| `content` | yes | string | Full artifact text including frontmatter (YAML + body) for jk/local; raw text for hub |
| `reason` | yes | string | One-sentence rationale for routing this finding here |
| `source_session` | yes | string | Claude Code session name or ID |

All seven fields are required. Missing any one causes the runner to exit non-zero with a
clear error naming the missing field. The runner never guesses.

### Optional fields (master classification/authoring cost)

| Field | Required | Type | Description |
|---|---|---|---|
| `model` | no | string | LLM model used for classification/authoring (e.g. `claude-opus-4-7`) |
| `tokens` | no | int | Token count for the classification/authoring step |
| `cost_usd` | no | float | Cost in USD for the classification/authoring step |

These fields represent the master's upstream work -- the runner passes them through to the
dashboard-API POST as-is. The deterministic runner never computes them. Omit when the cost data
is unavailable.

## Runner Invocation

```bash
python scripts/knowledge-router.py <manifest.json>
python scripts/knowledge-router.py --dry-run <manifest.json>
```

`--dry-run`: print all planned actions; perform no file writes, git operations, or POSTs.
Exit 0 on successful plan; exit 1 on validation errors.

The master invokes the runner via Bash tool. The manifest JSON is written to a
temporary file first, then the path is passed as the CLI argument.

## What the Runner Does (step by step)

1. **Load and validate manifest.** Parse JSON. Check all required fields present and
   non-empty. Verify `destination` is one of `{jit-knowledge, local, hub}`. Exit 1
   on any failure.
2. **Compute content hash.** SHA-256 of `destination + type + content`. Hex-encode.
3. **Check idempotency.** Scan `knowledge-audit.log.md` for a row with matching hash,
   AND scan all-branch git history for a commit message carrying the hash. If found
   in either: print "already deployed"; exit 0. The git-history scan catches
   unmerged deploy PRs.
4. **Validate frontmatter** (jit-knowledge and local only). YAML-parse the leading
   `---` block from `content`. Check required fields: `type`, `purpose`, `tags`,
   `scope`, `last_evaluated`. Exit 1 naming the missing fields if invalid. NEVER
   scaffold or author missing frontmatter.
5. **Derive target path.** Apply path resolution per destination table above.
6. **Deploy + audit row.**
   - `jit-knowledge`: create branch `feat/kr-<type>-<slug-fragment>-<YYYYMMDD>`,
     write content to `<target_path>`, append the audit row to
     `knowledge-audit.log.md` IN-BRANCH, commit BOTH files, open PR via
     `gh pr create` with a title and body referencing `reason` and `source_session`.
     The audit row rides inside the deploy PR.
   - `local`: write content to the resolved local path (create parent dirs as
     needed), then append the audit row to `knowledge-audit.log.md`.
   - `hub`: append a timestamped entry to `.HUB/Hub.md` `## Lessons Learned` section
     (create the section if absent), then append the audit row.
7. **Audit row format.** One pipe-delimited row:
   `timestamp | type | slug | destination | risk_tier | source_session | content_hash | status`.
   For `jit-knowledge` the `destination` field is the target file path; for `local`
   it is the resolved file path; for `hub` it is the Hub.md path.
8. **POST to dashboard-API.** `POST $KNOWLEDGE_API_URL/api/knowledge` with the row data
   as JSON. Payload includes:
   - Core fields: `content_hash`, `change_type` (= manifest `type`), `risk_tier`,
     `destination` (resolved path or PR URL), `change_ts` (ISO-8601 UTC),
     `summary` (= `reason`), `source_session`, `trigger_type`, `agent_role`, `status`.
   - Git/PR fields (`jit-knowledge` destination only): `repo` (`"<you>/jit-knowledge"`),
     `branch` (deploy branch name), `commit_sha` (deploy commit SHA), `pr_url` (PR URL),
     `pr_number` (integer parsed from PR URL).
   - Content diff: `diff_content` -- for `jit-knowledge` = `git show <sha> --format=`;
     for `local` = the artifact `content`; for `hub` = the appended raw text.
   - Cost fields (from manifest optional fields, if present): `model`, `tokens`, `cost_usd`.
   Null/absent fields are omitted from the payload. If `KNOWLEDGE_API_URL` or
   `KNOWLEDGE_API_TOKEN` absent: log warning, skip POST, continue.
9. **Report.** Print a brief summary of what was deployed (or planned in dry-run).
   Exit 0.

## Subagent Intake (WS3 nuance)

Subagents NEVER call this skill directly. The flow is:
1. Subagent writes a frontmatter-complete lesson artifact (draft frontmatter) and
   returns a `LESSONS: <path> (<count> appended)` pointer in its STATUS return.
2. Master reads the lesson artifact to validate breadth (is this one-repo, local,
   or cross-system canonical?). Master sets `destination` and `risk_tier`.
3. Master assembles the manifest and invokes this skill.

## QA Gates

The skill output fails review if:
- The runner opens a PR to main or pushes directly to main
- The runner self-merges any PR
- The runner scaffolds or authors frontmatter (it must only validate and reject)
- A duplicate deploy occurs (idempotency check was skipped or buggy)
- A required parameter is missing but the runner infers a value anyway
- The audit log row is missing after a successful deploy
- ENV vars are absent and the runner raises an exception instead of logging a warning

## Required Tooling

- Python 3.8+ with PyYAML (`pip install pyyaml`)
- `gh` CLI authenticated to `<you>/jit-knowledge` (for `destination: jit-knowledge`)
- `KNOWLEDGE_API_URL` and `KNOWLEDGE_API_TOKEN` env vars (for dashboard-API POST; optional)
- Read/write access to the jit-knowledge clone
- Read/write access to `~/.claude/` (for `destination: local`)

## Example Invocation (master side)

```python
# Master writes manifest to temp file
import json, tempfile, subprocess, os

manifest = {
    "type": "rule",
    "destination": "jit-knowledge",
    "risk_tier": 2,
    "slug": "rules/api-test-before-e2e",
    "content": "---\ntype: rule\n...\n---\n\nBody.\n",
    "reason": "Pattern recurs in jitai-api and scanner-platform; promoting to canonical.",
    "source_session": "knowledge-master-2026-05-21"
}

with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
    json.dump(manifest, f)
    tmp = f.name

result = subprocess.run(
    ["python", "scripts/knowledge-router.py", tmp],
    cwd="<CodeBasePath>/jit-knowledge",  # resolve <CodeBasePath> per governance/path-conventions.md
    capture_output=True, text=True
)
os.unlink(tmp)

print(result.stdout)
if result.returncode != 0:
    raise RuntimeError(result.stderr)
```

## Improvement Loop

After each use of this skill, review the run: did a manifest field need explaining;
did a destination or path-resolution case come up that the runner did not handle
cleanly; did the dashboard-API payload shape drift from `/api/knowledge`. If the gap is
permanent, update this SKILL.md and `scripts/knowledge-router.py` -- do not just fix
the one run. The skill gets sharper every session (Rule 4 of the build-skill
standard).

## Related

- `projects/recursive-improvement-loop-plan.md` -- WS4 spec that defines this skill
- `governance/FRONTMATTER-SCHEMA.md` -- schema the runner validates against
- `skills/validate-frontmatter/SKILL.md` -- full frontmatter validation procedure;
  this runner reuses the required-field check (not the full PR-opening flow)
- `knowledge-audit.log.md` -- append-only local audit log this runner writes
- `skills/knowledge-router/test-scenarios.md` -- test scenarios for self-test
- `scripts/knowledge-router.py` -- the deterministic runner this skill documents
