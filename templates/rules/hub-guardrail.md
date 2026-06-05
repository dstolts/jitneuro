---
type: rule
purpose: Prohibit versioning or deleting Hub.md, define when .HUB/ is git-tracked vs gitignored, and prohibit writing secrets into Hub.md. Hub.md is the active task list -- one in-place file, never a secret store.
read_when: Before any operation that creates, renames, deletes, or archives Hub.md or .HUB/ contents -- violating this rule destroys the durable task record or leaks secrets.
tags: [hub-md, task-list, guardrail, session-state, durable-state, secrets, security]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Hub.md Guardrail

## Rules

1. **Never version Hub.md.** Hub.md is the active task list -- updated in place,
   never copied to Hub-01.md, Hub-v2.md, or any variant. There is exactly ONE
   Hub.md per `.HUB/` folder.
2. **Never delete the Hub.md FILE.** It is the durable record of task state.
   The file always remains. Completed tasks are normally marked done in place.
   **Monthly scrub exception:** during a dedicated monthly scrub session,
   completed tasks MAY be removed from Hub.md to keep it scannable. The file
   itself stays; only the closed-out task lines are pruned. Scrubs are a
   deliberate, scheduled operation -- not mid-session cleanup. Mid-work,
   completed tasks stay in place as the durable audit trail until the next
   scrub cycle.
3. **`.HUB/` is git-tracked by default; gitignored only on public repos.**
   For private and internal repos, `.HUB/` (including Hub.md) is committed to
   git so progress and Owner open questions survive across machines, sessions,
   and contributors. For public repos, Owner manually adds `.HUB/` to that
   repo's `.gitignore` so internal session state does not leak. Do NOT add a
   blanket global gitignore for `.HUB/`.
4. **No secrets in Hub.md -- ever, regardless of git-tracked state.** API keys,
   tokens, passwords, signing keys, refresh tokens, OAuth client secrets, JWTs,
   connection strings containing credentials, DB passwords, webhook signing
   secrets, and any other secret value MUST NOT appear in Hub.md. Secrets
   belong in `.env` files only.
   - On a private repo, Hub.md is readable by anyone with repo access.
   - On a public repo (where Hub.md is gitignored), the repo could become
     public-history later, OR a contributor could accidentally commit
     Hub.md, OR the gitignore could be misconfigured.
   - In either case, secrets-in-Hub.md is leaked or one accident from leaked.
   - If a secret is accidentally written into Hub.md: rotate the secret
     immediately AND scrub git history.
5. **Reference, do not embed.** When Hub.md needs to point at a secret-bearing
   value, reference the env-var name and its location, never the value itself.
   Example: "RESEND_API_KEY in `Automation/.env`" -- NOT the actual key.

## Why

Hub.md is the single source of truth for session task state. Versioning it
fragments the task list across files, causing tasks to be lost and work to be
duplicated. Deleting it destroys the only durable record of in-progress work --
in-memory task lists and session state are volatile.

Committing `.HUB/` to git on private repos preserves session state across
machines and contributors, which is the whole point of having a durable task
list. Public repos need `.HUB/` gitignored because the session-state content is
operational (not product) and the audience is internal-only.

Either way, secrets are categorically out of scope for Hub.md. The trust
boundary for Hub.md is "all repo contributors today + everyone who ever sees
the repo in the future." That is not the trust boundary for secrets. Secrets
live in `.env`, which is gitignored everywhere, on every repo.

## What Violates This Guardrail

- Creating Hub-01.md, Hub-v2.md, or any numbered/versioned variant
- Applying file-versioning rules to Hub.md (Hub.md is explicitly exempt)
- Deleting the Hub.md file or replacing it with a new one
- Moving Hub.md to an archive folder
- Removing completed-task lines outside of a scheduled monthly scrub session
  (mid-session removal destroys the audit trail; wait for the scrub cycle)
- Adding `.HUB/` to a global or workspace-wide gitignore that affects every
  repo (the gitignore for `.HUB/` is per-repo, on public repos only)
- Writing any secret value into Hub.md (rotate + scrub if it happens)
- Treating Hub.md as a "private scratchpad" -- on private repos it is
  committed and visible to every contributor; on public repos it is one
  misconfiguration away from leaking

## Related

- `~/.claude/rules/security-guardrails.md` -- secrets-in-docs rule (broader scope)
- Repo-local `.env.example` files -- canonical place to declare env vars
- `Automation/.env` (or equivalent) -- canonical place to store secret values
