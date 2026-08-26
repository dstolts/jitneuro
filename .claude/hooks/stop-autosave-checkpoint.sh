#!/bin/bash
# JitNeuro Crash-Autosave Stop Hook (housekeeper-autosave pattern, ticket #3212)
# Event: Stop -- fires at every turn-end / yield boundary, far more often than
# SessionEnd (which only fires on a CLEAN exit and never fires at all when the
# terminal/process is killed -- e.g. a machine crash mid-session).
#
# PURPOSE: bound the staleness of the last on-disk checkpoint so a crashed
# terminal never loses more than one throttle window of state. Origin:
# 2026-07-10 Mac crash mid-session -- recovery worked, but the only
# checkpoint on disk was the morning's manual /save; hours of subsequent
# work had no mechanical safety net.
#
# THIS DOES NOT REPLACE /save. A Stop hook only receives session_id, cwd, and
# transcript_path on stdin -- it has no access to TodoWrite, questions.md
# deltas, or in-flight reasoning, so it cannot write a narrative checkpoint.
# What it CAN do, cheaply and safely, every throttle window:
#   1. Refresh a timestamp + fast local git facts (branch, dirty-file count,
#      last commit) so staleness is bounded even between narrative saves.
#   2. Copy forward the last known narrative /save (if one exists) into the
#      same file, so the crash-autosave file is a superset (narrative +
#      fresher mechanical facts), not a competing thinner file.
#
# THROTTLE: writes at most once per JIT_KNOWLEDGE_AUTOSAVE_INTERVAL_S seconds
# (default 600 = 10 min) per session, tracked via the autosave file's own
# mtime -- no separate marker file needed.
#
# NEVER BLOCKS: always exit 0 (fail-open). A Stop-hook exit 2 blocks the
# agent's yield; this safety-net hook must never do that -- a crash in THIS
# script must never trap the session either (set +e throughout).
#
# RECURSION GUARD (ticket #4313): even though this hook never blocks, it still
# writes a checkpoint file every throttle window. When a sibling Stop hook
# blocks and Claude Code re-enters the Stop event with stop_hook_active=true,
# re-running this write is pure duplicate work on a stop the session is already
# trying to end. So we honor stop_hook_active here too: when it is JSON boolean
# true we exit 0 immediately, before any filesystem mutation. Fail-open parse
# (only a bare boolean true bypasses; malformed/absent/"true"-string fall
# through to the normal throttled autosave).
#
# Verify with: templates/claude-hooks/tests/stop-autosave-checkpoint.test.sh
#          and templates/claude-hooks/tests/stop-hook-recursion-guard.test.sh

set +e  # never abort on errors -- fail-open, always

# ---- read hook payload (stdin JSON) ----
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 _line; do
    INPUT="${INPUT}${_line}"
  done
fi

SESSION_ID="${CLAUDE_SESSION_ID:-}"
[ -z "$SESSION_ID" ] && SESSION_ID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
CWD=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$PWD}"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$CWD}"
STATE_DIR="$PROJECT_DIR/.sessions"
HEARTBEATS_DIR="$STATE_DIR/heartbeats"
LOG="/tmp/jitneuro-crash-autosave.log"
INTERVAL="${JIT_KNOWLEDGE_AUTOSAVE_INTERVAL_S:-600}"

# ---- RECURSION GUARD (ticket #4313): honor stop_hook_active, FAIL-OPEN ----
# Runs BEFORE mkdir and any checkpoint write. Only a bare JSON boolean  true
# bypasses; false / absent / malformed / the STRING "true" all fall through to
# the normal throttled autosave. Kept byte-identical to stop-continue-queue.sh's
# copy on purpose -- each Stop hook is self-contained so a missing shared helper
# can never disable this safety-critical, fail-open check.
_stop_hook_active_is_true(){
  # $1 = raw payload JSON string.
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$1" | python3 -c 'import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(1)
sys.exit(0 if d.get("stop_hook_active") is True else 1)' >/dev/null 2>&1
    return $?
  fi
  # No python3 -- conservative regex: the value must be a bare boolean  true
  # (token followed by whitespace then , or } or line-end), never the "true" string.
  printf '%s' "$1" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true([[:space:]]*[,}]|[[:space:]]*$)'
}
if _stop_hook_active_is_true "$INPUT"; then
  echo "[$(date 2>/dev/null)] stop_hook_active=true -> recursion guard: skip autosave (no write) [#4313]" >> "$LOG" 2>/dev/null
  exit 0
