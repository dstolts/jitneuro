#!/bin/bash
# jk-owner-path-gate -- PreToolUse gate for rules/owner-facing-artifact-paths.md
# (ticket #4595: graduate the Owner-requested WIP path guardrail into a
# deterministic harness backstop).
#
# WHAT IT DOES
# Session-side enforcement of the Owner-facing artifact-path contract. Two
# concerns, split by which tool is about to run:
#
#   1. WRITE SIDE (Write / Edit) -- an authored work product must not land in a
#      session scratchpad (`^(/private)?/tmp/`, `/tmp/`, `claude-<pid>` temp
#      dirs). Those are wiped on session rotation; anything another step,
#      session, or person consumes belongs in the owning repo under ~/Code.
#      Default WARN (non-blocking) so genuine harness-internal tool I/O is not
#      trapped -- flip to BLOCK with JIT_OWNER_PATH_GATE_MODE=block.
#
#   2. OPEN / PRESENT SIDE (Bash `code`/`open`/`cursor` <path>) -- a path shown
#      to Owner MUST exist, be non-empty, live under the workspace (not a
#      scratchpad), and NOT be branch-only content in a SHARED main checkout
#      (which vanishes the moment the clone switches branches -- present via a
#      dedicated `git worktree` path instead). `code <nonexistent>` silently
#      opens a BLANK buffer; Owner sees an empty file and loses trust in every
#      other link. These are hard BLOCKs (the incident this rule came from),
#      unless JIT_OWNER_PATH_GATE_MODE=off.
#
# Event: PreToolUse, matchers: "Write", "Edit", "Bash"
# Exit contract (rules/claude-code-hook-deployment.md):
#   0 = allow (compliant, non-matching tool, off, or any parse failure --
#       FAIL-OPEN, never traps the session)
#   1 = WARN mode hit -- non-blocking banner on stderr, action still runs
#   2 = BLOCK mode hit -- action blocked, stderr fed back to the model
#
# Config: JIT_OWNER_PATH_GATE_MODE env var -- "" / "default" (write-side WARN,
# open-side BLOCK), "block" (both BLOCK), "warn" (both WARN), "off" (disabled).
# Same config-env-var pattern as bash-secret-scan.sh's JIT_BASH_SECRET_SCAN_MODE.
#
# Bypass: DOE_HEADLESS=1 -- headless DOE workers do not present paths to Owner
# interactively and already write inside their own isolated worktree; kept
# symmetric with the bypass in owner-question-gate.sh / agent-cost-tiering-gate.sh.
#
# Canonical source: jit-knowledge/templates/claude-hooks/owner-path-gate.sh
# Install via: bash scripts/install.sh
#
# Test mode: `owner-path-gate.sh --verdict '<json-payload>'` prints the verdict
# (ALLOW / WARN:<reason> / BLOCK:<reason> / SKIP / PARSE_FAIL) without exit-1/2
# side effects, for unit testing (see
# templates/claude-hooks/tests/owner-path-gate.test.sh). Existence, non-empty,
# and shared-checkout-branch facts are environmental; a test payload may inject
# them deterministically with top-level "test_exists" / "test_nonempty" /
# "test_shared_branch" booleans (never present in a real Claude payload, so
# live invocation always computes them from the filesystem/git instead).

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- scratchpad / tmp path shape (pure string) ----------
# Leading (/private)?/tmp, a bare /tmp segment, or a claude-<digits> harness
# temp dir anywhere in the path. Kept in sync with the rule body's examples.
_is_scratchpad_path() {
  printf '%s' "$1" | grep -Eq '^(/private)?/tmp/|(^|/)tmp/|/claude-[0-9]+/|/scratchpad/'
}

