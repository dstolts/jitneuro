#!/usr/bin/env bash
# session-start-lane-register.sh -- on session load, register this agent's
# STABLE lane + current FOCUS in HubCentral so other agents and the Owner can
# find the right lane to talk to.
#
# Delegates to lane-heartbeat.sh --force (bypasses the throttle) so registration
# is immediate on load. See lane-heartbeat.sh / lane-resolve.sh for the model:
#   LANE  = stable repo identity (NOT branch, NOT worktree) -> addressing
#   FOCUS = "<lane> @ <branch> [- note]" (dynamic) -> what it's working on now
# Presence auto-expires server-side after ~1h without a heartbeat, so a crashed
# agent disappears on its own.
#
# Fail-safe: never blocks session start.
#
# Headless DOE bypass (ticket #3160): lane-heartbeat.sh --force POSTs
# status="alive" with lane+focus, i.e. it registers THIS session as an active
# interactive lane presence. A headless `claude -p` DOE tick (doe-tick.sh)
# fires frequently and briefly -- registering each tick would pollute the
# lane registry with phantom "interactive" presences that aren't a session
# anyone can talk to. Skip registration when DOE_HEADLESS=1.
if [ "${DOE_HEADLESS:-}" = "1" ]; then
  exit 0
fi

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SELF_DIR/lane-heartbeat.sh" --force >/dev/null 2>&1 || true
exit 0
