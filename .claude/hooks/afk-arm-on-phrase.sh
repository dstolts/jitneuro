#!/bin/bash
# JitNeuro AFK Auto-Arm Hook (afk-arm-on-phrase.sh)
# Event: UserPromptSubmit -- fires when the user submits a prompt, BEFORE the model runs.
#
# PURPOSE: let the user arm autonomous mode by simply SAYING they are AFK in chat,
# with no /afk slash command. On an AFK phrase it writes the session-scoped
# autonomous-mode flag that the Stop hook (stop-continue-queue.sh) reads, so the
# session then works the Hub.md ACTIVE TODO queue unattended and cannot stop while
# unblocked tasks remain. On an explicit return/disarm phrase it removes the flag.
#
# SESSION-SCOPED (v2): the flag is per-session --
#   <STATE_DIR>/autonomous-mode.<SESSION_ID>.flag
# so arming one session does NOT block sibling sessions sharing the same workspace.
# When SESSION_ID is unavailable, falls back to the legacy workspace-shared flag.
#
# FAIL-OPEN: never blocks the prompt; any error just exits 0.
#
# PROJECT_DIR resolution order (same as stop-continue-queue.sh):
#   1. CLAUDE_PROJECT_DIR env var
#   2. "cwd" field from the UserPromptSubmit JSON payload
#   3. $PWD
#
# SESSION_ID resolution order:
#   1. CLAUDE_SESSION_ID env var (set by Claude Code harness)
#   2. "session_id" field from the UserPromptSubmit JSON payload
#
# DISARM: only on an EXPLICIT stand-down phrase ("I'm back", "disarm", "stand down",
# "stop afk", "afk off", "stop autonomous", "exit autonomous"). While armed, mid-run
# answers, clarifications, or additional context do NOT disarm.
#
# Canonical source: jit-knowledge/templates/claude-hooks/afk-arm-on-phrase.sh
# Install via:  bash scripts/install.sh

set +e   # FAIL-OPEN -- never abort; a crash must allow the prompt, never block the user
INPUT=$(cat 2>/dev/null || true)

norm(){ printf '%s' "$1" | sed 's#\\#/#g; s#\#/#g'; }

# ---------- extract the prompt text ----------
# Prefer jq (full JSON parse). Fall back to a non-greedy sed that stops at the
# FIRST closing quote so it never bleeds into later JSON fields like cwd.
# Do NOT fall back to the whole payload -- a path containing an AFK word would
# wrongly arm the flag.
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
fi
[ -z "$PROMPT" ] && \
  PROMPT=$(printf '%s' "$INPUT" \
    | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -1)

# ---------- resolve project dir and flag path ----------
CWD=$(printf '%s' "$INPUT" \
  | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1)
[ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJECT_DIR=$(norm "${CLAUDE_PROJECT_DIR:-$CWD}")
STATE_DIR="$PROJECT_DIR/.sessions"

# ---------- resolve SESSION_ID ----------
SESSION_ID="${CLAUDE_SESSION_ID:-}"
[ -z "$SESSION_ID" ] && \
  SESSION_ID=$(printf '%s' "$INPUT" \
    | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -1)

# Flag paths
LEGACY_FLAG="$STATE_DIR/autonomous-mode.flag"
if [ -n "$SESSION_ID" ]; then
  SESSION_FLAG="$STATE_DIR/autonomous-mode.$SESSION_ID.flag"
else
  SESSION_FLAG=""
fi

LC=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ---------- DISARM: explicit stand-down ONLY ----------
# Deliberately tight: while armed, answers or clarifications must NOT disarm.
# Only a clear, unambiguous stand-down phrase disarms THIS session's flag.
case "$LC" in
  *"i'm back"*|*"im back"*|*"i am back"* \
  |*"disarm"*|*"stand down"* \
  |*"stop afk"*|*"end afk"*|*"afk off"* \
  |*"stop autonomous"*|*"autonomous off"*|*"exit autonomous"*)
    # Remove session-scoped flag (primary)
    if [ -n "$SESSION_FLAG" ] && [ -f "$SESSION_FLAG" ]; then
      rm -f "$SESSION_FLAG" 2>/dev/null
    fi
    # Remove legacy flag ONLY if it is not scoped to another session
    # (i.e., content is "on" or "on:<THIS_SESSION>" -- never remove "on:<OTHER>")
    if [ -f "$LEGACY_FLAG" ]; then
      LEGACY_LINE=$(head -1 "$LEGACY_FLAG" 2>/dev/null | tr -d '\r' | tr -d '[:space:]')
      case "$LEGACY_LINE" in
        on|ON)
          rm -f "$LEGACY_FLAG" 2>/dev/null ;;
        on:*|ON:*)
          LEGACY_SID="${LEGACY_LINE#*:}"
          if [ -z "$SESSION_ID" ] || [ "$LEGACY_SID" = "$SESSION_ID" ]; then
            rm -f "$LEGACY_FLAG" 2>/dev/null
          fi
          # else: legacy flag belongs to another session -- leave it alone
          ;;
      esac
    fi
    echo "<< Autonomous Mode Disarmed >>"
    echo "[autonomous] DISARMED -- user returned. The assistant should echo the banner line above so the user can validate. The Stop hook will allow normal stops again."
    exit 0 ;;
esac

# ---------- ARM: AFK signal ----------
case "$LC" in
  *afk* \
  |*"stepping away"*|*"step away"* \
  |*"be back later"*|*"back later"* \
  |*brb* \
  |*"going to lunch"*|*"out to lunch"* \
  |*"heading out"*|*"logging off"*|*"signing off"* \
  |*"away for"*|*"out for a"*|*"gone for"* \
  |*"back in an hour"*|*"back in a bit"*|*"back tomorrow"* \
  |*"going to bed"*|*"call it a night"* \
  |*"run unattended"*|*"work the queue unattended"*)
    mkdir -p "$STATE_DIR" 2>/dev/null
    if [ -n "$SESSION_FLAG" ]; then
      # Preferred: session-scoped flag (only arms THIS session)
      printf 'on\n' > "$SESSION_FLAG" 2>/dev/null
      ARMED_AT="$SESSION_FLAG"
    else
      # Fallback: legacy workspace-shared flag (no SESSION_ID available)
      printf 'on\n' > "$LEGACY_FLAG" 2>/dev/null
      ARMED_AT="$LEGACY_FLAG"
    fi
    echo "<< Full Autonomous Mode Enabled >>"
    echo "[autonomous] ARMED via AFK phrase (flag: $ARMED_AT). The assistant MUST echo the banner line above as the FIRST line of its reply so the user can validate. The Stop hook will now BLOCK stops while the active Hub.md '## ACTIVE TODO' has unblocked tasks, so the session keeps working the queue unattended. Disarm by saying you are back (e.g. \"I'm back\") or run: rm $ARMED_AT"
    exit 0 ;;
esac

exit 0
