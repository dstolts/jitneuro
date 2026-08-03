#!/bin/bash
# jk-bash-secret-scan -- PreToolUse gate on Bash: scans the literal command
# argv for secret-shaped values before the command executes. Ticket #4617.
#
# WHAT IT DOES
# Runtime counterpart to the CI-side scripts/lint-cli-secret-safety.sh
# (rules/cli-secret-safety.md). The CI lint diff-scopes COMMITTED source for
# the anti-pattern of a secret VARIABLE bound to a CLI flag (`--token $VAR`)
# -- it can never see a resolved literal value, because committed code never
# contains one. This hook is the opposite case: it inspects the actual Bash
# command an agent is about to RUN, where a resolved secret literal (not a
# variable reference) can appear directly in argv -- e.g. a copy-pasted
# `curl -H "Authorization: Bearer sk-live-abc123..."`. That literal would
# never surface in a source diff, only at the moment a live shell command is
# about to execute it -- this hook is the only place that scan is possible.
#
# DETECTION (two independent checks, either one flags a hit):
#   1. KNOWN-PREFIX -- a vendor-recognizable secret token shape appears
#      anywhere in the command (AWS AKIA..., GitHub ghp_/gho_/ghu_/ghs_/ghr_,
#      Slack xox[baprs]-, Stripe sk_live_/sk_test_/rk_live_, OpenAI sk-...,
#      Anthropic sk-ant-..., Google AIza..., a 3-segment JWT eyJ...).
#   2. FLAG+HIGH-ENTROPY -- a `--password|--token|--api-key|--secret|
#      --client-secret|--auth-token`-shaped flag (or `KEY=VALUE` assignment
#      named like one) is bound to a LITERAL value (not a `$VAR`/`${VAR}`
#      reference -- see cli-secret-safety.md's "OK: use $VAR inline" case,
#      which this hook must NOT flag) that is high-entropy: length >= 16 and
#      at least 3 of {lowercase, uppercase, digit, symbol} character classes.
#      A small placeholder denylist (changeme, your_, <..>, example, dummy,
#      placeholder, xxxx, todo) suppresses the obvious non-secret cases.
#
# Event: PreToolUse, matcher: "Bash"
# Exit contract (rules/claude-code-hook-deployment.md):
#   0 = allow (no hit, non-Bash tool, or any parse failure -- FAIL-OPEN)
#   1 = WARN mode hit -- non-blocking warning banner, command still runs
#   2 = BLOCK mode hit -- command is blocked, stderr fed back to the model
#
# Config: JIT_BASH_SECRET_SCAN_MODE env var -- "warn" (default), "block", or
# "off". Matches the config-env-var pattern other hooks in this directory use
# (e.g. DOE_HEADLESS bypass in owner-question-gate.sh) rather than inventing
# a new config file.
#
# Canonical source: jit-knowledge/templates/claude-hooks/bash-secret-scan.sh
# Install via: bash scripts/install.sh
#
# Test mode: `bash-secret-scan.sh --verdict '<command>'` prints the verdict
# (ALLOW / HIT:<reason>) without exit-2/exit-1 side effects, for unit testing
# (see templates/claude-hooks/tests/bash-secret-scan.test.sh).

set +e  # FAIL-OPEN -- a crash in this hook must never block a session

# ---------- known vendor secret-token shapes ----------
KNOWN_PREFIX_RE='AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|xox[baprs]-[0-9A-Za-z-]{10,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{20,}|sk_live_[0-9a-zA-Z]{10,}|sk_test_[0-9a-zA-Z]{10,}|rk_live_[0-9a-zA-Z]{10,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'

# ---------- secret-named flags/vars (same vocabulary as cli-secret-safety.md) ----------
SECRET_NAME_RE='(password|passwd|token|api[_-]?key|secret|client[_-]?secret|auth[_-]?token|credential)'

# Placeholder/example values that look secret-shaped but are not. Checked
# case-insensitively against the candidate value.
PLACEHOLDER_RE='changeme|your[_-]|<[^>]*>|example|dummy|placeholder|xxxx|todo|redacted|00000000'

_check_known_prefix() {
  echo "$1" | grep -Eq "$KNOWN_PREFIX_RE"
}

