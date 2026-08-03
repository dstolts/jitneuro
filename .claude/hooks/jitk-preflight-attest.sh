#!/bin/bash
# jitk-preflight-attest.sh -- attestation command for DESIGN 4615 (ticket
# #4615), Stage 1 (WARN mode). Companion to jitk-preflight-gate.sh.
#
# WHAT IT DOES
# The agent runs this ONCE, immediately after finishing the bootstrap chain
# reads (AGENTS.md -> COMPANY.md -> README.md -> INDEX.md ->
# rules/interactive-master-orchestrator.md) and printing the Bootstrap
# Confirmation Banner ("<< -- Running Thin, As Orchestrator ... -->>"). It:
#   1. resolves <KnowledgeRoot> the same way the SessionStart hooks do;
#   2. confirms the chain-anchor files exist and are non-empty;
#   3. confirms this session's engagement sentinel
#      (bootstrap-pending.<SID>) was written by SessionStart;
#   4. on success: writes preflight-done.<SID>.marker and removes the
#      pending sentinel;
#   5. on failure: prints exactly what is missing and exits non-zero
#      WITHOUT writing the marker.
#
# THIS SCRIPT NEVER BRICKS A SESSION. It only ever writes or fails to write
# a small marker file -- it has no power to block a tool call itself (that
# is jitk-preflight-gate.sh's job, and in Stage 1 that gate can never block
# either). A failed attest simply means "not yet marked done"; read-only
# work and the attest retry are always available.
#
# Marker/state paths (design 1.2, project-scoped, mirrors
# stop-continue-queue.sh's STATE_DIR resolution):
#   <PROJECT_DIR>/.sessions/preflight/bootstrap-pending.<SID>
#   <PROJECT_DIR>/.sessions/preflight/preflight-done.<SID>.marker
#
# Usage:
#   bash ~/.claude/hooks/jitk-preflight-attest.sh
#
# Exit codes (informational only -- nothing downstream treats a non-zero
# exit here as fatal):
#   0 = marker written (or already present)
#   1 = verification failed; marker NOT written; message printed to stderr
#
# Canonical source: jit-knowledge/templates/claude-hooks/jitk-preflight-attest.sh
# Install via: bash scripts/install.sh
#
# Test mode: `jitk-preflight-attest.sh --verdict` prints the verdict
# (OK / MISSING:<what> / NO-SENTINEL / NO-SID) without exiting non-zero
# fatally, for unit testing (see
# templates/claude-hooks/tests/preflight-gate.test.sh, and
# scripts/tests/preflight-gate.test.sh in this ticket).

set +e  # never abort in a way that could look like a crash -- this is a
        # deliberate write-a-file-or-don't script, not a gate.

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
STATE_DIR="$PROJECT_DIR/.sessions/preflight"
mkdir -p "$STATE_DIR" 2>/dev/null

# ---------- resolve SID (native runtime env first; this is not a hook) ----------
# Claude exposes CLAUDE_SESSION_ID. Codex exposes CODEX_THREAD_ID in current
# clients and CODEX_SESSION_ID in some automation surfaces. Preserve that
# runtime-native identity instead of requiring callers to impersonate Claude.
SID="${CLAUDE_SESSION_ID:-${CODEX_THREAD_ID:-${CODEX_SESSION_ID:-}}}"

# ---------- resolve <KnowledgeRoot> (same chain as session-start-master-orchestrator-rule.sh) ----------
resolve_knowledge_root() {
  local root="${JIT_KNOWLEDGE_ROOT:-}"
  if [ -z "$root" ] && [ -f "$HOME/.claude/workspace.json" ]; then
    root=$(grep -o '"jit_knowledge_root"[[:space:]]*:[[:space:]]*"[^"]*"' \
      "$HOME/.claude/workspace.json" 2>/dev/null | head -1 \
      | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')
  fi
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    for cand in "$HOME/Code/jit-knowledge" "C:/Users/$USER/Code/jit-knowledge"; do
      [ -d "$cand" ] && { root="$cand"; break; }
    done
  fi
  printf '%s' "$root"
}
JK_ROOT="$(resolve_knowledge_root)"

# ---------- verdict computation (shared by hook mode and --verdict test mode) ----------
_verdict() {
  if [ -z "$SID" ]; then
    echo "NO-SID"
    return
  fi
  if [ -z "$JK_ROOT" ] || [ ! -d "$JK_ROOT" ]; then
    echo "MISSING:knowledge-root"
    return
  fi
  local missing=""
  for anchor in AGENTS.md COMPANY.md INDEX.md rules/interactive-master-orchestrator.md; do
    local f="$JK_ROOT/$anchor"
    if [ ! -s "$f" ]; then
      missing="${missing}${missing:+,}$anchor"
    fi
  done
  if [ -n "$missing" ]; then
    echo "MISSING:$missing"
    return
  fi
  if [ ! -f "$STATE_DIR/bootstrap-pending.$SID" ] && [ ! -f "$STATE_DIR/preflight-done.$SID.marker" ]; then
    echo "NO-SENTINEL"
    return
  fi
  echo "OK"
}

VERDICT="$(_verdict)"

# ---------- test-mode entry point ----------
if [ "${1:-}" = "--verdict" ]; then
  echo "$VERDICT"
  exit 0
fi

# ---------- act on the verdict ----------
case "$VERDICT" in
  OK)
    if [ -n "$SID" ]; then
      printf '%s' "$(date 2>/dev/null)" > "$STATE_DIR/preflight-done.$SID.marker" 2>/dev/null
      rm -f "$STATE_DIR/bootstrap-pending.$SID" 2>/dev/null
    fi
    echo "[jitk-preflight-attest] OK -- bootstrap chain anchors verified, preflight-done.$SID.marker written."
    exit 0
    ;;
  NO-SID)
    echo "[jitk-preflight-attest] FAILED: could not resolve a Claude or Codex session/thread ID -- no marker written. This is not a brick: read-only work and a retry (after the runtime ID resolves) are still available." >&2
    exit 1
    ;;
  NO-SENTINEL)
    echo "[jitk-preflight-attest] FAILED: no bootstrap-pending.$SID sentinel found under $STATE_DIR -- SessionStart may not have run yet (or ran before the operational-preflight hook was installed). Marker NOT written. Not a brick: JITK_PREFLIGHT_GATE=0 or a manual touch of preflight-done.$SID.marker remain available if this blocks legitimate work." >&2
    exit 1
    ;;
  MISSING:knowledge-root)
    echo "[jitk-preflight-attest] FAILED: could not resolve <KnowledgeRoot> (checked JIT_KNOWLEDGE_ROOT, ~/.claude/workspace.json, and default clone paths). Marker NOT written." >&2
    exit 1
    ;;
  MISSING:*)
    echo "[jitk-preflight-attest] FAILED: bootstrap chain anchor(s) missing or empty under $JK_ROOT -- ${VERDICT#MISSING:}. Marker NOT written." >&2
    exit 1
    ;;
  *)
    echo "[jitk-preflight-attest] FAILED: unrecognized verdict '$VERDICT'. Marker NOT written (fail-closed on the marker only -- this does not block any tool call)." >&2
    exit 1
    ;;
esac
