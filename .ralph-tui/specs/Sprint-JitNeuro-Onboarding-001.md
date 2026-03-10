# Sprint-JitNeuro-Onboarding-001

**Goal:** Reduce onboarding friction from ~12 manual steps to 3 (install, restart, verify) across all user scenarios
**Status:** PENDING APPROVAL
**Branch:** sprint-jitneuro-onboarding-001
**Commit prefix:** [Ralph] ONB-
**Created:** 2026-03-10

---

## Prerequisites: Sprint-JitNeuro-PRRules-001

PR rules must be configured on the GitHub repo BEFORE this sprint begins, so all sprint work flows through PRs.

### US-PR-001: Configure GitHub branch protection on main
**Priority:** P0 (Prerequisite)
**Description:** Set up branch protection rules on `dstolts/jitneuro` main branch via GitHub settings or `gh` CLI. All changes must go through PRs -- no direct pushes to main.
**Acceptance Criteria:**
- [ ] Main branch requires PR before merging
- [ ] At least 1 approval required (can be self for solo repo)
- [ ] Status checks not required initially (no CI yet)
- [ ] Force push disabled on main
- [ ] Branch deletion protection enabled on main
- [ ] Verified: direct push to main is rejected

### US-PR-002: Create PR template
**Priority:** P1
**Description:** Add `.github/pull_request_template.md` with summary, test plan, and checklist sections. Keeps PRs consistent.
**Files:** .github/pull_request_template.md (NEW)
**Acceptance Criteria:**
- [ ] Template includes: Summary, Test Plan, Checklist
- [ ] Template appears automatically when creating PR on GitHub
- [ ] Checklist includes: docs updated, /verify passes, tested on bash + PowerShell

