#!/bin/bash
# session-start-operational-preflight.sh -- mechanical enforcement companion
# to rules/master-agent-operational-requirements.md (ticket #3188).
#
# Fires on every Claude Code SessionStart (startup, resume, clear, compact).
# Installed by scripts/install.sh into ~/.claude/hooks/ and registered under
# hooks.SessionStart in ~/.claude/settings.json (see session-start-*.sh
# siblings for the same pattern). Writes to stdout, which Claude Code injects
# as SessionStart additionalContext.
#
# Keeps a master agent's operational baseline current WITHOUT Owner having to
# remember to check it by hand: repo currency (jit-knowledge + the HubCentral
# CLI plugin repo), install-drift detection, DOE runner armed/disarmed state,
# lane ready-queue depth, lane inbox unread count, and work-items JWT expiry
# -- surfaced as WARN lines plus one compact status line.
#
# TIMEBOX (binding): total hook wall-clock budget is ~8s by default
# (JK_PREFLIGHT_BUDGET_SECONDS). The hook is registered with a 10s timeout in
# settings.json (matching its session-start-*.sh siblings); this script
# targets comfortably under that so it is never killed mid-write. Every
# network-bound step checks the remaining budget before starting and skips
# (WARN, never an error) once the budget is spent.
#
# FAIL-OPEN (binding): this hook NEVER blocks session start. Every failure
# mode -- missing clone, dirty tree, unreachable endpoint, missing
# credential, exhausted budget, no timeout binary -- degrades to a WARN line
# and `exit 0`. There is no path in this script that exits non-zero or hangs
# past its budget.
#
# DESIGN DECISION (2026-07-10, ticket #3188): "detect templates changed
# since last install.sh run" resolves to WARN-only here BY DEFAULT, not an
# auto re-run of install.sh. install.sh performs a full sync (clone/pull, hook
# registration, manifest rebuild, skill copy) that is not bounded to a few
# seconds -- running it synchronously inside a SessionStart hook would
# itself violate "never block session start." See
# rules/master-agent-operational-requirements.md's "Why WARN, not
# auto-install" section for the full reasoning. Ticket #3316 added an
# EXPLICIT opt-in escape hatch (JITK_PREFLIGHT_AUTOHEAL=1) for
# sessions/Owner that knowingly accept the latency tradeoff -- see the
# install-drift section below. The default did not change; the opt-in did
# not exist before #3316.
#
# INSTALL-DRIFT AUTHORITY (2026-07-10, ticket #3316): the install-drift field
# below is no longer a bare "unknown" when it cannot positively confirm
# current -- see cognition/decisions/knowledge-enforcement-gap-rca-2026-07-10.md
# for the incident (a hook merged to `main`, sat unregistered on a machine for
# hours, and this field said `install=unknown` instead of failing loud). It
# now runs scripts/check-install-drift.sh as the authoritative signal and only
# falls back to a cheap sentinel check, never straight back to silence.
#
# DOE_HEADLESS bypass (ticket #3160 pattern): a headless `claude -p` DOE tick
# has no interactive reader for a status line, and already runs its OWN
# tick-start pull (scripts/doe/doe-tick.sh step (c2)) -- skip entirely.
#
# Origin: Owner 2026-07-10 -- "make sure rules for master agents make these
# requirements required (runners, pickup tasks, pull repos, etc) so I do not
# need to manage, the system is automatically enforced."

set +e  # never abort -- a preflight check must not block the session

if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

# --- (0) DESIGN 4615 (ticket #4615) engagement sentinel -------------------
# Writes bootstrap-pending.<SID> so jitk-preflight-gate.sh knows this exact
# SID is a real bootstrapped master session (its ENGAGEMENT SENTINEL -- see
# that hook's header). Also appends a one-line status to a per-session
# preflight log. Both are pure awareness/bookkeeping writes: any failure
# here (unresolved SID, unwritable dir) degrades silently and NEVER blocks
# session start -- this hook's overriding contract is unchanged.
JITK_SID=""
if command -v timeout >/dev/null 2>&1; then
  JITK_SS_INPUT=$(timeout 2 cat 2>/dev/null || true)
elif command -v gtimeout >/dev/null 2>&1; then
  JITK_SS_INPUT=$(gtimeout 2 cat 2>/dev/null || true)
else
  JITK_SS_INPUT=$(cat 2>/dev/null || true)
