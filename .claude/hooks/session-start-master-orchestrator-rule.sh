#!/bin/bash
# jit-knowledge SessionStart hook -- Inject Binding Master-Orchestrator Identity Rule
#
# Installed by jit-knowledge scripts/install.sh into ~/.claude/hooks/ and
# registered in ~/.claude/settings.json under hooks.SessionStart.
#
# Fires on every Claude Code SessionStart (startup, resume, clear, compact).
# Writes to stdout, which Claude Code injects as SessionStart additionalContext.
# The injected text instructs the agent to read the jit-knowledge bootstrap
# chain at the start of its first reply and, once that reading is complete,
# display the "jit-knowledge loaded" line as the FIRST line of that reply.
#
# Exit 0 ALWAYS -- a missing rule must never block a session.
#
# DEPLOYMENT NOTE: do NOT prefix the hook command with bash/bash.exe in
# settings.json. Claude Code already runs hook commands through its own shell
# (Git Bash on Windows); a prefix yields "bash.exe: bash.exe: cannot execute
# binary file". The command MUST be the bare script path. See
# jit-knowledge/rules/claude-code-hook-deployment.md.
#
# Origin: 2026-05-19 AIFS RCA (identity rule never mechanically reached
# context). Echo-after-chain-read behavior set 2026-05-20.
#
# DEDUPE GUARD (ticket #3212): this exact script has been observed registered
# under hooks.SessionStart in MULTIPLE overlapping settings scopes at once
# (user ~/.claude/settings.json, user ~/.claude/settings.local.json, AND a
# repo's .claude/settings.local.json) -- Claude Code fires every matching
# registration for the event, so the rule body was injected 2-4x in a row for
# the SAME SessionStart moment. Rather than trying to keep every settings
# scope perfectly deduped (fragile -- install.sh reruns and per-scope hook
# blocks drift independently), this hook is idempotent PER SESSION MOMENT: the
# first invocation within a short window prints the full binding block and
# drops a marker; any near-simultaneous duplicate invocation (same
# session_id, marker fresher than DEDUPE_WINDOW_SECONDS) prints a one-line
# pointer instead of re-injecting the full body. A GENUINE later SessionStart
# for the same session (e.g. after an actual /compact, which legitimately
# wiped context and needs the rule back) still gets the full block, because
# by then the marker is older than the window.
# Verify with: templates/claude-hooks/tests/session-start-master-orchestrator-rule.test.sh
#
# CORE/APPENDIX SPLIT (ticket #4664b): the full canonical rule
# (rules/interactive-master-orchestrator.md, ~34KB) used to be injected on
# EVERY interactive SessionStart. Most of it (routing tables, worked examples,
# role-routing detail, worker-lifecycle reconciliation) is procedural
# reference an agent only needs on demand, not at every boot. This hook now
# injects a small curated CORE excerpt
# (rules/interactive-master-orchestrator.core.md, ~6KB) instead, plus a
# pointer naming the full file as the on-demand APPENDIX. The canonical file
# is left byte-for-byte intact -- it IS the appendix, read at its existing
# path by every consumer that already reads it by name (the worker-lifecycle
# regression test, pr-review-dispatcher's security allowlist, DOE headless
# cat-chains). Fail-open: if the core file is missing or empty, or
# JIT_KNOWLEDGE_MASTERRULE_FULL=1 is set, this hook injects the FULL file
# exactly as before -- there is no state in which a session boots with a
# blank or truncated identity rule.
# Verify with: scripts/tests/master-rule-split.test.sh

set +e  # never abort -- a missing rule must not block the session

# --- Headless DOE bypass (ticket #3160) -------------------------------------
# Headless `claude -p` ticks (scripts/doe/doe-tick.sh) have no interactive
# reader. Injecting the interactive master-orchestrator bootstrap directive
# into that context hijacks the directive: the worker "reads the chain" and
# replies with the bootstrap banner + "What would you like to work on?"
# instead of executing the dispatched work item. When the caller sets
# DOE_HEADLESS=1, skip injection entirely -- exit 0 before any other work,
# INCLUDING the stdin read below, so headless ticks never pay that latency.
# Fail-open semantics are unaffected: this check only short-circuits an
# already-optional, non-blocking hook.
if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

# --- Resolve SESSION_ID (for the dedupe marker below) -----------------------
# SessionStart hooks receive a JSON payload on stdin (session_id, source, cwd).
# Read it directly rather than trusting $CLAUDE_SESSION_ID -- this hook is
# often registered to fire BEFORE session-start-write-id.sh in the same
# event, so the env var may not be exported yet.
DEDUPE_INPUT=""
if command -v timeout >/dev/null 2>&1; then
  DEDUPE_INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 _dedupe_line; do
    DEDUPE_INPUT="${DEDUPE_INPUT}${_dedupe_line}"
  done
