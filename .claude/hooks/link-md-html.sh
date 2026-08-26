#!/usr/bin/env bash
# link-md-html.sh -- PostToolUse hook (matcher: Write|Edit|MultiEdit).
#
# Owner directive 2026-07-23 ("we need a new rule, any new or modified .md or
# .html file created/changed must display a clickable link to the file --
# this needs to be mechanical"): whenever a Markdown or HTML file is created
# or modified, surface a CLICKABLE link to that file so Owner can open it
# immediately. Mechanical by design -- the hook itself emits the link via a
# systemMessage, so it does NOT depend on the model remembering to do it.
#
# Clickability: Claude Code renders absolute file paths as clickable links
# (cmd/ctrl-click to open). We emit the resolved absolute path.
#
# Fail-open: any parse error or missing dependency exits 0 and emits nothing,
# so this hook can never block or fail the tool call it fires after.
set +e

input="$(cat)"
[ -z "$input" ] && exit 0

# Resolve the target file path (absolute) from the PostToolUse payload.
fp="$(printf '%s' "$input" | python3 -c '
import sys, json, os
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {}) or {}
    fp = ti.get("file_path") or ti.get("notebook_path") or ""
    cwd = d.get("cwd") or os.getcwd()
    if fp and not os.path.isabs(fp):
        fp = os.path.normpath(os.path.join(cwd, fp))
    print(fp)
except Exception:
    print("")
' 2>/dev/null)"

[ -z "$fp" ] && exit 0

# Case-insensitive extension gate: Markdown or HTML only.
shopt -s nocasematch 2>/dev/null
case "$fp" in
  *.md|*.markdown|*.html|*.htm) : ;;
  *) exit 0 ;;
esac
shopt -u nocasematch 2>/dev/null

# Emit the clickable link as a systemMessage (shown to Owner) plus a short
# additionalContext note (so the model is aware and can echo it if useful).
printf '%s' "$fp" | python3 -c '
import sys, json
fp = sys.stdin.read().strip()
if not fp:
    sys.exit(0)
print(json.dumps({
    "systemMessage": "MD/HTML file written -- open: " + fp,
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "A Markdown/HTML file was created or modified. Present a clickable link to it for the Owner: " + fp
    }
}))
' 2>/dev/null

exit 0