fi
JITK_SID=$(printf '%s' "$JITK_SS_INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/')
[ -z "$JITK_SID" ] && JITK_SID="${CLAUDE_SESSION_ID:-}"

if [ -n "$JITK_SID" ]; then
  JITK_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
  JITK_PREFLIGHT_DIR="$JITK_PROJECT_DIR/.sessions/preflight"
  mkdir -p "$JITK_PREFLIGHT_DIR" 2>/dev/null
  if [ ! -f "$JITK_PREFLIGHT_DIR/preflight-done.$JITK_SID.marker" ]; then
    : > "$JITK_PREFLIGHT_DIR/bootstrap-pending.$JITK_SID" 2>/dev/null
    # Actionable, per-session attest instruction on stdout (reaches agent
    # context). This is the happy-path trigger for the preflight-before-
    # mutation gate (ticket #4615): without it the attest command is never
    # run and no session ever produces a preflight-done marker, which is what
    # would block every session if the gate were flipped to block mode.
    echo "[jk-preflight] ACTION (ticket #4615): after reading the bootstrap chain and printing the Running-Thin banner, run ONCE: bash ~/.claude/hooks/jitk-preflight-attest.sh (safe/non-blocking -- records this session's preflight-done marker)."
  fi
  printf '%s SessionStart fired for %s (sentinel written)\n' "$(date 2>/dev/null)" "$JITK_SID" \
    >> "$JITK_PREFLIGHT_DIR/preflight.$JITK_SID.log" 2>/dev/null
fi

HOOK_STARTED_AT=$SECONDS
HOOK_BUDGET_SECONDS="${JK_PREFLIGHT_BUDGET_SECONDS:-8}"

budget_left() {
  local elapsed=$((SECONDS - HOOK_STARTED_AT))
  local left=$((HOOK_BUDGET_SECONDS - elapsed))
  [ "$left" -lt 0 ] && left=0
  printf '%s' "$left"
}
budget_ok() {
  [ "$(budget_left)" -gt 0 ]
}

TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
fi
run_timeout() {
  # run_timeout <seconds> <cmd...> -- bounded when a timeout binary exists,
  # unbounded otherwise (best-effort; never this script's problem to solve
  # coreutils installation).
  local secs="$1"; shift
  if [ -n "$TIMEOUT_BIN" ]; then
    "$TIMEOUT_BIN" "${secs}s" "$@"
  else
    "$@"
  fi
}

WARN_LINES=()
warn() { WARN_LINES+=("$1"); }

# --- resolve jit-knowledge root (same chain as session-start-master-orchestrator-rule.sh) ---
JK_ROOT="${JIT_KNOWLEDGE_ROOT:-}"
if [ -z "$JK_ROOT" ] && [ -f "$HOME/.claude/workspace.json" ]; then
  JK_ROOT=$(grep -o '"jit_knowledge_root"[[:space:]]*:[[:space:]]*"[^"]*"' \
    "$HOME/.claude/workspace.json" 2>/dev/null | head -1 \
    | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')
fi
if [ -z "$JK_ROOT" ] || [ ! -d "$JK_ROOT" ]; then
  for cand in "$HOME/Code/jit-knowledge" "C:/Users/$USER/Code/jit-knowledge"; do
    if [ -d "$cand" ]; then JK_ROOT="$cand"; break; fi
  done
fi

# HubCentral here means the CLI *plugin* repo (~/Code/HubCentral, ships
# devops-task-curl.sh / intercom-curl.sh) -- deliberately NOT the
# HUBCENTRAL_ROOT env var already used elsewhere (rules/autonomous-execution.md,
# templates/claude-hooks/stop-continue-queue.sh) for the file-backed
# _HubCentral/<lane>/Hub.md fallback hub. Different root, different purpose;
# reusing that name would collide. HUBCENTRAL_CLI_ROOT is this hook's own
# override.
HC_ROOT="${HUBCENTRAL_CLI_ROOT:-$HOME/Code/HubCentral}"

# --- (1) repo currency: git pull --ff-only, skip-if-dirty, budget+timeout-bound ---
# Reports one compact token per repo: clean | pulled:<N> | dirty-skip | error:<msg> | not-found.
# NOTE: this function is invoked via command substitution ($(...)) by its
# caller below, which runs it in a SUBSHELL -- any warn() call made INSIDE
# this function would mutate only the subshell's copy of WARN_LINES and be
# silently lost when the subshell exits (a real bug caught during ticket
# #3188 testing: the "was N commits behind" WARN never appeared). This
# function therefore encodes everything the caller needs to know IN ITS
# PRINTED TOKEN and does no warn() calls itself; the caller (running in the
# main shell, not a subshell) parses the token and calls warn() there.
pull_status() {
  local root="$1"
  # .git is a directory for a normal clone, a FILE (gitdir pointer) for a
  # worktree checkout -- check both (matches scripts/install.sh's
  # _is_git_repo() pattern) so a worktree root is not misreported not-found.
  { [ -d "$root/.git" ] || [ -f "$root/.git" ]; } || { printf 'not-found'; return; }
  if ! git -C "$root" diff --quiet 2>/dev/null || ! git -C "$root" diff --cached --quiet 2>/dev/null; then
    printf 'dirty-skip'
    return
  fi
  local behind
  behind="$(run_timeout 3 git -C "$root" rev-list --count 'HEAD..@{u}' 2>/dev/null)"
  case "$behind" in ''|*[!0-9]*) behind=0 ;; esac
  local out status
  out="$(GIT_TERMINAL_PROMPT=0 run_timeout 5 git -C "$root" pull --ff-only origin main 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'error:%s' "$(printf '%s' "$out" | tr '\n' ' ' | tr -s ' ' | cut -c1-160)"
    return
  fi
  if [ "$behind" -gt 0 ]; then
    printf 'pulled:%s' "$behind"
  else
    printf 'clean'
  fi
}

REPO_STATUS_JK="not-found"
REPO_STATUS_HC="not-found"
if [ -n "$JK_ROOT" ] && budget_ok; then
  REPO_STATUS_JK="$(pull_status "$JK_ROOT")"
fi
if budget_ok; then
  REPO_STATUS_HC="$(pull_status "$HC_ROOT")"
fi

# Parse each token DIRECTLY in the main shell -- deliberately NOT wrapped in
# a function called via $(...), which would re-introduce the exact subshell
# bug this rewrite fixes. warn() must execute in the main shell to persist.
case "$REPO_STATUS_JK" in
  not-found)
    warn "jit-knowledge clone not found -- repo currency unknown" ;;
  dirty-skip)
    warn "jit-knowledge working tree is dirty -- pull skipped (not a failure; another process owns local state right now)" ;;
  error:*)
    warn "jit-knowledge repo currency -- pull failed (may be diverged/offline/auth): ${REPO_STATUS_JK#error:}"
    REPO_STATUS_JK="error" ;;
  pulled:*)
    JK_BEHIND="${REPO_STATUS_JK#pulled:}"
    warn "jit-knowledge was $JK_BEHIND commit(s) behind origin/main -- pulled up to date automatically"
    REPO_STATUS_JK="pulled($JK_BEHIND)" ;;