fi

# No session id -- nothing reliable to key a per-session file off of. Fail
# open silently rather than guessing a shared filename that could collide
# across sessions.
[ -z "$SESSION_ID" ] && exit 0

mkdir -p "$STATE_DIR" 2>/dev/null

# ---- resolve active session name from heartbeat (same lookup as session-end-autosave.sh) ----
SESSION_NAME=""
if [ -f "$HEARTBEATS_DIR/$SESSION_ID" ]; then
  SESSION_NAME=$(cat "$HEARTBEATS_DIR/$SESSION_ID" 2>/dev/null | tr -d '[:space:]')
fi
[ "$SESSION_NAME" = "none" ] && SESSION_NAME=""
[ -z "$SESSION_NAME" ] && SESSION_NAME="_unnamed-$SESSION_ID"

AUTOSAVE_FILE="$STATE_DIR/${SESSION_NAME}.crash-autosave.md"

# ---- throttle: skip if the last autosave write is still fresh ----
NOW=$(date +%s 2>/dev/null)
if [ -f "$AUTOSAVE_FILE" ] && [ -n "$NOW" ]; then
  LAST=$(stat -c %Y "$AUTOSAVE_FILE" 2>/dev/null || stat -f %m "$AUTOSAVE_FILE" 2>/dev/null)
  if [ -n "$LAST" ]; then
    AGE=$((NOW - LAST))
    if [ "$AGE" -lt "$INTERVAL" ] 2>/dev/null; then
      exit 0
    fi
  fi
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")

# ---- fast, local-only git facts (no network calls -- Stop hooks stay quick) ----
GIT_BRANCH="unknown"
GIT_DIRTY="unknown"
GIT_LAST_COMMIT="unknown"
if command -v git >/dev/null 2>&1 && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
  [ -z "$GIT_BRANCH" ] && GIT_BRANCH="unknown"
  GIT_DIRTY=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  GIT_LAST_COMMIT=$(git -C "$PROJECT_DIR" log -1 --format='%h %s' 2>/dev/null)
  [ -z "$GIT_LAST_COMMIT" ] && GIT_LAST_COMMIT="unknown"
fi

# ---- carry forward the last narrative /save, if one exists ----
NARRATIVE_FILE="$STATE_DIR/${SESSION_NAME}.md"
if [ -f "$NARRATIVE_FILE" ]; then
  NARRATIVE_BLOCK="$(cat "$NARRATIVE_FILE" 2>/dev/null)"
else
  NARRATIVE_BLOCK="(no narrative /save found yet for this session -- run /save to create templates/session-checkpoint-template.md's structure; this file is a mechanical-only safety net until then)"
fi

cat > "$AUTOSAVE_FILE" <<EOF
---
type: crash-autosave
session: ${SESSION_NAME}
autosaved_at: ${TIMESTAMP}
session_id: ${SESSION_ID}
reboot-safe: mechanical-only
---

# Crash Autosave (Housekeeper Safety Net -- ticket #3212)

Refreshed mechanically by the Stop-hook autosave (throttled every
~${INTERVAL}s, this session's mtime-based clock). NOT a substitute for
/save -- see templates/session-checkpoint-template.md for the narrative
structure /save produces. This file's only job is to bound staleness: if the
process is killed with no clean SessionEnd, this file is never more than one
throttle window behind.

## Mechanical snapshot (this hook's own facts, always fresh as of autosaved_at)
- Working directory: ${PROJECT_DIR}
- Git branch: ${GIT_BRANCH}
- Dirty files (git status --porcelain line count): ${GIT_DIRTY}
- Last commit: ${GIT_LAST_COMMIT}

## Last narrative checkpoint (copied forward from ${SESSION_NAME}.md)
${NARRATIVE_BLOCK}

## Recovery
If this file's autosaved_at is newer than ${SESSION_NAME}.md's checkpointed
date, this is the freshest known anchor. Run \`/load ${SESSION_NAME}\`, then
reconcile the narrative section above against the mechanical snapshot (git
branch / dirty files / last commit) before continuing -- the gap between the
two is exactly the work this hook could not narrate.
EOF

echo "[$(date 2>/dev/null)] Crash-autosave refreshed: $AUTOSAVE_FILE (session=$SESSION_NAME)" >> "$LOG" 2>/dev/null

exit 0
