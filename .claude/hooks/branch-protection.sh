#!/bin/bash
# JitNeuro Branch Protection Hook (PreToolUse on Bash)
# Blocks git push to protected branches + destructive git ops without explicit bypass.
#
# RED zone enforcement: push to a protected branch requires the owner's explicit
# permission. This hook enforces it programmatically so an agent can't accidentally
# push.
#
# HARDENED (#2676): the push detector parses the git SUBCOMMAND and its REFSPECS
# instead of substring-matching the branch name anywhere in the command. This closes
# the bypasses AND the false-positives of the old regex:
#   - HEAD:main and refs/heads/main refspecs are recognized as targeting main
#   - +refspec (e.g. +feature:main) is treated as a force push
#   - `git -c x=y push ...` global-option prefixes are handled
#   - `b=main; git push origin $b` simple variable indirection is resolved
#   - "main" appearing in a NON-push segment (e.g. `git push origin feat && gh pr
#     create --base main`) no longer false-blocks a legitimate feature push
#
# PR-STATE GUARD (#3788): a non-protected, non-force push to a branch whose most
# recent PR is already MERGED or CLOSED is also blocked. Origin: 2026-07-13 -- a
# fix was pushed to PR #677's branch 3 minutes after Owner manually merged it; the
# commit was stranded outside main's history and needed a recovery PR (#681). One
# `gh pr list` call per push, FAIL-OPEN on any error/timeout/missing-gh/no-PR-found
# (see check_pr_state below). The companion runtime-neutral guard for pushes made
# OUTSIDE Claude Code (Codex, a bare terminal) is tools/git-pr-state-guard.sh --
# duplicated rather than sourced here because this file is deployed standalone into
# ~/.claude/hooks/, with no guaranteed jit-knowledge clone alongside it at runtime.
#
# CWD-CORRECT BRANCH RESOLUTION (worktree false-block fix, 2026-08-01): when a
# push refspec carries no explicit destination branch (e.g. `git push origin`
# relying on an upstream tracking branch), the current-branch fallback MUST
# resolve HEAD in the directory the push will actually run from -- NOT in
# whatever directory this hook subprocess happens to start in. The hook
# subprocess's own cwd is the Claude Code SESSION's cwd (often the main clone,
# on `main`), which differs from a worktree branch's directory when a Bash
# command targets a worktree. Getting this wrong produced a real false-block:
# a legitimate worktree push was evaluated as if it were pushing whatever
# branch the session's own cwd happened to be on, matched that branch's old
# merged PR, and was refused. Claude Code's PreToolUse payload carries the
# session's authoritative "cwd" field (see session-end-lessons-flush.sh for
# the same extraction pattern) -- this hook now threads that cwd through to
# every git/gh call the fallback path makes (`git -C`, and a `cd` inside the
# gh subshell) instead of relying on ambient process cwd. Force-push and
# protected-branch detection are unaffected: those are driven entirely off
# the refspec/flag TEXT, never off cwd.

set +e  # never abort on errors

# Early exit: skip if not in a git repo (avoids unnecessary git calls)
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CONFIG="$(dirname "$SCRIPT_DIR")/knowledge.json"; [ -f "$CONFIG" ] || CONFIG="$(dirname "$SCRIPT_DIR")/jitneuro.json"
LOG="/tmp/jitneuro-branch-protection.log"

