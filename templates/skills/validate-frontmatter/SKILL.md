---
type: skill
name: validate-frontmatter
purpose: BINDING tool for every agent proposing or revising YAML frontmatter on jitneuro artifacts; reads files in scope, generates or re-evaluates frontmatter against the canonical v1.1 schema (with purpose-strength self-check, sibling-awareness, snake_case normalization, custom-field preservation), and opens an Owner-reviewed PR; MUST be invoked for initial backfill, re-validation, monthly sweeps, and targeted ad-hoc maintenance.
tags: [frontmatter, metadata, validation, skill, governance, jitneuro, manifest]
scope: public
departments: [all]
owner_role: governance
schema_version: v1.1
read_when: Before proposing or revising YAML frontmatter on any jitneuro artifact, or when running initial backfill, re-validation, or monthly sweep.
last_evaluated: 2026-06-03
---

# validate-frontmatter

Single-source skill for evaluating, generating, and updating file-level frontmatter across jitneuro artifacts. Works in two modes (auto-detected per file): **initial-fill** when a file has no frontmatter, **re-validate** when frontmatter exists.

Canonical schema: `governance/FRONTMATTER-SCHEMA.md` (v1.1).

## Operating Principle

- **The skill triggers; the schema governs.** The skill's job is to produce schema-conformant proposals. Schema decisions (required fields, scope values, tag rules) live in `governance/FRONTMATTER-SCHEMA.md`, not here.
- **AI never auto-commits to main.** The skill always produces a pull request. Owner reviews + merges. No exceptions.
- **One scope, one PR.** A single invocation produces one auto-PR covering the files in that scope. Multi-folder runs (scope="all") fan out to per-folder PRs via the orchestrator pattern below.
- **Master orchestrates; sub-agents read.** When scope exceeds `--max-files`, master enumerates and dispatches clean-context sub-agents per sub-batch. Master never holds file content; only the structured proposals returned by sub-agents. See `~/.claude/rules/context-safety.md` + `~/.claude/rules/master-delegation.md`.
- **Idempotent.** Re-invoking on the same scope is safe: re-validate mode detects when proposed frontmatter equals current frontmatter and skips that file from the PR.

## When to Use This Skill

- **Initial backfill** of a folder that has no frontmatter yet (PR2 pilot + PR2 series of the rollout)
- **Re-validation** when a file's content has changed substantively and the frontmatter may be stale (Owner-driven OR caught by the PR-CHECKLIST gate)
- **Monthly straggler sweep** -- calendared invocation with `scope=all`
- **Targeted ad-hoc invocation** -- "validate frontmatter on the API agents"; "validate frontmatter on `org/cmo/managers/`"

Not the right tool for:

- Editing the schema itself (edit `governance/FRONTMATTER-SCHEMA.md`)
- Generating the manifest VIEW (that is `scripts/rebuild-manifest.py` after PR3 lands)
- Reviewing a PR's frontmatter inline (that is the PR-CHECKLIST + CI passive warning)

## Inputs

| Field | Required | Default | Source |
|---|---|---|---|
| `scope` | yes | -- | Directory path (`governance/`), file list (`"skills/oc-review/SKILL.md skills/map-repo/SKILL.md"`), or `all` |
| `--max-files` | no | 25 | Per-sub-agent cap; aligns `~/.claude/rules/context-safety.md` |
| `--mode` | no | `auto` | `auto` (per-file detection) \| `initial-fill` \| `re-validate` |
| `--dry-run` | no | false | Print proposals only; do not write files or open PR |

## Procedure

### 0. Sync with origin (always first)

Before any evaluation, the agent (master OR sub-agent) pulls the latest from the target base branch. Other developers may be working on the same repo; stale state risks generating frontmatter against shape that has already changed upstream.

```
git fetch origin
git checkout main
git pull origin main --ff-only
```

Sub-agents dispatched in multi-batch mode receive a "pull first" instruction in their dispatch prompt. The orchestrator sub-agent pulls; each per-folder sub-agent re-pulls before starting its batch (cheap; avoids race conditions when multiple PRs land mid-run).

### 1. Resolve scope