# ---------- live shared-checkout-branch detection ----------
# True when the path lives inside a git work tree that is the repo's MAIN clone
# (NOT a linked worktree -- a linked worktree's git-dir contains /worktrees/)
# AND HEAD is on a non-default branch AND the path is not itself under a
# Worktrees/ segment. Best-effort and fail-open: any git error -> not shared.
_live_shared_branch() {
  local path="$1" dir gitdir branch
  case "$path" in
    */Worktrees/*) return 1 ;;  # already a dedicated worktree path -- fine
  esac
  dir="$path"
  [ -e "$dir" ] || dir="$(dirname "$path")"
  command -v git >/dev/null 2>&1 || return 1
  ( cd "$dir" 2>/dev/null || exit 1
    [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] || exit 1
    gitdir="$(git rev-parse --git-dir 2>/dev/null)"
    case "$gitdir" in
      */worktrees/*) exit 1 ;;  # linked worktree -- not a shared main checkout
    esac
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    case "$branch" in
      main|master|uat|HEAD|"") exit 1 ;;  # default branch or detached -- fine
    esac
    exit 0
  )
}

# ---------- classify one payload; prints verdict (+ reason) ----------
# Verdicts: ALLOW | SKIP | PARSE_FAIL | WARN:<reason> | BLOCK:<reason>
_classify() {
  local payload="$1"
  if ! command -v python3 >/dev/null 2>&1; then
    # No JSON parser -- extracting a path from arbitrary Bash argv or nested
    # tool_input with grep alone is unsafe. Fail open.
    echo "PARSE_FAIL"
    return 0
  fi

  # Stage 1 (python): pull tool_name, candidate target path(s), the side
  # (write|open), and any injected test facts out of the JSON.
  local parsed
  parsed="$(INPUT_JSON="$payload" python3 - <<'PYEOF'
import json, os, re, shlex, sys

raw = os.environ.get("INPUT_JSON", "")
try:
    data = json.loads(raw)
except Exception:
    print("PARSE_FAIL"); sys.exit(0)
if not isinstance(data, dict):
    print("PARSE_FAIL"); sys.exit(0)

tool = data.get("tool_name", "")
if tool and tool not in ("Write", "Edit", "Bash"):
    print("SKIP"); sys.exit(0)

ti = data.get("tool_input", {}) or {}
if not isinstance(ti, dict):
    print("PARSE_FAIL"); sys.exit(0)

def test_fact(key):
    v = data.get(key, None)
    if v is True:  return "1"
    if v is False: return "0"
    return ""

exists_f = test_fact("test_exists")
nonempty_f = test_fact("test_nonempty")
shared_f = test_fact("test_shared_branch")

side = ""
path = ""

if tool in ("Write", "Edit"):
    side = "write"
    path = str(ti.get("file_path", "") or "")
    if not path:
        print("PARSE_FAIL"); sys.exit(0)
elif tool == "Bash":
    side = "open"
    cmd = str(ti.get("command", "") or "")
    if not cmd:
        print("PARSE_FAIL"); sys.exit(0)
    # Find the first editor-open invocation and take its path argument.
    # Openers: code / code-insiders / cursor / open / xdg-open / gio open.
    # Match the opener as a bareword command (start of string or after a
    # shell separator) so we do not fire on `mycode`, `encode`, etc.
    m = re.search(
        r'(?:^|[;&|]|&&|\|\||\bgio\s+)\s*'
        r'(code-insiders|code|cursor|xdg-open|open)\b',
        cmd,
    )
    if not m:
        print("SKIP"); sys.exit(0)

    # Tokenize only the invocation argument tail. Quoting is handled by
    # shlex; shell separators terminate the opener invocation.
    try:
        lexer = shlex.shlex(
            cmd[m.end():], posix=True, punctuation_chars=";&|<>"
        )
        lexer.whitespace_split = True
        lexer.commenters = ""
        args = []
        for token in lexer:
            if token and all(char in ";&|<>" for char in token):
                break
            args.append(token)
    except ValueError:
        print("PARSE_FAIL"); sys.exit(0)

    # Flags are not filesystem targets. macOS `open -a <App> <target>` has a
    # required app-name value, so skip both -a and that value before selecting
    # the target. This also supports quoted app names such as "Google Chrome".
    opener = m.group(1)
    index = 0
    while index < len(args):
        arg = args[index]
        if opener == "open" and arg in ("-a", "--application"):
            index += 2
            continue
        if arg.startswith("-"):
            index += 1
            continue
        path = arg
        break
    if not path:
        print("SKIP"); sys.exit(0)

    # Browser/resource URL schemes are not filesystem paths and must never be
    # subjected to existence, size, scratchpad, or shared-checkout checks.
    if "://" in path:
        print("SKIP"); sys.exit(0)
else:
    print("SKIP"); sys.exit(0)

# Emit one record per line for the shell stage to act on.
print("OK")
print("side=" + side)
print("path=" + path)
print("exists=" + exists_f)
print("nonempty=" + nonempty_f)
print("shared=" + shared_f)
PYEOF
)"

  local head
  head="$(printf '%s\n' "$parsed" | head -1)"
  case "$head" in
    SKIP)       echo "SKIP";       return 0 ;;
    PARSE_FAIL) echo "PARSE_FAIL"; return 0 ;;
    OK) : ;;  # fall through to stage 2
    *)          echo "PARSE_FAIL"; return 0 ;;
  esac

  local side path exists nonempty shared
  side="$(printf '%s\n' "$parsed"     | sed -n 's/^side=//p'     | head -1)"
  path="$(printf '%s\n' "$parsed"     | sed -n 's/^path=//p'     | head -1)"
  exists="$(printf '%s\n' "$parsed"   | sed -n 's/^exists=//p'   | head -1)"
  nonempty="$(printf '%s\n' "$parsed" | sed -n 's/^nonempty=//p' | head -1)"
  shared="$(printf '%s\n' "$parsed"   | sed -n 's/^shared=//p'   | head -1)"

  # ----- WRITE SIDE: only the scratchpad concern applies -----
  if [ "$side" = "write" ]; then
    if _is_scratchpad_path "$path"; then
      echo "WARN:scratchpad-write"
    else
      echo "ALLOW"
    fi
    return 0
  fi

  # ----- OPEN SIDE: scratchpad -> nonexistent -> empty -> shared-branch -----
  if _is_scratchpad_path "$path"; then
    echo "BLOCK:scratchpad-open"; return 0
  fi

  # Existence: injected fact wins in test mode, else stat the filesystem.
  if [ -n "$exists" ]; then
    [ "$exists" = "1" ] || { echo "BLOCK:nonexistent"; return 0; }
  else
    [ -e "$path" ] || { echo "BLOCK:nonexistent"; return 0; }
  fi

  # Non-empty: injected fact wins in test mode, else `test -s`.
  if [ -n "$nonempty" ]; then
    [ "$nonempty" = "1" ] || { echo "BLOCK:empty"; return 0; }
  else
    [ -s "$path" ] || { echo "BLOCK:empty"; return 0; }
  fi

  # Shared-checkout branch content: injected fact wins in test mode, else the
  # live git heuristic.
  if [ -n "$shared" ]; then
    [ "$shared" = "1" ] && { echo "BLOCK:shared-checkout-branch"; return 0; }
  else
    if _live_shared_branch "$path"; then
      echo "BLOCK:shared-checkout-branch"; return 0
    fi
  fi

  echo "ALLOW"
}

# ---------- test-mode entry point ----------
# Placed BEFORE the headless bypass on purpose: --verdict is a pure classifier
# with no exit-1/2 side effects, so it must stay deterministic for unit tests
# regardless of whether DOE_HEADLESS is set in the invoking environment.
if [ "${1:-}" = "--verdict" ]; then
  _classify "${2:-}"
  exit 0
fi

# ---------- headless bypass ----------
# Headless DOE workers do not present paths to Owner interactively and already
# write inside their own isolated worktree; kept symmetric with the bypass in
# owner-question-gate.sh / agent-cost-tiering-gate.sh.
if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

# ---------- config ----------
MODE="${JIT_OWNER_PATH_GATE_MODE:-default}"
if [ "$MODE" = "off" ]; then
  exit 0
fi

# ---------- hook mode: read stdin ----------
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi
[ -z "$INPUT" ] && exit 0   # nothing to inspect -- fail open

RESULT="$(_classify "$INPUT")"
VERDICT="${RESULT%%:*}"
REASON="${RESULT#*:}"
[ "$REASON" = "$RESULT" ] && REASON=""

# Resolve the effective disposition for this hit, honoring MODE overrides.
# default: write-side hits WARN, open-side hits BLOCK.
_emit_block() {
  {
    echo "BLOCKED by jk-owner-path-gate (rules/owner-facing-artifact-paths.md): $1"
    echo ""
    echo "An Owner-facing path must exist, be non-empty, live under the workspace"
    echo "(~/Code -- never /tmp or a session scratchpad), and NOT be branch-only"
    echo "content in a shared main checkout. \`code <nonexistent>\` silently opens a"
    echo "BLANK buffer; a scratchpad path is a broken link on a session-rotation timer;"
    echo "a shared-checkout branch file vanishes the moment the clone switches branches."
    echo ""
    echo "Fix before presenting or opening:"
    echo "  - Write/author the artifact into the owning repo under ~/Code, commit it,"
    echo "    and reference its stable committed path; or"
    echo "  - present branch content via a dedicated worktree path"
    echo "    (~/Code/Worktrees/<repo>/<slug>/...), never a shared-clone branch checkout; and"
    echo "  - verify the file exists and is non-empty (test -s <path>) FIRST."
  } >&2
  exit 2
}
_emit_warn() {
  echo "WARNING (jk-owner-path-gate, rules/owner-facing-artifact-paths.md): $1 -- an authored lane work product should land in the owning repo under ~/Code (versioned, discoverable, survives session rotation), not a session scratchpad. Set JIT_OWNER_PATH_GATE_MODE=block to enforce." >&2
  exit 1
}

case "$VERDICT" in
  WARN)
    case "$MODE" in
      block) _emit_block "authored work product targets a session scratchpad ($REASON)" ;;
      off)   exit 0 ;;
      *)     _emit_warn "Write/Edit targets a session scratchpad ($REASON)" ;;
    esac
    ;;
  BLOCK)
    case "$MODE" in
      warn)  echo "WARNING (jk-owner-path-gate): would block presenting/opening $REASON path; see rules/owner-facing-artifact-paths.md" >&2; exit 1 ;;
      *)     _emit_block "attempt to open/present a $REASON path" ;;
    esac
    ;;
  ALLOW|SKIP|PARSE_FAIL|"")
    exit 0 ;;
  *)
    exit 0 ;;  # unrecognized verdict -- fail open
esac
