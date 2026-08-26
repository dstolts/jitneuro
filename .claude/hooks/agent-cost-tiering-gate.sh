#!/bin/bash
# jk-agent-cost-tiering-gate -- PreToolUse gate for rules/agent-cost-tiering.md
# (ticket #2562: "research requests must not use Opus" was documented nowhere
# enforceable -- validated 2026-07-05).
#
# WHAT IT DOES
# Inspects every `Agent` tool dispatch. The call MUST select a model explicitly
# and the prompt MUST contain the complete task/agent-class/provider/model/persona dispatch
# envelope defined in rules/agent-cost-tiering.md.
# The declared task class determines a provider-neutral agent class, which
# determines the allowed runtime model. Either mismatch blocks
# unless MODEL-EXCEPTION names the concrete reason and authority for deviating.
# This closes both silent model inheritance and anonymous/default-persona work.
#
# Event: PreToolUse, matcher: "Agent"
# Exit contract (rules/claude-code-hook-deployment.md):
#   0 = allow (compliant payload, non-Agent tool, or any parse failure --
#       FAIL-OPEN, never traps the session)
#   2 = block; stderr is fed back to the model as the next directive
#
# Bypass: DOE_HEADLESS=1 -- headless DOE ticks are already routed through
# db/doe/model-tier-map.json's route_model(), the equivalent enforcer for
# that path (see rules/agent-cost-tiering.md Mechanical Enforcer table).
# Kept symmetric with the bypass pattern in owner-question-gate.sh /
# session-start-lane-register.sh.
#
# Canonical source: jit-knowledge/templates/claude-hooks/agent-cost-tiering-gate.sh
# Install via: bash scripts/install.sh
#
# Test mode: `agent-cost-tiering-gate.sh --verdict '<json-payload>'` prints
# the verdict (ALLOW / BLOCK / PARSE_FAIL / SKIP) without exit-2 side
# effects, for unit testing (see
# templates/claude-hooks/tests/agent-cost-tiering-gate.test.sh).

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- headless bypass ----------
if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