**Execution:** Run US-PR-001 and US-PR-002 first (on main, since branch protection doesn't exist yet). Then all onboarding sprint work goes through PRs on sprint-jitneuro-onboarding-001 branch.

---

## Onboarding Scenarios

| # | Scenario | Current Experience | Friction | Sprint? |
|---|----------|-------------------|----------|---------|
| S1 | Fresh install, no existing repos | Install works. User must manually configure hooks JSON, create CLAUDE.md, bundles, engrams. 12+ manual steps. | HIGH | YES |
| S2 | Fresh install, existing repos WITHOUT JitNeuro context | Install creates workspace .claude/ but repos have no brainstem, no engrams. User must /onboard each repo manually. No prompt to do so. | HIGH | YES |
| S3 | Fresh install, existing repos WITH JitNeuro context (already in git) | Works if user ran git pull first. No prompt to pull. If repos are behind, same as S2. | MEDIUM | YES |
| S4 | Multi-machine sync (same user, 2nd machine) | Dan's exact scenario. Repos cloned but behind. Workspace .claude/ doesn't exist. Must install + onboard each repo. No guidance. | HIGH | YES (core scenario) |
| S5 | Re-install / upgrade (new JitNeuro version) | Commands + hooks overwrite (safe). Manifest, bundles, engrams preserved (safe). But no changelog, no "what's new", no version tracking. | LOW | YES (small) |
| S6 | Team member joining existing workspace | Workspace .claude/ exists (committed). But new member's machine needs user-level hooks config. No team onboarding guide. MEMORY.md merge conflicts possible. | MEDIUM | DEFER (v0.2) |
| S7 | Adding to existing Claude Code setup (user has custom commands) | Commands silently overwritten with -Force. No backup, no warning, no merge. User loses custom commands with same names. | HIGH | YES |
| S8 | Windows-specific friction | Hooks require bash (Git Bash/WSL). Path separators mixed. No detection or guidance. | MEDIUM | YES |
| S9 | Project-mode install (single repo) | Works but hooks config still manual. Simpler than workspace but same friction points. | MEDIUM | YES (covered by S1 fixes) |
| S10 | User-mode install (global ~/.claude/) | Works but hooks apply to ALL projects. No per-project override guidance. | LOW | DEFER |
| S11 | Post-install: hooks not configured | #1 friction point. Manual JSON editing. No validation. No test. User doesn't know if hooks work. | CRITICAL | YES |
| S12 | Post-install: "what do I do now?" | No first-time checklist. No guided setup. 5 manual steps listed as equal priority. | HIGH | YES |
| S13 | Onboarding new repo into existing workspace | /onboard works but is manual. No auto-discovery of unonboarded repos. | MEDIUM | YES (covered by S2) |
| S14 | Upgrading JitNeuro (new commands, hooks changed) | No version tracking. No diff of what changed. User doesn't know if they need to re-run install. | LOW | DEFER (v0.2) |

---

## Problem Statement

JitNeuro installation creates the file structure but leaves the user with 8-12 manual steps before the system is functional. The biggest gaps:

1. **Hooks require manual JSON editing** -- no auto-configuration, no validation, no test
2. **Existing repos get no context** -- install doesn't scan workspace for repos to onboard
3. **No git sync awareness** -- repos may be behind, missing committed CLAUDE.md files
4. **No post-install verification** -- user doesn't know if setup is complete or broken
5. **Custom commands silently overwritten** -- no backup, no warning
6. **No multi-machine guidance** -- 2nd machine setup is undocumented

## Scope

### In Scope
- Auto-configure hooks in settings.local.json (S1, S11)
- Post-install repo scan + batch onboard prompt (S2, S4, S13)
- Git sync check for stale repos (S3, S4)
- Post-install verification command (S12)
- Backup existing commands before overwrite (S7)
- Windows bash detection + guidance (S8)
- Upgrade detection (S5, minimal)
- Update install scripts (bash + PowerShell)
- Update docs (QUICKSTART.md, setup-guide.md)

### Out of Scope
- Team collaboration patterns / MEMORY.md merge handling (S6 -- v0.2)
- User-mode per-project overrides (S10 -- v0.2)
- Full upgrade/migration system with changelogs (S14 -- v0.2)
- Interactive TUI installer
- CI/CD integration

---

## Cross-Cutting: Shared Data Files (Holistic Review Addition)

Both install scripts must NOT hardcode command lists, version numbers, or hooks
config. Instead, extract to shared single-source files:
- **VERSION** (repo root): single version string, read by both scripts
- **jitneuro-hooks.json** (templates/hooks/): extended with hookEvents array,
  both scripts build settings.local.json from this
- **Command list**: dynamic scan of templates/commands/*.md (no arrays)

This eliminates the #1 maintenance drift risk identified in review.

## User Stories

### US-001: Auto-configure hooks in settings.local.json
**Priority:** P0 (Critical -- #1 friction point)
**Description:** After copying hook files, install script should create or merge hooks config into settings.local.json. Atomic writes, path quoting, PS 5.1 compat. When jq missing and existing settings exist, SKIP merge (don't destroy config). Build hooks config from shared jitneuro-hooks.json.
**Files:** install.sh, install.ps1, templates/hooks/jitneuro-hooks.json, .gitignore
**Acceptance Criteria:**
- [ ] Install creates settings.local.json if it doesn't exist
- [ ] Install merges hooks into existing settings.local.json without overwriting other config
- [ ] No jq + existing settings: SKIP merge, warn, existing file UNTOUCHED
- [ ] No jq + no existing settings: create hooks-only file
- [ ] All paths quoted in generated JSON (handles spaces in paths)
- [ ] Atomic write: temp file then mv/rename (no partial writes)
- [ ] Hook scripts chmod 500, hooks dir chmod 700 (Linux/Mac)
- [ ] PowerShell 5.1 compatible (no -AsHashtable)
- [ ] Hooks config built from jitneuro-hooks.json (single source of truth)
- [ ] *.backup added to .gitignore
- [ ] After install + restart, all 4 hooks fire correctly

### US-002: Backup existing commands before overwrite
**Priority:** P1
**Description:** Before overwriting commands, diff against source. If different, back up to `.backup/` (most recent only -- git handles history). Use dynamic command list from templates/commands/ scan.
**Files:** install.sh, install.ps1
**Acceptance Criteria:**
- [ ] Existing commands backed up to .claude/commands/.backup/ before overwrite
- [ ] Only backs up commands that differ from source (skip identical files)
- [ ] Single backup copy (most recent), not timestamped
- [ ] Command list dynamic (scan templates/commands/*.md, no hardcoded array)
- [ ] User informed: "Backed up N existing commands to .backup/"
- [ ] If no conflicts, no backup created (clean output)

### US-003: Post-install workspace repo scan
**Priority:** P0
**Description:** After install (workspace mode), scan workspace for git repos and show JitNeuro status. Cap display at 30 repos. Truncate long names. No network operations.
**Files:** install.sh, install.ps1
**Acceptance Criteria:**
- [ ] Detects all directories with .git/ under workspace root (1 level deep)
- [ ] Reports status table: repo name, CLAUDE.md, brainstem, engram
- [ ] Skips .claude/ and jitneuro directories
- [ ] Long repo names truncated at 20 chars
- [ ] Large workspaces capped at 30 repos displayed
- [ ] Suggests /onboard or git pull for repos missing context
- [ ] Works on both bash and PowerShell

### US-004: Git sync check (SIMPLIFIED -- deferred to /onboard)
**Priority:** P2
**Description:** Per holistic review (all 4 reviewers flagged), remove git fetch from install scripts. /onboard already handles git sync in interactive context where auth issues can be addressed. Install just adds a tip line after repo scan.
**Acceptance Criteria:**
- [ ] No git fetch in install scripts
- [ ] Tip line after repo scan: "/onboard checks if repos are behind their remote"
- [ ] /onboard handles git sync interactively (verified in US-009)

### US-005: Windows bash detection and guidance
**Priority:** P1
**Description:** Detect bash on Windows. Check Git Bash standard + Scoop/Chocolatey paths. Validate with `bash --version` (filter shims). WSL detected but explicitly not supported for hooks.
**Files:** install.ps1
**Acceptance Criteria:**
- [ ] Checks Git Bash standard, Scoop, Chocolatey paths
- [ ] Validates "GNU bash" via --version (filters shims)
- [ ] WSL: detected but warns "not supported for hooks"
- [ ] If found: uses detected path with forward slashes in hooks config
- [ ] If not found: warns, install continues, commands work without bash

### US-006: Post-install verification command (/verify)
**Priority:** P0
**Description:** /verify checks 9 components and reports status. Validates hook event names and script paths. Uses relative paths in output. Checks .jitneuro-version for install completeness. Read-only.
**Files:** templates/commands/verify.md (NEW)
**Acceptance Criteria:**
- [ ] Checks 9 components: install version, commands, hooks files, hooks config, bundles, engrams, manifest, current repo, MEMORY.md
- [ ] Validates hook event names against known Claude Code events
- [ ] Validates hook script paths exist on disk
- [ ] Checks .jitneuro-version for install completeness
- [ ] Uses relative paths in output (no full system paths)
- [ ] Reports GREEN/YELLOW/RED with specific fix instructions
- [ ] Suggests /save to functionally test hooks fire
- [ ] Read-only (no file modifications)

### US-007: Upgrade detection
**Priority:** P2
**Description:** Read version from VERSION file (single source of truth). Detect pre-versioned installs. Write .jitneuro-version LAST to signal complete install.
**Files:** install.sh, install.ps1, VERSION (NEW)
**Acceptance Criteria:**
- [ ] VERSION file at repo root (single source of truth)
- [ ] Both scripts read from VERSION (no hardcoded version strings)
- [ ] Detects pre-versioned installs (commands exist but no version file)
- [ ] .jitneuro-version written LAST (signals complete install)
- [ ] Interrupted install: no version file = detectable by /verify

### US-008: Update QUICKSTART.md and setup-guide.md
**Priority:** P1
**Description:** Update docs for automated flow. Add scenario sections, Windows notes, troubleshooting FAQ.
**Files:** QUICKSTART.md, docs/setup-guide.md
**Acceptance Criteria:**
- [ ] QUICKSTART reduced to 4 steps: Clone, Install, Restart, /verify
- [ ] No manual hooks config step (automated by US-001)
- [ ] Setup guide has scenario sections: fresh install, multi-machine, existing repos, upgrade
- [ ] Windows section: bash detection, WSL not supported, PowerShell 5.1+
- [ ] Note: repo scan output shows repo names in terminal
- [ ] Troubleshooting FAQ: 6+ common issues (bash, hooks, jq, interrupted install)

### US-011: Split README.md into README + docs/concepts.md
**Priority:** P1
**Description:** README.md is 439 lines -- too long for a GitHub landing page. Move deep-dive content to docs/ and keep README as a concise overview (~200 lines) with links. Preserves all content, just reorganizes for scanability.
**Files:** README.md (REWRITE), docs/concepts.md (NEW), docs/architecture.md (NEW)
**Acceptance Criteria:**
- [ ] README.md under 220 lines
- [ ] Key Concepts section replaced with 4-line summary + link to docs/concepts.md
- [ ] Neural Network Mapping table moved to docs/architecture.md
- [ ] Conversation Logging detail moved to docs/commands-reference.md or concepts.md
- [ ] Context Budget + Size Limits moved to docs/concepts.md
- [ ] Primitives Used table moved to docs/architecture.md
- [ ] Lineage section moved to docs/architecture.md or removed
- [ ] All moved content linked from README (no broken references)
- [ ] docs/concepts.md has anchor IDs for deep links (#bundles, #engrams, etc.)
- [ ] Quick Start, Architecture diagram, Roadmap, Disclaimer remain in README

### US-009: Smarter /onboard -- scan, refresh, git-aware
**Priority:** P1
**Description:** Upgrade /onboard instructions so Claude handles all scenarios naturally. `/onboard` with no args scans workspace and shows status table. `/onboard <repo>` checks existing state -- if already onboarded but stale, offers refresh instead of regenerating. If repo is behind remote and CLAUDE.md exists on remote, suggests pulling first.
**Files:** templates/commands/onboard.md (DONE -- already updated)
**Acceptance Criteria:**
- [ ] `/onboard` (no args) scans workspace, shows repo status table
- [ ] `/onboard <repo>` on already-onboarded repo detects staleness and offers refresh
- [ ] Git fetch check: if CLAUDE.md on remote but not local, suggests pull first
- [ ] Offers to create a bundle after onboarding: "/bundle <domain> to generate one"
- [ ] Each file still requires approval before writing

### US-010: Smarter /bundle -- create, refresh, split, manifest sync
**Priority:** P1
**Description:** Upgrade /bundle instructions so Claude handles the full lifecycle. `/bundle <name>` on a missing bundle offers to create it by analyzing workspace repos/domains. `/bundle` with no args checks manifest health. Supports refresh and split through natural language.
**Files:** templates/commands/bundle.md (DONE -- already updated)
**Acceptance Criteria:**
- [ ] `/bundle <name>` on missing bundle: analyzes workspace, drafts bundle, asks approval
- [ ] `/bundle` (no args): lists bundles with line counts, flags manifest mismatches
- [ ] Refresh: "refresh the blog bundle" re-analyzes source and shows diff
- [ ] Split: over-80-line bundles get split suggestion with proposed names
- [ ] After any write: updates context-manifest.md automatically
- [ ] Suggests routing weight entries for MEMORY.md

### US-012: Switch PreCompact hook default to block mode
**Priority:** P0 (Critical -- data loss prevention)
**Description:** Change jitneuro-hooks.json default from "warn" to "block". Warn mode injects a message asking Claude to offer /save, but Claude can ignore it under context pressure. Block mode (exit 2) halts compaction until the user responds -- no silent context loss. Update template, install scripts, docs, and /verify to reflect block as default.
**Files:** templates/hooks/jitneuro-hooks.json, docs/hooks-guide.md
**Acceptance Criteria:**
- [ ] templates/hooks/jitneuro-hooks.json: preCompactBehavior default is "block"
- [ ] Fresh install sets block mode
- [ ] Existing installs: jitneuro-hooks.json updated on re-install (file is overwritten by install scripts)
- [ ] docs/hooks-guide.md documents block vs warn behavior and how to switch
- [ ] /verify checks preCompactBehavior value and warns if set to "warn"

### US-HER: Holistic Execution Review
**Priority:** Required
**Description:** Post-execution review from 4 personas (Architect, Maintenance, Reliability, Security).
**Acceptance Criteria:**
- [ ] All story ACs validated
- [ ] No dead code introduced
- [ ] No spec deviations
- [ ] Install scripts tested on both bash and PowerShell

---

## Execution Order

| Order | Story | Risk | Est | Dependencies |
|-------|-------|------|-----|-------------|
| 0a | US-PR-001 | Low | 10m | None (on main, before branch protection) |
| 0b | US-PR-002 | Low | 10m | None (on main) |
| 1 | Cross-cutting | Low | 10m | Create VERSION, update jitneuro-hooks.json |
| 2 | US-005 | Med | 15m | None (Windows bash detection) |
| 3 | US-001 | High | 40m | US-005 (bash path), cross-cutting (hooks JSON) |
| 4 | US-002 | Low | 15m | Cross-cutting (dynamic command list) |
| 5 | US-003 | Low | 20m | None |
| 6 | US-004 | Low | 5m | US-003 (add tip line) |
| 7 | US-007 | Low | 15m | Cross-cutting (VERSION file) |
| 8 | US-009 | Low | 5m | DONE (commit updated onboard.md) |
| 9 | US-010 | Low | 5m | DONE (commit updated bundle.md) |
| 10 | US-006 | Med | 25m | US-001 (knows what to verify) |
| 11 | US-011 | Low | 20m | None (can run in parallel) |
| 12 | US-012 | Low | 10m | None (config + docs) |
| 13 | US-008 | Low | 20m | All above (documents final flow) |
| 14 | US-HER | -- | 15m | All above |

**Total estimated: ~3.75 hours**

**Note:** US-009 and US-010 are already done -- the command templates (onboard.md,
bundle.md) were updated with smarter instructions as part of spec creation.

---

## Deferred to v0.2 (Sprint-JitNeuro-Onboarding-002)

| Scenario | Why Deferred |
|----------|-------------|
| S6: Team member joining | Requires MEMORY.md merge strategy, shared vs personal bundle separation. |
| S10: User-mode per-project overrides | Edge case. Most users use workspace or project mode. |
| S14: Full upgrade/migration system | Needs changelog generation. Over-engineering for v0.1. |
| Interactive TUI installer | Nice-to-have. CLI is sufficient for developer audience. |
| Worktree context bootstrap | WorktreeCreate hook to symlink bundles/engrams. No real users hitting this yet. Revisit when worktree adoption grows. |
| Cross-worktree /status | Show worktree state alongside repos. Premature -- worktrees not widely used. |
| Worktree-aware /save + /load | Capture worktree state in checkpoints. Premature -- same reason. |

---

## Risk Assessment (Updated Post-Holistic Review)

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| settings.local.json merge corrupts config | Medium | High | Atomic write (temp+rename). Backup first. No-jq = skip merge. |
| Windows bash detection finds shim | Low | Medium | Validate with `bash --version`, require "GNU bash" |
| Hook file tampering in shared workspace | Low | Medium | chmod 700/500 on hooks dir/scripts |
| /verify false confidence (GREEN but broken) | Low | Medium | Validate hook paths exist. Suggest /save as functional test. |
| Partial install (interrupted) | Low | Medium | Write .jitneuro-version LAST. /verify checks for it. |
| Dual-script maintenance drift | Medium | Medium | Shared data files (VERSION, hooks JSON, dynamic cmd list) |
| Command overwrite loses customizations | Medium | Low | Backup to .backup/ before overwrite |
| Path injection in hooks JSON | Low | High | Quote all paths in generated JSON |