- If `scope` is a directory: enumerate `*.md` files (and any non-MD files in scope per FRONTMATTER-SCHEMA.md inclusion patterns)
- If `scope` is a file list: use as-is
- If `scope=all`: enumerate every in-scope file across all included directories per `governance/FRONTMATTER-SCHEMA.md` "Inclusion / exclusion"
- Apply exclusion patterns from the schema doc (skip `.github/`, `.zArchive/`, auto-generated reports, lockfiles, etc.)
- Filter to files matching FRONTMATTER-SCHEMA.md inclusion list

### 2. Dispatch to sub-agent (always, with a narrow exception)

**Default rule:** master ALWAYS dispatches a sub-agent for the per-file evaluation, regardless of file count. Master orchestrates; sub-agents read. Master never holds file content; only the structured proposals returned by sub-agents. This aligns `~/.claude/rules/master-delegation.md` and the "AI never reads at master tier" principle.

**Narrow exception (opt-in only):** if scope is <=3 files AND the invoker explicitly requests master-direct execution, master MAY do the evaluation in its own context. 3-file cap exists because spawning a sub-agent has overhead that exceeds the cost of master reading 3 small files; above that, always delegate. This is OFF by default; invoker must pass `--master-direct` to opt in.

**Multi-batch:** if resolved file count exceeds `--max-files` (default 25) per sub-agent, master enumerates and dispatches MULTIPLE sub-agents in parallel, one per <= 25-file sub-batch (see step 6).

| Scope size | Default behavior |
|---|---|
| 1-3 files | One sub-agent dispatch (default) OR master-direct if `--master-direct` |
| 4-25 files | One sub-agent dispatch (clean context; max-files cap) |
| 26+ files | Multi-batch: master enumerates + dispatches parallel sub-agents per <= 25-file sub-batch; one PR per sub-batch |

For PR2 pilot (`governance/`, 11 files): one sub-agent dispatch.
For `scope=all` (~244 files): multi-batch orchestration; ~13 sub-agents in parallel.

### 3. Per-file evaluation (sub-agent context)

Sub-agent receives: scope (file list), schema doc path, tag seed reference. Sub-agent processes each file in its scope in its own clean context. For each file in scope:

#### 3a. Read file content + existing frontmatter

```
- Parse first YAML block (if `---` at line 1)
- Existing frontmatter = parsed object (or null)
- Body = remainder
```

#### 3b. Decide mode (when `--mode=auto`)

- No frontmatter OR frontmatter missing required fields: `initial-fill`
- All required fields present: `re-validate`

#### 3c. Sibling-awareness peek (v1.1)

Before generating frontmatter, the sub-agent reads the frontmatter (NOT the body) of 1-2 sibling files in the same folder. This provides tag-style and convention consistency anchors so generated frontmatter doesn't drift from the local norm.

```
- Enumerate sibling files in the same folder (same depth)
- Pick 1-2 representatives that already have frontmatter
  - Prefer files with `last_evaluated: 2026-05` or later (recently-validated, schema-current)
  - Skip files marked `status: deprecated` or `status: tombstone`
- Read ONLY their frontmatter blocks (first YAML block; do not read bodies)
- Pass the sibling frontmatter to the generator prompt as the "local convention reference"
```

For a folder with only one file (the file being evaluated), skip this step -- no siblings exist. For top-level files (e.g., `COMPANY.md`), peek at sibling top-level files (`BRAND-VOICE.md`, `BRAND-GUIDELINES.md`).

Why: without sibling-awareness, the generator produces correct-but-inconsistent tag choices across files in the same folder. Adjacent files end up with `aeo` on one and `answer-engine-optimization` on the next, both technically valid but locally inconsistent.

#### 3d. Generate or re-evaluate frontmatter (AI evaluation)

Send to the AI with this contract:

