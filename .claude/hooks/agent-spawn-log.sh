#!/usr/bin/env bash
# agent-spawn-log.sh -- PreToolUse hook (matcher: "Agent")
#
# Pure-bash, zero-LLM-cost logger. Appends ONE line per new subagent spawn
# to a PER-LANE log file under ~/.claude/logs/ so the operator can `tail -f`
# just the new entries for a given lane. Additive-only observability -- it
# never blocks a spawn and never changes dispatch behavior. Always exits 0
# (fail-open).
#
# Lane resolution (WS6, Epic #4526 -- see scripts/session-lane-resolve.sh):
#   lane = SESSION IDENTITY first (env / session env-file / registry),
#   NEVER just the project dir's path. Falls back to basename of
#   `git -C "$CLAUDE_PROJECT_DIR" rev-parse --show-toplevel`, then basename
#   of "$CLAUDE_PROJECT_DIR", then "unknown" when session-lane-resolve.sh is absent
#   or resolve_session_lane() misses on every tier (guarded inline fallback).
#   Sanitized to [A-Za-z0-9._-] (anything else -> "-").
#
# Per-lane file: ~/.claude/logs/agent-spawns.<lane>.log
#
# Claude Code PreToolUse payload shape (stdin, JSON):
#   { "session_id": "...", "tool_name": "Agent",
#     "tool_input": { "description": "...", "subagent_type": "...",
#                      "model": "...", "prompt": "..." }, ... }
# "model" may be ABSENT when the dispatcher omits it -- the agent then
# inherits the parent/session tier. That case is logged as model=INHERIT.
#
# Persona extraction (schema v1.1): dispatch prompts are required to carry a
# "PERSONA: <named role>" line inside tool_input.prompt per
# rules/agent-cost-tiering.md. The first such line's value is extracted and
# logged as persona=<value>; when no PERSONA line is present (or prompt is
# absent), persona=none.
#
# Log line format (pipe-delimited, SQL-friendly for the planned dash #3938
# read; see references/agent-spawn-log-schema.md for the full versioned
# schema and consumer-parsing guidance):
#
#   v1   (legacy, still emitted by unupgraded installs -- readers MUST stay
#        tolerant of this shape):
#     <ISO8601Z> | lane=<lane> | model=<model-or-INHERIT> | type=<type-or-none> | title=<description>
#
#   v1.1 (current -- this file):
#     <ISO8601Z> | lane=<lane> | model=<model-or-INHERIT> | type=<type-or-none> | persona=<persona-or-none> | title=<description>
#
# New fields are ALWAYS inserted before `title=` (title may legitimately
# contain spaces and is intentionally the last field so its content is
# unambiguous to a naive pipe-split parser). Every non-title field value is
# pipe-sanitized at write time (literal '|' -> '-', see sanitize_field) so
# title= is mechanically the only field that can carry a pipe. Never remove
# or reorder an existing field -- see references/agent-spawn-log-schema.md's
# versioning rule.
#
# Usage:
#   agent-spawn-log.sh              # normal hook mode: reads the PreToolUse payload from stdin
#   agent-spawn-log.sh --selftest [lane]
#                                   # synthetic payload, no live session required; prints + appends
#                                   # a test line (optional lane override, default "selftest-lane"),
#                                   # and reports which per-lane file it wrote to.

set +e

LOG_DIR="$HOME/.claude/logs"

# Sanitize an arbitrary string to a safe lane token: [A-Za-z0-9._-], else "-".
sanitize_lane() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'
}

# Resolve the lane via the shared session-identity-first resolver (WS6,
# Epic #4526): lane = SESSION IDENTITY (env / env-file / registry), never
# just the project dir's git toplevel. A cwd/PROJECT_DIR-derived hint is
# still computed and passed in for the resolver's identity/cwd mismatch
# warning, and doubles as the GUARDED INLINE FALLBACK if session-lane-resolve.sh is
# missing or fails to define resolve_session_lane -- reproducing the exact
# pre-WS6 behavior so a missing shared script never breaks this logger.
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

  # GUARDED INLINE FALLBACK: resolver missing/failed -- reproduce pre-WS6
  # behavior (cwd/PROJECT_DIR-derived lane).
  [ -z "$lane" ] && lane="$cwd_hint"

  [ -z "$lane" ] && lane="unknown"
  lane=$(sanitize_lane "$lane")
  [ -z "$lane" ] && lane="unknown"
  printf '%s' "$lane"
}

# Collapse newlines so one spawn always yields exactly one log line.
sanitize() {
  printf '%s' "$1" | tr '\n\r' '  '
}

# Field-level sanitization for every NON-title field: newline collapse PLUS
# literal '|' -> '-'. The schema contract (references/agent-spawn-log-schema.md)
# guarantees title= is the ONLY field that may contain a literal pipe, so a
# naive "split on ' | '" consumer parser is safe -- this function ENFORCES
# that guarantee at the producer rather than assuming it. persona= in
# particular is free text from an LLM-authored PERSONA: envelope line, not a
# closed enum, and model=/type= are arbitrary tool_input values.
sanitize_field() {
  printf '%s' "$1" | tr '\n\r|' '  -'
}

