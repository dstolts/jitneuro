#!/usr/bin/env bash
# Emits the latest machine-wide knowledge upgrade receipt into an active
# session.  It is deliberately local-first: a bad/missing HubCentral token
# must never prevent a knowledge upgrade notice from reaching an agent.
set -u
STATE_DIR="${JIT_KNOWLEDGE_SYNC_STATE_DIR:-$HOME/.sessions/knowledge-sync}"
NOTICE="$STATE_DIR/notice.json"
[ -f "$NOTICE" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
python3 - "$NOTICE" <<'PY' 2>/dev/null
import json, sys
try:
    n = json.load(open(sys.argv[1]))
    status = n.get("status", "unknown")
    c = n.get("consumers", {})
    print("[knowledge-sync] %s: commit=%s consumers=%s/%s. %s" % (
        status, n.get("knowledgeCommit", "unknown")[:12], c.get("ready", 0),
        c.get("total", 0), n.get("action", "inspect knowledge-sync state")))
except Exception:
    pass
PY
