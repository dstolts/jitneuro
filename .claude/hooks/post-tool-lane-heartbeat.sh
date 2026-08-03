#!/usr/bin/env bash
# post-tool-lane-heartbeat.sh -- PostToolUse hook. Sends a THROTTLED lane
# heartbeat (<= once / 10min) so an actively-working lane's presence + focus
# stay fresh. Silent/mechanical -- no conversation noise.
#
# This is the BONUS keep-alive for active work. The PRIMARY time-based
# keep-alive for paused/idle agents is the scheduled poll (intercom-agent-poll),
# which force-heartbeats on a ~20min timer regardless of tool use.
#
# Fail-safe: exits 0 always; runs the send in the background so it never adds
# latency to a tool call.
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SELF_DIR/lane-heartbeat.sh" >/dev/null 2>&1 &
exit 0
