#!/usr/bin/env bash
# JitNeuro E2E Orphan Process Reaper (POSIX) -- ticket #2695
#
# Root cause this closes: rules/e2e-test-safety.md item 4 ("No orphans") was
# advisory only -- nothing actually verified or reaped leftover browser/test
# processes after an aborted/hung agent-launched e2e run. On an 8-core
# priority VM, a single aborted run can leave a full tree of Playwright
# worker + headless Chromium (renderer/gpu/utility) processes running,
# software-rendering (SwiftShader, no GPU) any looping page and pegging
# every core with no visible browser window as evidence. See the "Root
# Cause" section of rules/e2e-test-safety.md for the full diagnosis.
#
# Installed by scripts/install.sh into a consuming repo's `.claude/scripts/`
# alongside the other templates/scripts/*.sh utilities. Wire `--pretest`/
# `--posttest` into your e2e npm scripts or Playwright's globalSetup/
# globalTeardown for a project-owned enforcement point; the companion
# `templates/claude-hooks/e2e-reaper-hook.sh` PostToolUse hook is the
# always-on safety net that fires the same logic automatically.
#
# This script finds and kills the FULL process tree of any orphaned
# Playwright/Cypress/Puppeteer test-runner or headless-browser process, on
# POSIX (macOS/Linux). Use it:
#   --pretest   before starting a new e2e batch, to clear leftovers from a
#               prior aborted/killed run (a previous abort may not have run
#               posttest, e.g. session crash or `kill -9` on the shell).
#   --posttest  immediately after a run (pass or fail) to GUARANTEE zero
#               orphans remain -- the acceptance bar for ticket #2695.
#   --list      report matches without killing (verification / dry-run).
#   --classify '<cmdline>'   test-mode: echo yes/no for one command-line
#               string, no process scan (used by the unit tests in
#               templates/scripts/tests/e2e-process-reaper.test.sh).
#
# Exit codes: 0 = clean (no orphans found, or all killed successfully).
#             1 = orphans remained after --posttest's kill+verify pass.
#
# Portable: pure bash + ps/grep/kill, no python/jq/pgrep-flag dependency
# (busybox ps on some containers lacks pgrep -f options this avoids).

set +e  # never let the reaper itself hang the caller on an unexpected error

SELF_PID=$$

# --- Classification --------------------------------------------------------
#
# Matches a process command line against the set of e2e test-runner /
# headless-browser signatures this ticket is scoped to. Kept narrow: this
# must not reap an unrelated node/chrome process (e.g. the user's browser,
# an unrelated dev server) just because it shares a binary name.
is_e2e_orphan_cmdline() {
  local cmd="$1"
  # Playwright's own CLI/worker/browser-server processes: node running
  # something under a playwright(-core) package path, or the .bin shim
  # invocation itself, or the downloaded-browser cache dir.
  echo "$cmd" | grep -qiE 'node_modules[/\\]\.bin[/\\]playwright' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'node_modules[/\\]playwright(-core)?[/\\]' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'ms-playwright' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'playwright.*(worker|run-server|test-server)' && { echo yes; return; }
  # Cypress runner + its bundled Electron/Chromium.
  echo "$cmd" | grep -qiE 'node_modules[/\\]\.bin[/\\]cypress' && { echo yes; return; }
  echo "$cmd" | grep -qiE 'node_modules[/\\]cypress[/\\]' && { echo yes; return; }
  echo "$cmd" | grep -qiE '\.cache[/\\][Cc]ypress' && { echo yes; return; }
  # Puppeteer's cached headless Chromium.
  echo "$cmd" | grep -qiE 'puppeteer.*\.local-chromium' && { echo yes; return; }
  # Headless Chromium/chrome-headless-shell invoked with automation flags --
  # only match when BOTH a headless-automation flag AND a test-tool
  # ancestry hint are present, to avoid matching an unrelated headless
  # Chrome the user launched directly for something else.
  if echo "$cmd" | grep -qiE '(chrome|chromium)(-headless-shell)?' && \
     echo "$cmd" | grep -qiE -- '--headless|--remote-debugging-port|--enable-automation'; then
    echo "$cmd" | grep -qiE 'ms-playwright|playwright|cypress|puppeteer' && { echo yes; return; }
  fi
  echo no
}

# --- Test mode ---------------------------------------------------------------
if [ "${1:-}" = "--classify" ]; then
  echo "$(is_e2e_orphan_cmdline "${2:-}")"
  exit 0
fi

# --- Portable process listing -------------------------------------------------
# Emits "pid<TAB>ppid<TAB>command" lines. `ps -eo` with these keywords is
# POSIX-portable across macOS (BSD ps) and Linux (procps/busybox).
list_procs() {
  ps -Ao 'pid=,ppid=,command=' 2>/dev/null || ps -eo 'pid=,ppid=,args=' 2>/dev/null
}

# Reshape raw ps output into clean pid<TAB>ppid<TAB>command lines.
snapshot_procs() {
  list_procs | awk '{
    pid=$1; ppid=$2;
    $1=""; $2="";
    sub(/^[ \t]+/, "");
    printf "%s\t%s\t%s\n", pid, ppid, $0
  }'
}

