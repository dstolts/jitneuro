#!/usr/bin/env bash
# Submit a non-canonical knowledge draft to the shared transport folder.
# The scanner, not this command, decides canonical placement and writes a DB task.
set -euo pipefail

ROOT="${KNOWLEDGE_WIP_ROOT:-/Volumes/Code/knowledge-wip}"
OUTBOX="${KNOWLEDGE_WIP_OUTBOX:-$HOME/.claude/knowledge-wip/outbox}"
LANE=""
TITLE=""
READ_WHEN=""
FILE=""
FLUSH=0

usage() {
  echo "Usage: knowledge-wip-submit.sh --file DRAFT.md --lane <lane> --title <title> --read-when <trigger> | --flush"
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --lane) LANE="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --read-when) READ_WHEN="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    --outbox) OUTBOX="$2"; shift 2 ;;
    --flush) FLUSH=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done
flush_outbox() {
  [ -d "$OUTBOX" ] || { echo "outbox empty"; return 0; }
  [ -d "$ROOT/incoming" ] || { echo "share unavailable; outbox retained=$OUTBOX"; return 0; }
  count=0
  for packet in "$OUTBOX"/*; do
    [ -d "$packet" ] || continue
    name="$(basename "$packet")"
    if [ -e "$ROOT/incoming/$name" ]; then
      echo "outbox duplicate retained=$name" >&2
      continue
    fi
    mv "$packet" "$ROOT/incoming/$name"
    count=$((count + 1))
  done
  echo "outbox flushed=$count retained=$OUTBOX"
}
[ "$FLUSH" -eq 0 ] || { flush_outbox; exit 0; }
[ -f "$FILE" ] || { echo "--file must name a readable draft" >&2; exit 2; }
[ -n "$LANE" ] && [ -n "$TITLE" ] && [ -n "$READ_WHEN" ] || { usage >&2; exit 2; }

packet="$(date -u +%Y%m%dT%H%M%SZ)-${LANE}-$$"
destination="$ROOT/incoming"
deferred=0
if [ ! -d "$destination" ]; then
  destination="$OUTBOX"
  deferred=1
fi
mkdir -p "$destination"
tmp="$destination/.${packet}.partial"
final="$destination/$packet"
mkdir "$tmp"
trap 'rm -rf "$tmp"' EXIT
cp "$FILE" "$tmp/draft.md"
sha="$(shasum -a 256 "$tmp/draft.md" | awk '{print $1}')"
python3 - "$tmp/manifest.json" "$packet" "$LANE" "$TITLE" "$READ_WHEN" "$sha" <<'PY'
import json, sys
from datetime import datetime, timezone
path, packet, lane, title, read_when, sha = sys.argv[1:]
with open(path, "w", encoding="utf-8") as f:
    json.dump({"schema": 1, "packet_id": packet, "source_lane": lane,
               "title": title, "read_when": read_when, "submitted_at": datetime.now(timezone.utc).isoformat(),
               "artifact": "draft.md", "sha256": sha}, f, indent=2)
    f.write("\n")
PY
mv "$tmp" "$final" # atomic publication within the selected local/share filesystem
trap - EXIT
if [ "$deferred" -eq 1 ]; then
  printf 'deferred packet=%s outbox=%s; it will flush when the share is mounted\n' "$packet" "$final"
else
  printf 'submitted packet=%s transport=%s\n' "$packet" "$final"
fi
