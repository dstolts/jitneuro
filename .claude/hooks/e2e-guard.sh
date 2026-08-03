#!/bin/bash
# JitNeuro E2E/Browser Test Guard (PreToolUse on Bash) -- ticket #2692
# Enforces rules/e2e-test-safety.md mechanically: agent-launched browser/E2E
# test commands must be headless, non-interactive, and wall-clock-bounded so
# they can never hang an unattended session or a shared VM.
#
# Portable: pure bash + grep/sed, no python/jq dependency. Must run under
# Windows Git-Bash and macOS/Linux bash per rules/claude-code-hook-deployment.md.
#
# BLOCKS (exit 2):
#   1. Interactive/visible-browser flags: --headed, --debug, --ui, --inspect,
#      --inspect-brk on a recognized browser-test command.
#   2. A referenced spec/test file (existing, resolvable relative to cwd) that
#      contains page.pause() (Playwright) or .pause() (Cypress).
#   3. A bare test-run invocation (playwright test / cypress run / vitest run
#      --browser / puppeteer script) with no wall-clock cap: no Bash-tool
#      `timeout` param, no `run_in_background: true`, and no in-command
#      `timeout <n> ...` / `gtimeout <n> ...` wrapper.
#
# ADVISORY (exit 0, printed to stderr, never blocks): missing --workers cap,
# missing chromium --disable-gpu/--disable-dev-shm-usage, missing nice/taskset
# or platform-equivalent priority/affinity constraint. These are resource-fence
# best practices (2026-07-06 8-core priority-VM directive) that cannot be
# verified reliably from a CLI string alone (often set in playwright.config.*),
# so they nudge rather than block -- see rules/claude-code-hook-deployment.md
# section 3 on reserving exit 2 for genuine hangs.
#
# Test mode: `e2e-guard.sh --verdict '<command>' [timeout] [run_in_background]`
# echoes BLOCK:<reason> or ALLOW without needing real hook stdin.

set +e  # never abort the guard itself on an unexpected error

LOG="/tmp/jitneuro-e2e-guard.log"

# --- Command classification ----------------------------------------------------
#
# Segment-anchored, not whole-string substring search. A naive substring grep
# false-positives on ordinary commands that merely MENTION a tool name in
# quoted data, e.g. `git commit -m "add playwright test config"` -- that
# string contains "playwright test" but is not an invocation of it. Splitting
# on shell separators (&&, ||, |, ;) and anchoring each segment's check to its
# own start (after optional `npx `/`VAR=val ` prefixes) mirrors the technique
# branch-protection.sh uses for `git push` detection.

# Echo each top-level command segment on its own line.
split_segments() {
  local cmd="$1" work
  work="${cmd//&&/$'\n'}"; work="${work//||/$'\n'}"; work="${work//|/$'\n'}"; work="${work//;/$'\n'}"
  printf '%s\n' "$work"
}