esac
case "$REPO_STATUS_HC" in
  not-found)
    warn "HubCentral CLI plugin clone not found at $HC_ROOT (set HUBCENTRAL_CLI_ROOT to override) -- repo currency unknown" ;;
  dirty-skip)
    warn "HubCentral working tree is dirty -- pull skipped" ;;
  error:*)
    warn "HubCentral repo currency -- pull failed (may be diverged/offline/auth): ${REPO_STATUS_HC#error:}"
    REPO_STATUS_HC="error" ;;
  pulled:*)
    HC_BEHIND="${REPO_STATUS_HC#pulled:}"
    warn "HubCentral was $HC_BEHIND commit(s) behind origin/main -- pulled up to date automatically"
    REPO_STATUS_HC="pulled($HC_BEHIND)" ;;
esac

# --- (2) install-drift detection (ticket #3316) ---
# Ticket #3316 RCA (cognition/decisions/knowledge-enforcement-gap-rca-2026-07-10.md):
# a hook (owner-question-gate.sh, #2747) merged to `main` and sat INERT on this
# machine for hours -- file present, never registered in settings.local.json --
# because install.sh was never re-run post-merge, and THIS FIELD reported
# `install=unknown` instead of a loud, actionable signal. `unknown` reads as
# "nothing to see here" to both operator and agent. Fixed here: the field now
# resolves to an authoritative CURRENT/DRIFT(n) via scripts/check-install-drift.sh
# (content-hash, per-file -- catches exactly the class of drift a top-level
# version-marker bump can miss) and only falls back to `unknown` when that
# script itself is unavailable or times out, in which case a cheap sentinel
# check (2c below) still tries before giving up.
INSTALL_DRIFT="unknown"

# (2a) cheap version-marker heads-up (kept for its own WARN text; informational
# only -- NOT the status-line source of truth below, since a top-level
# knowledge.json version bump does not necessarily accompany every hook/rule
# change that matters, which is exactly the gap this ticket found).
if [ -n "$JK_ROOT" ] && [ -f "$JK_ROOT/templates/knowledge.json" ]; then
  REPO_VERSION="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$JK_ROOT/templates/knowledge.json" 2>/dev/null \
    | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/"$//')"
  INSTALLED_VERSION=""
  if [ -f "$HOME/.claude/knowledge.json" ]; then
    INSTALLED_VERSION="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/knowledge.json" 2>/dev/null \
      | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/"$//')"
  elif [ -f "$HOME/.claude/jitneuro.json" ]; then
    INSTALLED_VERSION="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/jitneuro.json" 2>/dev/null \
      | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/"$//')"
  fi
  if [ -n "$REPO_VERSION" ] && [ -n "$INSTALLED_VERSION" ] && [ "$REPO_VERSION" != "$INSTALLED_VERSION" ]; then
    warn "knowledge.json version marker changed since last install.sh run (installed=$INSTALLED_VERSION repo=$REPO_VERSION)"
  elif [ -n "$REPO_VERSION" ] && [ -z "$INSTALLED_VERSION" ]; then
    warn "jit-knowledge templates present but no install marker found at ~/.claude/knowledge.json -- run: bash $JK_ROOT/scripts/install.sh"
  fi
fi