# Build the full set of descendant PIDs (recursive) for a given root PID,
# using an already-captured process snapshot (avoids re-listing per node,
# and avoids a TOCTOU window where a process could re-parent mid-walk).
collect_descendants() {
  local root="$1" snapshot="$2"
  local -a frontier=("$root") all=()
  local pid ppid cmd line
  while [ "${#frontier[@]}" -gt 0 ]; do
    local next=()
    for pid in "${frontier[@]}"; do
      all+=("$pid")
      while IFS=$'\t' read -r cpid cppid _; do
        [ "$cppid" = "$pid" ] && next+=("$cpid")
      done <<< "$snapshot"
    done
    frontier=("${next[@]}")
  done
  printf '%s\n' "${all[@]}"
}

# Terminate the full descendant tree of the given root PIDs: SIGTERM, grace
# period, SIGKILL any survivors, then verify. Returns 1 if anything survives
# SIGKILL (should only happen for an unkillable zombie/kernel-wedged proc).
# This is the shared primitive behind both the system-wide scan (`reap`) and
# the explicit-target test mode (`--kill-tree`), so the unit tests exercise
# the SAME kill/verify code path the real reaper uses in production.
terminate_tree() {
  local snapshot="$1"; shift
  local -a roots=("$@")
  local root pid

  local -a all_pids=()
  for root in "${roots[@]}"; do
    while IFS= read -r pid; do
      [ -n "$pid" ] && all_pids+=("$pid")
    done < <(collect_descendants "$root" "$snapshot")
  done

  # De-dupe (avoid bash 4+ associative arrays -- macOS ships bash 3.2).
  local -a uniq_pids=()
  if [ "${#all_pids[@]}" -gt 0 ]; then
    while IFS= read -r pid; do
      [ -n "$pid" ] && uniq_pids+=("$pid")
    done < <(printf '%s\n' "${all_pids[@]}" | sort -un)
  fi

  echo "e2e-process-reaper: killing ${#uniq_pids[@]} process(es) (tree, TERM then KILL)."
  kill -TERM "${uniq_pids[@]}" 2>/dev/null
  sleep 2
  local -a still_alive=()
  for pid in "${uniq_pids[@]}"; do
    kill -0 "$pid" 2>/dev/null && still_alive+=("$pid")
  done
  if [ "${#still_alive[@]}" -gt 0 ]; then
    kill -KILL "${still_alive[@]}" 2>/dev/null
    sleep 1
  fi

  local -a remaining=()
  for pid in "${uniq_pids[@]}"; do
    kill -0 "$pid" 2>/dev/null && remaining+=("$pid")
  done
  if [ "${#remaining[@]}" -gt 0 ]; then
    echo "e2e-process-reaper: WARNING -- ${#remaining[@]} process(es) survived SIGKILL: ${remaining[*]}" >&2
    return 1
  fi
  echo "e2e-process-reaper: verified clean -- 0 orphans remain."
  return 0
}

reap() {
  local mode="$1"  # list | kill
  local snapshot
  snapshot="$(snapshot_procs)"

  local -a match_pids=()
  local pid ppid cmd
  while IFS=$'\t' read -r pid ppid cmd; do
    [ -z "$pid" ] && continue
    [ "$pid" = "$SELF_PID" ] && continue
    [ "$(is_e2e_orphan_cmdline "$cmd")" = "yes" ] && match_pids+=("$pid")
  done <<< "$snapshot"

  if [ "${#match_pids[@]}" -eq 0 ]; then
    [ "$mode" = "list" ] && echo "e2e-process-reaper: no matching processes found."
    return 0
  fi

  echo "e2e-process-reaper: found ${#match_pids[@]} matching root process(es):"
  local root
  for root in "${match_pids[@]}"; do
    local line
    line="$(printf '%s\n' "$snapshot" | awk -F'\t' -v p="$root" '$1==p{print; exit}')"
    echo "  pid=$root  $(printf '%s' "$line" | cut -f3-)"
  done

  [ "$mode" = "list" ] && return 0

  # Kill: for every matched root, reap the full descendant tree (covers
  # Chromium's renderer/gpu/utility children, whether or not they share a
  # process group with the root -- Playwright does not always setsid).
  terminate_tree "$snapshot" "${match_pids[@]}"
}

case "${1:-}" in
  --list)      reap list ;;
  --pretest)   reap kill ;;
  --posttest)  reap kill ;;
  --kill)      reap kill ;;
  --kill-tree)
    # Test/scoped hook: terminate a SPECIFIC root PID's descendant tree
    # without the classify scan, so unit tests can verify the kill/verify
    # primitive against a known fake process without touching unrelated
    # processes on a shared machine.
    ROOT_PID="${2:-}"
    if ! echo "$ROOT_PID" | grep -qE '^[0-9]+$'; then
      echo "Usage: e2e-process-reaper.sh --kill-tree <pid>" >&2
      exit 64
    fi
    SNAP="$(snapshot_procs)"
    terminate_tree "$SNAP" "$ROOT_PID"
    ;;
  *)
    echo "Usage: e2e-process-reaper.sh --pretest|--posttest|--kill|--list|--kill-tree <pid>|--classify '<cmdline>'" >&2
    exit 64
    ;;
esac
exit $?