# Read protected branches from config (default: main, master)
PROTECTED="main|master"
ALLOWED_URLS=""
if [ -f "$CONFIG" ]; then
  ARRAY_CONTENT=$(grep -o '"protectedBranches"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$CONFIG" 2>/dev/null | grep -o '\[.*\]')
  BRANCHES=$(echo "$ARRAY_CONTENT" | grep -o '"[a-zA-Z0-9_-]*"' | tr -d '"' | tr '\n' '|' | sed 's/|$//')
  [ -n "$BRANCHES" ] && PROTECTED="$BRANCHES"
  ALLOWED_URLS=$(grep -o '"mainPushAllowed"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$CONFIG" 2>/dev/null | grep -o '"https://[^"]*"' | tr -d '"')
fi

# Check if current repo's remote is in the allowed list. Takes the actual
# push cwd (from the PreToolUse "cwd" field, or the --verdict test arg) so it
# reads the remote of the repo actually being pushed, not this hook
# subprocess's own ambient cwd.
is_repo_allowed() {
  local cwd_arg="${1:-}"
  [ -z "$ALLOWED_URLS" ] && return 1
  local REMOTE_URL
  if [ -n "$cwd_arg" ]; then
    REMOTE_URL=$(git -C "$cwd_arg" remote get-url origin 2>/dev/null)
  else
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
  fi
  [ -z "$REMOTE_URL" ] && return 1
  echo "$ALLOWED_URLS" | while IFS= read -r url; do
    [ "$url" = "$REMOTE_URL" ] && exit 0
  done
  return $?
}

# --- Push analysis -------------------------------------------------------------

# Resolve simple leading `name=value` assignments used later as $name / ${name}.
# Handles the `b=main; git push origin $b` indirection class.
resolve_vars() {
  local cmd="$1" work seg vname vval
  work="${cmd//&&/$'\n'}"; work="${work//||/$'\n'}"; work="${work//;/$'\n'}"
  while IFS= read -r seg; do
    seg="${seg#"${seg%%[![:space:]]*}"}"  # ltrim
    if [[ "$seg" =~ ^([A-Za-z_][A-Za-z0-9_]*)=([A-Za-z0-9_./:+-]+) ]]; then
      vname="${BASH_REMATCH[1]}"; vval="${BASH_REMATCH[2]}"
      cmd="${cmd//\$\{$vname\}/$vval}"
      cmd="${cmd//\$$vname/$vval}"
    fi
  done <<< "$work"
  printf '%s' "$cmd"
}

# Classify one command segment. Echoes: FORCE | PROTECTED | OK | OK:<dst-branch>
# OK (no colon) means "not a git push at all" -- git_push_verdict must NOT run a
# PR-state check for it. OK:<dst-branch> means "a real, non-force, non-protected
# push" -- <dst-branch> may be empty (no explicit refspec token; caller resolves
# the current branch) but a PR-state check IS warranted.
segment_verdict() {
  local seg="$1"
  local -a t
  set -f; IFS=' ' read -r -a t <<< "$seg"; set +f
  local n=${#t[@]} i=0
  while [[ $i -lt $n && "${t[$i]}" != "git" ]]; do ((i++)); done
  [[ $i -ge $n ]] && { echo OK; return; }
  ((i++))  # past 'git'
  # skip git global options (some take a following value)
  while [[ $i -lt $n ]]; do
    case "${t[$i]}" in
      -c|-C|--git-dir|--work-tree|--namespace|--super-prefix|--config-env) ((i+=2)); continue ;;
      --*=*|-*) ((i++)); continue ;;
      *) break ;;
    esac
  done
  [[ $i -ge $n ]] && { echo OK; return; }
  [[ "${t[$i]}" != "push" ]] && { echo OK; return; }
  ((i++))  # past 'push'
  local force=0 protected=0 tok refspec dst nonflag=0 branch_tok=""
  while [[ $i -lt $n ]]; do
    tok="${t[$i]}"; ((i++))
    case "$tok" in
      --force|-f|--force-with-lease|--force-with-lease=*|--force-if-includes) force=1; continue ;;
      -*) continue ;;
    esac
    nonflag=$((nonflag + 1))
    refspec="$tok"
    [[ "$refspec" == +* ]] && { force=1; refspec="${refspec#+}"; }
    if [[ "$refspec" == *:* ]]; then dst="${refspec#*:}"; else dst="$refspec"; fi
    dst="${dst#refs/heads/}"
    # First non-flag token is the remote name, not a destination branch --
    # only the SECOND-and-later non-flag token is a real refspec candidate.
    [[ $nonflag -ge 2 ]] && branch_tok="$dst"
    [[ -n "$dst" ]] && echo "$dst" | grep -qxE "($PROTECTED)" && protected=1
  done
  [[ $force -eq 1 ]] && { echo FORCE; return; }
  [[ $protected -eq 1 ]] && { echo PROTECTED; return; }
  echo "OK:$branch_tok"
}

