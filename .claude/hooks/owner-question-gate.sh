#!/bin/bash
# jk-owner-question-hook -- PreToolUse gate for the Owner-Question Protocol
# (rules/owner-question-protocol.md). Ticket #2747.
#
# WHAT IT DOES
# Session-side companion to the dash-api server-side validation
# (dashapi-owner-question-gate). Covers the path the API cannot see: an
# interactive agent asking Owner directly via the AskUserQuestion tool.
# Inspects the tool payload and BLOCKS the call unless each question first
# carries the AI-VALUE-GATE precursor (context, AI work completed, and why
# Owner is uniquely required), followed by a recognized classification marker:
#   OWNER-ACTION       -- only Owner has the authority/access
#   OWNER-DECISION     -- genuine business tradeoff; requires at least one
#                          option marked "(Recommended)"
#   CLARIFICATION:     -- escape hatch for a genuine blocking clarification;
#                          requires a one-line why-only-Owner reason
# A raw, unclassified question is a protocol violation, not a style nit.
# The block message re-injects the full A/B/CLARIFICATION templates verbatim
# so the agent reformats and retries immediately -- the block IS the training.
#
# Event: PreToolUse, matcher: "AskUserQuestion"
# Exit contract (rules/claude-code-hook-deployment.md):
#   0 = allow (compliant payload, non-AskUserQuestion tool, or any parse
#       failure -- FAIL-OPEN, never traps the session)
#   2 = block; stderr is fed back to the model as the next directive
#
# Bypass: DOE_HEADLESS=1 -- headless DOE workers never call AskUserQuestion,
# kept symmetric with the bypass pattern in session-start-lane-register.sh /
# session-start-master-orchestrator-rule.sh.
#
# Canonical source: jit-knowledge/templates/claude-hooks/owner-question-gate.sh
# Install via: bash scripts/install.sh
#
# Test mode: `owner-question-gate.sh --verdict '<json-payload>'` prints the
# verdict (ALLOW / BLOCK / PARSE_FAIL / SKIP) without exit-2 side effects, for
# unit testing (see templates/claude-hooks/tests/owner-question-gate.test.sh).

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- headless bypass ----------
if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

# ---------- classify one payload; prints ALLOW|BLOCK|PARSE_FAIL|SKIP (+ reasons) ----------
_classify() {
  local payload="$1"
  if ! command -v python3 >/dev/null 2>&1; then
    # No JSON parser available -- nested question/options arrays cannot be
    # safely inspected with grep alone. Fail open rather than risk a false
    # block or a false allow from a fragile heuristic.
    echo "PARSE_FAIL"
    return 0
  fi
  INPUT_JSON="$payload" python3 - <<'PYEOF'
import json, os, sys

raw = os.environ.get("INPUT_JSON", "")
try:
    data = json.loads(raw)
except Exception:
    print("PARSE_FAIL")
    sys.exit(0)

if not isinstance(data, dict):
    print("PARSE_FAIL")
    sys.exit(0)

tool_name = data.get("tool_name", "")
if tool_name and tool_name != "AskUserQuestion":
    print("SKIP")
    sys.exit(0)

tool_input = data.get("tool_input", {}) or {}
if not isinstance(tool_input, dict):
    print("PARSE_FAIL")
    sys.exit(0)

questions = tool_input.get("questions", [])
if not isinstance(questions, list) or not questions:
    # Nothing shaped like an AskUserQuestion payload to validate.
    print("PARSE_FAIL")
    sys.exit(0)

if len(questions) != 1:
    print("BLOCK")
    print("question payload: exactly one Owner question is allowed per interaction; received %d" % len(questions))
    sys.exit(0)

violations = []
for i, q in enumerate(questions):
    if not isinstance(q, dict):
        violations.append("question %d: not an object" % (i + 1))
        continue

    qtext = str(q.get("question", "") or "")
    header = str(q.get("header", "") or "")
    combined = qtext + "\n" + header

    # Primary precursor: formatting a question correctly is not enough. The
    # asking agent must first attest that AI exhausted discovery, judgment,
    # specialist routing, and verification without sacrificing quality.
    required_gate = "AI-VALUE-GATE: OWNER REQUIRED"
    required_fields = ("CONTEXT:", "AI WORK COMPLETED:", "WHY OWNER:")
    gate_violations = []
    if required_gate not in qtext:
        gate_violations.append("missing AI-VALUE-GATE: OWNER REQUIRED")
    for field in required_fields:
        value = ""
        for line in qtext.splitlines():
            if line.strip().startswith(field):
                value = line.strip()[len(field):].strip()
                break
        if len(value) < 10 or value.startswith("<"):
            gate_violations.append("missing substantive %s" % field)
    if gate_violations:
        violations.append("question %d: %s" % (i + 1, "; ".join(gate_violations)))
        continue

    options = q.get("options", []) or []
    opt_texts = []
    if isinstance(options, list):
        for o in options:
            if isinstance(o, dict):
                opt_texts.append(
                    str(o.get("label", "") or "") + " " + str(o.get("description", "") or "")
                )
            else:
                opt_texts.append(str(o))

    has_decision = "OWNER-DECISION" in combined
    has_action = "OWNER-ACTION" in combined or "OWNER BLOCKED:" in combined
    has_clarification = "CLARIFICATION:" in combined

    if has_decision:
        recommended = any("(Recommended)" in t for t in opt_texts) or "(Recommended)" in combined
        if not recommended:
            violations.append(
                "question %d: OWNER-DECISION marker present but no option marked (Recommended)" % (i + 1)
            )
        continue

    if has_action:
        continue

    if has_clarification:
        # Prefer the question field for the why-line length check -- the
        # header is a short UI tab label (<=12 chars) and would inflate an
        # otherwise-empty "why" with unrelated text if combined naively.
        source = qtext if "CLARIFICATION:" in qtext else combined
        after = source.split("CLARIFICATION:", 1)[1].strip()
        if len(after) < 10:
            violations.append(
                "question %d: CLARIFICATION: marker present but missing a one-line why-only-Owner reason" % (i + 1)
            )
        continue

    violations.append(
        "question %d: no classification marker (OWNER-ACTION / OWNER-DECISION / CLARIFICATION:)" % (i + 1)
    )

if violations:
    print("BLOCK")
    for v in violations:
        print(v)
else:
    print("ALLOW")
PYEOF
}

