#!/bin/bash
# owner-question-shape-gate.sh -- PreToolUse gate that enforces the SHAPE of an
# Owner-facing approval question, so an approval that lands can actually be
# stamped and never has to be re-asked (companion to skills/approve and
# approval-drift-gate.sh; RCA Owner-accepted 2026-07-29).
#
# This is a SHAPE gate, distinct from owner-question-gate.sh (which enforces the
# Owner-Question Protocol CLASSIFICATION -- AI-VALUE-GATE + OWNER-ACTION/
# OWNER-DECISION/CLARIFICATION). This gate enforces three properties that make
# an approval durable and stampable:
#
#   1. STABLE ID          -- the question carries a stable number/ID the stamp
#      and the surfaces can key on (a `#<ticket>`, `Q<n>`, or `<PREFIX>-<n>`).
#      Without an ID the approval cannot be closed on a surface or de-duped, so
#      it drifts and gets re-asked.
#   2. FULL ARTIFACT PATH -- any artifact the Owner is asked to approve is named
#      by a full ABSOLUTE path (or repo@sha:path), never a bare filename. Same
#      rule approve.sh's --artifact enforces. A bare filename is unstampable and
#      ambiguous.
#   3. GATED TYPE ONLY    -- the question does not ask Owner to approve a
#      NON-gated type (a contract, a spec, or a DDL-less "proposal"). Those
#      route to the panel / AI machinery, not to an Owner approval prompt. Only
#      gated kinds (schema/deploy/rbac, i.e. carrying DDL/migration/table/
#      registry/deploy/rbac evidence) belong in an Owner approval question.
#
# ENGAGEMENT (checked first): this gate only inspects
#   * AskUserQuestion tool calls, and
#   * Write/Edit tool calls whose file_path ends in questions.md
# and, within those, only questions that are Owner APPROVAL requests
# (mention approve / lock / sign-off / "ok to proceed"). Any other tool, or a
# question that is not an approval request, is SKIP/ALLOW -- this gate never
# touches non-approval questions.
#
# Exit contract (rules/claude-code-hook-deployment.md):
#   0 = allow (compliant, non-matching tool, non-approval question, or ANY parse
#       failure -- FAIL-OPEN, never traps the session)
#   2 = block; stderr fed back to the model as the next directive. FAIL-CLOSED
#       ONLY on a confirmed shape violation.
#
# Bypass: DOE_HEADLESS=1 (headless workers never AskUserQuestion);
#         OWNER_QUESTION_SHAPE_GATE=0 (global escape hatch).
#
# Event/matcher: PreToolUse, matchers "AskUserQuestion", "Write", "Edit".
#
# Canonical source:
#   jit-knowledge/templates/claude-hooks/owner-question-shape-gate.sh
# Install-time settings.json wiring is a knowledge-lane follow-up -- NOT wired
# live by this ticket.
#
# Test mode: `owner-question-shape-gate.sh --verdict '<json-payload>'` prints the
# verdict (ALLOW / BLOCK / PARSE_FAIL / SKIP) without exit-2 side effects (see
# templates/claude-hooks/tests/owner-question-shape-gate.test.sh).

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- escape hatches ----------
[ "${OWNER_QUESTION_SHAPE_GATE:-}" = "0" ] && exit 0
[ "${DOE_HEADLESS:-}" = "1" ] && exit 0

