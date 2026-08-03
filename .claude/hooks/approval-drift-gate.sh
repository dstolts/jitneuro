#!/bin/bash
# approval-drift-gate.sh -- SessionStart(WARN) / Stop(BLOCK) gate for the
# approve-stamp mechanism (skills/approve). RCA-driven (Owner-accepted
# 2026-07-29): an Owner approval recorded in ONE ledger kept drifting out of
# sync with the executable registry and the Owner surfaces, so already-approved
# schemas were re-presented forever. `approve` (skills/approve/approve.sh)
# stamps all three at once; THIS gate catches the drift when a stamp was
# skipped -- i.e. an Owner-lock signal whose registry row OR surface-close is
# MISSING.
#
# WHAT IT SCANS
#   * The schema registry            (governance/approved-schema-registry.md)
#   * A bounded set of surface files  (questions.md, decisions docs) and schema
#     proposals (WIP-Drafts/SCHEMA-*.md, docs/design/SCHEMA-*.md), capped.
#   Configure the scan root with APPROVE_DRIFT_ROOT (default: resolved
#   jit-knowledge root). Add extra explicit surfaces with APPROVE_DRIFT_SURFACES
#   (colon-separated absolute paths). The registry path can be overridden with
#   APPROVE_DRIFT_REGISTRY.
#
# DRIFT SIGNALS (deterministic, filesystem-only -- no DB query at Stop time)
#   A. UNSTAMPED LOCK  -- a file carries an Owner-lock/approval signal
#      (OWNER-LOCK, OWNER-LOCKED, "Owner lock", owner-locked, "Owner verbatim:
#      ...lock", a "## Answered" ... LOCKED entry) but the file contains NO
#      matching `approve-stamp:` token. The lock was asserted in prose but never
#      stamped everywhere -> registry/surface state is unverified. WARN/BLOCK.
#   B. REGISTRY GAP    -- a surface file carries a SCHEMA-kind stamp
#      (`approve-stamp:approve-schema-<ticket>-<hex>`) but the registry contains
#      neither that source-ref nor the stamped artifact. The lock stamped its
#      surfaces but never landed the executable registry row. WARN/BLOCK.
#
# MODE
#   SessionStart preflight -> WARN  (print to stderr, ALWAYS exit 0)
#   Stop / yield           -> BLOCK (print to stderr, exit 2 on drift)
#   Selected by --mode warn|block, or env APPROVE_DRIFT_GATE_MODE, default warn.
#   The Claude Code hook event is passed in the payload as hook_event_name;
#   when present, SessionStart forces warn and Stop forces block regardless of
#   the flag (so one registered script serves both events).
#
# THE ABSOLUTE INVARIANT (anti-brick): in WARN mode this script MUST ALWAYS
# exit 0, on every path -- internal errors, missing deps, unreadable root,
# malformed payload. In BLOCK mode it fails OPEN (exit 0) on any scan/parse
# error and fails CLOSED (exit 2) ONLY on a confirmed drift finding. A crash in
# this hook must never trap a session.
#
# Event/matcher: register under SessionStart AND Stop (branches on the event).
# Exit contract (rules/claude-code-hook-deployment.md):
#   0 = allow / warn-only
#   2 = block (Stop mode, confirmed drift); stderr fed back as the next directive
#
# Bypass: DOE_HEADLESS=1 (headless DOE stamps via its own path);
#         APPROVE_DRIFT_GATE=0 (global escape hatch).
#
# Canonical source: jit-knowledge/templates/claude-hooks/approval-drift-gate.sh
# Install-time settings.json wiring is a knowledge-lane follow-up -- NOT wired
# live by this ticket.
#
# Test mode: `approval-drift-gate.sh --scan <root>` prints CLEAN or DRIFT plus
# one finding per line, exit 0, no block side effects (see
# templates/claude-hooks/tests/approval-drift-gate.test.sh).

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- escape hatches ----------
[ "${APPROVE_DRIFT_GATE:-}" = "0" ] && exit 0
[ "${DOE_HEADLESS:-}" = "1" ] && exit 0