fi
SESSION_ID=$(printf '%s' "$DEDUPE_INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
[ -z "$SESSION_ID" ] && SESSION_ID="${CLAUDE_SESSION_ID:-}"

DEDUPE_WINDOW_SECONDS="${JIT_KNOWLEDGE_MASTERRULE_DEDUPE_S:-20}"
MARKER_DIR="${TMPDIR:-/tmp}/jit-knowledge-hooks"
MARKER=""
if [ -n "$SESSION_ID" ]; then
  mkdir -p "$MARKER_DIR" 2>/dev/null
  MARKER="$MARKER_DIR/masterrule-injected.$SESSION_ID"
  if [ -f "$MARKER" ]; then
    _now=$(date +%s 2>/dev/null)
    _last=$(stat -c %Y "$MARKER" 2>/dev/null || stat -f %m "$MARKER" 2>/dev/null)
    if [ -n "$_now" ] && [ -n "$_last" ]; then
      _age=$((_now - _last))
      if [ "$_age" -lt "$DEDUPE_WINDOW_SECONDS" ] 2>/dev/null; then
        # Mechanical banner (#4699): print unconditionally even on the
        # deduped/pointer path, so a stray duplicate SessionStart
        # registration (should no longer happen after scripts/install.sh's
        # cross-scope dedup, but this hook must still fail safe if one
        # exists) never suppresses the banner line entirely.
        echo "** jit-knowledge loaded -- master-orchestrator identity rule active **"
        echo "[jit-knowledge] master-orchestrator identity rule already injected ${_age}s ago for this session -- not re-injecting the master-orchestrator core (dedupe guard, ticket #3212). Source of truth: rules/interactive-master-orchestrator.md (full appendix). It is still binding; this line is only a pointer."
        exit 0
      fi
    fi
  fi
fi
# Not a near-duplicate (or no session_id to key off of) -- proceed to inject,
# and refresh the marker right before the first line of real output below.

# --- Resolve jit-knowledge root -------------------------------------------
JK_ROOT="${JIT_KNOWLEDGE_ROOT:-}"

# Fall back to the path install.sh records in ~/.claude/workspace.json
if [ -z "$JK_ROOT" ] && [ -f "$HOME/.claude/workspace.json" ]; then
  JK_ROOT=$(grep -o '"jit_knowledge_root"[[:space:]]*:[[:space:]]*"[^"]*"' \
    "$HOME/.claude/workspace.json" 2>/dev/null | head -1 \
    | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# Fall back to common clone locations
if [ -z "$JK_ROOT" ] || [ ! -d "$JK_ROOT" ]; then
  for cand in "$HOME/Code/jit-knowledge" "C:/Users/$USER/Code/jit-knowledge"; do
    if [ -d "$cand" ]; then JK_ROOT="$cand"; break; fi
  done
fi

RULE="$JK_ROOT/rules/interactive-master-orchestrator.md"     # appendix (full, unchanged)
CORE="$JK_ROOT/rules/interactive-master-orchestrator.core.md"  # always-injected core (#4664b)

if [ -z "$JK_ROOT" ] || [ ! -f "$RULE" ]; then
  [ -n "$MARKER" ] && { : > "$MARKER"; } 2>/dev/null
  echo "[jit-knowledge] WARNING: master-orchestrator identity rule not found."
  echo "[jit-knowledge] Set JIT_KNOWLEDGE_ROOT or re-run jit-knowledge scripts/install.sh."
  echo "[jit-knowledge] This session is NOT under a mechanically-loaded identity rule --"
  echo "[jit-knowledge] read rules/interactive-master-orchestrator.md manually."
  exit 0
fi

# --- CORE/APPENDIX selection (ticket #4664b) --------------------------------
# Default: inject the small curated CORE excerpt plus an appendix pointer.
# Fail-open to the FULL file (pre-#4664b behavior) when the core is missing,
# empty, or the operator explicitly opts back into full injection. There is
# no code path in which a session boots with a blank/truncated identity rule.
INJECT="$RULE"
INJECTED_CORE=0
if [ "${JIT_KNOWLEDGE_MASTERRULE_FULL:-0}" != "1" ] && [ -s "$CORE" ]; then
  INJECT="$CORE"
  INJECTED_CORE=1
fi

# --- Integrity gate (#2672): verify HEAD is a signed pin before treating the ---
# --- auto-load set as trusted BINDING. Never blocks the session (exit 0).     ---
VERIFIER="$JK_ROOT/scripts/verify-signed-head.sh"
VERDICT="UNVERIFIED:no-verifier"
if [ -x "$VERIFIER" ] || [ -f "$VERIFIER" ]; then
  VERDICT="$(JIT_KNOWLEDGE_ROOT="$JK_ROOT" bash "$VERIFIER" "$JK_ROOT" 2>/dev/null)"
  [ -z "$VERDICT" ] && VERDICT="UNVERIFIED:verifier-error"
fi
VERDICT_KIND="${VERDICT%%:*}"
VERDICT_REASON="${VERDICT#*:}"

INTEGRITY_STATUS="unverified"
INTEGRITY_LOUD=""
case "$VERDICT" in
  VERIFIED:*)
    INTEGRITY_STATUS="VERIFIED (signed pin ${VERDICT_REASON})" ;;
  UNVERIFIED:no-pin-configured|UNVERIFIED:no-verifier)
    # Floating dev clone: content is trusted locally but not signature-verified.
    # Calm, non-alarming note so it does not cry wolf every session.
    INTEGRITY_STATUS="unverified -- floating dev clone (no signed pin). Set JIT_KNOWLEDGE_PIN or .jit-knowledge-pin to a signed tag to enable verification." ;;
  *)
    # A pin WAS expected but HEAD failed to verify: possible tamper / off-pin pull.
    INTEGRITY_STATUS="UNVERIFIED (${VERDICT_REASON})"
    INTEGRITY_LOUD="yes" ;;