```
Schema: <governance/FRONTMATTER-SCHEMA.md v1.1 -- required + known-optional field list>
Tag seed vocabulary: <current INDEX.md tag corpus + skill-extension rules>
Local convention reference: <1-2 sibling frontmatter blocks from step 3c, or "none">
File content: <the file body, capped at first 4000 lines>
Existing frontmatter (if any): <parsed object>

Task:
- Generate (or, in re-validate mode, propose updates to) the frontmatter
- Required fields: type, purpose, tags, scope, last_evaluated
- Optional fields per file type (charters/skills get role-specific fields)
- Optional v1.1 fields (propose ONLY when the file body positively signals their relevance):
  cadence, cadence_hook, trigger, workflow, typical_duration, typical_cost, current_limitations, charter_subtype
- Tag rules: lowercase-kebab; 3-5 tags target; prefer seed vocabulary; align with the
  local convention reference where possible; flag new tags with [NEW]
- Naming convention: snake_case for all multi-word field names (owner_role NOT owner-role,
  typical_duration NOT typical-duration); normalize kebab-case on re-validation
- Custom-field preservation (BINDING): any frontmatter field on the file that is NOT in
  the schema's required or known-optional list MUST be preserved as-is in the proposal.
  Do NOT strip unknown fields. Report them in the `unknown-fields:` proposal section.
- Cadence auto-mirror: if proposing `cadence: X` where X != on-trigger, ensure tag X is
  present in the tags array (add it if missing).
- `last_evaluated`: today (YYYY-MM-DD)

`purpose` REQUIREMENT (v1.1 -- self-check before emitting):
The purpose MUST pass the 3-question self-check. For the file you are evaluating, answer:

  1. WHO reads this? Name the actor class (master agent, specific role, specific specialist).
     "AI" alone is too generic.
  2. WHEN / in what trigger? Name the lifecycle moment (pre-publish gate, before opening a
     PR to main, at session start, when finding doc is committed). "When relevant" fails.
  3. WHAT BREAKS if they skip? Name the failure mode (missing CORS handler ships to prod,
     scan reports ship marketing scaffolding, parallel agent stomps the branch).
     If the cost-of-skipping is unstated, the purpose is decorative.

If all three are answerable from the file body: emit a purpose that NAMES at least WHO + WHEN
(WHAT-BREAKS is optional in the purpose line but should inform binding language). Use binding
verbs ("MUST be consulted by", "BINDING for ALL", "Required pre-read at", "Defines the contract
enforced by") rather than hedging verbs ("read when X needs to", "consult if relevant",
"provides guidance on").

If a binding playbook fires at MULTIPLE lifecycle stages, name them both (two-stage trigger
language): "BINDING at pre-draft AND pre-publish gates", "MUST be consulted pre-dispatch AND
at monthly-review", etc.

When the file's dominant case is a named real-world example (ExampleApp-API <-> ExampleApp-App,
"Stage 3 HeyGen avatar generation", scanner-platform <-> jit-dash), NAME IT in the purpose.
Abstract description loses agents; named examples trigger recognition.

If any of the three questions cannot be answered from the file body: flag the proposal as
`purpose-strength: WEAK` and emit the best purpose the body supports. Owner reviews; the right
fix is usually to strengthen the file's first paragraph THEN regenerate, not to ship a weak
purpose to main.

Return:
- YAML frontmatter block
- per-file rationale (3-5 sentences)
- list of any [NEW] tags introduced with justification
- `purpose-strength: STRONG | WEAK` self-assessment
- 3 short answers (one per self-check question) used in your evaluation
- `unknown-fields:` list (any custom fields preserved from existing frontmatter)
```

#### 3e. Quality check (second-agent verification)

Send the PROPOSED frontmatter alone (no file body) to a second AI agent with prompt:

```
You see ONLY the frontmatter for a file. Without reading the file:
1. What is this file for?
2. When would you read it?
3. What kind of file is this (charter / pattern / playbook / etc.)?
4. What breaks if an agent who should consult this file skips it?

Return: 4 short answers (one sentence each).
```

The orchestrator compares the second agent's answers to the file's actual top section (heading + first paragraph). Significant divergence (semantic distance > threshold OR mismatched type OR question 4 unanswerable) flags the proposal as `quality-check: NEEDS-REVIEW` in the auto-PR body. The 4th question is the v1.1 reinforcement of the purpose-strength self-check: if the second agent (which sees ONLY the frontmatter) cannot tell what breaks when an agent skips the file, the purpose is too weak.

#### 3f. Schema validation