# (2b) authoritative check: scripts/check-install-drift.sh (content-hash,
# per-file rules-surface audit). Measured ~0.4s wall-clock on a normal clone
# (well inside the ~2s this step is budgeted); bounded by run_timeout AND
# capped to whatever's left of the hook's own budget so it can never blow the
# ~8s total.
DRIFT_SCRIPT="$JK_ROOT/scripts/check-install-drift.sh"
if [ -n "$JK_ROOT" ] && [ -f "$DRIFT_SCRIPT" ] && budget_ok; then
  DRIFT_TIMEOUT=2
  DRIFT_BUDGET_LEFT="$(budget_left)"
  [ "$DRIFT_BUDGET_LEFT" -lt "$DRIFT_TIMEOUT" ] && DRIFT_TIMEOUT="$DRIFT_BUDGET_LEFT"
  if [ "$DRIFT_TIMEOUT" -ge 1 ]; then
    DRIFT_OUT="$(run_timeout "$DRIFT_TIMEOUT" bash "$DRIFT_SCRIPT" --root "$JK_ROOT" 2>/dev/null)"
    DRIFT_RC=$?
    if [ "$DRIFT_RC" -eq 0 ]; then
      INSTALL_DRIFT="CURRENT"
    elif [ "$DRIFT_RC" -eq 1 ]; then
      DRIFT_N="$(printf '%s\n' "$DRIFT_OUT" | grep -Ec '^\[drift\] (MISSING|STALE|LOCAL-EDIT|TEMPLATE-DRIFT) ')"
      case "$DRIFT_N" in ''|*[!0-9]*) DRIFT_N=1 ;; esac
      INSTALL_DRIFT="DRIFT($DRIFT_N)"
      warn "install drift: DRIFT($DRIFT_N) -- run: bash $JK_ROOT/scripts/install.sh"
      # Opt-in auto-heal (explicit escape hatch from the WARN-only default --
      # see rules/master-agent-operational-requirements.md's "Why WARN, not
      # auto-install" design decision, which this toggle respects rather than
      # reverses: default stays WARN-only, JITK_PREFLIGHT_AUTOHEAL=1 is an
      # explicit opt-in for sessions/Owner that accept the latency tradeoff).
      # Fail-open: any install.sh error or timeout degrades to a WARN, never
      # blocks the session.
      if [ "${JITK_PREFLIGHT_AUTOHEAL:-0}" = "1" ] && budget_ok; then
        AUTOHEAL_TIMEOUT="$(budget_left)"
        [ "$AUTOHEAL_TIMEOUT" -gt 6 ] && AUTOHEAL_TIMEOUT=6
        if [ "$AUTOHEAL_TIMEOUT" -ge 1 ] && run_timeout "$AUTOHEAL_TIMEOUT" bash "$JK_ROOT/scripts/install.sh" >/dev/null 2>&1; then
          warn "JITK_PREFLIGHT_AUTOHEAL=1: ran install.sh to close the DRIFT($DRIFT_N) gap above -- re-checking"
          if run_timeout 2 bash "$DRIFT_SCRIPT" --root "$JK_ROOT" >/dev/null 2>&1; then
            INSTALL_DRIFT="autoheal-ok(was DRIFT($DRIFT_N))"
          else
            INSTALL_DRIFT="autoheal-partial(was DRIFT($DRIFT_N))"
            warn "JITK_PREFLIGHT_AUTOHEAL=1: install.sh ran but drift remains -- check manually"
          fi
        else
          warn "JITK_PREFLIGHT_AUTOHEAL=1: install.sh failed or timed out -- drift NOT closed, run manually: bash $JK_ROOT/scripts/install.sh"
        fi
      fi
    fi
    # any other DRIFT_RC (e.g. 124 from a timeout, or the script erroring)
    # leaves INSTALL_DRIFT=unknown and falls through to the sentinel fallback
  fi
fi

# (2c) fast sentinel fallback -- only reached when (2b) could not run at all
# (check-install-drift.sh missing, budget exhausted, or an unexpected exit
# code). Cheap: one file read, one `git rev-parse`, no subprocess diffing.
# Approximate by design (a managed-header SHA mismatch does not always mean a
# MEANINGFUL drift -- see check-install-drift.sh's own STALE-vs-LOCAL-EDIT
# distinction) but strictly better than reporting `unknown` when a real,
# if imprecise, signal is available.
if [ "$INSTALL_DRIFT" = "unknown" ] && [ -n "$JK_ROOT" ]; then
  SENTINEL_DST="$HOME/.claude/rules/hub-guardrail.md"
  if [ -f "$SENTINEL_DST" ]; then
    REPO_SHA_SENTINEL="$(git -C "$JK_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
    if [ "$REPO_SHA_SENTINEL" != "unknown" ] && head -1 "$SENTINEL_DST" 2>/dev/null | grep -q "$REPO_SHA_SENTINEL"; then
      INSTALL_DRIFT="CURRENT(sentinel)"
    else
      INSTALL_DRIFT="DRIFT(sentinel)"
      warn "sentinel check (rules/hub-guardrail.md managed-header SHA) suggests install.sh drift -- run: bash $JK_ROOT/scripts/install.sh"
    fi
  else
    warn "no install-drift signal available (check-install-drift.sh unavailable and sentinel rule not deployed) -- run: bash $JK_ROOT/scripts/install.sh"
  fi
fi

# --- (3) DOE runner real state: flag + launchd load + recent tick ---
RUNNER_STATE="disarmed"
if [ -n "$JK_ROOT" ] && [ -f "$JK_ROOT/scripts/doe/runner-status.sh" ]; then
  RUNNER_STATE="$(run_timeout 2 bash "$JK_ROOT/scripts/doe/runner-status.sh" "$JK_ROOT" 2>/dev/null)"
  [ -z "$RUNNER_STATE" ] && RUNNER_STATE="unknown"
fi

