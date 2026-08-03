#!/bin/bash
# jitk-preflight-gate.sh -- PreToolUse gate for DESIGN 4615 (ticket #4615),
# STAGE 1 (WARN MODE ONLY).
#
# WHAT IT DOES (Stage 1)
# Classifies Edit / Write / mutating-Bash tool calls against the session's
# preflight-attestation state (see jitk-preflight-attest.sh). When a
# candidate mutation happens on a bootstrapped-but-unattested session, it
# LOGS a would-block event and prints a one-line WARN to stderr -- and then
# ALWAYS exits 0. Nothing is ever blocked in Stage 1. This file also
# implements the JITK_PREFLIGHT_GATE_MODE=block code path described by the
# design's Stage 2 rollout section, so the eventual blocking flip is a
# config change, not a rewrite -- but NO shipped config in this ticket ever
# sets that mode, and the hard-coded default below is "warn".
#
# THE ABSOLUTE INVARIANT (binding, out-of-scope-to-change): in warn mode
# (the only mode any installed config in this ticket enables), this script
# MUST ALWAYS exit 0, on every code path, including internal errors,
# malformed payloads, missing dependencies, and unresolved session IDs.
# Anti-brick strictly outranks classification accuracy.
#
# Matchers: Edit, Write, Bash (register the SAME script under all three;
# it branches on tool_name).
#
# Engagement rule (checked first, before any classification):
#   JITK_PREFLIGHT_GATE=0            -> exit 0  (global escape hatch)
#   DOE_HEADLESS=1                    -> exit 0  (headless workers bootstrap themselves)
#   SID cannot be resolved            -> exit 0  (fail-open)
#   no bootstrap-pending.<SID> AND
#     no preflight-done.<SID>.marker  -> exit 0  (never ran SessionStart:
#                                                  subagent / non-master /
#                                                  non-Claude-Code context)
#   preflight-done.<SID>.marker exists -> exit 0  (already attested)
#
# Bootstrap escape (design 2.2, the single most important exemption -- the
# gate must never forbid the action that clears it):
#   - any Bash command invoking jitk-preflight-attest.sh
#   - any Write/Edit whose target path is under
#     <STATE_DIR>/preflight/ or <STATE_DIR>/heartbeats/
#
# Bash mutation classification (design 2.3): a DENYLIST, default-allow.
# Anything not on the denylist -- all read-only commands and any unknown
# command -- flows without a WARN. This guarantees "a read-only Bash must
# never be [warned/would-block-logged as mutation]," at the accepted minor
# cost that a truly novel mutating command could slip through pre-marker
# (acceptable: the gate only needs to catch the FIRST mutation to force
# attestation, and Stage 1 cannot block regardless).
#
# Edit and Write are inherently mutating (subject only to the state-dir
# exemption above).
#
# Canonical source: jit-knowledge/templates/claude-hooks/jitk-preflight-gate.sh
# Install via: bash scripts/install.sh
#
# Test mode: `jitk-preflight-gate.sh --verdict '<json-payload>'` prints the
# verdict (ALLOW / WARN / BLOCK / SKIP / PARSE_FAIL) without exit-2/log side
# effects, for unit testing. See scripts/tests/preflight-gate.test.sh.

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- global escape hatches (checked first, before anything else) ----------
if [ "${JITK_PREFLIGHT_GATE:-1}" = "0" ]; then
  exit 0
fi
if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

MODE="${JITK_PREFLIGHT_GATE_MODE:-warn}"

# ---------- resolve PROJECT_DIR / STATE_DIR (mirrors stop-continue-queue.sh) ----------
norm() {
  local p="$1"
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) printf '%s' "$p" | sed 's/\\/\//g' ;;
    *) printf '%s' "$p" ;;
  esac
}
CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJECT_DIR="$(norm "$CWD")"
STATE_DIR="$PROJECT_DIR/.sessions"
PREFLIGHT_DIR="$STATE_DIR/preflight"
HEARTBEATS_DIR="$STATE_DIR/heartbeats"

