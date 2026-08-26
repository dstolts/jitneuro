#!/bin/bash
# JitNeuro SessionEnd Lessons Flush Hook (WS5)
# Flushes active session's learn.md lesson queue to a durable
# flat file so lessons are never lost on context reset or crash.
#
# The durable file: .sessions/lessons-pending.md
# Format: one-per-line log, append-only.
# /learn reads this file alongside the active hub's learn.md during Agent A scan.
#
# This hook is a safety net -- it fires even when /save was not called.
# It does NOT replace /learn; it ensures raw lessons survive until /learn runs.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_DIR="${SESSIONS_DIR:-$HOME/Code/.sessions}"
HEARTBEATS_DIR="$SESSION_DIR/heartbeats"
LESSONS_FILE="$SESSION_DIR/lessons-pending.md"
LOG="/tmp/jitneuro-lessons-flush.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
ISO_TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")

# Read hook input with timeout to get session_id
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

SESSION_ID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"')

# Resolve session name from heartbeat
CURRENT_SESSION=""
if [ -n "$SESSION_ID" ]; then
  HEARTBEAT_FILE="$HEARTBEATS_DIR/$SESSION_ID"
  if [ -f "$HEARTBEAT_FILE" ]; then
    CURRENT_SESSION=$(cat "$HEARTBEAT_FILE" 2>/dev/null | tr -d '[:space:]')
  fi
fi
[ "$CURRENT_SESSION" = "none" ] && CURRENT_SESSION=""

echo "[$(date 2>/dev/null)] LessonsFlush: session=$CURRENT_SESSION" >> "$LOG" 2>/dev/null

# Find learn.md -- look in common locations
LEARN_FILE=""
# Try active hub learn.md relative to CWD extracted from input
CWD=$(echo "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"')
if [ -n "$CWD" ] && [ -f "$CWD/.hub/learn.md" ]; then
  LEARN_FILE="$CWD/.hub/learn.md"
elif [ -n "$CWD" ] && [ -f "$CWD/.HUB/learn.md" ]; then
  LEARN_FILE="$CWD/.HUB/learn.md"
fi
# Fallback: check session state dir for _hub-path.txt written by /save and
# derive learn.md from the active hub directory.
if [ -z "$LEARN_FILE" ] && [ -n "$CURRENT_SESSION" ] && [ -f "$SESSION_DIR/_hub-path.txt" ]; then
  STORED_HUB=$(cat "$SESSION_DIR/_hub-path.txt" 2>/dev/null | tr -d '[:space:]')
  if [ -f "$STORED_HUB" ]; then
    HUB_DIR="$(dirname "$STORED_HUB")"
    [ -f "$HUB_DIR/learn.md" ] && LEARN_FILE="$HUB_DIR/learn.md"
  fi
fi

if [ -z "$LEARN_FILE" ]; then
  echo "[$(date 2>/dev/null)] LessonsFlush: no learn.md found, skipping." >> "$LOG" 2>/dev/null
  exit 0
fi

echo "[$(date 2>/dev/null)] LessonsFlush: reading $LEARN_FILE" >> "$LOG" 2>/dev/null

# Extract ## Open Lessons section from learn.md.
# Look for lines between "## Open Lessons" and the next "## " heading.
IN_SECTION=0
LESSON_LINES=""
LESSON_COUNT=0
while IFS= read -r line; do
  if echo "$line" | grep -q '^## Open Lessons'; then
    IN_SECTION=1
    continue
  fi
  if [ "$IN_SECTION" = "1" ]; then
    # Stop at next heading
    if echo "$line" | grep -q '^## '; then
      break
    fi
    # Skip processed markers and placeholder lines
    if echo "$line" | grep -q '(Processed by /learn'; then
      IN_SECTION=0  # section is already processed, nothing to flush
      break
    fi
    if echo "$line" | grep -q '^No open lessons\.'; then
      continue
    fi
    # Collect non-empty lines that look like lessons
    if [ -n "$(echo "$line" | tr -d '[:space:]')" ]; then
      LESSON_LINES="${LESSON_LINES}${line}
"
      LESSON_COUNT=$((LESSON_COUNT + 1))
    fi
  fi
done < "$LEARN_FILE"

if [ "$LESSON_COUNT" -eq 0 ]; then
  echo "[$(date 2>/dev/null)] LessonsFlush: no unprocessed lessons found." >> "$LOG" 2>/dev/null
  exit 0
fi

# Append lessons to durable flat file
mkdir -p "$SESSION_DIR" 2>/dev/null

# Write header for this flush batch
{
  echo ""
  echo "## Flushed: $ISO_TS (session: ${CURRENT_SESSION:-unknown}, learn: $LEARN_FILE)"
  echo "$LESSON_LINES"
} >> "$LESSONS_FILE" 2>/dev/null

echo "[$(date 2>/dev/null)] LessonsFlush: flushed $LESSON_COUNT lessons to $LESSONS_FILE" >> "$LOG" 2>/dev/null
exit 0