# --- (3b) git-janitor hygiene summary (ticket #3189, scripts/git-janitor.sh) ---
# Cheap, local, --no-fetch, --summary-only dry-run pass over jit-knowledge's
# OWN worktrees/branches -- awareness only (never mutates; this hook never
# passes --apply). Budget-gated and best-effort like every other network- or
# scan-bound step in this file: skipped entirely once the budget is spent,
# and a missing/slow janitor script degrades to "unknown", never a failure.
JANITOR_STATE="unknown"
if [ -n "$JK_ROOT" ] && [ -f "$JK_ROOT/scripts/git-janitor.sh" ] && budget_ok; then
  JANITOR_SUMMARY="$(run_timeout 3 bash "$JK_ROOT/scripts/git-janitor.sh" --repo "$JK_ROOT" --dry-run --no-fetch --summary-only 2>/dev/null)"
  if [ -n "$JANITOR_SUMMARY" ]; then
    WT_WOULD="$(printf '%s' "$JANITOR_SUMMARY" | grep -o 'worktrees_would_remove=[0-9]*' | cut -d= -f2)"
    WT_REPORTED="$(printf '%s' "$JANITOR_SUMMARY" | grep -o 'worktrees_reported=[0-9]*' | cut -d= -f2)"
    BR_WOULD="$(printf '%s' "$JANITOR_SUMMARY" | grep -o 'branches_would_delete=[0-9]*' | cut -d= -f2)"
    DIRTY="$(printf '%s' "$JANITOR_SUMMARY" | grep -o 'dirty_trees=[0-9]*' | cut -d= -f2)"
    JANITOR_STATE="wt_removable=${WT_WOULD:-?}/reported=${WT_REPORTED:-?} branches_removable=${BR_WOULD:-?} dirty=${DIRTY:-?}"
    if [ "${WT_WOULD:-0}" -gt 0 ] 2>/dev/null || [ "${BR_WOULD:-0}" -gt 0 ] 2>/dev/null || [ "${DIRTY:-0}" -gt 0 ] 2>/dev/null; then
      warn "git hygiene: $JANITOR_STATE -- run: bash $JK_ROOT/scripts/git-janitor.sh --apply (see rules/master-agent-operational-requirements.md)"
    fi
  fi
fi

# --- (3c) origin-sync summary (ticket #3789, scripts/audit-origin-sync.sh) ---
# Cheap, local, --no-fetch, --summary-only pass over jit-knowledge's OWN
# worktrees/branches -- awareness only (never mutates; report-only by
# design). Detects the class of finding git-janitor above does NOT cover:
# UNPUSHED / STRANDED local work (a local branch tip that lives on no
# origin ref, a branch with no upstream, stale uncommitted dirty files, or
# an existing stash) rather than removable hygiene. Origin: 2026-07-13 --
# an ad hoc audit found 5 branches with unpushed commits that had to be
# hand-preserved to backup refs; this field is the mechanical detector so
# that recovery never again depends on someone remembering to run the
# audit by hand. Budget-gated and best-effort like every other scan-bound
# step in this file: skipped entirely once the budget is spent, and a
# missing/slow script degrades to "unknown", never a failure -- the
# script's own nonzero exit on "findings exist" is deliberately IGNORED
# here (captured via command substitution only) so it can never fail this
# fail-open hook.
ORIGIN_SYNC_STATE="unknown"
if [ -n "$JK_ROOT" ] && [ -f "$JK_ROOT/scripts/audit-origin-sync.sh" ] && budget_ok; then
  ORIGIN_SYNC_SUMMARY="$(run_timeout 3 bash "$JK_ROOT/scripts/audit-origin-sync.sh" --repo "$JK_ROOT" --no-fetch --summary-only 2>/dev/null)"
  if [ -n "$ORIGIN_SYNC_SUMMARY" ]; then
    STRANDED_N="$(printf '%s' "$ORIGIN_SYNC_SUMMARY" | grep -o 'stranded=[0-9]*' | cut -d= -f2)"
    NO_UPSTREAM_N="$(printf '%s' "$ORIGIN_SYNC_SUMMARY" | grep -o 'no_upstream=[0-9]*' | cut -d= -f2)"
    DIRTY_STALE_N="$(printf '%s' "$ORIGIN_SYNC_SUMMARY" | grep -o 'dirty_stale=[0-9]*' | cut -d= -f2)"
    STASHES_N="$(printf '%s' "$ORIGIN_SYNC_SUMMARY" | grep -o 'stashes=[0-9]*' | cut -d= -f2)"
    TOTAL_N="$(printf '%s' "$ORIGIN_SYNC_SUMMARY" | grep -o 'total_findings=[0-9]*' | cut -d= -f2)"
    ORIGIN_SYNC_STATE="${TOTAL_N:-0}"
    if [ "${STRANDED_N:-0}" -gt 0 ] 2>/dev/null; then
      warn "origin-sync: $STRANDED_N stranded branch(es) (commits nowhere on origin) -- run: bash $JK_ROOT/scripts/audit-origin-sync.sh --repo $JK_ROOT"
    fi
    if [ "${TOTAL_N:-0}" -gt 0 ] 2>/dev/null; then
      warn "origin-sync summary: stranded=${STRANDED_N:-?} no_upstream=${NO_UPSTREAM_N:-?} dirty_stale=${DIRTY_STALE_N:-?} stashes=${STASHES_N:-?}"
    fi
  fi
fi