# ---------- read stdin (2s bounded, never hang a tool call) ----------
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
elif command -v gtimeout >/dev/null 2>&1; then
  INPUT=$(gtimeout 2 cat 2>/dev/null || true)
else
  INPUT=$(cat 2>/dev/null || true)
fi

# ---------- resolve SID (env first, payload fallback -- mirrors stop-continue-queue.sh) ----------
SID="${CLAUDE_SESSION_ID:-}"
if [ -z "$SID" ] && [ -n "$INPUT" ]; then
  SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

# ---------- extract tool_name / command / file_path without requiring python3 ----------
# Prefer python3 (robust to nested JSON) but degrade gracefully to a grep
# heuristic, and to "SKIP-classification, allow" if neither can make sense
# of the payload -- this hook must never error out into anything but exit 0.
TOOL_NAME=""
CMD=""
FILE_PATH=""
PARSE_OK=0

if [ -n "$INPUT" ] && command -v python3 >/dev/null 2>&1; then
  PARSED="$(INPUT_JSON="$INPUT" python3 - <<'PYEOF' 2>/dev/null
import json, os, sys
raw = os.environ.get("INPUT_JSON", "")
try:
    data = json.loads(raw)
except Exception:
    print("PARSE_FAIL|||")
    sys.exit(0)
if not isinstance(data, dict):
    print("PARSE_FAIL|||")
    sys.exit(0)
tool_name = str(data.get("tool_name", "") or "")
tool_input = data.get("tool_input", {}) or {}
if not isinstance(tool_input, dict):
    tool_input = {}
cmd = str(tool_input.get("command", "") or "")
file_path = str(tool_input.get("file_path", "") or "")
# Flatten newlines so downstream shell parsing of this single line stays sane.
cmd = cmd.replace("\n", " ; ")
print(f"OK|||{tool_name}|||{cmd}|||{file_path}")
PYEOF
)"
  case "$PARSED" in
    OK\|\|\|*)
      PARSE_OK=1
      REST="${PARSED#OK|||}"
      TOOL_NAME="${REST%%|||*}"
      REST="${REST#*|||}"
      CMD="${REST%%|||*}"
      FILE_PATH="${REST#*|||}"
      ;;
    *)
      PARSE_OK=0
      ;;
  esac
elif [ -n "$INPUT" ]; then
  # No python3: crude but conservative grep fallback. Only trust it enough
  # to extract tool_name; command/file_path extraction without a real JSON
  # parser is too fragile to drive a WARN decision, so leave them empty
  # (falls through to "no candidate mutation" -> exit 0).
  TOOL_NAME=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/')
  [ -n "$TOOL_NAME" ] && PARSE_OK=1
fi

# ---------- engagement rule ----------
_engagement_verdict() {
  if [ -z "$SID" ]; then
    echo "SKIP:no-sid"
    return
  fi
  if [ ! -f "$PREFLIGHT_DIR/bootstrap-pending.$SID" ] && [ ! -f "$PREFLIGHT_DIR/preflight-done.$SID.marker" ]; then
    echo "SKIP:not-engaged"
    return
  fi
  if [ -f "$PREFLIGHT_DIR/preflight-done.$SID.marker" ]; then
    echo "SKIP:attested"
    return
  fi
  echo "ENGAGED"
}

