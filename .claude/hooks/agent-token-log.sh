#!/usr/bin/env bash
# agent-token-log.sh -- PostToolUse hook (matcher: "Agent")
#
# Pure-bash, zero-LLM-cost token-return logger. Companion to
# agent-cost-tiering-gate.sh (PreToolUse block) and agent-spawn-log.sh
# (PreToolUse spawn record): where those two fire when a subagent is
# DISPATCHED, this one fires when a subagent RETURNS and records the
# `TOKENS: in=X out=X model=<model>` line every subagent MUST emit per
# ~/.claude/rules/subagent-communication.md's return-format contract.
# Additive-only observability -- never blocks a return, always exits 0
# (fail-open). Implements rules/cost-governor-architecture.md's "Token
# Logger (zero AI tokens)" role using a bash/file-backed logger instead of
# the aspirational `scripts/log-tokens.ps1` (PowerShell is broken on the
# Owner Mac -- see reference_pwsh_broken_on_mac -- and Claude Code hooks
# must be POSIX-shell executable anyway).
#
# Origin: jit-knowledge #4614 / dash-api RCA rca_master-inline-execution_2026-07-21.md
# (Owner-accepted) -- 11 anonymous subagent dispatches on 2026-07-21 left
# zero token telemetry behind, so there was no evidence trail to diagnose
# cost or model-tier drift after the fact. This hook closes that gap: every
# Agent return -- compliant or not -- gets one log line, so a return that
# skipped the TOKENS: line is itself visible (tokens_missing=true) instead
# of silently vanishing.
#
# Claude Code PostToolUse payload shape (stdin, JSON):
#   { "session_id": "...", "tool_name": "Agent",
#     "tool_input": { "description": "...", "subagent_type": "...", "model": "..." },
#     "tool_response": <string, or {"content": "..."} , or {"content": [{"type":"text","text":"..."}]}> }
# The exact tool_response shape is not part of any stable public contract,
# so extraction tries, in order: a bare string, `.content` as a string,
# `.content[].text` joined, then falls back to grepping the raw payload
# text for a TOKENS: line -- the same tiered jq/grep-fallback pattern
# agent-spawn-log.sh uses for tool_input.
#
# Log line format (pipe-delimited, same family as
# references/agent-spawn-log-schema.md; SQL-friendly for a future dash
# read):
#   v1:
#     <ISO8601Z> | lane=<lane> | model=<model-or-UNKNOWN> | in=<n-or-0> | out=<n-or-0> | status=<STATUS-or-none> | tokens_missing=<true|false>
#
# Per-lane file: ~/.claude/logs/agent-tokens.<lane>.log
#
# Usage:
#   agent-token-log.sh              # normal hook mode: reads the PostToolUse payload from stdin
#   agent-token-log.sh --selftest [lane]
#                                   # synthetic compliant-return payload, no live session required
#   agent-token-log.sh --selftest-missing [lane]
#                                   # synthetic payload with NO TOKENS: line, proves the
#                                   # tokens_missing=true visibility path

set +e

LOG_DIR="$HOME/.claude/logs"

sanitize_lane() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'
}

# Lane resolution -- identical contract to agent-spawn-log.sh (WS6, Epic #4526):
# session identity first, guarded inline fallback to cwd/PROJECT_DIR toplevel,
# then "unknown".
resolve_lane() {
  local pdir cwd_hint lib lane toplevel
  pdir="${CLAUDE_PROJECT_DIR:-}"
  cwd_hint=""
  if [ -n "$pdir" ] && command -v git >/dev/null 2>&1; then
    toplevel=$(git -C "$pdir" rev-parse --show-toplevel 2>/dev/null)
    [ -n "$toplevel" ] && cwd_hint=$(basename "$toplevel")
  fi
  [ -z "$cwd_hint" ] && [ -n "$pdir" ] && cwd_hint=$(basename "$pdir")

  lib="${BASH_SOURCE[0]%/*}/session-lane-resolve.sh"
  if [ -f "$lib" ]; then
    # shellcheck disable=SC1090
    . "$lib" 2>/dev/null
  fi

  lane=""
  if command -v resolve_session_lane >/dev/null 2>&1; then
    lane=$(resolve_session_lane "$cwd_hint" 2>/dev/null)
  fi

  [ -z "$lane" ] && lane="$cwd_hint"
  [ -z "$lane" ] && lane="unknown"
  lane=$(sanitize_lane "$lane")
  [ -z "$lane" ] && lane="unknown"
  printf '%s' "$lane"
}

sanitize_field() {
  printf '%s' "$1" | tr '\n\r|' '  -'
}

# Append one line to the per-lane token log. Sets LAST_LOG_FILE for callers.
append_line() {
  # $1=lane $2=model $3=in $4=out $5=status $6=missing(true|false)
  local lane model tin tout status missing ts line
  lane=$(sanitize_field "$1")
  model=$(sanitize_field "$2")
  tin=$(sanitize_field "$3")
  tout=$(sanitize_field "$4")
  status=$(sanitize_field "$5")
  missing=$(sanitize_field "$6")
  [ -z "$lane" ] && lane="unknown"
  [ -z "$model" ] && model="UNKNOWN"
  [ -z "$tin" ] && tin="0"
  [ -z "$tout" ] && tout="0"
  [ -z "$status" ] && status="none"
  [ -z "$missing" ] && missing="true"
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  [ -z "$ts" ] && ts="unknown-time"
  LAST_LOG_FILE="$LOG_DIR/agent-tokens.${lane}.log"
  mkdir -p "$LOG_DIR" 2>/dev/null
  line="${ts} | lane=${lane} | model=${model} | in=${tin} | out=${tout} | status=${status} | tokens_missing=${missing}"
  echo "$line" >> "$LAST_LOG_FILE" 2>/dev/null
  printf '%s\n' "$line"
}