# --- (3d) Hub.md staleness check (ticket #4663) ---
# Additive, WARN-only, fail-open awareness of whether the ACTIVE lane's
# Hub.md (the durable task-state file per rules/documentation-updates.md /
# rules/hub-guardrail.md) has gone stale -- i.e. nobody has touched it in a
# long time even though sessions keep running against this lane. This never
# blocks the session; any resolution error degrades to `hub=unknown`.
#
# Resolution mirrors the lane/hub-lookup pattern already used by
# stop-continue-queue.sh (see that file's "resolve HubCentral root" and
# "cwd .HUB/Hub.md" sections): lane = basename of the project's git toplevel,
# preferring the branch-agnostic $HUBCENTRAL_ROOT/<lane>/Hub.md hub, then
# falling back to the project's own .hub/.HUB Hub.md variants.
HUB_STATE="none"
HUB_STALE_HOURS="${JITK_HUB_STALE_HOURS:-24}"
case "$HUB_STALE_HOURS" in ''|*[!0-9]*) HUB_STALE_HOURS=24 ;; esac

HUB_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HUB_GIT_TOP="$(run_timeout 2 git -C "$HUB_PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)"
HUB_LANE=""
if [ -n "$HUB_GIT_TOP" ]; then
  HUB_LANE="$(basename "$HUB_GIT_TOP")"
fi

HUB_FILE=""
if [ -n "$HUB_LANE" ]; then
  HC_ROOT_FOR_HUB="${HUBCENTRAL_ROOT:-}"
  if [ -z "$HC_ROOT_FOR_HUB" ] && [ -n "$HUB_GIT_TOP" ]; then
    HUB_CODE_ROOT="$(dirname "$HUB_GIT_TOP")"
    [ -d "$HUB_CODE_ROOT/_HubCentral" ] && HC_ROOT_FOR_HUB="$HUB_CODE_ROOT/_HubCentral"
  fi
  if [ -n "$HC_ROOT_FOR_HUB" ] && [ -f "$HC_ROOT_FOR_HUB/$HUB_LANE/Hub.md" ]; then
    HUB_FILE="$HC_ROOT_FOR_HUB/$HUB_LANE/Hub.md"
  fi
fi
if [ -z "$HUB_FILE" ] && [ -n "$HUB_GIT_TOP" ]; then
  for cand in "$HUB_GIT_TOP/.hub/hub.md" "$HUB_GIT_TOP/.HUB/hub.md" \
              "$HUB_GIT_TOP/.hub/Hub.md" "$HUB_GIT_TOP/.HUB/Hub.md"; do
    if [ -f "$cand" ]; then HUB_FILE="$cand"; break; fi
  done
fi

if [ -n "$HUB_FILE" ] && [ -f "$HUB_FILE" ]; then
  HUB_MTIME_EPOCH=""
  # Prefer the file's last commit time when it is git-tracked (more meaningful
  # than a checkout/clone mtime, which resets on every fresh clone/checkout);
  # fall back to filesystem mtime (macOS `stat -f`, Linux/GNU `stat -c`).
  if [ -n "$HUB_GIT_TOP" ]; then
    HUB_MTIME_EPOCH="$(run_timeout 2 git -C "$HUB_GIT_TOP" log -1 --format=%ct -- "$HUB_FILE" 2>/dev/null)"
  fi
  case "$HUB_MTIME_EPOCH" in ''|*[!0-9]*) HUB_MTIME_EPOCH="" ;; esac
  if [ -z "$HUB_MTIME_EPOCH" ]; then
    HUB_MTIME_EPOCH="$(stat -f %m "$HUB_FILE" 2>/dev/null)"
    case "$HUB_MTIME_EPOCH" in ''|*[!0-9]*) HUB_MTIME_EPOCH="" ;; esac
  fi
  if [ -z "$HUB_MTIME_EPOCH" ]; then
    HUB_MTIME_EPOCH="$(stat -c %Y "$HUB_FILE" 2>/dev/null)"
    case "$HUB_MTIME_EPOCH" in ''|*[!0-9]*) HUB_MTIME_EPOCH="" ;; esac
  fi

  if [ -n "$HUB_MTIME_EPOCH" ]; then
    HUB_NOW_EPOCH="$(date +%s 2>/dev/null)"
    case "$HUB_NOW_EPOCH" in ''|*[!0-9]*) HUB_NOW_EPOCH="" ;; esac
    if [ -n "$HUB_NOW_EPOCH" ]; then
      HUB_AGE_SECONDS=$((HUB_NOW_EPOCH - HUB_MTIME_EPOCH))
      [ "$HUB_AGE_SECONDS" -lt 0 ] && HUB_AGE_SECONDS=0
      HUB_AGE_HOURS=$((HUB_AGE_SECONDS / 3600))
      if [ "$HUB_AGE_HOURS" -gt "$HUB_STALE_HOURS" ]; then
        HUB_STATE="stale:${HUB_AGE_HOURS}h"
        warn "active Hub.md ($HUB_FILE) looks stale -- last updated ${HUB_AGE_HOURS}h ago (> ${HUB_STALE_HOURS}h); reconcile task state per rules/documentation-updates.md"
      else
        HUB_STATE="fresh:${HUB_AGE_HOURS}h"
      fi
    else
      HUB_STATE="unknown"
    fi
  else
    HUB_STATE="unknown"
  fi
fi