# ---------- resolve jit-knowledge root ----------
_resolve_root() {
  if [ -n "${APPROVE_DRIFT_ROOT:-}" ] && [ -d "$APPROVE_DRIFT_ROOT" ]; then
    printf '%s' "$APPROVE_DRIFT_ROOT"; return
  fi
  if [ -n "${JIT_KNOWLEDGE_ROOT:-}" ] && [ -d "$JIT_KNOWLEDGE_ROOT" ]; then
    printf '%s' "$JIT_KNOWLEDGE_ROOT"; return
  fi
  # Walk up from the script's own location (works in the repo checkout).
  local d
  d="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
  if [ -n "$d" ] && [ -f "$d/INDEX.md" ]; then printf '%s' "$d"; return; fi
  if [ -d "$HOME/Code/jit-knowledge" ]; then printf '%s' "$HOME/Code/jit-knowledge"; return; fi
  printf '%s' ""
}

# ---------- the scan; prints "CLEAN" or "DRIFT" + findings ----------
# Usage: _scan <root>
_scan() {
  local root="$1"
  [ -z "$root" ] && { echo "CLEAN"; return 0; }  # no root -> fail open, nothing to scan
  [ ! -d "$root" ] && { echo "CLEAN"; return 0; }

  local registry="${APPROVE_DRIFT_REGISTRY:-$root/governance/approved-schema-registry.md}"

  ROOT="$root" REGISTRY="$registry" EXTRA="${APPROVE_DRIFT_SURFACES:-}" python3 - <<'PYEOF' 2>/dev/null
import os, re, glob, sys

root     = os.environ.get("ROOT", "")
registry = os.environ.get("REGISTRY", "")
extra    = os.environ.get("EXTRA", "")

# Bounded candidate set -- never a full-tree walk at Stop time.
CAP = 400
cands = []
patterns = [
    os.path.join(root, "**", "questions.md"),
    os.path.join(root, "WIP-Drafts", "SCHEMA-*.md"),
    os.path.join(root, "**", "docs", "design", "SCHEMA-*.md"),
    os.path.join(root, "**", "decisions.md"),
]
for pat in patterns:
    try:
        for p in glob.glob(pat, recursive=True):
            cands.append(p)
            if len(cands) >= CAP:
                break
    except Exception:
        pass
    if len(cands) >= CAP:
        break
for p in extra.split(":"):
    p = p.strip()
    if p:
        cands.append(p)

# De-dup, keep order.
seen = set(); files = []
for p in cands:
    if p not in seen:
        seen.add(p); files.append(p)

def read(path):
    try:
        with open(path, "r", errors="replace") as f:
            return f.read()
    except Exception:
        return None

registry_txt = read(registry) or ""

STAMP_RE  = re.compile(r"approve-stamp:approve-([a-z]+)-([0-9A-Za-z_.#-]+)-([0-9a-f]{6,})")
# Owner-lock / approval assertion signals (prose or marker).
LOCK_SIGNALS = [
    re.compile(r"OWNER[-\s]?LOCK(ED)?", re.I),
    re.compile(r"\bOwner\s+lock\b", re.I),
    re.compile(r"\bowner-locked\b", re.I),
    re.compile(r"Owner\s+verbatim:.{0,80}lock", re.I | re.S),
]
# A "## Answered ... LOCKED" entry also counts as a lock assertion.
ANSWERED_LOCKED_RE = re.compile(r"^\s*[-*].*\bLOCKED\b", re.I)

findings = []

for path in files:
    txt = read(path)
    if txt is None:
        continue  # unreadable -> skip (fail open per file)

    has_stamp = "approve-stamp:" in txt

    # ---- Signal A: an Owner-lock assertion with NO stamp anywhere in the file.
    lock_asserted = any(rx.search(txt) for rx in LOCK_SIGNALS)
    if not lock_asserted:
        # also treat an Answered-LOCKED bullet as a lock assertion
        for line in txt.splitlines():
            if ANSWERED_LOCKED_RE.search(line):
                lock_asserted = True
                break
    if lock_asserted and not has_stamp:
        findings.append(
            "UNSTAMPED-LOCK %s -- Owner-lock/approval asserted but no "
            "approve-stamp: token; registry+surface sync is unverified. "
            "Run `approve` (skills/approve) to stamp it everywhere." % path
        )

    # ---- Signal B: a SCHEMA-kind stamp present, but registry lacks it.
    for m in STAMP_RE.finditer(txt):
        kind, ticket, _hex = m.group(1), m.group(2), m.group(3)
        if kind != "schema":
            continue
        source_ref = m.group(0).split("approve-stamp:", 1)[1]
        if source_ref in registry_txt:
            continue  # registry references the stamp -> landed
        # also accept: the ticket id appears in a registry row
        if re.search(r"#%s\b" % re.escape(ticket), registry_txt):
            continue
        findings.append(
            "REGISTRY-GAP %s -- schema stamp %s present on this surface but "
            "the schema registry has no matching row (source-ref/ticket #%s). "
            "The registry row (b) was never landed." % (path, source_ref, ticket)
        )

if findings:
    print("DRIFT")
    for f in findings:
        print(f)
else:
    print("CLEAN")
PYEOF
  # If python3 is unavailable or errored, print CLEAN (fail open).
  if [ $? -ne 0 ]; then echo "CLEAN"; fi
}