# ---------- classify one payload; prints ALLOW|BLOCK|PARSE_FAIL|SKIP (+reasons) ----------
_classify() {
  local payload="$1"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "PARSE_FAIL"   # no JSON parser -> fail open
    return 0
  fi
  INPUT_JSON="$payload" python3 - <<'PYEOF'
import json, os, re, sys

raw = os.environ.get("INPUT_JSON", "")
try:
    data = json.loads(raw)
except Exception:
    print("PARSE_FAIL"); sys.exit(0)
if not isinstance(data, dict):
    print("PARSE_FAIL"); sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
if not isinstance(tool_input, dict):
    print("PARSE_FAIL"); sys.exit(0)

# Gather the Owner-facing text blocks to inspect.
blocks = []
if tool_name == "AskUserQuestion":
    questions = tool_input.get("questions", [])
    if not isinstance(questions, list) or not questions:
        print("PARSE_FAIL"); sys.exit(0)
    for q in questions:
        if isinstance(q, dict):
            blocks.append(str(q.get("question", "") or "") + "\n" + str(q.get("header", "") or ""))
        else:
            blocks.append(str(q))
elif tool_name in ("Write", "Edit"):
    fp = str(tool_input.get("file_path", "") or "")
    if not fp.endswith("questions.md"):
        print("SKIP"); sys.exit(0)
    # Inspect only the newly-written content, not the whole file.
    content = tool_input.get("content")
    if content is None:
        content = tool_input.get("new_string", "")
    blocks.append(str(content or ""))
else:
    print("SKIP"); sys.exit(0)

# Only ENGAGE on Owner APPROVAL requests. A non-approval question is out of
# scope for this shape gate.
APPROVAL_RE = re.compile(r"\b(approve|approval|lock it|owner-lock|owner lock|sign[-\s]?off|ok to proceed|lock the)\b", re.I)

# A gated kind is one carrying schema/DDL/deploy/rbac evidence.
GATED_RE = re.compile(r"\b(schema|ddl|migration|table|column|index|registry|deploy|rbac|role|grant|permission)\b", re.I)
# A non-gated approval subject: an artifact type that should NOT be an Owner
# approval prompt when no gated evidence backs it.
NONGATED_SUBJECT_RE = re.compile(r"\b(contract|spec|proposal|design doc|plan)\b", re.I)

# Stable ID: #123, Q3, ABC-123, ticket 123, id: 123.
ID_RE = re.compile(r"(#\d{2,})|(\bQ\d+\b)|(\b[A-Z]{2,}-\d+\b)|(\bticket\s*#?\d+\b)|(\bid[:=]\s*\d+)", re.I)

# Any filename-with-extension token; used to enforce full-path.
FILE_TOKEN_RE = re.compile(r"(?<![\w./@-])([\w.@#-]+\.(?:md|sql|ts|tsx|js|json|ya?ml|py|sh|txt))\b")

def is_full_path(tok):
    # absolute path, repo@sha:path, or any token carrying a path separator
    if tok.startswith("/"):
        return True
    if "@" in tok and ":" in tok:
        return True
    if "/" in tok:
        return True
    return False

violations = []
engaged = False
for i, text in enumerate(blocks):
    if not APPROVAL_RE.search(text):
        continue  # not an approval request -> this gate does not apply to it
    engaged = True
    label = "block %d" % (i + 1)

    # (1) stable ID
    if not ID_RE.search(text):
        violations.append(
            "%s: Owner approval question lacks a stable number/ID "
            "(#<ticket>, Q<n>, or <PREFIX>-<n>). It cannot be closed on a "
            "surface or de-duped, so it will be re-asked." % label
        )

    # (2) full artifact path -- any filename token must be a full path
    for m in FILE_TOKEN_RE.finditer(text):
        tok = m.group(1)
        if not is_full_path(tok):
            violations.append(
                "%s: artifact '%s' is a bare filename -- use a full absolute "
                "path (/...) or repo@sha:path. A bare filename is unstampable." % (label, tok)
            )
            break

    # (3) gated type only -- reject an approval of a non-gated subject with no
    # gated evidence in the text.
    if NONGATED_SUBJECT_RE.search(text) and not GATED_RE.search(text):
        m = NONGATED_SUBJECT_RE.search(text)
        violations.append(
            "%s: this asks Owner to approve a non-gated type ('%s') with no "
            "schema/DDL/deploy/rbac evidence. Contracts/specs/DDL-less proposals "
            "route to the panel or AI machinery, not an Owner approval prompt "
            "(rules/owner-question-protocol.md type C)." % (label, m.group(1))
        )

if not engaged:
    print("SKIP"); sys.exit(0)

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
  INPUT="$(timeout 2 cat 2>/dev/null || true)"
else
  while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
fi
[ -z "$INPUT" ] && exit 0   # nothing to inspect -- fail open

RESULT="$(_classify "$INPUT")"
VERDICT="$(printf '%s\n' "$RESULT" | head -1)"
REASONS="$(printf '%s\n' "$RESULT" | tail -n +2)"

case "$VERDICT" in
  BLOCK)
    {
      echo "BLOCKED by the Owner-approval SHAPE gate (skills/approve +"
      echo "rules/owner-question-protocol.md): this Owner approval question is"
      echo "not in a durable, stampable shape and would drift / be re-asked."
      echo ""
      echo "Violations:"
      printf '%s\n' "$REASONS"
      echo ""
      echo "Required shape for an Owner APPROVAL question:"
      echo "  1. STABLE ID     -- carry a #<ticket>, Q<n>, or <PREFIX>-<n> the"
      echo "                      approval can be keyed on and closed by."
      echo "  2. FULL PATH     -- name every artifact by a full ABSOLUTE path"
      echo "                      (/...) or repo@sha:path, never a bare filename."
      echo "  3. GATED TYPE    -- only ask Owner to approve a gated kind"
      echo "                      (schema/deploy/rbac with DDL/migration/table/"
      echo "                      registry evidence). A contract, spec, or"
      echo "                      DDL-less proposal routes to the panel or AI"
      echo "                      machinery -- NOT an Owner approval prompt."
      echo ""
      echo "Once Owner locks it, stamp it EVERYWHERE with skills/approve so it is"
      echo "never re-asked:  approve --ticket <id> --artifact <full-path>"
      echo "  --kind <schema|deploy|rbac> --phrase \"<owner phrase>\" --evidence <path>"
    } >&2
    exit 2 ;;
  ALLOW|SKIP|PARSE_FAIL|"")
    exit 0 ;;
  *)
    exit 0 ;;  # unrecognized verdict -- fail open
esac
