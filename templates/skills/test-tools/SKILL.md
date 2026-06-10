---
type: skill
purpose: Smoke-test all Claude Code tools and MCP servers via auto-discovery with a three-phase report; skipping means tool failures are discovered mid-task instead of at session start.
read_when: At session start after a machine change, MCP reconfiguration, or when a tool is suspected to be broken.
tags: [test-tools, smoke-test, mcp, tools, diagnostic]
scope: public
departments: [all]
status: canonical
last_evaluated: 2026-06-03
source: backport from jitneuro 2026-05-28
---

# /test-tools

Smoke-test all Claude Code tools and MCP servers.

## Phase 1: Core tools

Test each built-in Claude Code tool:
- Read: read a known file and verify non-empty result
- Write: write a temp file and verify creation
- Edit: make a trivial edit to temp file and verify
- Bash: run `echo "test"` and verify output
- Glob: glob for `*.md` in workspace root and verify results
- Grep: grep for `type:` in a known file and verify matches

Report: PASS / FAIL per tool.

## Phase 2: MCP auto-discovery

Read `~/.claude/settings.json` (or equivalent) to discover registered MCP servers.

For each server:
1. Identify the server name and registered tools
2. Run a lightweight read/list operation against each tool
3. Report: PASS (responded) / FAIL (error) / TIMEOUT (no response in 10s)

## Phase 3: Report

```
TOOL SMOKE TEST RESULTS
=======================
Core tools:  7/7 PASS
MCP servers: 3 found
  github:    8/8 tools PASS
  filesystem: 16/16 tools PASS
  salesforce: 2/8 tools FAIL (auth error)

Action needed:
  - salesforce MCP: re-authenticate (see ~/.claude/docs/salesforce-access.md)
```

## What this does NOT do

Does not write to production paths. Does not commit. All test writes go to a temp location that is cleaned up after the test.