# ---------- test-mode entry point ----------
if [ "${1:-}" = "--scan" ]; then
  RESULT="$(_scan "${2:-}")"
  # In test mode, print exactly what the scan found; no block side effects.
  printf '%s\n' "$RESULT"
  exit 0
fi

# ---------- determine mode ----------
MODE="${APPROVE_DRIFT_GATE_MODE:-warn}"
# allow --mode <warn|block>
if [ "${1:-}" = "--mode" ]; then
  MODE="${2:-warn}"; shift 2 2>/dev/null
fi

# ---------- read hook payload (optional; used to detect the event) ----------
INPUT=""
if command -v python3 >/dev/null 2>&1; then
  if command -v timeout >/dev/null 2>&1; then
    INPUT="$(timeout 2 cat 2>/dev/null || true)"
  else
    while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
  fi
  if [ -n "$INPUT" ]; then
    EVENT="$(INPUT_JSON="$INPUT" python3 - <<'PYEOF' 2>/dev/null
import json, os
try:
    d = json.loads(os.environ.get("INPUT_JSON", ""))
    print(str(d.get("hook_event_name", "")) if isinstance(d, dict) else "")
except Exception:
    print("")
PYEOF
)"
    case "$EVENT" in
      SessionStart) MODE="warn" ;;
      Stop|SubagentStop) MODE="block" ;;
    esac
  fi
fi

ROOT="$(_resolve_root)"
RESULT="$(_scan "$ROOT")"
VERDICT="$(printf '%s\n' "$RESULT" | head -1)"
FINDINGS="$(printf '%s\n' "$RESULT" | tail -n +2)"

if [ "$VERDICT" != "DRIFT" ]; then
  exit 0   # CLEAN, or any non-DRIFT (fail open)
fi

if [ "$MODE" = "block" ]; then
  {
    echo "BLOCKED by the approve-stamp mechanism (skills/approve): an Owner"
    echo "approval/lock is out of sync -- its registry row OR its surface-close"
    echo "is MISSING. Do not yield with drift outstanding; stamp it first."
    echo ""
    echo "Drift found:"
    printf '%s\n' "$FINDINGS"
    echo ""
    echo "Fix: run the canonical stamp so the lock lands EVERYWHERE at once --"
    echo "  approve --ticket <id> --artifact <full-path> --kind <schema|contract|deploy|rbac> \\"
    echo "          --phrase \"<owner lock phrase>\" --evidence <path|inline> \\"
    echo "          [--registry <path>] [--questions <path>] [--decisions <path>]"
    echo "Validate first with --dry-run. See skills/approve/SKILL.md."
    echo "If a finding is a false positive, add the approve-stamp: token that the"
    echo "stamp writes, or set APPROVE_DRIFT_GATE=0 for this one session."
  } >&2
  exit 2
fi

# WARN mode -- print and ALWAYS exit 0.
{
  echo "** WARN approve-stamp drift: an Owner approval/lock's registry row or"
  echo "   surface-close appears MISSING. Stamp it with skills/approve before it"
  echo "   is re-asked. Findings:"
  printf '   %s\n' "$FINDINGS"
} >&2
exit 0