# --- (3e) DOE lane-block banner (Owner directive 2026-08-02) --------------
# Owner directive 2026-08-02, verbatim: "if there is a doe block the
# knowledge lane MUST display a large, easy to see multi-line (5+) banner to
# alert me." Mechanical detection of any DOE lane currently kill-flagged so a
# blocked lane is impossible to miss at session start rather than depending
# on someone noticing a stalled Ready queue days later.
#
# A "DOE block" here is a per-lane budget-kill flag file
# (scripts/doe/state.<lane>/doe-kill.flag) written by doe-tick.sh when the
# kill rule trips (see that file's KILL_FLAG / "budget kill rule tripped"
# comments) -- present = the lane will not dispatch until Owner clears it.
# These live under the DOE RUNTIME checkout, not necessarily this clone (see
# doe-runtime-sync.sh / arm-doe.sh for the scripts/doe/state.<lane> layout).
#
# Root resolution (first that exists, fail-open, matches the runtime-root
# convention doe-health-check.sh already uses via
# DOE_HEALTH_CHECK_RUNTIME_CHECKOUT_ROOT):
#   1) $DOE_HEALTH_CHECK_RUNTIME_CHECKOUT_ROOT/scripts/doe (env override)
#   2) $HOME/Code/Worktrees/jit-knowledge/doe-runtime/scripts/doe (default
#      runtime checkout on this machine)
#   3) $JK_ROOT/scripts/doe (main-clone fallback -- state.<lane> dirs can
#      also live directly under the resolved jit-knowledge clone)
# A pure local directory glob -- cheap, but still budget-gated like every
# other scan step in this file. Any resolution failure (no root, unreadable
# dir, no flags found) degrades silently to doe_blocked=none; this section
# NEVER errors and NEVER blocks the session.
DOE_STATE_ROOT=""
if [ -n "${DOE_HEALTH_CHECK_RUNTIME_CHECKOUT_ROOT:-}" ] && [ -d "${DOE_HEALTH_CHECK_RUNTIME_CHECKOUT_ROOT}/scripts/doe" ]; then
  DOE_STATE_ROOT="${DOE_HEALTH_CHECK_RUNTIME_CHECKOUT_ROOT}/scripts/doe"
elif [ -d "$HOME/Code/Worktrees/jit-knowledge/doe-runtime/scripts/doe" ]; then
  DOE_STATE_ROOT="$HOME/Code/Worktrees/jit-knowledge/doe-runtime/scripts/doe"
elif [ -n "$JK_ROOT" ] && [ -d "$JK_ROOT/scripts/doe" ]; then
  DOE_STATE_ROOT="$JK_ROOT/scripts/doe"
fi

# doe_flag_since <flag-path> -- human-readable mtime, BSD stat (macOS) then
# GNU stat (Linux CI) then epoch-to-date, falling back to "unknown" rather
# than erroring (mirrors the (3d) Hub.md staleness section's stat fallback).
doe_flag_since() {
  local flag="$1" epoch=""
  epoch="$(stat -f %m "$flag" 2>/dev/null)"
  case "$epoch" in ''|*[!0-9]*) epoch="" ;; esac
  if [ -z "$epoch" ]; then
    epoch="$(stat -c %Y "$flag" 2>/dev/null)"
    case "$epoch" in ''|*[!0-9]*) epoch="" ;; esac
  fi
  if [ -n "$epoch" ]; then
    local human
    human="$(date -r "$epoch" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null)"
    [ -z "$human" ] && human="$(date -d "@$epoch" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null)"
    if [ -n "$human" ]; then
      printf '%s' "$human"
      return
    fi
  fi
  printf 'unknown'
}

DOE_BLOCKED_LANES=""
DOE_BANNER_ROWS=()
if [ -n "$DOE_STATE_ROOT" ] && [ -d "$DOE_STATE_ROOT" ] && budget_ok; then
  for d in "$DOE_STATE_ROOT"/state.*; do
    [ -d "$d" ] || continue
    DOE_FLAG="$d/doe-kill.flag"
    [ -f "$DOE_FLAG" ] || continue
    DOE_LANE_NAME="$(basename "$d")"
    DOE_LANE_NAME="${DOE_LANE_NAME#state.}"
    DOE_SINCE="$(doe_flag_since "$DOE_FLAG")"
    DOE_BLOCKED_LANES="${DOE_BLOCKED_LANES:+$DOE_BLOCKED_LANES,}$DOE_LANE_NAME"
    DOE_BANNER_ROWS+=("# LANE: $DOE_LANE_NAME")
    DOE_BANNER_ROWS+=("#   SINCE: $DOE_SINCE")
    DOE_BANNER_ROWS+=("#   CAUSE: budget kill rule -- lane will not dispatch until cleared")
    DOE_BANNER_ROWS+=("#   EFFECT: Ready tickets STALLED")
    DOE_BANNER_ROWS+=("#   RESUME: rm $DOE_FLAG")
  done
fi

DOE_BLOCKED_STATUS="none"
if [ -n "$DOE_BLOCKED_LANES" ]; then
  DOE_BLOCKED_STATUS="$DOE_BLOCKED_LANES"
  DOE_BORDER="################################################################################"
  # Printed HERE (not queued to WARN_LINES) so it is the first thing this
  # hook emits -- ahead of every WARN line, which only print in the "emit"
  # section at the very end of the script. At least 8 lines even with a
  # single blocked lane (well over Owner's "5+" ask): border, blank, title,
  # blank, separator, 5 per-lane fields, border.
  echo "[jk-preflight] DOE BLOCK DETECTED"
  echo "$DOE_BORDER"
  echo "#"
  echo "#   DOE LANE BLOCKED -- OWNER ATTENTION REQUIRED"
  echo "#"
  echo "$DOE_BORDER"
  for row in "${DOE_BANNER_ROWS[@]}"; do
    echo "$row"
  done
  echo "$DOE_BORDER"