# Strip leading whitespace plus any leading env-assignment (`VAR=val `) or
# wrapper-command (`timeout 300 `, `gtimeout 300 `, `nice -n 10 `, `taskset
# 0x3 `) prefixes so the underlying tool name is the first real token. This
# lets is_e2e_command/is_test_run_command see THROUGH the wrapper commands
# the remediation messages themselves recommend adding.
strip_prefix() {
  local seg="$1" changed=1
  seg="${seg#"${seg%%[![:space:]]*}"}"  # ltrim
  while [[ $changed -eq 1 ]]; do
    changed=0
    if [[ "$seg" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; then
      seg="${BASH_REMATCH[1]}"; changed=1; continue
    fi
    if [[ "$seg" =~ ^g?timeout[[:space:]]+[0-9]+[a-z]?[[:space:]]+(.*)$ ]]; then
      seg="${BASH_REMATCH[1]}"; changed=1; continue
    fi
    if [[ "$seg" =~ ^nice([[:space:]]+-n[[:space:]]*-?[0-9]+)?[[:space:]]+(.*)$ ]]; then
      seg="${BASH_REMATCH[2]}"; changed=1; continue
    fi
    if [[ "$seg" =~ ^taskset[[:space:]]+[^[:space:]]+[[:space:]]+(.*)$ ]]; then
      seg="${BASH_REMATCH[1]}"; changed=1; continue
    fi
  done
  printf '%s' "$seg"
}

# Is this command shape a browser/E2E test invocation at all? Keep this
# narrow -- false positives block unrelated Bash calls (ls, grep, cat, etc.)
# and unrelated commands that merely mention a tool name in quoted data.
is_e2e_command() {
  local cmd="$1" seg s
  while IFS= read -r seg; do
    [[ -z "$seg" ]] && continue
    s="$(strip_prefix "$seg")"
    echo "$s" | grep -qiE '^(npx[[:space:]]+)?(playwright|cypress)([[:space:]]|$)' && { echo yes; return; }
    echo "$s" | grep -qiE '^vitest[[:space:]].*(--browser|browser:test|browser\.test)' && { echo yes; return; }
    echo "$s" | grep -qiE '^(npx[[:space:]]+)?puppeteer([[:space:]]|$)' && { echo yes; return; }
    echo "$s" | grep -qiE '^npm[[:space:]]+run[[:space:]]+(e2e|test:e2e|test:browser|browser:test)([[:space:]]|$)' && { echo yes; return; }
  done <<< "$(split_segments "$cmd")"
  echo no
}

# Is this specifically a "run the tests now" invocation (vs. e.g. `playwright
# --version`, `playwright codegen`, `playwright install`)? Only these need the
# timeout/workers enforcement -- codegen/install are one-shot dev commands.
is_test_run_command() {
  local cmd="$1" seg s
  while IFS= read -r seg; do
    [[ -z "$seg" ]] && continue
    s="$(strip_prefix "$seg")"
    echo "$s" | grep -qiE '^(npx[[:space:]]+)?(playwright)([[:space:]]+[a-z:-]+)*[[:space:]]+test([[:space:]]|$)' && { echo yes; return; }
    echo "$s" | grep -qiE '^(npx[[:space:]]+)?cypress[[:space:]]+run([[:space:]]|$)' && { echo yes; return; }
    echo "$s" | grep -qiE '^vitest[[:space:]]+run.*(--browser|browser:test)' && { echo yes; return; }
    echo "$s" | grep -qiE '^npm[[:space:]]+run[[:space:]]+(e2e|test:e2e|test:browser|browser:test)([[:space:]]|$)' && { echo yes; return; }
  done <<< "$(split_segments "$cmd")"
  echo no
}

# --- Interactive/hang-prone flag detection -------------------------------------

has_interactive_flag() {
  local cmd="$1"
  echo "$cmd" | grep -qE '(^|[[:space:]])--headed([[:space:]]|$)' && { echo "--headed"; return; }
  echo "$cmd" | grep -qE '(^|[[:space:]])--debug([[:space:]]|$)' && { echo "--debug"; return; }
  echo "$cmd" | grep -qE '(^|[[:space:]])--ui([[:space:]]|$)' && { echo "--ui"; return; }
  echo "$cmd" | grep -qE '(^|[[:space:]])--inspect(-brk)?(=|[[:space:]]|$)' && { echo "--inspect"; return; }
  echo "$cmd" | grep -qE '(^|[[:space:]])--watch([[:space:]]|$)' && { echo "--watch"; return; }
  echo ""
}

# --- page.pause() / .pause() in a referenced spec file -------------------------

# Extract argument tokens that look like file/glob paths (not flags, contain a
# path separator or a known test-file extension) and grep any that resolve to
# a real file for an interactive pause call.
find_pause_in_specs() {
  local cmd="$1"
  local -a toks
  set -f; IFS=' ' read -r -a toks <<< "$cmd"; set +f
  local tok
  for tok in "${toks[@]}"; do
    case "$tok" in
      -*) continue ;;
    esac
    case "$tok" in
      *.spec.ts|*.spec.js|*.spec.tsx|*.spec.jsx|*.test.ts|*.test.js|*.test.tsx|*.test.jsx|*.cy.ts|*.cy.js)
        if [ -f "$tok" ] && grep -qE '\.pause\(\)' "$tok" 2>/dev/null; then
          echo "$tok"
          return
        fi
        ;;
    esac
  done
  echo ""
}

# --- Wall-clock cap detection ---------------------------------------------------

# True if the command string itself wraps the invocation in a POSIX timeout.
has_shell_timeout_wrapper() {
  local cmd="$1"
  echo "$cmd" | grep -qE '(^|[[:space:];&|])(g?timeout)[[:space:]]+[0-9]' && { echo yes; return; }
  echo no
}

# --- Test mode -------------------------------------------------------------------
if [ "${1:-}" = "--verdict" ]; then
  CMD="${2:-}"
  TOOL_TIMEOUT="${3:-}"
  RUN_BG="${4:-}"
  IS_E2E="$(is_e2e_command "$CMD")"
  if [ "$IS_E2E" != "yes" ]; then echo "ALLOW"; exit 0; fi
  FLAG="$(has_interactive_flag "$CMD")"
  if [ -n "$FLAG" ]; then echo "BLOCK:interactive-flag:$FLAG"; exit 0; fi
  PAUSE_FILE="$(find_pause_in_specs "$CMD")"
  if [ -n "$PAUSE_FILE" ]; then echo "BLOCK:page-pause:$PAUSE_FILE"; exit 0; fi
  if [ "$(is_test_run_command "$CMD")" = "yes" ]; then
    if [ "$RUN_BG" = "true" ]; then echo "ALLOW"; exit 0; fi
    if echo "$TOOL_TIMEOUT" | grep -qE '^[0-9]+$'; then echo "ALLOW"; exit 0; fi
    if [ "$(has_shell_timeout_wrapper "$CMD")" = "yes" ]; then echo "ALLOW"; exit 0; fi
    echo "BLOCK:no-timeout"
    exit 0
  fi
  echo "ALLOW"
  exit 0