# ---------- test-mode entry point ----------
if [ "${1:-}" = "--verdict" ]; then
  _classify "${2:-}"
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
VERDICT="$(printf '%s\n' "$RESULT" | head -1)"
REASONS="$(printf '%s\n' "$RESULT" | tail -n +2)"

case "$VERDICT" in
  BLOCK)
    {
      echo "BLOCKED by the Owner-Question Protocol (rules/owner-question-protocol.md):"
      echo "one or more questions failed the mandatory AI-VALUE-GATE precursor or"
      echo "classification contract. Resolve internally when possible; otherwise"
      echo "reformat and retry with the precursor plus one template below."
      echo ""
      echo "Violations:"
      echo "$REASONS"
      echo ""
      echo "MANDATORY PRECURSOR -- run BEFORE classification or asking:"
      echo "  AI-VALUE-GATE: OWNER REQUIRED"
      echo "  CONTEXT: <what is happening and why it matters, in plain language>"
      echo "  AI WORK COMPLETED: <research, specialist/panel decision, tests, or verification already performed>"
      echo "  WHY OWNER: <authority, business judgment, access, irreversible risk, or conflicting directive only Owner can resolve>"
      echo ""
      echo "If AI can discover, decide, delegate to a specialist, test, or safely"
      echo "default the matter without sacrificing verified quality, DO NOT ASK."
      echo "Execute, verify, and report the result instead."
      echo "Ask at most ONE question per interaction, with full plain-language context."
      echo ""
      echo "TYPE A -- OWNER-ACTION (only Owner has the authority/access):"
      echo "  OWNER BLOCKED: <what>"
      echo "  WHY ONLY YOU: <reason>"
      echo "  TO UNBLOCK: <numbered exact steps -- clicks or commands, copy-pasteable>"
      echo "  TIME: ~N min"
      echo "  BLOCKS: <tickets>"
      echo ""
      echo "TYPE B -- OWNER-DECISION (genuine business tradeoff):"
      echo "  OWNER-DECISION: <the decision, one line>"
      echo "  OPTIONS:"
      echo "    1. <option> (Recommended)"
      echo "    2. <option>"
      echo "    [3. <option>]"
      echo "  RECOMMENDATION: <chosen option> -- confidence: <high|medium|low>"
      echo "  EVIDENCE: <evidence> (method: <testing method>)"
      echo "  WHAT-WOULD-CHANGE-MY-MIND: <specific fact or result that would flip the call>"
      echo "  DEFAULT-ON-SILENCE: if no answer by <when>, we default to <X>"
      echo "  BLOCKS: <tickets, or none>"
      echo "  Exactly ONE option must carry \"(Recommended)\"."
      echo ""
      echo "ESCAPE HATCH -- CLARIFICATION: (genuine blocking clarification only):"
      echo "  CLARIFICATION: <question>"
      echo "  WHY ONLY OWNER: <one-line reason only Owner can answer this>"
      echo ""
      echo "A type C question (technical correctness / done-ness / PR review /"
      echo "design) NEVER reaches Owner as a raw question -- run the applicable"
      echo "machinery first (rules/verify-before-claiming.md, the PR-QA chain, or a"
      echo "panel/divergent synthesis) and escalate only the RESULT as an"
      echo "OWNER-DECISION with the verification report as EVIDENCE."
      echo ""
      echo "Put the marker in the \"question\" (or \"header\") field of each question"
      echo "item; for OWNER-DECISION mark exactly one option's label/description"
      echo "\"(Recommended)\"."
    } >&2
    exit 2 ;;
  ALLOW|SKIP|PARSE_FAIL|"")
    exit 0 ;;
  *)
    exit 0 ;;  # unrecognized verdict -- fail open
esac
