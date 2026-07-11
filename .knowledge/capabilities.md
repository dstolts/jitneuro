---
type: reference
purpose: "Machine-queryable, per-repo Capability Index for jitneuro -- catalogs the cross-platform installer and the packaged template libraries (skills, hooks, commands, dashboard scripts, community-publish pipeline) it ships to consumer repos, so an agent (or the pre-build reuse gate, ticket 3230) can answer does existing capability cover X in one query instead of building a duplicate installer or template library. MUST be consulted before authoring a new installer entry point, template category, or publish-pipeline script in this repo."
read_when: Before building any new installer mode, template library category (skill/hook/command), or community-publish script in jitneuro, and before filing a REUSE_CHECK verdict on a new-system ticket against this repo.
tags: [capability-index, reuse-gate, duplicate-system-prevention, knowledge-index]
scope: public
departments: [all]
last_evaluated: 2026-07-11
---

# Capability Index -- jitneuro

Per-repo, machine-queryable inventory of jitneuro's own existing capabilities.
Schema, format rationale, auto-generation strategy, staleness CI design, and query
contract are defined in `dstolts/jit-knowledge` `references/capability-index-design.md`
(design of record, ticket #3227) -- this file is a fleet-rollout instance of that
design (ticket #3232, phase 3), sibling to jit-knowledge's own `.knowledge/capabilities.md`
worked example.

**SEED STATUS:** this is a hand-authored seed (fleet rollout pass), not a claim of
full coverage. 6 entries below are real and verified against `uat` (default branch)
on 2026-07-11, covering the cross-platform installer and the five template
libraries it packages (skills, hooks, commands, dashboard scripts, community
publish pipeline). jitneuro's own repo layout (`templates/skills/*/SKILL.md`,
`templates/hooks/*.sh`) does not match this tool's narrow auto-scan heuristics
(`^skills/[^/]+/SKILL\.md$`, `^templates/claude-hooks/.*\.sh$` -- anchored to a
runtime-repo layout, not a template-distribution layout), so `--refresh`'s
auto-scan currently finds zero signals here; that is expected, not a bug. Full
backfill of finer-grained entries (per-skill, per-hook) is a hand-curation
exercise for a future pass, not a mechanical one for this repo.

**Do not read this file in full at session start.** Query it (grep, or the
follow-up `query-capabilities.py` tool once built) when checking whether a
capability already exists before building a new one.

Entry format: fenced YAML block, one per capability, keyed by a stable `id:` slug
inside `<!-- CAP-START:<id> --> ... <!-- CAP-END:<id> -->` markers. Grouped by
`kind` under `## <kind>` headings. See the design doc's "Format decision" section
for why this shape was chosen over a pipe-delimited table.

---

## module

<!-- CAP-START:jitneuro-installer -->
```yaml
id: jitneuro-installer
name: Cross-Platform Installer
kind: module
purpose: Bash (install.sh) and PowerShell (install.ps1) installer that materializes templates/ into a target .claude/ scope -- workspace (parent dir, covers all repos under it), project (current repo only), or user (~/.claude/, machine-wide) -- the single entry point every adopter runs instead of hand-copying template files.
entry_points:
  - install.sh
  - install.ps1
owner_lane: jitneuro
status: verified
last_verified: 2026-07-11
```
<!-- CAP-END:jitneuro-installer -->

<!-- CAP-START:command-template-library -->
```yaml
id: command-template-library
name: Slash Command Template Library
kind: module
purpose: Markdown slash-command templates (afk, audit, bundle, dashboard, health, gitstatus, diff, enterprise, onboard, orchestrate, schedule, verify, and shortcuts) copied by the installer into a consumer repo's command surface -- the packaged command set an adopter gets instead of authoring commands from scratch.
entry_points:
  - templates/commands
owner_lane: jitneuro
status: verified
last_verified: 2026-07-11
```
<!-- CAP-END:command-template-library -->

<!-- CAP-START:session-dashboard-scripts -->
```yaml
id: session-dashboard-scripts
name: Session Dashboard + Listing Scripts
kind: module
purpose: Shell scripts (dashboard.sh, sessions.sh) packaged under templates/scripts/ that render the session dashboard and list active sessions once installed into a consumer repo -- the reference implementation the /dashboard and /sessions command templates call into.
entry_points:
  - templates/scripts/dashboard.sh
  - templates/scripts/sessions.sh
owner_lane: jitneuro
status: verified
last_verified: 2026-07-11
```
<!-- CAP-END:session-dashboard-scripts -->

<!-- CAP-START:community-publish-pipeline -->
```yaml
id: community-publish-pipeline
name: Community Publish Manifest + Docs
kind: module
purpose: COMMUNITY-PUBLISH-MANIFEST.json plus the community/ directory (adhd-friendly, business-strategy guides) defining what ships in the public OSS release and the adopter-facing framing docs around it -- the single manifest that gates what content is safe to publish externally.
entry_points:
  - templates/COMMUNITY-PUBLISH-MANIFEST.json
  - community/README.md
owner_lane: jitneuro
status: verified
last_verified: 2026-07-11
```
<!-- CAP-END:community-publish-pipeline -->

## hook

<!-- CAP-START:hook-template-library -->
```yaml
id: hook-template-library
name: Claude Code Lifecycle Hook Template Library
kind: hook
purpose: Bash hook script templates (heartbeat, session-start identity/post-clear/recovery/scheduled-agents, session-end autosave/lessons-flush, pre-compact-save, pre-agent-register, post-agent-complete, branch-protection, stop-continue-queue) installed into a consumer repo's .claude/hooks/ -- the packaged hook set an adopter gets instead of hand-writing lifecycle automation.
entry_points:
  - templates/hooks
owner_lane: jitneuro
status: verified
last_verified: 2026-07-11
```
<!-- CAP-END:hook-template-library -->

## skill

<!-- CAP-START:skill-template-library -->
```yaml
id: skill-template-library
name: Claude Code Skill Template Library
kind: skill
purpose: 42 packaged Claude Code SKILL.md templates (schedule, learn, enterprise, verify, handoff, health, session-close, pulse, test-tools, bundle, and more) under templates/skills/ that the installer copies into a consumer repo's skill surface -- the packaged skill catalog an adopter gets instead of authoring skills from scratch.
entry_points:
  - templates/skills
owner_lane: jitneuro
status: verified
last_verified: 2026-07-11
```
<!-- CAP-END:skill-template-library -->
