# Test Tools

Smoke-test every available Claude Code tool and MCP server. Reports PASS/FAIL for each.
Diagnostic only -- creates one temp file, then deletes it. No other side effects.

## Instructions

When invoked as `/test-tools`:

Run ALL tests below. Use parallel tool calls where possible (group independent tests together).
For each test, catch errors gracefully -- a failure in one test must NOT stop the others.

Report results in this format at the end:
```
Tool Test Results (YYYY-MM-DD HH:MM)
=============================================
CORE TOOLS
  [PASS] Bash            -- echo worked
  [PASS] Read            -- read CLAUDE.md (N lines)
  [PASS] Write           -- created temp file
  [PASS] Edit            -- edited temp file
  [PASS] Glob            -- found N .md files
  [PASS] Grep            -- pattern matched in N files
  [PASS] Agent           -- subagent returned OK
  [PASS] WebFetch        -- fetched URL (status 200)
  [PASS] WebSearch       -- returned N results
  [PASS] TaskCreate      -- task created and deleted

MCP SERVERS
  [PASS] github:get_me           -- authenticated as <user>
  [PASS] filesystem:list_dir     -- listed N items
  [SKIP] some-server:some_tool   -- not connected
  [FAIL] broken:tool_name        -- error: <message>

SUMMARY: 14/16 PASS, 1 FAIL, 1 SKIP
=============================================
```

### Phase 1: Core Tools

All core tool tests use paths relative to the current working directory or well-known safe targets.
Use forward slashes in ALL Bash tool paths (Windows bash treats backslashes as escape characters).

**Batch 1 (independent, run in parallel):**
1. **Bash**: `echo "tool-test-ok"` -- PASS if output contains "tool-test-ok"
2. **Read**: Read first 5 lines of the nearest CLAUDE.md (check CWD, then CWD/.claude/, then parent dirs) -- PASS if content returned
3. **Glob**: `**/*.md` in the current working directory -- PASS if any files found
4. **Grep**: Search for a common word like "the" in the nearest CLAUDE.md -- PASS if matches found
5. **WebFetch**: Fetch https://httpbin.org/get -- PASS if response received
6. **WebSearch**: Search "Claude Code" -- PASS if results returned

**Batch 2 (sequential write/edit/read cycle):**
7. **Write**: Create `.claude/test-tools-temp.md` in CWD (or CWD/.test-tools-temp.md if no .claude/) with content "test-write-ok" -- PASS if created
8. **Edit**: Replace "test-write-ok" with "test-edit-ok" in the temp file -- PASS if succeeded
9. **Read verify**: Read the temp file, confirm it contains "test-edit-ok" -- PASS if matched
10. **Bash cleanup**: Delete the temp file using `rm` with forward-slash path -- silent cleanup

**Batch 3 (independent):**
11. **TaskCreate**: Create a task "Test task - auto-delete" -- PASS if task ID returned. Immediately delete it (TaskUpdate status: deleted).
12. **Agent**: Spawn a quick subagent (subagent_type: Explore) with prompt "Return STATUS: OK and nothing else" -- PASS if returns STATUS: OK

### Phase 2: MCP Server Auto-Discovery

Do NOT hardcode MCP server names. Instead, auto-discover what's available:

1. Use **ToolSearch** with a broad query like `"mcp"` (max_results: 50) to discover all available MCP tools
2. Parse the results to identify unique MCP server prefixes (the part between `mcp__` and the next `__`)
3. For each discovered server, pick ONE safe read-only tool to test:

**Server selection heuristics (pick the first match):**
| Server prefix contains | Test tool pattern | Test input |
|------------------------|-------------------|------------|
| github | `get_me` | (no args) |
| filesystem | `list_directory` or `list_allowed_directories` | CWD path |
| azure-sql | `subscription_list` | (no args) |
| stripe | `get_stripe_account_info` or `list_products` | (no args, or limit 1) |
| salesforce | `salesforce_search_objects` | searchPattern: "Account" |
| firebase | `firebase_list_projects` | (no args) |
| ms-learn-docs | `microsoft_docs_search` | query: "Azure" |
| context7 | `resolve-library-id` | libraryName: "react", query: "react docs" |
| ai-diagnostics | `test_environment` | environment: "uat" |
| (any other) | Pick the first tool that looks read-only (list, get, search, describe, read, fetch) | Minimal safe args |

4. For each server, use **ToolSearch** to fetch the specific tool schema, then call it
5. If a tool call succeeds: `[PASS]`
6. If a tool call errors: `[FAIL]` with first line of error
7. If ToolSearch returns no tools for a server: `[SKIP] -- not connected`

### Phase 3: Report

After all tests complete, compile the results table shown above.

Include:
- Total counts: PASS, FAIL, SKIP
- For any FAIL, include a one-line remediation hint:
  - Auth errors: "Re-authenticate (e.g., sf org login, az login, check API key)"
  - Connection errors: "Check MCP server config in .mcp.json or settings"
  - Unknown tool errors: "MCP server may need restart or update"
  - Path errors: "Check file exists and path uses forward slashes"

### Error Handling
- If a ToolSearch fails to find a tool schema: `[SKIP] <server> -- schema not available`
- If a tool call throws: `[FAIL] <server>:<tool> -- <error first line>`
- If a tool call times out: `[FAIL] <server>:<tool> -- timeout`
- Never let one failure stop the rest of the tests
- Always clean up the temp file, even if Edit fails

### Important
- This command is diagnostic -- minimize side effects
- Delete any test tasks created during the run
- Do not modify any real data via MCP servers (read-only operations only)
- Maximize parallelism -- run all independent tests simultaneously
- Use forward slashes in ALL Bash paths
- Works from any working directory -- no hardcoded paths
- MCP server list is dynamic -- new servers are auto-detected