# Character-class-diversity entropy proxy: length >= 16 and >= 3 of
# {lower, upper, digit, symbol} classes present. Deliberately simple (no
# Shannon-entropy math) so it stays bash-3.2/macOS-safe with no dependency.
_is_high_entropy() {
  local v="$1" classes=0
  [ ${#v} -lt 16 ] && return 1
  echo "$v" | grep -Eq "$PLACEHOLDER_RE" 2>/dev/null && return 1
  [[ "$v" =~ [a-z] ]] && classes=$((classes + 1))
  [[ "$v" =~ [A-Z] ]] && classes=$((classes + 1))
  [[ "$v" =~ [0-9] ]] && classes=$((classes + 1))
  [[ "$v" =~ [^a-zA-Z0-9] ]] && classes=$((classes + 1))
  [ "$classes" -ge 3 ]
}

# Scans for `--flag VALUE`, `--flag=VALUE`, `-f VALUE`, and `NAME=VALUE`
# shapes where the flag/var name matches SECRET_NAME_RE and VALUE is a
# literal (not a $VAR/${VAR} reference) high-entropy string.
_check_flag_secret() {
  local cmd="$1"
  local -a tokens
  set -f; IFS=' ' read -r -a tokens <<< "$cmd"; set +f
  local n=${#tokens[@]} i=0 tok next name val
  while [ $i -lt $n ]; do
    tok="${tokens[$i]}"
    # --flag=value or NAME=value
    if [[ "$tok" == *=* ]]; then
      name="${tok%%=*}"
      val="${tok#*=}"
      name="${name#--}"
      if echo "$name" | grep -Eqi "$SECRET_NAME_RE"; then
        val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
        if [[ "$val" != \$* ]] && _is_high_entropy "$val"; then
          echo "flag-secret:$name"
          return 0
        fi
      fi
    fi
    # --flag VALUE / -f VALUE (space-separated)
    if [[ "$tok" == --* || "$tok" == -* ]]; then
      name="${tok#--}"; name="${name#-}"
      if echo "$name" | grep -Eqi "^${SECRET_NAME_RE}$"; then
        next="${tokens[$((i+1))]:-}"
        val="${next%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
        if [[ -n "$val" && "$val" != \$* && "$val" != --* ]] && _is_high_entropy "$val"; then
          echo "flag-secret:$name"
          return 0
        fi
      fi
    fi
    i=$((i + 1))
  done
  return 1
}

# Analyze a full command string. Echoes: HIT:known-prefix | HIT:<flag-secret:name> | ALLOW
scan_verdict() {
  local cmd="$1" hit
  if _check_known_prefix "$cmd"; then
    echo "HIT:known-prefix"
    return
  fi
  hit="$(_check_flag_secret "$cmd")"
  if [ -n "$hit" ]; then
    echo "HIT:$hit"
    return
  fi
  echo "ALLOW"
}

# --- Test mode: `bash-secret-scan.sh --verdict '<command>'` echoes the verdict ---
if [ "${1:-}" = "--verdict" ]; then
  scan_verdict "${2:-}"
  exit 0
fi

# ---------- config ----------
MODE="${JIT_BASH_SECRET_SCAN_MODE:-warn}"
if [ "$MODE" = "off" ]; then
  exit 0
fi

# ---------- hook mode: read tool input JSON from stdin ----------
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

# Prefer a real JSON parse (handles escaped/embedded quotes inside the
# command, which the plain-command case below cannot) and fall back to the
# grep/sed heuristic used by branch-protection.sh when python3 is unavailable.
COMMAND=""
if command -v python3 >/dev/null 2>&1; then
  COMMAND=$(INPUT_JSON="$INPUT" python3 - <<'PYEOF' 2>/dev/null
import json, os
try:
    data = json.loads(os.environ.get("INPUT_JSON", ""))
    print(data.get("tool_input", {}).get("command", ""), end="")
except Exception:
    pass
PYEOF
)
fi
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//')
fi
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)/\1/p' 2>/dev/null | head -1 | sed 's/"[[:space:]]*,.*//' | sed 's/"[[:space:]]*}//')
fi

# If the command could not be parsed, fail open rather than analyze raw JSON
# (which would produce noisy/incorrect matches against JSON syntax itself).
[ -z "$COMMAND" ] && exit 0

VERDICT="$(scan_verdict "$COMMAND")"
case "$VERDICT" in
  HIT:*)
    REASON="${VERDICT#HIT:}"
    MSG="Bash argv secret scan: this command looks like it embeds a secret-shaped literal ($REASON, rules/cli-secret-safety.md). Use stdin / heredoc / a file-ref instead of a literal CLI argument."
    if [ "$MODE" = "block" ]; then
      echo "BLOCKED by jk-bash-secret-scan: $MSG" >&2
      exit 2
    else
      echo "WARNING (jk-bash-secret-scan): $MSG" >&2
      exit 1
    fi
    ;;
esac

exit 0