- All required fields present
- `scope` in {public, internal, internal-only}
- `tags` is array of lowercase-kebab strings
- `last_evaluated` is ISO date
- `type` in the canonical type set
- All multi-word field names use snake_case (kebab-case names like `owner-role` flagged for normalization, not rejection)
- `cadence` (if present) in {morning-brief, weekly, monthly, quarterly, annual, on-trigger, ad-hoc}
- `charter_subtype` (if present on a charter) in {chief, manager, specialist}
- `current_limitations` (if present) is array of strings
- Unknown fields are preserved (not rejected) and reported in the `unknown-fields:` section of the PR body

Schema failures = file is set to `proposal-status: SCHEMA-FAIL` and surfaced in PR body for manual fix. snake_case normalization is NOT a schema failure -- it is an auto-fix surfaced in the PR body for Owner approval.

#### 3g. Idempotency check

If `--mode` resolves to `re-validate` AND proposed frontmatter == existing frontmatter (semantic equality, ignoring `last_evaluated` and order): skip this file from the PR.

A v1.1 re-evaluation that produces ONLY a `last_evaluated` date bump (no other change) MUST also be skipped per `~/.claude/rules/owner-preferences.md` no-noise discipline. Bumping the date without a reason is noise.

### 4. Aggregate per-file results

Build the proposal record:

```
- file: <path>
- mode: initial-fill | re-validate
- proposal-status: OK | NEEDS-REVIEW | SCHEMA-FAIL
- current-frontmatter: <object or null>
- proposed-frontmatter: <object>
- rationale: <text>
- new-tags: [<list>]
- quality-check: PASS | NEEDS-REVIEW | SKIPPED
- second-agent-answers: <text>     # now 4 answers, including "what breaks if skipped"
- purpose-strength: STRONG | WEAK   # v1.1 self-assessment
- purpose-self-check-answers:       # v1.1 -- the WHO / WHEN / WHAT-BREAKS triplet
    who: <text>
    when: <text>
    what_breaks: <text>
- normalizations:                   # v1.1 -- list of kebab-case -> snake_case renames applied
    - <e.g., "owner-role -> owner_role">
- unknown-fields:                   # v1.1 -- custom fields preserved from existing frontmatter
    - <e.g., "budget: $250/mo">
- siblings-consulted:               # v1.1 -- which sibling files informed tag/style choices
    - <path>
```

### 5. Apply + open PR

If `--dry-run`: print the aggregate report; stop.