fi

# --- (4) lane ready-count + (5) inbox unread-count + (6) JWT expiry: best-effort, network-bound, budget-gated ---
LANE_READY="?"
INBOX_UNREAD="?"
JWT_EXPIRY="unknown"

ENV_FILE="${WORK_ITEMS_ENV_FILE:-}"
if [ -z "$ENV_FILE" ]; then
  SESSIONS_DIR="$HOME/Code/.sessions/work-items/sessions"
  if [ -d "$SESSIONS_DIR" ]; then
    LANE_GUESS="$(basename "${JK_ROOT:-$PWD}")"
    ENV_FILE="$(ls -t "$SESSIONS_DIR"/claude-*-"${LANE_GUESS}"-knowledge.env 2>/dev/null | head -1)"
  fi
fi

if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
  get_env() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | sed -e 's/^["'\'']//' -e 's/["'\'']$//'; }
  JWT="$(get_env WORK_ITEMS_SKILL_JWT)"
  EXPIRES_AT="$(get_env WORK_ITEMS_TOKEN_EXPIRES_AT)"
  LANE_NAME="$(get_env WORK_ITEMS_REFRESH_LANE)"
  [ -z "$LANE_NAME" ] && [ -n "$JK_ROOT" ] && LANE_NAME="$(basename "$JK_ROOT")"

  if [ -n "$EXPIRES_AT" ] && command -v python3 >/dev/null 2>&1; then
    JWT_EXPIRY="$(python3 -c "
import sys, datetime
raw = '''$EXPIRES_AT'''
try:
    exp = datetime.datetime.fromisoformat(raw.replace('Z', '+00:00'))
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=datetime.timezone.utc)
    now = datetime.datetime.now(datetime.timezone.utc)
    delta = (exp - now).total_seconds()
    if delta <= 0:
        print('EXPIRED')
    else:
        h = int(delta // 3600); m = int((delta % 3600) // 60)
        print(f'{h}h{m}m')
except Exception:
    print('unknown')
" 2>/dev/null)"
    [ -z "$JWT_EXPIRY" ] && JWT_EXPIRY="unknown"
    [ "$JWT_EXPIRY" = "EXPIRED" ] && warn "work-items JWT is EXPIRED ($ENV_FILE) -- run hubcentral-login to refresh"
  fi

  if [ -n "$JWT" ] && [ -n "$LANE_NAME" ] && budget_ok && command -v python3 >/dev/null 2>&1; then
    HC_INTERCOM="$HC_ROOT/scripts/intercom-curl.sh"
    if [ -f "$HC_INTERCOM" ]; then
      HB_JSON="$(run_timeout 3 bash "$HC_INTERCOM" heartbeat --from "claude:preflight:${LANE_NAME}" --lane "$LANE_NAME" --raw --env-file "$ENV_FILE" 2>/dev/null)"
      if [ -n "$HB_JSON" ]; then
        PARSED="$(printf '%s' "$HB_JSON" | python3 -c 'import json,sys
try:
    print(int(json.load(sys.stdin).get("unread") or 0))
except Exception:
    print("?")' 2>/dev/null)"
        [ -n "$PARSED" ] && INBOX_UNREAD="$PARSED"
      fi
    fi
  fi

  if [ -n "$JWT" ] && [ -n "$LANE_NAME" ] && budget_ok && command -v python3 >/dev/null 2>&1; then
    HC_DEVOPS="$HC_ROOT/scripts/devops-task-curl.sh"
    if [ -f "$HC_DEVOPS" ]; then
      READY_JSON="$(run_timeout 3 bash "$HC_DEVOPS" ready --lane "$LANE_NAME" --limit 50 --raw --env-file "$ENV_FILE" 2>/dev/null)"
      if [ -n "$READY_JSON" ]; then
        PARSED="$(printf '%s' "$READY_JSON" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    items = d.get("items") if isinstance(d, dict) else d if isinstance(d, list) else []
    print(len(items) if isinstance(items, list) else "?")
except Exception:
    print("?")' 2>/dev/null)"
        [ -n "$PARSED" ] && LANE_READY="$PARSED"
      fi
    fi
  fi
else
  warn "no work-items env file resolved -- lane ready-count, inbox unread-count, and JWT expiry unavailable this session (run hubcentral-login)"
fi

# --- emit: WARN lines first, then the single compact status line ---
for w in "${WARN_LINES[@]:-}"; do
  [ -n "$w" ] && echo "[jk-preflight] WARN: $w"
done

ELAPSED=$((SECONDS - HOOK_STARTED_AT))
echo "[jk-preflight] jit-knowledge=$REPO_STATUS_JK HubCentral=$REPO_STATUS_HC install=$INSTALL_DRIFT runner=$RUNNER_STATE doe_blocked=$DOE_BLOCKED_STATUS janitor=($JANITOR_STATE) origin_sync=$ORIGIN_SYNC_STATE lane_ready=$LANE_READY inbox_unread=$INBOX_UNREAD hub=$HUB_STATE jwt_expires_in=$JWT_EXPIRY elapsed=${ELAPSED}s"
echo "[jk-preflight] See rules/master-agent-operational-requirements.md for what each field means and how to act on a WARN."

exit 0