# Resolve a merged/closed-PR guard for a destination branch (#3788). Echoes:
#   ALLOW                              -- no gh, no PR found, or any gh error/timeout
#   BLOCK:merged-pr:<branch>:<prnum>
#   BLOCK:closed-pr:<branch>:<prnum>
# FAIL OPEN by design: this only ever blocks on a CONFIRMED merged/closed PR for
# the exact branch being pushed -- never on ambiguity, missing gh, or a network
# hiccup. One `gh pr list` call, bounded by a short timeout when available.
check_pr_state() {
  local branch="$1" cwd_arg="${2:-}"
  [[ -z "$branch" ]] && { echo ALLOW; return; }
  command -v gh >/dev/null 2>&1 || { echo ALLOW; return; }

  local timeout_bin=""
  if command -v timeout >/dev/null 2>&1; then
    timeout_bin="timeout 3"
  elif command -v gtimeout >/dev/null 2>&1; then
    timeout_bin="gtimeout 3"
  fi

  # Run gh from the actual push cwd (not this hook subprocess's ambient cwd)
  # so it resolves the correct repo when a worktree cwd differs from the
  # session's own cwd. A failed `cd` fails the whole subshell -> rc != 0 ->
  # ALLOW (fail-open), same as any other gh error.
  local out rc
  out="$(
    if [[ -n "$cwd_arg" ]]; then cd "$cwd_arg" 2>/dev/null || exit 1; fi
    $timeout_bin gh pr list --head "$branch" --state all --json number,state,mergedAt --limit 1 \
      --jq '.[0] | if . == null then "" else ((.number|tostring) + "|" + .state) end' 2>/dev/null
  )"
  rc=$?
  [[ $rc -ne 0 ]] && { echo ALLOW; return; }
  [[ -z "$out" ]] && { echo ALLOW; return; }

  local num="${out%%|*}" state="${out##*|}"
  case "$state" in
    MERGED) echo "BLOCK:merged-pr:$branch:$num" ;;
    CLOSED) echo "BLOCK:closed-pr:$branch:$num" ;;
    *) echo ALLOW ;;
  esac
}

# Analyze a full command string. Echoes:
#   BLOCK:force | BLOCK:protected | BLOCK:merged-pr:<branch>:<num> |
#   BLOCK:closed-pr:<branch>:<num> | ALLOW
#
# cwd_arg is the ACTUAL directory the push will run from (Claude Code's
# PreToolUse "cwd" field in hook mode; an optional 3rd --verdict arg in test
# mode). Only used by the empty-refspec current-branch fallback and the
# repo-allowlist/PR-state gh lookups -- force/protected detection stays
# text-only and is unaffected.
git_push_verdict() {
  local cmd cwd_arg work seg v dst pv
  cmd="$(resolve_vars "$1")"
  cwd_arg="${2:-}"
  work="${cmd//&&/$'\n'}"; work="${work//||/$'\n'}"; work="${work//|/$'\n'}"; work="${work//;/$'\n'}"
  while IFS= read -r seg; do
    [[ -z "$seg" ]] && continue
    v="$(segment_verdict "$seg")"
    case "$v" in
      FORCE) echo "BLOCK:force"; return ;;
      PROTECTED) if is_repo_allowed "$cwd_arg"; then :; else echo "BLOCK:protected"; return; fi ;;
      OK:*)
        dst="${v#OK:}"
        if [[ -z "$dst" ]]; then
          if [[ -n "$cwd_arg" ]]; then
            dst="$(git -C "$cwd_arg" rev-parse --abbrev-ref HEAD 2>/dev/null)"
          else
            dst="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
          fi
        fi
        if [[ -n "$dst" ]]; then
          pv="$(check_pr_state "$dst" "$cwd_arg")"
          case "$pv" in
            BLOCK:*) echo "$pv"; return ;;
          esac
        fi
        ;;
    esac
  done <<< "$work"
  echo "ALLOW"
}

