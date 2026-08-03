#!/usr/bin/env bash
# Run the exact-commit SQL-derived Knowledge routing bootstrap at Claude
# SessionStart. The command is fail-open by contract: unavailable, stale, or
# degraded routes record a per-boot fallback and leave Git files authoritative.
set -u

resolve_knowledge_root() {
  local root="${JIT_KNOWLEDGE_ROOT:-}"
  if [ -z "$root" ] && [ -f "$HOME/.claude/workspace.json" ]; then
    root="$(grep -o '"jit_knowledge_root"[[:space:]]*:[[:space:]]*"[^"]*"' \
      "$HOME/.claude/workspace.json" 2>/dev/null | head -1 \
      | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')"
  fi
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    for candidate in "$HOME/Code/jit-knowledge" "C:/Users/$USER/Code/jit-knowledge"; do
      [ -d "$candidate" ] && { root="$candidate"; break; }
    done
  fi
  printf '%s' "$root"
}

ROOT="$(resolve_knowledge_root)"
if [ -z "$ROOT" ] || [ ! -x "$ROOT/scripts/knowledge-reboot-handoff.sh" ]; then
  echo "SQL BOOTSTRAP: KnowledgeRoot unavailable; using repo-local/Git files."
  exit 0
fi

bash "$ROOT/scripts/knowledge-reboot-handoff.sh" sql-bootstrap --root "$ROOT" \
  || echo "SQL BOOTSTRAP: bootstrap helper failed; using exact local Git files."
exit 0