# ---------- classify one payload; prints ALLOW|BLOCK|PARSE_FAIL|SKIP (+ reasons) ----------
_classify() {
  local payload="$1"
  if ! command -v python3 >/dev/null 2>&1; then
    # No JSON parser available -- fail open rather than risk a false block
    # from a fragile grep-only heuristic.
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
if tool_name and tool_name != "Agent":
    print("SKIP")
    sys.exit(0)

tool_input = data.get("tool_input", {}) or {}
if not isinstance(tool_input, dict):
    print("PARSE_FAIL")
    sys.exit(0)

description = str(tool_input.get("description", "") or "")
prompt = str(tool_input.get("prompt", "") or "")
subagent_type = str(tool_input.get("subagent_type", "") or "")
model = tool_input.get("model", None)
model_str = str(model).strip().lower() if model is not None else ""

if not description and not prompt and not subagent_type:
    # Nothing shaped like an Agent dispatch payload to validate.
    print("PARSE_FAIL")
    sys.exit(0)

def marker(name):
    prefix = name.lower() + ":"
    for line in prompt.splitlines():
        stripped = line.strip()
        if stripped.lower().startswith(prefix):
            return stripped.split(":", 1)[1].strip()
    return ""

task_class = marker("TASK-CLASS").lower().replace("_", "-").replace(" ", "-")
agent_class = marker("AGENT-CLASS").lower().replace("_", "-").replace(" ", "-")
provider = marker("PROVIDER").lower()
prompt_model = marker("MODEL").lower()
reasoning_effort = marker("REASONING-EFFORT").lower()
model_reason = marker("MODEL-REASON")
persona = marker("PERSONA")
charter = marker("CHARTER")
exception = marker("MODEL-EXCEPTION")

missing = []
if not model_str:
    missing.append("explicit Agent model field")
if not task_class:
    missing.append("TASK-CLASS")
if not agent_class:
    missing.append("AGENT-CLASS")
if provider != "anthropic":
    missing.append("PROVIDER: anthropic")
if not prompt_model:
    missing.append("MODEL")
if not reasoning_effort:
    missing.append("REASONING-EFFORT")
if not model_reason:
    missing.append("MODEL-REASON")
if not persona:
    missing.append("PERSONA")
if not charter or charter.lower() in ("none", "default", "n/a"):
    missing.append("CHARTER (an explicit path, not none/default)")
if not exception:
    missing.append("MODEL-EXCEPTION (use none when no exception applies)")

if missing:
    print("BLOCK")
    print("missing required dispatch selection: " + ", ".join(missing))
    sys.exit(0)

if prompt_model != model_str:
    print("BLOCK")
    print("prompt MODEL %s does not match Agent model field %s" % (prompt_model, model_str))
    sys.exit(0)

TASK_AGENT_CLASSES = {
    "research": "research", "scan": "research", "inventory": "research",
    "extraction": "structured", "summarize": "structured", "summary": "structured",
    "classify": "structured", "rank": "structured", "triage": "structured",
    "coding": "engineering", "implementation": "engineering", "refactor": "engineering",
    "drafting": "engineering", "code-review": "engineering", "ci-repair": "engineering",
    "ux-design": "judgment", "architecture": "judgment", "final-verdict": "judgment",
    "dispute-ruling": "judgment", "wide-context-orchestration": "judgment",
}

expected_agent_class = TASK_AGENT_CLASSES.get(task_class)
if expected_agent_class is None:
    print("BLOCK")
    print("unknown TASK-CLASS: %s -- select a canonical class or define its mapping before dispatch" % task_class)
    sys.exit(0)
if agent_class != expected_agent_class:
    print("BLOCK")
    print("TASK-CLASS %s requires AGENT-CLASS %s; got %s" % (
        task_class, expected_agent_class, agent_class
    ))
    sys.exit(0)

AGENT_CLASS_MODELS = {
    "research": {"haiku"},
    "structured": {"haiku"},
    "engineering": {"sonnet"},
    "judgment": {"opus", "fable"},
}
allowed = AGENT_CLASS_MODELS[agent_class]

if model_str in allowed:
    print("ALLOW")
    sys.exit(0)

if exception.lower() not in ("none", "n/a"):
    authority_tokens = (
        "owner", "rules/", "rule:", "unavailable", "availability",
        "capability", "context-window", "context window", "safety",
    )
    if len(exception) >= 20 and any(token in exception.lower() for token in authority_tokens):
        print("ALLOW")
        sys.exit(0)
    print("BLOCK")
    print("MODEL-EXCEPTION must cite a concrete rule/Owner authorization or capability/availability/safety constraint")
    sys.exit(0)

print("BLOCK")
print("TASK-CLASS %s / AGENT-CLASS %s requires model %s; got %s with no MODEL-EXCEPTION" % (
    task_class, agent_class, "/".join(sorted(allowed)), model_str
))
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
      echo "BLOCKED by rules/agent-cost-tiering.md: this Agent dispatch did not"
      echo "make a complete, compatible model-and-persona selection."
      echo ""
      echo "Reason: $REASONS"
      echo ""
      echo "Set the Agent model field and put these non-empty lines in the prompt:"
      echo "  TASK-CLASS: <canonical class>"
      echo "  AGENT-CLASS: <provider-neutral capability class>"
      echo "  PROVIDER: anthropic"
      echo "  MODEL: <same value as the Agent model field>"
      echo "  REASONING-EFFORT: <level or not-exposed>"
      echo "  MODEL-REASON: <why this exact tier fits>"
      echo "  PERSONA: <named role>"
      echo "  CHARTER: <explicit charter path>"
      echo "  MODEL-EXCEPTION: none"
      echo "Use MODEL-EXCEPTION only for a specific rule- or Owner-authorized"
      echo "deviation. Silent inheritance and anonymous/default personas are blocked."
    } >&2
    exit 2 ;;
  ALLOW|SKIP|PARSE_FAIL|"")
    exit 0 ;;
  *)
    exit 0 ;;  # unrecognized verdict -- fail open
esac