# ---------- bootstrap escape (design 2.2) ----------
_is_bootstrap_escape() {
  # Bash invoking the attest command is always allowed.
  if [ "$TOOL_NAME" = "Bash" ] && printf '%s' "$CMD" | grep -q 'jitk-preflight-attest\.sh'; then
    return 0
  fi
  # Write/Edit targeting .sessions bookkeeping paths is always allowed.
  if { [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; } && [ -n "$FILE_PATH" ]; then
    case "$FILE_PATH" in
      "$PREFLIGHT_DIR"/*|"$HEARTBEATS_DIR"/*) return 0 ;;
    esac
  fi
  return 1
}

# ---------- Bash mutation classification (design 2.3: denylist, default-allow) ----------
_split_segments() {
  local cmd="$1" work
  work="${cmd//&&/$'\n'}"; work="${work//||/$'\n'}"; work="${work//;/$'\n'}"; work="${work//|/$'\n'}"
  printf '%s\n' "$work"
}

_is_mutating_bash_segment() {
  local s="$1"
  # git mutations
  echo "$s" | grep -qE '(^|[[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+(commit|push|merge|rebase|reset|revert|tag|cherry-pick|am|apply)([[:space:]]|$)' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])git[[:space:]]+branch[[:space:]]+-D' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])git[[:space:]]+stash[[:space:]]+(push|pop|apply)' && { echo yes; return; }
  # gh mutations
  echo "$s" | grep -qE '(^|[[:space:]])gh[[:space:]]+(pr|issue)[[:space:]]+(create|merge|edit|close|comment)' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])gh[[:space:]]+release[[:space:]]+create' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])gh[[:space:]]+repo[[:space:]]+(create|delete)' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])gh[[:space:]]+api[[:space:]].*-X[[:space:]]*(POST|PUT|PATCH|DELETE)' && { echo yes; return; }
  # filesystem writes
  echo "$s" | grep -qE '(^|[[:space:]])(rm|rmdir|mv|cp|mkdir|truncate|dd|chmod|chown|ln)([[:space:]]|$)' && { echo yes; return; }
  # in-place edits
  echo "$s" | grep -qE '(^|[[:space:]])(sed|perl)[[:space:]]+-i' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])tee([[:space:]]|$)' && { echo yes; return; }
  # redirection to a real file (excluding /dev/null and fd-dups like 2>&1):
  # strip /dev/null redirects and fd-dup redirects first, then check whether
  # any ">" or ">>" targeting a real path remains.
  local cleaned
  cleaned="$(echo "$s" | sed -E 's/[0-9]*>>?[[:space:]]*\/dev\/null//g; s/[0-9]>&[0-9]//g')"
  echo "$cleaned" | grep -qE '>>?[[:space:]]*[^[:space:]]' && { echo yes; return; }
  # package / deploy mutations
  echo "$s" | grep -qE '(^|[[:space:]])(npm|pnpm|yarn)[[:space:]]+(install|add|publish)' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])pip[[:space:]]+install' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])docker[[:space:]]+(build|push|run)' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])az[[:space:]].*[[:space:]]create([[:space:]]|$)' && { echo yes; return; }
  echo "$s" | grep -qE '(^|[[:space:]])terraform[[:space:]]+apply' && { echo yes; return; }
  # devops mutations
  echo "$s" | grep -qE 'devops-task[-a-z]*\.(sh|ps1)[[:space:]]+(create|update|claim|complete|release|link-dep|archive)' && { echo yes; return; }
  echo "no"
}

_is_mutating_bash() {
  local cmd="$1" seg
  while IFS= read -r seg; do
    [ -z "$seg" ] && continue
    [ "$(_is_mutating_bash_segment "$seg")" = "yes" ] && { echo yes; return; }
  done <<< "$(_split_segments "$cmd")"
  echo no
}

# ---------- verdict computation (shared by hook mode and --verdict test mode) ----------
_verdict() {
  local eng
  eng="$(_engagement_verdict)"
  case "$eng" in
    SKIP:*) echo "$eng"; return ;;
  esac

  if [ "$PARSE_OK" -ne 1 ] || [ -z "$TOOL_NAME" ]; then
    echo "PARSE_FAIL"
    return
  fi

  case "$TOOL_NAME" in
    Edit|Write|Bash) : ;;
    *) echo "SKIP:not-a-candidate-tool"; return ;;
  esac

  if _is_bootstrap_escape; then
    echo "ALLOW:escape"
    return
  fi

  local is_mutation="no"
  case "$TOOL_NAME" in
    Edit|Write) is_mutation="yes" ;;
    Bash) is_mutation="$(_is_mutating_bash "$CMD")" ;;
  esac

  if [ "$is_mutation" != "yes" ]; then
    echo "ALLOW:read-only"
    return
  fi

  if [ "$MODE" = "block" ]; then
    echo "BLOCK"
  else
    echo "WARN"
  fi
}

VERDICT="$(_verdict)"

# ---------- test-mode entry point ----------
if [ "${1:-}" = "--verdict" ] && [ -n "${2:-}" ]; then
  INPUT="$2"
  # re-parse with the injected payload (test harness passes it as $2 instead
  # of stdin so it can be combined with env-var mode switches deterministically)
  SID="${CLAUDE_SESSION_ID:-}"
  if [ -z "$SID" ]; then
    SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  fi
  if command -v python3 >/dev/null 2>&1; then
    PARSED="$(INPUT_JSON="$INPUT" python3 - <<'PYEOF' 2>/dev/null
import json, os, sys
raw = os.environ.get("INPUT_JSON", "")
try:
    data = json.loads(raw)
except Exception:
    print("PARSE_FAIL|||")
    sys.exit(0)
if not isinstance(data, dict):
    print("PARSE_FAIL|||")
    sys.exit(0)
tool_name = str(data.get("tool_name", "") or "")
tool_input = data.get("tool_input", {}) or {}
if not isinstance(tool_input, dict):
    tool_input = {}
cmd = str(tool_input.get("command", "") or "")
file_path = str(tool_input.get("file_path", "") or "")
cmd = cmd.replace("\n", " ; ")
print(f"OK|||{tool_name}|||{cmd}|||{file_path}")
PYEOF
)"
    case "$PARSED" in
      OK\|\|\|*)
        PARSE_OK=1
        REST="${PARSED#OK|||}"
        TOOL_NAME="${REST%%|||*}"
        REST="${REST#*|||}"
        CMD="${REST%%|||*}"
        FILE_PATH="${REST#*|||}"
        ;;
      *) PARSE_OK=0 ;;
    esac
  else
    PARSE_OK=0
  fi
  _verdict
  exit 0
fi

# ---------- hook mode: act on the verdict, log, and (Stage 1) ALWAYS exit 0 ----------
LOG="$PREFLIGHT_DIR/would-block.${SID:-unknown}.log"

case "$VERDICT" in
  WARN)
    mkdir -p "$PREFLIGHT_DIR" 2>/dev/null
    printf '%s tool=%s cmd_or_path=%s\n' "$(date 2>/dev/null)" "$TOOL_NAME" "${CMD:-$FILE_PATH}" >> "$LOG" 2>/dev/null
    echo "[jitk-preflight-gate] WARN (would-block, Stage 1 does not enforce): session $SID has not attested the bootstrap chain. Run: bash ~/.claude/hooks/jitk-preflight-attest.sh" >&2
    exit 0
    ;;
  BLOCK)
    # Stage 2 code path -- unreachable unless JITK_PREFLIGHT_GATE_MODE=block
    # is explicitly set, which no config shipped in this ticket does. Left
    # here so the eventual Owner-gated flip is a config change only.
    mkdir -p "$PREFLIGHT_DIR" 2>/dev/null
    printf '%s tool=%s cmd_or_path=%s BLOCKED\n' "$(date 2>/dev/null)" "$TOOL_NAME" "${CMD:-$FILE_PATH}" >> "$LOG" 2>/dev/null
    cat >&2 <<EOF
BLOCKED by jitk-preflight-gate (ticket #4615): this session has not attested
that the bootstrap chain was read. Mutations are gated until you do.

To clear (after actually reading AGENTS.md -> COMPANY.md -> README.md ->
INDEX.md and printing the Running-Thin banner), run ONCE:
  bash ~/.claude/hooks/jitk-preflight-attest.sh

Emergency unblock (Owner / wrongly-blocked session):
  export JITK_PREFLIGHT_GATE=0     # disables this gate for the session
EOF
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