# --- Test mode: `branch-protection.sh --verdict '<command>' [<cwd>]` echoes the
# verdict. The optional 3rd arg simulates the PreToolUse "cwd" field so tests can
# exercise the worktree-vs-session-cwd branch-resolution path deterministically. ---
if [ "${1:-}" = "--verdict" ]; then
  git_push_verdict "${2:-}" "${3:-}"
  exit 0
fi

# --- Hook mode -----------------------------------------------------------------

# Read hook input with timeout
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do
    INPUT="${INPUT}${line}"
  done
fi

# Extract the command from tool input JSON (no python dependency)
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//')
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)/\1/p' 2>/dev/null | head -1 | sed 's/"[[:space:]]*,.*//' | sed 's/"[[:space:]]*}//')
fi

# Extract the session's authoritative cwd (top-level "cwd" field on the
# PreToolUse payload -- same extraction pattern as session-end-lessons-flush.sh).
# This is the directory the command will ACTUALLY run in; it is what the
# empty-refspec current-branch fallback and the gh lookups key off, instead of
# this hook subprocess's own ambient cwd (see CWD-CORRECT BRANCH RESOLUTION
# note at the top of this file).
CWD=$(echo "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//')

echo "[$(date 2>/dev/null)] PreToolUse fired. Command=${COMMAND:0:100} Cwd=${CWD:0:100}" >> "$LOG" 2>/dev/null

# If we still can't parse the command, analyze the raw input rather than allow-all
ANALYZE="$COMMAND"
[ -z "$ANALYZE" ] && ANALYZE="$INPUT"

VERDICT="$(git_push_verdict "$ANALYZE" "$CWD")"
case "$VERDICT" in
  BLOCK:force)
    echo "BLOCKED by JitNeuro branch protection: force push detected (incl +refspec)." >&2
    echo "Force push is destructive and requires the project owner's explicit permission." >&2
    exit 2 ;;
  BLOCK:protected)
    echo "BLOCKED by JitNeuro branch protection: git push to a protected branch is a RED zone action." >&2
    echo "Protected branches: $PROTECTED. This requires the project owner's explicit permission." >&2
    exit 2 ;;
  BLOCK:merged-pr:*|BLOCK:closed-pr:*)
    IFS=':' read -r _tag _kind _branch _prnum <<< "$VERDICT"
    _label="merged"; [ "$_kind" = "closed-pr" ] && _label="closed"
    echo "BLOCKED by JitNeuro branch protection: PR #$_prnum for branch '$_branch' is already $_label (ticket #3788)." >&2
    echo "Pushing new commits to it now would strand them outside the $_label PR's history." >&2
    echo "" >&2
    echo "Recovery path:" >&2
    echo "  1. git log --oneline -n 5                        # find the commit(s) to recover" >&2
    echo "  2. git checkout -b ${_branch}-recovery origin/main" >&2
    echo "  3. git cherry-pick <sha> [<sha>...]" >&2
    echo "  4. git push -u origin ${_branch}-recovery" >&2
    echo "  5. gh pr create --base main --head ${_branch}-recovery" >&2
    exit 2 ;;
esac

# Check for git branch -D (force delete branch) -- case-sensitive, -d (safe delete) is allowed
if echo "$ANALYZE" | grep -qE 'git\s+branch\s+-D\s' 2>/dev/null; then
  echo "BLOCKED by JitNeuro branch protection: force branch delete detected." >&2
  echo "This is destructive and requires the project owner's explicit permission." >&2
  exit 2
fi

# Check for git reset --hard
if echo "$ANALYZE" | grep -qiE 'git\s+reset\s+--hard' 2>/dev/null; then
  echo "BLOCKED by JitNeuro branch protection: git reset --hard detected." >&2
  echo "This discards uncommitted work. Requires the project owner's explicit permission." >&2
  exit 2
fi

# Check for git rebase onto a protected branch (rewrites history on protected branch)
if echo "$ANALYZE" | grep -qiE "git\s+rebase\s+.*($PROTECTED)" 2>/dev/null; then
  echo "BLOCKED by JitNeuro branch protection: rebase onto protected branch detected." >&2
  echo "Protected branches: $PROTECTED. Requires the project owner's explicit permission." >&2
  exit 2
fi

exit 0
