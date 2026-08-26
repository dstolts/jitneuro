#!/bin/bash
# cd-lane-guard.sh -- PreToolUse(Bash) guard.
#
# Owner directive 2026-08-01 (Knowledge session). Strictness A:
#   BLOCK a persistent top-level `cd` whose ABSOLUTE (or ~) target resolves to a
#   DIFFERENT stable lane than THIS session's lane -- the "wrong-lane write"
#   failure mode (trust-zones RED: cross-lane write).
#
#   ALLOW everything else, specifically:
#     * git -C <abs> ...                 (no top-level cd; CWD-safe)
#     * ( cd <abs> && <cmd> )            (subshell; auto-reverts)
#     * cd <relative>  (e.g. cd server)  (v1: assumed in-repo)
#     * cd into the SAME lane (subdirs, same-repo worktrees)
#     * Read/Grep/Glob                   (need no cd at all)
#
# FAIL-OPEN on ANY ambiguity (missing python3, parse failure, unresolved lane,
# empty input, non-Bash tool). It only ever blocks when it POSITIVELY resolves
# two DIFFERENT lanes. A hook bug must never wedge a session or a DOE runner.
#
# Reuses the canonical resolvers already installed alongside it:
#   lane-resolve.sh          (dir  -> stable repo/lane id; worktree-aware)
#   session-lane-resolve.sh  (sourced; resolve_session_lane -> session lane)
#
# Test seam: export CD_LANE_GUARD_CURRENT_LANE to force the "current lane"
# deterministically (used by cd-lane-guard.test.sh).
set +e

HOOKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- read the tool-call JSON from stdin (2s cap) --------------------------
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  INPUT=$(cat 2>/dev/null || true)
fi
[ -z "$INPUT" ] && exit 0                 # nothing to inspect -> allow

command -v python3 >/dev/null 2>&1 || exit 0   # no parser -> allow

# ---- pull the Bash command string (skip any other tool) -------------------
CMD=$(INPUT_JSON="$INPUT" python3 - <<'PY'
import json, os, sys
try:
    d = json.loads(os.environ.get("INPUT_JSON", "") or "{}")
except Exception:
    sys.exit(0)
if d.get("tool_name") != "Bash":
    print("__SKIP__"); sys.exit(0)
ti = d.get("tool_input") or {}
if not isinstance(ti, dict):
    print("__SKIP__"); sys.exit(0)
print(ti.get("command", "") or "__SKIP__")
PY
)
[ "$CMD" = "__SKIP__" ] && exit 0
[ -z "$CMD" ] && exit 0

# ---- extract top-level, absolute/~ cd targets -----------------------------
# Subshell groups ( ... ) are stripped first, so `( cd X && .. )` is exempt.
# `git -C <path>` never matches (only a literal leading `cd` does).
TARGETS=$(CMD="$CMD" python3 - <<'PY'
import os, re
cmd = os.environ.get("CMD", "")

# remove parenthesised subshell groups (CWD-safe) via paren-depth
buf, depth = [], 0
for ch in cmd:
    if ch == '(':
        depth += 1
    elif ch == ')':
        depth = max(0, depth - 1)
    elif depth == 0:
        buf.append(ch)
top = ''.join(buf)

targets = []
for seg in re.split(r'(?:&&|\|\||;|\n|\|)', top):
    seg = seg.strip()
    m = re.match(r'^cd\s+(?:-[^\s]+\s+)*(.+)$', seg)   # allow flags like `cd -P`
    if not m:
        continue
    parts = m.group(1).split()
    if not parts:
        continue
    tok = parts[0].strip('"').strip("'")
    # v1 scope: only absolute or ~ targets (relative cd is assumed in-repo)
    if tok.startswith('/') or tok.startswith('~'):
        targets.append(tok)

for t in targets:
    print(t)
PY
)
[ -z "$TARGETS" ] && exit 0                # no absolute top-level cd -> allow

# ---- current session lane (identity-first; path only as fallback) ---------
CUR="${CD_LANE_GUARD_CURRENT_LANE:-}"
if [ -z "$CUR" ] && [ -f "$HOOKDIR/session-lane-resolve.sh" ]; then
  CUR=$(bash -c '. "$1" 2>/dev/null; resolve_session_lane "" 2>/dev/null' _ "$HOOKDIR/session-lane-resolve.sh" 2>/dev/null)
fi
[ -z "$CUR" ] && CUR=$(bash "$HOOKDIR/lane-resolve.sh" "$PWD" 2>/dev/null)
[ -z "$CUR" ] && exit 0                    # cannot resolve current lane -> allow

# ---- ALLOWED lane set (multi-lane masters) --------------------------------
# A single master may legitimately span several lanes (e.g. the Knowledge
# master covers jit-knowledge + HubCentral). ALLOWED starts as {CUR} and is
# widened by:
#   1. env CD_LANE_GUARD_ALLOWED_LANES  (space/comma list; overrides everything)
#   2. every group row in the group file that CONTAINS CUR -- all its lanes.
# Group file (user-editable, not installer-managed):
#   $CD_LANE_GROUPS_FILE  else  ~/Code/.claude/cd-lane-groups.tsv
# Format per line:  <group-name>\t<lane1> <lane2> ...   ('#' = comment)
ALLOWED=" ${CUR} "
if [ -n "${CD_LANE_GUARD_ALLOWED_LANES:-}" ]; then
  ALLOWED=" $(printf '%s' "$CD_LANE_GUARD_ALLOWED_LANES" | tr ',' ' ') "
else
  GROUPS_FILE="${CD_LANE_GROUPS_FILE:-$HOME/Code/.claude/cd-lane-groups.tsv}"
  if [ -f "$GROUPS_FILE" ]; then
    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue ;; esac
      lanes=$(printf '%s' "$line" | sed 's/^[^[:space:]]*[[:space:]]*//')  # drop group name
      case " $lanes " in
        *" $CUR "*) ALLOWED="${ALLOWED}${lanes} " ;;
      esac
    done < "$GROUPS_FILE"
  fi
fi

# ---- compare each target's lane; block if outside the ALLOWED set ---------
while IFS= read -r t; do
  [ -z "$t" ] && continue
  case "$t" in "~"*) t="${HOME}${t#\~}" ;; esac
  TL=$(bash "$HOOKDIR/lane-resolve.sh" "$t" 2>/dev/null)
  [ -z "$TL" ] && continue                 # target lane unresolved -> allow this one
  if [ -n "$TL" ] && [ "${ALLOWED#*" $TL "}" = "$ALLOWED" ]; then
    {
      echo "cross-lane cd BLOCKED (cd-lane-guard, strictness A)."
      echo "Session lane: ${CUR}   allowed:${ALLOWED}"
      echo "Target lane:  ${TL}   (path: ${t})  -- NOT in the allowed set."
      echo ""
      echo "This is the wrong-lane-write failure mode. Use a CWD-safe form:"
      echo "  * git:       git -C \"${t}\" <subcommand>"
      echo "  * run cmd:   ( cd \"${t}\" && <cmd> )     # subshell, auto-reverts"
      echo "  * read/find: Read/Grep/Glob take absolute paths -- no cd needed"
      echo ""
      echo "If this master legitimately spans both lanes, add them to one group in"
      echo "  ~/Code/.claude/cd-lane-groups.tsv   (e.g.:  knowledge<TAB>${CUR} ${TL})"
      echo "A genuine cross-lane WRITE needs an intercom handoff to the owning"
      echo "lane or explicit Owner lane-switch approval first (trust-zones RED)."
    } >&2
    exit 2
  fi
done <<EOF
$TARGETS
EOF

exit 0
