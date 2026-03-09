# convlog

Toggle-based conversation logging. When enabled, every user prompt and response
summary is appended to a daily log file in `.logs/` at the repo root.

## Toggle Commands

Trigger on any of these patterns (case-insensitive):
- `convlog on` or `convlog on <session-name>`
- `convlog off`
- `convlog status`

This skill is controlled by a toggle state stored in `.claude/session-state.md`
under the `conversation_log` field:

```
conversation_log: on   # or "off"
```

Default: off (unless session-state.md says otherwise)

## Behavior When Enabled

**TRIGGER:** The FIRST action upon receiving any new user request -- before any
other tool calls or work -- is to append the user's prompt to the log file.

### Sequence for every user message (when logging is on):

1. **IMMEDIATELY** append the user's verbatim prompt to the log file
2. If the previous log entry has no `**Response:**` line, write the response
   summary for that entry FIRST, then append the new prompt
3. Perform the requested work
4. After work is complete, append the response summary to the current entry

### Log File Location and Naming

- Directory: `.logs/` at the repo root
- File naming: `YYYYMMDD-HHMMSS-<session-name>.md`
- One file per calendar day

### Session Start (when logging is first enabled):

1. Run `date +"%Y%m%d"` via Bash to get today's date
2. Glob for `.logs/YYYYMMDD-*-<session-name>.md`
3. If a file exists for today: append to it
4. If no file exists: create a new file using `date +"%Y%m%d-%H%M%S"` for
   the full timestamp in the filename

### Log Entry Format

```markdown
### Prompt N
> <user prompt verbatim -- preserve line breaks with > on each line>

**Response:** <concise summary of what you did>
```

- Prompt numbers are sequential within the file (Prompt 1, Prompt 2, etc.)
- The `>` blockquote preserves the user's exact words
- Response summary should be 1-3 sentences covering what actions were taken
- Multi-line user prompts: each line gets its own `>` prefix

### Example Log File

```markdown
# Conversation Log -- 2026-03-09

### Prompt 1
> Fix the auth token bug in the API

**Response:** Found expired token not triggering refresh in auth.ts:42. Added 5-minute buffer to expiry check. Modified auth.ts, added test in auth.test.ts.

### Prompt 2
> Now deploy that to staging

**Response:** Built and deployed to staging via deploy.yml. Health check passed. Staging URL: https://staging.example.com

### Prompt 3
> Switch to the frontend repo and update the login form

(response pending -- work in progress)
```

### Edge Cases

- If the user's prompt is very long (over 500 words), log the first 500 words
  followed by `[truncated -- full prompt was ~N words]`
- If the session ends or logging is toggled off before a response is written,
  leave the entry as `(response pending -- session ended)`
- If `/clear` is run, the log file persists (it's on disk, not in context).
  After `/load`, check the toggle state and continue logging if enabled.
- The `.logs/` directory should be added to `.gitignore` by default (logs may
  contain sensitive prompts). Users can remove from `.gitignore` if they want
  logs committed.

## Session Name

The `<session-name>` in the filename is configurable. Set it when enabling:

```
/conversation-log on FirstMover
```

If no session name is provided, use `session` as the default:
`YYYYMMDD-HHMMSS-session.md`

The session name persists in `session-state.md` so it survives `/clear` + `/load`.

## Toggle Implementation

When `convlog on [session-name]` is invoked:

1. Update `.claude/session-state.md`:
   ```
   conversation_log: on
   conversation_log_session: <session-name>
   ```
2. Determine or create today's log file
3. If new file, write header: `# Conversation Log -- YYYY-MM-DD`
4. Confirm: "Conversation logging enabled. File: .logs/YYYYMMDD-HHMMSS-<name>.md"

When `convlog off` is invoked:

1. Write any pending response summary to the current log entry
2. Append: `### Logging disabled at [time]`
3. Update `.claude/session-state.md`:
   ```
   conversation_log: off
   ```
4. Confirm: "Conversation logging disabled."

When `convlog status` is invoked:

1. Read `.claude/session-state.md` for toggle state
2. Report:
   - Logging: on/off
   - Session name: [name]
   - Log file: [path]
   - Prompt count: [N]

## Important

- Logging is per-session. It does not persist across sessions unless
  session-state.md carries the toggle forward via /save + /load.
- Log files are append-only. Never modify or delete previous entries.
- The TRIGGER behavior (log prompt FIRST) is critical -- it ensures no
  prompt is lost even if the response fails or context is cleared.
- Keep response summaries concise. The log is a record, not a transcript.
