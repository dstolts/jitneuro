#!/usr/bin/env bash
# lane-resolve.sh -- resolve the STABLE HubCentral lane for a working directory.
#
# DESIGN (per Owner 2026-07-05): a lane must be a STABLE identity, never a
# moving target. Therefore lane is derived from the REPO identity, and:
#   - NEVER the git branch (branches change with every ticket)
#   - NEVER the worktree path (worktrees are created/removed per task)
# A git worktree is resolved back to its MAIN repository before mapping.
#
# Resolution order for the raw repo id:
#   1. `origin` remote basename        (branch/worktree independent, most stable)
#   2. MAIN worktree dir basename       (via --git-common-dir; resolves worktrees)
#   3. plain directory basename         (non-git dirs)
#
# The raw repo id is then lowercased, normalized through the canonical repo
# alias registry, and only then passed through a lane map:
#   1. canonical repo aliases (authorization identity; not session/focus data)
#   2. external override file  ($LANE_MAP, else ~/Code/.claude/lane-map.tsv)
#   3. embedded defaults below
#   4. fallback: lane == repo id
#
# UMBRELLA vs INDIVIDUAL lanes: to roll several repos into one umbrella lane
# (e.g. AIFS covering app+api+auth), point them all at the same lane id in the
# override file. To split them, give each its own lane id. Default here is an
# individual, per-repo lane -- predictable and stable.
#
# Usage:  lane-resolve.sh [dir]        # prints the resolved lane id, or nothing
set -euo pipefail

DIR="${1:-$PWD}"

# --- 1. raw repo id (stable; branch/worktree independent) ------------------
repo=""
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  url="$(git -C "$DIR" remote get-url origin 2>/dev/null || true)"
  if [ -n "$url" ]; then
    repo="${url##*/}"        # strip path
    repo="${repo%.git}"      # strip .git
  else
    # No remote: resolve worktree -> MAIN repo dir via the common git dir.
    common="$(git -C "$DIR" rev-parse --git-common-dir 2>/dev/null || true)"
    if [ -n "$common" ]; then
      case "$common" in
        /*) maindir="$(dirname "$common")" ;;
        *)  maindir="$(cd "$DIR" && cd "$(dirname "$common")" 2>/dev/null && pwd || echo "$DIR")" ;;
      esac
      repo="$(basename "$maindir")"
    fi
  fi
fi
[ -n "$repo" ] || repo="$(basename "$DIR")"

# lowercase
repo="$(printf '%s' "$repo" | tr '[:upper:]' '[:lower:]')"

# --- 2. canonical repo identity (must precede lane/session presentation) ----
# HubCentral authorization is scoped to canonical repository identity. Legacy
# lane labels and human-friendly aliases are accepted as inputs, but must never
# be forwarded as the authorization identity.
canonical_repo_id() {
  case "$1" in
    aifs-app|aifieldsupport-app) printf '%s\n' "aifieldsupport-app" ;;
    aifs-api|aifieldsupport-api) printf '%s\n' "aifieldsupport-api" ;;
    aifs-auth|aifieldsupport-auth) printf '%s\n' "aifieldsupport-auth" ;;
    *) printf '%s\n' "$1" ;;
  esac
}
repo="$(canonical_repo_id "$repo")"

# --- 3. external override map (user-editable, not clobbered by installer) ---
lane=""
MAP="${LANE_MAP:-$HOME/Code/.claude/lane-map.tsv}"
if [ -f "$MAP" ]; then
  # first whitespace-separated field == repo, second == lane; '#' comments ignored
  # NB: under `set -euo pipefail`, an unmapped repo makes the first grep exit 1;
  # pipefail would propagate that and set -e would abort the script here, before
  # the embedded-defaults fallback below. `|| true` keeps a no-match benign so an
  # unmapped repo falls through to the `*) lane=$repo` default instead of exiting 1.
  lane="$(grep -iE "^[[:space:]]*${repo}[[:space:]]" "$MAP" 2>/dev/null \
          | grep -vE '^[[:space:]]*#' | head -1 | awk '{print $2}' || true)"
fi

# Existing operator maps may still emit a legacy alias. Normalize map output
# too, so a preserved pre-upgrade map cannot reintroduce a non-canonical auth
# identity. Intentional umbrella ids such as `aifs` remain unchanged.
[ -z "$lane" ] || lane="$(canonical_repo_id "$(printf '%s' "$lane" | tr '[:upper:]' '[:lower:]')")"

# --- 4. embedded defaults (canonical authorization identities) -------------
if [ -z "$lane" ]; then
  case "$repo" in
    aifieldsupport-api)  lane="aifieldsupport-api" ;;
    aifieldsupport-app)  lane="aifieldsupport-app" ;;
    aifieldsupport-auth) lane="aifieldsupport-auth" ;;
    jit-knowledge)       lane="jit-knowledge" ;;
    hubcentral)          lane="jit-knowledge" ;;
    *)                   lane="$repo" ;;   # fallback: lane == repo id
  esac
fi

printf '%s\n' "$lane"
