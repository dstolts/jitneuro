#!/usr/bin/env bash
# jit-knowledge-pre-compact.sh
#
# Fires on Claude Code's PreCompact event (BEFORE context compaction).
# Prints a directive into Claude's context so the post-compact Claude
# (which inherits the compacted summary + any text emitted here) sees a
# clear instruction to invoke /knowledge as its first action.
#
# /knowledge re-anchors the session by:
#   - Re-reading the full bootstrap chain (AGENTS.md, jit-knowledge,
#     binding rules, repo-local context including .HUB/Hub.md)
#   - Printing the Mandatory Session Preflight block
#   - Printing the "How I'm acting" status report
#   - Step 6: Refreshing TodoWrite from Hub.md + .sessions/<name>.md
#   - Step 7: Auto-resuming the next executable task
#
# Together, those mean compaction does not lose session continuity --
# the next response after compact picks up the queue from durable state.
#
# Hook output convention: plain text echoed to stdout is injected into
# Claude's context window post-compact.

cat <<'EOF'

=== POST-COMPACT BOOTSTRAP DIRECTIVE (jit-knowledge PreCompact hook) ===

Your context was just compacted. The in-conversation TodoWrite task list
was lost in the compact, but the durable state (Hub.md + .sessions/)
is intact.

REQUIRED FIRST ACTION post-compact: invoke /knowledge

/knowledge will:
  - Re-read the bootstrap chain (workspace AGENTS.md, jit-knowledge,
    binding rules, active repo context, .HUB/Hub.md, todo/backlog.md)
  - Print the Mandatory Session Preflight block
  - Print the "How I'm acting" status report
  - Step 6: Rebuild TodoWrite from Hub.md + .sessions/<name>.md
  - Step 7: Auto-resume the next executable task (per pre-compact queue)

Do this BEFORE responding to any user prompt or making any tool call.
The user has already authorized this pattern; do not ask for confirmation.

After /knowledge completes, continue per Owner's directive at the time
of compaction (recorded in the active sessions checkpoint at
~/Code/.sessions/<name>.md).

=== END POST-COMPACT DIRECTIVE ===

EOF
exit 0