# Extract .tool_input.model via jq, else grep fallback (mirrors agent-spawn-log.sh).
extract_dispatch_model_jq() {
  printf '%s' "$1" | jq -r '(.tool_input // {}) | .model // empty' 2>/dev/null
}
extract_dispatch_model_grep() {
  printf '%s' "$1" | tr -d '\n' | grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}

# Extract the return text from tool_response, trying string / .content string /
# .content[].text array, falling back to the raw JSON text for a grep scan.
extract_response_text_jq() {
  printf '%s' "$1" | jq -r '
    (.tool_response) as $r |
    if ($r | type) == "string" then $r
    elif ($r | type) == "object" and (($r.content) | type) == "string" then $r.content
    elif ($r | type) == "object" and (($r.content) | type) == "array" then
      ($r.content | map(.text // "") | join("\n"))
    else ($r | tostring)
    end
  ' 2>/dev/null
}

# Parse "TOKENS: in=<n> out=<n> model=<model>" and an optional leading
# "STATUS: OK|BLOCKED|PARTIAL" line out of return text. Sets TOK_IN, TOK_OUT,
# TOK_MODEL, RET_STATUS, TOK_FOUND (1|0).
parse_return_text() {
  local text="$1" line
  TOK_IN="" TOK_OUT="" TOK_MODEL="" RET_STATUS="" TOK_FOUND=0
  line=$(printf '%s\n' "$text" | grep -m1 -E '^[[:space:]]*TOKENS:')
  if [ -n "$line" ]; then
    TOK_FOUND=1
    TOK_IN=$(printf '%s' "$line" | grep -o 'in=[0-9]*' | head -1 | cut -d= -f2)
    TOK_OUT=$(printf '%s' "$line" | grep -o 'out=[0-9]*' | head -1 | cut -d= -f2)
    TOK_MODEL=$(printf '%s' "$line" | grep -o 'model=[^[:space:]]*' | head -1 | cut -d= -f2)
  fi
  RET_STATUS=$(printf '%s\n' "$text" | grep -m1 -E '^[[:space:]]*STATUS:' | sed -E 's/^[[:space:]]*STATUS:[[:space:]]*//' | sed -E 's/[[:space:]]*$//')
}

if [ "${1:-}" = "--selftest" ] || [ "${1:-}" = "--selftest-missing" ]; then
  MODE="$1"
  LANE="${2:-selftest-lane}"
  LANE=$(sanitize_lane "$LANE")
  [ -z "$LANE" ] && LANE="selftest-lane"
  if [ "$MODE" = "--selftest" ]; then
    RESP_TEXT='STATUS: OK\nTOKENS: in=1200 out=340 model=sonnet\nFILES_CHANGED: none\nRESULT: selftest ok'
  else
    RESP_TEXT='STATUS: OK\nFILES_CHANGED: none\nRESULT: selftest, no TOKENS line'
  fi
  parse_return_text "$(printf '%b' "$RESP_TEXT")"
  DISPATCH_MODEL="sonnet"
  MODEL="${TOK_MODEL:-$DISPATCH_MODEL}"
  if [ "$TOK_FOUND" = "1" ]; then
    append_line "$LANE" "$MODEL" "$TOK_IN" "$TOK_OUT" "$RET_STATUS" "false"
  else
    append_line "$LANE" "$DISPATCH_MODEL" "0" "0" "$RET_STATUS" "true"
  fi
  echo "[selftest] wrote to: $LAST_LOG_FILE" >&2
  exit 0
fi

# ---------- test-mode entry point (no side effects beyond $HOME/.claude/logs) ----------
if [ "${1:-}" = "--test" ]; then
  INPUT="${2:-}"
else
  # Normal hook mode: bounded stdin read so a stuck pipe never hangs the tool call.
  INPUT=""
  if command -v timeout >/dev/null 2>&1; then
    INPUT=$(timeout 2 cat 2>/dev/null || true)
  else
    while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
  fi
fi
[ -z "$INPUT" ] && exit 0

# Scope to Agent tool only.
TOOL_NAME=""
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
else
  TOOL_NAME=$(printf '%s' "$INPUT" | tr -d '\n' | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')
fi
[ -n "$TOOL_NAME" ] && [ "$TOOL_NAME" != "Agent" ] && exit 0

LANE=$(resolve_lane)

if command -v jq >/dev/null 2>&1; then
  DISPATCH_MODEL=$(extract_dispatch_model_jq "$INPUT")
  RESP_TEXT=$(extract_response_text_jq "$INPUT")
else
  DISPATCH_MODEL=$(extract_dispatch_model_grep "$INPUT")
  RESP_TEXT="$INPUT"
fi
[ -z "$RESP_TEXT" ] && RESP_TEXT="$INPUT"

parse_return_text "$RESP_TEXT"

if [ "$TOK_FOUND" = "1" ]; then
  MODEL="${TOK_MODEL:-${DISPATCH_MODEL:-UNKNOWN}}"
  append_line "$LANE" "$MODEL" "$TOK_IN" "$TOK_OUT" "$RET_STATUS" "false" >/dev/null 2>&1
else
  append_line "$LANE" "${DISPATCH_MODEL:-UNKNOWN}" "0" "0" "$RET_STATUS" "true" >/dev/null 2>&1
fi

exit 0
