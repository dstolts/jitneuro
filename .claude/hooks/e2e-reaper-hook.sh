#!/bin/bash
# JitNeuro E2E Orphan Process Reaper Hook (PostToolUse on Bash) -- ticket #2695
#
# Root cause (see rules/e2e-test-safety.md "Root Cause" section): an
# agent-launched e2e test-run command (Playwright/Cypress/Puppeteer) can exit
# -- normally, on timeout, or on abort -- while leaving orphaned browser
# (chromium renderer/gpu/utility) or worker processes running. On a GPU-less
# VM those orphans software-render (SwiftShader) any looping/animated page in
# a hung tab, pegging every core with no visible browser window as evidence.
# `templates/claude-hooks/e2e-guard.sh` (ticket #2692) prevents unsafe
# invocations BEFORE they run (PreToolUse); this hook is the AFTER-the-fact
# safety net: every time an e2e test-run command finishes (pass, fail, or
# killed by the shell timeout wrapper), it fires the process-tree reaper in
# the background so orphans never survive past the tool call that spawned
# them, regardless of whether the consuming repo also wires its own
# pretest/posttest npm scripts.
#
# Non-blocking by design: reaping runs backgrounded (nohup + disown-style)
# so this hook returns immediately and never adds latency to the agent loop.
# Fail open: any unexpected error here must never block or fail the tool call
# it fires after.
#
# Portable: pure bash + ps/grep/kill, no python/jq dependency. Mirrors the
# command-classification approach in e2e-guard.sh (segment-anchored, not
# naive substring match) so a command merely mentioning "playwright test" in
# quoted data is never treated as a real invocation.

set +e

LOG="/tmp/jitneuro-e2e-reaper-hook.log"

split_segments() {
  local cmd="$1" work
  work="${cmd//&&/$'\n'}"; work="${work//||/$'\n'}"; work="${work//|/$'\n'}"; work="${work//;/$'\n'}"
  printf '%s\n' "$work"
}

strip_prefix() {
  local seg="$1" changed=1
  seg="${seg#"${seg%%[![:space:]]*}"}"
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

# Same shape as e2e-guard.sh's is_test_run_command -- only these need a
# post-run reap; --version/codegen/install are one-shot, never leave a
# browser tree running.
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

# --- Orphan classification (mirrors scripts/e2e-process-reaper.sh) -------------

is_e2e_orphan_cmdline() {
  local cmd="$1"
  echo "$cmd" | grep -qiE 'node_modules[/\\]\.bin[/\\]playwright' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'node_modules[/\\]playwright(-core)?[/\\]' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'ms-playwright' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'playwright.*(worker|run-server|test-server)' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'node_modules[/\\]\.bin[/\\]cypress' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'node_modules[/\\]cypress[/\\]' && { echo yes; return; }
  echo "$cmd" | grep -qiE '\.cache[/\\][Cc]ypress' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'puppeteer.*\.local-chromium' && { echo yes; return; }
  if echo "$cmd" | grep -qiE '(chrome|chromium)(-headless-shell)?' && \
     echo "$cmd" | grep -qiE -- '--headless|--remote-debugging-port|--enable-automation'; then
    echo "$cmd" | grep -qiE 'ms-playwright|playwright|cypress|puppeteer' && { echo yes; return; }
  fi
  echo no
}

reap_orphans() {
  local snapshot pid ppid cmd
  snapshot="$( (ps -Ao 'pid=,ppid=,command=' 2>/dev/null || ps -eo 'pid=,ppid=,args=' 2>/dev/null) | awk '{
    pid=$1; ppid=$2; $1=""; $2=""; sub(/^[ \t]+/, ""); printf "%s\t%s\t%s\n", pid, ppid, $0
  }')"
  local -a roots=()
  while IFS=$'\t' read -r pid ppid cmd; do
    [ -z "$pid" ] && continue
    [ "$pid" = "$$" ] && continue
    [ "$(is_e2e_orphan_cmdline "$cmd")" = "yes" ] && roots+=("$pid")
  done <<< "$snapshot"
  [ "${#roots[@]}" -eq 0 ] && return 0

  # Recursive descendant collection (same approach as scripts/e2e-process-reaper.sh).
  local -a all_pids=()
  local root
  for root in "${roots[@]}"; do
    local -a frontier=("$root")
    while [ "${#frontier[@]}" -gt 0 ]; do
      local -a next=()
      local p
      for p in "${frontier[@]}"; do
        all_pids+=("$p")
        while IFS=$'\t' read -r cpid cppid _; do
          [ "$cppid" = "$p" ] && next+=("$cpid")
        done <<< "$snapshot"
      done
      frontier=("${next[@]}")
    done
  done

  local -a uniq_pids=()
  if [ "${#all_pids[@]}" -gt 0 ]; then
    while IFS= read -r pid; do
      [ -n "$pid" ] && uniq_pids+=("$pid")
    done < <(printf '%s\n' "${all_pids[@]}" | sort -un)
  fi

  echo "[$(date 2>/dev/null)] reaping ${#uniq_pids[@]} orphan(s) after e2e run: ${uniq_pids[*]}" >> "$LOG" 2>/dev/null
  kill -TERM "${uniq_pids[@]}" 2>/dev/null
  sleep 2
  local pid2
  for pid2 in "${uniq_pids[@]}"; do
    kill -0 "$pid2" 2>/dev/null && kill -KILL "$pid2" 2>/dev/null
  done
}

# --- Test mode -------------------------------------------------------------------
# `e2e-reaper-hook.sh --is-test-run '<cmd>'` and `--classify-orphan '<cmdline>'`
# expose the two pure classification functions for unit tests without needing
# real hook stdin or real processes.
if [ "${1:-}" = "--is-test-run" ]; then
  is_test_run_command "${2:-}"
  exit 0
fi
if [ "${1:-}" = "--classify-orphan" ]; then
  is_e2e_orphan_cmdline "${2:-}"
  exit 0
fi

# --- Hook mode -----------------------------------------------------------------

INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//')
[ -z "$COMMAND" ] && exit 0  # nothing to analyze, fail open

if [ "$(is_test_run_command "$COMMAND")" != "yes" ]; then
  exit 0
fi

echo "[$(date 2>/dev/null)] e2e-reaper-hook fired after e2e run. Command=${COMMAND:0:120}" >> "$LOG" 2>/dev/null

# Fire-and-forget in the background: never add latency to the hook chain,
# never let a reaper hang/crash affect the tool-call result it followed.
( reap_orphans ) >/dev/null 2>>"$LOG" &
disown 2>/dev/null || true

exit 0