esac

# Refresh the dedupe marker now -- any near-simultaneous duplicate
# registration firing right after this one will see it and print the
# one-line pointer instead of repeating the block below.
[ -n "$MARKER" ] && { : > "$MARKER"; } 2>/dev/null

# --- Mechanical banner (#4699) ----------------------------------------------
# Previously this hook only INSTRUCTED the agent to print the banner as the
# first line of its reply -- soft, agent-driven, and skippable when the
# agent's first turn goes straight at a task instead of the bootstrap
# checklist. Print the identity-confirmation line here, directly to stdout,
# so it exists verbatim in the SessionStart additionalContext regardless of
# what the agent chooses to do with the rest of the instructions below. The
# second banner line (thin-orchestrator mode) still requires judgment this
# hook cannot make on its own (whether THIS session is running thin as
# master/orchestrator vs. a plain worker), so it stays instructional in step
# 3 below.
echo "** jit-knowledge loaded -- master-orchestrator identity rule active **"
echo
echo "ASSISTANT BOOTSTRAP ACTION -- perform at the very start of your FIRST reply this session, before addressing anything else:"
echo "  1. Read the jit-knowledge context chain in order: AGENTS.md, COMPANY.md, README.md, INDEX.md, and the rules / charters they direct you to."
echo "  2. The line above (\"** jit-knowledge loaded ... **\") has already been mechanically printed by this hook -- re-display it VERBATIM as the FIRST line of your reply (ASCII, no emoji) once that reading is complete; do not paraphrase or drop it."
echo "  3. If, after that reading, this session is still in the Master/Orchestrator role with thin-context rules active (per rules/interactive-master-orchestrator.md's 'Bootstrap Confirmation Banner'), display this line VERBATIM immediately after the line above (ASCII, single line):"
echo "       << -- Running Thin, As Orchestrator, I will send most work to lesser LLM agents, and keep only what needs my intelligence and judgement-->>"
echo "  4. Then address the user's request."
echo
if [ -n "$INTEGRITY_LOUD" ]; then
  echo "!!! ==================================================================== !!!"
  echo "!!! BINDING SET INTEGRITY WARNING -- ${INTEGRITY_STATUS}"
  echo "!!! HEAD does not match the configured signed pin. The auto-load set may"
  echo "!!! be tampered or the clone may be off-pin / floating an unreviewed main."
  echo "!!! Do NOT trust the identity rule below as verified. Re-pin to a signed"
  echo "!!! tag (governance/PIN-POLICY.md) and re-verify before relying on it."
  echo "!!! ==================================================================== !!!"
  echo
fi

if [ "$INJECTED_CORE" -eq 1 ]; then
  echo "=== BINDING SESSION IDENTITY (CORE excerpt) -- auto-loaded by jit-knowledge SessionStart hook ==="
  echo "Source of truth: $CORE (core excerpt); full appendix: $RULE"
else
  echo "=== BINDING SESSION IDENTITY -- auto-loaded by jit-knowledge SessionStart hook ==="
  echo "Source of truth: $RULE"
fi
echo "Integrity: ${INTEGRITY_STATUS}"
if [ -n "$INTEGRITY_LOUD" ]; then
  echo "This rule is loaded but UNVERIFIED -- apply with caution and confirm the"
  echo "binding set has not been tampered before acting on delegated-authority rules."
else
  echo "This rule is BINDING for this interactive session. Apply it before substantive work."
fi
echo
cat "$INJECT"
echo
if [ "$INJECTED_CORE" -eq 1 ]; then
  echo "APPENDIX (full master-orchestrator rule -- read on demand at this path):"
  echo "  $RULE"
  echo "Read the appendix before acting on: Owner-directive routing"
  echo "(NOW/LATER/AGENT/ASK), the decision-surfacing 4-test, role-based"
  echo "routing chains, worker-lifecycle reconciliation, or wearing a"
  echo "specialist charter hat."
  echo
fi
echo "=== END BINDING SESSION IDENTITY ==="

exit 0