# Append one line to the per-lane log. Sets LAST_LOG_FILE for callers.
append_line() {
  # $1 = lane, $2 = model, $3 = subagent_type, $4 = persona, $5 = description
  local lane model stype persona desc ts line
  lane=$(sanitize_field "$1")
  model=$(sanitize_field "$2")
  stype=$(sanitize_field "$3")
  persona=$(sanitize_field "$4")
  desc=$(sanitize "$5")
  [ -z "$lane" ] && lane="unknown"
  [ -z "$model" ] && model="INHERIT"
  [ -z "$stype" ] && stype="none"
  [ -z "$persona" ] && persona="none"
  [ -z "$desc" ] && desc="(untitled)"
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  [ -z "$ts" ] && ts="unknown-time"
  LAST_LOG_FILE="$LOG_DIR/agent-spawns.${lane}.log"
  mkdir -p "$LOG_DIR" 2>/dev/null
  line="${ts} | lane=${lane} | model=${model} | type=${stype} | persona=${persona} | title=${desc}"
  echo "$line" >> "$LAST_LOG_FILE" 2>/dev/null
  printf '%s\n' "$line"
}

# Extract a field from .tool_input via jq.
extract_field_jq() {
  # $1 = json text, $2 = field name
  printf '%s' "$1" | jq -r --arg f "$2" '(.tool_input // {}) | .[$f] // empty' 2>/dev/null
}

# Fallback: grep the first "field":"value" occurrence in the flattened payload.
# Robust-enough fallback for environments without jq; not a full JSON parser.
extract_field_grep() {
  # $1 = json text, $2 = field name
  printf '%s' "$1" | tr -d '\n' | grep -o "\"${2}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"
}

# Extract the first "PERSONA: <value>" line from a prompt string (already
# unescaped by jq -- real newlines).
extract_persona_from_prompt() {
  # $1 = prompt text
  printf '%s\n' "$1" | grep -m1 -E '^[[:space:]]*PERSONA:' | sed -E 's/^[[:space:]]*PERSONA:[[:space:]]*//' | sed -E 's/[[:space:]]*$//'
}

# Fallback (no jq): best-effort scan of the RAW json text for a literal
# "PERSONA:" marker. Within compact JSON, an embedded newline in the prompt
# string is escaped as the two-character sequence backslash-n, so a run of
# non-backslash, non-quote characters after "PERSONA:" approximates "to end
# of that line". Not a full JSON parser -- documented best-effort fallback,
# same tier as extract_field_grep above.
extract_persona_grep_raw() {
  # $1 = raw json text
  printf '%s' "$1" | grep -o 'PERSONA:[^\\"]*' | head -1 | sed -E 's/^PERSONA:[[:space:]]*//' | sed -E 's/[[:space:]]*$//'
}

extract_all() {
  # $1 = json text -> sets DESC, STYPE, MODEL, PERSONA
  if command -v jq >/dev/null 2>&1; then
    DESC=$(extract_field_jq "$1" "description")
    STYPE=$(extract_field_jq "$1" "subagent_type")
    MODEL=$(extract_field_jq "$1" "model")
    PROMPT=$(printf '%s' "$1" | jq -r '(.tool_input // {}) | .prompt // empty' 2>/dev/null)
    PERSONA=$(extract_persona_from_prompt "$PROMPT")
  else
    DESC=$(extract_field_grep "$1" "description")
    STYPE=$(extract_field_grep "$1" "subagent_type")
    MODEL=$(extract_field_grep "$1" "model")
    PERSONA=$(extract_persona_grep_raw "$1")
  fi
}

if [ "$1" = "--selftest" ]; then
  LANE="${2:-selftest-lane}"
  LANE=$(sanitize_lane "$LANE")
  [ -z "$LANE" ] && LANE="selftest-lane"
  SAMPLE='{"session_id":"selftest-session","transcript_path":"/tmp/x","cwd":"/tmp","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"Selftest sample dispatch","subagent_type":"general-purpose","model":"sonnet","prompt":"TASK-CLASS: implementation\nPROVIDER: anthropic\nMODEL: sonnet\nPERSONA: DevOps Engineer (selftest)\nCHARTER: agents/dev-shop-pack/devops-engineer/CHARTER.md\n\nDo the selftest task."}}'
  extract_all "$SAMPLE"
  append_line "$LANE" "$MODEL" "$STYPE" "$PERSONA" "$DESC"
  echo "[selftest] wrote to: $LAST_LOG_FILE" >&2
  exit 0
fi

# Normal hook mode: bounded read of stdin so a stuck pipe can never hang the tool call.
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
fi
[ -z "$INPUT" ] && exit 0

LANE=$(resolve_lane)
extract_all "$INPUT"
append_line "$LANE" "$MODEL" "$STYPE" "$PERSONA" "$DESC" >/dev/null 2>&1

exit 0
