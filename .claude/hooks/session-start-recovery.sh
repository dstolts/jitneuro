#!/bin/bash
# JitNeuro SessionStart Recovery Hook
# Fires after compaction to re-inject critical context into Claude's window.
#
# Resolves THIS session's own checkpoint via session-id -> heartbeats/<id> ->
# session name -> .sessions/<name>.md. Only when that chain cannot
# resolve (heartbeat missing/unset, or its named checkpoint does not exist)
# does it fall back to the most-recently-modified checkpoint on disk, and it
# labels that fallback explicitly as an UNVERIFIED GUESS so a different
# session's saved context can never be mistaken for this session's own state.
#
# Ticket #3211: the prior implementation always picked the newest-mtime
# .sessions/*.md file with no identity check at all, so compacting
# session A while session B had saved more recently injected session B's
# checkpoint into session A's context (right context omitted, wrong context
# injected). session-end-autosave.sh already resolves identity correctly via
# heartbeats/<session-id> -- this hook now does the same.
#
# stdout from this hook goes directly into Claude's context window.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
SESSION_DIR="${SESSIONS_DIR:-$HOME/Code/.sessions}"
HEARTBEATS_DIR="$SESSION_DIR/heartbeats"
LOG="/tmp/jitneuro-session-recovery.log"

# Read hook input. Every SessionStart hook receives the same JSON payload on
# stdin, including session_id for THIS specific invocation.
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

# Resolve the session id for THIS invocation. Prefer the id parsed from this
# hook's own stdin JSON -- it is the freshest, most authoritative signal for
# the current invocation. Fall back to CLAUDE_SESSION_ID (exported by
# session-start-write-id.sh earlier in the same SessionStart chain) only when
# stdin does not carry a session_id, since an inherited/ambient env var can be
# stale or leak from an unrelated process and must never outrank the current
# request's own payload.
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
if [ -z "$SESSION_ID" ]; then
  SESSION_ID="${CLAUDE_SESSION_ID:-}"
fi

if [ ! -d "$SESSION_DIR" ]; then
  echo "[$(date 2>/dev/null)] Recovery: no sessions dir" >> "$LOG" 2>/dev/null
  exit 0
fi

# --- Resolve THIS session's own checkpoint via its heartbeat file ----------
RESOLVED_NAME=""
if [ -n "$SESSION_ID" ] && [ -f "$HEARTBEATS_DIR/$SESSION_ID" ]; then
  HEARTBEAT_NAME=$(cat "$HEARTBEATS_DIR/$SESSION_ID" 2>/dev/null | tr -d '[:space:]')
  if [ -n "$HEARTBEAT_NAME" ] && [ "$HEARTBEAT_NAME" != "none" ] && [ -f "$SESSION_DIR/$HEARTBEAT_NAME.md" ]; then
    RESOLVED_NAME="$HEARTBEAT_NAME"
  fi
fi

if [ -n "$RESOLVED_NAME" ]; then
  LATEST="$SESSION_DIR/$RESOLVED_NAME.md"
  SESSION_NAME="$RESOLVED_NAME"
  RESOLUTION="heartbeat"
  echo "[$(date 2>/dev/null)] Recovery: resolved via heartbeat (session_id=$SESSION_ID) -> $SESSION_NAME from $LATEST" >> "$LOG" 2>/dev/null
else
  # Fallback: identity could not be resolved (no session_id, no heartbeat
  # file for it, heartbeat says "none", or its named checkpoint is missing).
  # Guess the newest checkpoint on disk -- but label it clearly as an
  # unverified guess. Never present a guess as this session's confirmed
  # own state; that mislabeling is exactly the bug this fixes.
  LATEST=$(ls -t "$SESSION_DIR"/*.md 2>/dev/null | grep -v '_autosave\.md$' | head -1)
  if [ -z "$LATEST" ]; then
    echo "[$(date 2>/dev/null)] Recovery: no session files found (session_id=${SESSION_ID:-unknown})" >> "$LOG" 2>/dev/null
    exit 0
  fi
  SESSION_NAME=$(basename "$LATEST" .md)
  RESOLUTION="guess"
  echo "[$(date 2>/dev/null)] Recovery: GUESS fallback (session_id=${SESSION_ID:-unknown}, no heartbeat match) -> $SESSION_NAME from $LATEST" >> "$LOG" 2>/dev/null
fi

CONTENT=$(cat "$LATEST" 2>/dev/null || echo "(could not read session file)")

if [ "$RESOLUTION" = "heartbeat" ]; then
  cat <<EOF
[JitNeuro] Context was compacted. Restoring THIS session's own checkpoint (session-id resolved via heartbeat).

Session: $SESSION_NAME
Source: $LATEST

--- BEGIN SESSION STATE ---
$CONTENT
--- END SESSION STATE ---

IMPORTANT: Context was just compacted. The session state above is your last checkpoint.
Review it to understand what you were working on. If it seems stale, ask the user
if they want to continue from this state or start fresh.
EOF
else
  cat <<EOF
[JitNeuro] Context was compacted. UNVERIFIED GUESS -- could not resolve this session's own
checkpoint (session-id ${SESSION_ID:-unknown} has no matching heartbeat/checkpoint), so the
most recently modified checkpoint on this machine was injected instead. This may belong to
a DIFFERENT session.

Session (unconfirmed guess): $SESSION_NAME
Source: $LATEST

--- BEGIN SESSION STATE (UNVERIFIED GUESS) ---
$CONTENT
--- END SESSION STATE ---

IMPORTANT: Context was just compacted, but session identity could not be confirmed. Do
NOT assume the state above belongs to this session. Ask the user to confirm, or run
/load <name> to load the correct checkpoint explicitly.
EOF
fi

exit 0