Otherwise:
- Branch from current `main`: `frontmatter/<scope-slug>-<YYYYMMDD>`
- For each file with `proposal-status: OK`: write the frontmatter into the file (add YAML block at top; preserve body)
- For non-MD files: write sidecar `<file>.meta.yaml`
- Commit per file (so reviewer can see individual diffs cleanly), OR one commit per sub-batch if file count > 10 (commits don't add value past that point)
- Open ONE PR with:
  - Title: `frontmatter: <scope> backfill (<N> files)` for init-fill OR `frontmatter: re-validate <scope> (<N> updates)` for re-validate
  - Body sections:
    - **Summary** -- counts (N files; init-fill vs re-validate; proposal-status breakdown; purpose-strength STRONG vs WEAK count)
    - **Weak-purpose files (v1.1)** -- files with `purpose-strength: WEAK`, the 3-question self-check answers that triggered the flag, and the recommendation (usually: strengthen the file's first paragraph THEN regenerate). Owner triages.
    - **New tags** -- list of [NEW] tags introduced + per-tag justification (Owner approves; approved tags merge into seed)
    - **Quality check flags** -- files marked NEEDS-REVIEW with the second agent's divergent answers (Owner spot-check)
    - **Schema failures** -- files marked SCHEMA-FAIL with the error reason
    - **Normalizations applied (v1.1)** -- kebab-case -> snake_case renames per file; scope normalizations (`shared` -> `internal`)
    - **Custom fields preserved (v1.1)** -- per file, which non-schema fields were preserved as-is (`unknown-fields:`). Owner reviews; if a custom field is widely-used, it becomes a candidate for promotion to optional in a v1.2 schema bump.
    - **Cadence auto-mirror (v1.1)** -- files where `cadence: X` was set and tag `X` was auto-added
    - **Per-file rationale** -- the AI's reasoning for each file's frontmatter (first 3-5 batches; can be summarized later)

### 6. Multi-batch orchestrator pattern (scope > --max-files)

When file count exceeds `--max-files`, master MUST orchestrate via multiple sub-agents in parallel. Master never reads file content. (Note: this is mandatory for >25 files; sub-agent dispatch is also the DEFAULT for 4-25 files per step 2. Difference: 4-25 files = one sub-agent; >25 files = multiple parallel sub-agents.)

#### 6a. Enumerate

Master groups resolved files by parent folder; sub-batches large folders.

```
- governance/ (11)        -> 1 sub-agent
- skills/ (30)            -> 2 sub-agents (skills-a, skills-b)
- org/architect/ (8)      -> 1 sub-agent
- org/cmo/managers/ (15)  -> 1 sub-agent
- ...
```

Sub-batches MUST be <= `--max-files`.

#### 6b. Dispatch

For each sub-batch: master dispatches a Sonnet sub-agent with the sub-batch scope. Each sub-agent runs steps 3-4 in its own clean context. Sub-agent returns the aggregated proposal record (step 4 output) ONLY -- NOT file content.

#### 6c. Apply + open one PR per sub-batch

Master, holding only structured proposals, applies the writes per step 5. One PR per sub-batch.

Reason for per-sub-batch PRs (not one mega-PR): review session sanity (Owner can spot-check 25 files per sitting, not 244) + failure isolation (a bad batch rejects without losing the rest).

## QA Gates

Reject or revise the output if any of these are true:

- The skill auto-commits to `main` (must always be a PR; Owner is the gate)
- The skill produces frontmatter that fails schema validation but proceeds silently (must surface as `SCHEMA-FAIL` in the PR body)
- The skill skips the quality-check second-agent verification
- The skill mutates a file's BODY (frontmatter changes only; body untouched)
- The skill writes frontmatter to files matching the exclusion patterns in `governance/FRONTMATTER-SCHEMA.md`
- Master reads file content directly in any mode -- including small (4-25 file) batches. Default is always-delegate-to-sub-agent regardless of batch size; master-direct is gated behind `--master-direct` flag and capped at 3 files.
- Sub-agents skip the step-0 `git pull origin <base>` sync before reading files (stale-state risk; other developers may be active in the same repo)
- The skill produces NEW tags without flagging them as `[NEW]` in the PR body for Owner approval
- The skill normalizes `scope: shared` to `scope: internal` without surfacing the change in the PR body (existing-skill scope normalization is a visible, reviewable change, not a silent rewrite)
- The skill modifies `last_evaluated` on files where no other frontmatter field changed (idempotency: bumping the date without a reason is noise)
- **v1.1**: The skill emits a `purpose` that fails the 3-question self-check without flagging it as `purpose-strength: WEAK` in the PR body
- **v1.1**: The skill skips the sibling-awareness peek (step 3c) when sibling files with frontmatter exist
- **v1.1**: The skill STRIPS a non-schema field from existing frontmatter instead of preserving it under `unknown-fields:` (PRESERVE-ALL-FIELDS is binding; the org/A backfill incident is the cited origin)
- **v1.1**: The skill emits kebab-case multi-word field names (`owner-role`, `typical-duration`) instead of snake_case
- **v1.1**: The skill sets `cadence: X` (X != on-trigger) without also ensuring tag `X` is present in the tags array

## Required Tooling

- `gh` CLI authenticated to `<you>/jitneuro`
- AI agent dispatch capability (Sonnet by default; tier per `~/.claude/rules/system-processes.md`)
- File system access to the jitneuro clone

## Example Usage

### Pilot (PR2 first batch)

```
validate-frontmatter governance/
```

Runs single-batch (11 files); opens PR `frontmatter: governance/ backfill (11 files)` against `main`.

### Folder-by-folder rollout

```
validate-frontmatter _patterns/
validate-frontmatter workflows/
validate-frontmatter playbooks/
validate-frontmatter skills/
validate-frontmatter org/architect/
validate-frontmatter org/cmo/
...
```

### Big-folder split (org/)

```
validate-frontmatter "org/architect/ org/architect/managers/engineering-lead/ org/architect/managers/qa-lead/" --max-files=25
```

Master groups into one sub-batch; one PR.

### Targeted re-validation

```
validate-frontmatter "skills/oc-review/SKILL.md skills/map-repo/SKILL.md" --mode=re-validate
```

Owner asks the skill to re-evaluate two specific files. Skill returns drift if any; opens PR only if changes needed.

### Monthly straggler sweep (calendared)

```
validate-frontmatter all
```

Multi-batch mode. Master fans out to per-folder sub-agents. One PR per folder. Owner reviews ~13 PRs (or skips if no drift).

### Dry-run inspection

```
validate-frontmatter governance/ --dry-run
```

Prints proposals; opens no PR. Useful when piloting a new prompt revision.

## After This Skill Completes

- The PR(s) the skill opens are the durable record
- Owner reviews + merges (RED zone: never AI-merged)
- Approved [NEW] tags get added to the seed vocabulary in a follow-up PR (manual; one tag-vocab update per quarter is fine)
- `scripts/rebuild-manifest.py` (after PR3 lands) reads the frontmatter and regenerates INDEX.md manifest section automatically

## Related

- `governance/FRONTMATTER-SCHEMA.md` -- the canonical schema this skill conforms to (v1.1)
- `governance/PROMOTION-CRITERIA.md` -- updated in PR4 to require frontmatter on new artifacts
- `governance/PR-CHECKLIST.md` -- updated in PR4 with frontmatter-eval checkbox
- `scripts/rebuild-manifest.py` -- updated in PR3 to read frontmatter
- `.github/workflows/manifest-check.yml` -- gains a schema-validate step in PR4
- `~/.claude/rules/context-safety.md` -- binding for the 25-file orchestrator cap
- `~/.claude/rules/master-delegation.md` -- binding for the master-orchestrates-sub-agents-read pattern
- `~/.claude/rules/system-processes.md` -- Sonnet vs Haiku per task type
- `~/.claude/rules/owner-preferences.md` -- ASCII-only output; no-noise idempotency
- `skills/oc-review/SKILL.md` -- precedent skill following the same shape (trigger + charter chain)

## v1.1 changelog (2026-05-14)

Bumped from v1 to v1.1. Schema and behavior changes are all additive (no breaking changes for existing v1 frontmatter).

**Schema (governance/FRONTMATTER-SCHEMA.md):**
- New optional fields: `cadence`, `cadence_hook`, `trigger`, `workflow`, `typical_duration`, `typical_cost`, `current_limitations`, `charter_subtype`
- snake_case naming convention now binding; kebab-case auto-normalized on re-validation
- Cadence -> tag auto-mirroring rule (`cadence: morning-brief` -> tag `morning-brief`)
- Custom-field preservation (PRESERVE-ALL-FIELDS) made binding

**Skill (this file):**
- Sibling-awareness peek (step 3c) -- read 1-2 sibling frontmatter blocks before generating, for local convention consistency
- Purpose-strength 3-question self-check (WHO / WHEN / WHAT BREAKS) baked into generator prompt
- Two-stage trigger language guidance ("BINDING at pre-draft AND pre-publish")
- Named real-world example convention ("ExampleApp-API <-> ExampleApp-App" beats "two integrated repos")
- Binding-verb vocabulary (MUST be consulted by, BINDING for ALL, Required pre-read at) vs hedging-verb avoidance
- Quality-check second-agent prompt gained a 4th question ("what breaks if an agent skips this?") as cross-check on purpose strength
- Proposal record gained `purpose-strength`, `purpose-self-check-answers`, `normalizations`, `unknown-fields`, `siblings-consulted` fields
- PR body gained Weak-purpose, Normalizations, Custom fields preserved, Cadence auto-mirror sections

**Why each change:**
The 2026-05-13/14 frontmatter program shipped ~20+ PRs across the repo. Spot-check review revealed a dozen files where the AI-generated purpose was technically schema-conformant but practically weak -- it stated WHAT the file is without naming WHO reads it, WHEN, or WHAT BREAKS if skipped. Hedging language ("read when X needs to") lost agents that needed binding signal. Inconsistent tag choices across siblings created drift. One backfill batch stripped custom charter fields (`budget`, `validates`, `escalates_when`) because the generator treated unknown fields as removable. v1.1 addresses these as root cause -- the SKILL enforces strength criteria so future runs don't regenerate the same weaknesses.
