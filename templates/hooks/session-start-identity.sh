#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright 2025-2026 Just In Time AI INC
# JitNeuro SessionStart -- Master-Orchestrator Identity Anchor
# Fires on every SessionStart. Injects the binding identity rule into Claude's
# context window so the session acts as a MASTER AGENT / ORCHESTRATOR by default
# rather than a generic coding agent.
#
# Why a hook (not just CLAUDE.md): an advisory identity rule in CLAUDE.md is not
# reliably honored at session start. A mechanical SessionStart hook guarantees
# the identity reaches the context window before any substantive work.
#
# If an installed identity rule exists (rules/interactive-master-orchestrator.md)
# it is injected verbatim; otherwise a generic anchor is printed.

set +e  # never abort on errors

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
RULES_DIR="$CLAUDE_DIR/rules"
IDENTITY_RULE="$RULES_DIR/interactive-master-orchestrator.md"

# Drain stdin with a timeout so the hook never hangs if the pipe stays open.
INPUT=""
if command -v timeout >/dev/null 2>&1; then
  INPUT=$(timeout 2 cat 2>/dev/null || true)
else
  while IFS= read -r -t 2 line; do INPUT="${INPUT}${line}"; done
fi

echo "** JitNeuro loaded -- master-orchestrator identity active **"

if [ -f "$IDENTITY_RULE" ]; then
  echo "--- BINDING SESSION IDENTITY (jitneuro SessionStart hook) ---"
  cat "$IDENTITY_RULE" 2>/dev/null
  echo "--- END SESSION IDENTITY ---"
else
  cat <<'IDENTITY'
You are the MASTER AGENT and ORCHESTRATOR for this interactive session by default.
- Coordinate and delegate work to subagents; keep your own context thin.
- Specialist roles (reviewer, coder, researcher) are temporary hats, not your identity.
- Before substantive work, read this repo's CLAUDE.md, MEMORY.md, and .claude/rules/.
- Answering a question is NOT approval -- get explicit approval before changing code.
- Keep durable state in .HUB/Hub.md so work survives a context reset.
IDENTITY
fi

exit 0
