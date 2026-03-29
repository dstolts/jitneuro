#!/bin/bash
# JitNeuro SessionStart Hook: Post-Install Onboard Prompt
# Detects .needs-onboard marker left by install script.
# Injects a prompt into Claude's context to offer /onboard --all.
# Marker is deleted after Claude processes the prompt (by /onboard --all).
#
# stdout goes into Claude's context window as injected context.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
MARKER="$CLAUDE_DIR/.needs-onboard"

# Exit silently if no marker
[ ! -f "$MARKER" ] && exit 0

# Read marker content
INSTALLED=$(grep "^installed=" "$MARKER" 2>/dev/null | cut -d= -f2)
WORKSPACE=$(grep "^workspace=" "$MARKER" 2>/dev/null | cut -d= -f2)

cat <<EOF
[JitNeuro] Fresh install detected (installed: ${INSTALLED}).

JitNeuro was just installed in workspace mode. To build your project index
and create engrams for all repos, Claude can scan the workspace now.

RECOMMENDED ACTION: Ask the user:
"JitNeuro was just installed. Want me to scan and onboard all repos in ${WORKSPACE}?
This will populate your project index (MEMORY.md) and create context files (engrams)
for each repo. Takes about 2 minutes for 20 repos. (yes/no)"

If the user says yes: run /onboard --all
After /onboard --all completes (or user declines): delete the marker file at ${MARKER}
EOF

exit 0
