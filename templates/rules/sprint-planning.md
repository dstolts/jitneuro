# Sprint Planning and Execution

When sprint planning or holistic reviews are involved, load the sprint workflow
bundle if one exists in your project's bundles directory. It should contain:
- Holistic Plan Review (pre-execution, multi-persona evaluation, risk table)
- Holistic Execution Review (post-execution, bug flags, dead code detection)
- Planning flow (spec -> stories -> approve -> execute)
- Sprint naming, story granularity, backpressure, handoff rules
- Cross-repo sprint pattern (API first, then frontend)

**Key guardrails (always active, no bundle needed):**
- Sprint work MUST be on a feature branch or staging branch. NEVER commit directly to main.
- Git branch safety: never use `git checkout -b` without checking if the branch exists first.
- Handoff: after prepping a sprint, always end with the exact command needed to resume autonomous execution.
- Holistic reviews are mandatory -- pre-execution and post-execution.

## Cross-Repo Sprint Protocol

For each repo phase:
1. `cd [repo_path]`
2. `git checkout <staging-branch>` (or feature branch)
3. `git pull origin main`
4. `git status` -- STOP if dirty
5. Baseline build verify -- STOP if broken

After stories: build + type-check, grep pass criteria, commit per-repo.
Never mix commits across repos.
Never push without Owner's permission.
Never proceed to next repo if current fails.
Do not commit if tests fail due to sprint changes -- pre-existing failures are OK.

## Holistic Review Checklist

**Pre-execution:** Does the plan cover all affected repos? Are dependencies ordered correctly? Risk table populated?
**Post-execution:** Any dead code introduced? Any regressions? All acceptance criteria met?