fi

# --- Hook mode ---------------------------------------------------------------

INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//')
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)/\1/p' 2>/dev/null | head -1 | sed 's/"[[:space:]]*,.*//' | sed 's/"[[:space:]]*}//')
fi
[ -z "$COMMAND" ] && exit 0  # nothing to analyze, fail open

# tool_input.timeout (ms, Bash tool param) and run_in_background, when present
TOOL_TIMEOUT=$(echo "$INPUT" | grep -o '"timeout"[[:space:]]*:[[:space:]]*[0-9]*' 2>/dev/null | head -1 | grep -o '[0-9]*$')
RUN_BG=$(echo "$INPUT" | grep -o '"run_in_background"[[:space:]]*:[[:space:]]*\(true\|false\)' 2>/dev/null | head -1 | grep -o 'true\|false')

echo "[$(date 2>/dev/null)] e2e-guard fired. Command=${COMMAND:0:120}" >> "$LOG" 2>/dev/null

IS_E2E="$(is_e2e_command "$COMMAND")"
[ "$IS_E2E" != "yes" ] && exit 0

FLAG="$(has_interactive_flag "$COMMAND")"
if [ -n "$FLAG" ]; then
  echo "BLOCKED by JitNeuro e2e-guard: interactive/visible-browser flag '$FLAG' on a browser/E2E test command." >&2
  echo "Agent-launched E2E must stay headless and non-interactive (rules/e2e-test-safety.md)." >&2
  echo "Remediation: drop $FLAG. Playwright/Cypress default to headless -- do not override it." >&2
  exit 2
fi

PAUSE_FILE="$(find_pause_in_specs "$COMMAND")"
if [ -n "$PAUSE_FILE" ]; then
  echo "BLOCKED by JitNeuro e2e-guard: '$PAUSE_FILE' calls page.pause()/.pause(), which hangs headless runs waiting on a debugger/inspector that will never attach." >&2
  echo "Remediation: remove the pause() call from the spec before running it from an agent session (rules/e2e-test-safety.md)." >&2
  exit 2
fi

if [ "$(is_test_run_command "$COMMAND")" = "yes" ]; then
  OK=0
  [ "$RUN_BG" = "true" ] && OK=1
  echo "$TOOL_TIMEOUT" | grep -qE '^[0-9]+$' && OK=1
  [ "$(has_shell_timeout_wrapper "$COMMAND")" = "yes" ] && OK=1
  if [ "$OK" -ne 1 ]; then
    echo "BLOCKED by JitNeuro e2e-guard: no wall-clock cap on a browser/E2E test run." >&2
    echo "A bare test invocation with no timeout can hang an unattended session forever (rules/e2e-test-safety.md)." >&2
    echo "Remediation -- pick one:" >&2
    echo "  1. Pass the Bash tool's timeout param (e.g. timeout: 300000 for 5 min)." >&2
    echo "  2. Set run_in_background: true and poll/monitor instead of blocking foreground." >&2
    echo "  3. Wrap the command in a shell timeout: timeout 300 npx playwright test ..." >&2
    exit 2
  fi

  # Advisory-only resource-fence nudges (2026-07-06 8-core priority-VM
  # directive) -- never block on these; often set in config, not the CLI.
  ADVISE=""
  echo "$COMMAND" | grep -q -- '--workers=' || ADVISE="${ADVISE}  - Consider --workers=2 (or lower) to cap local parallelism on the priority VM.\n"
  echo "$COMMAND" | grep -qE 'nice[[:space:]]|taskset[[:space:]]|Start-Process.*-Priority' || ADVISE="${ADVISE}  - Consider running at below-normal priority (POSIX: nice -n 10 ...; Windows: Start-Process -Priority BelowNormal) so a runaway run can't saturate all cores.\n"
  if [ -n "$ADVISE" ]; then
    echo "[jitneuro e2e-guard] Resource-fence advisories (not blocking):" >&2
    printf '%b' "$ADVISE" >&2
    echo "  - Chromium launch args --disable-gpu --disable-dev-shm-usage belong in playwright.config (use.launchOptions.args) if not already set." >&2
    echo "  - Prefer CI for full-suite runs; scope local runs to the changed spec." >&2
  fi
fi

exit 0
