# Scripts

Deterministic bash scripts that power JitNeuro slash commands.

Commands like /dashboard and /sessions use these scripts for consistent,
reproducible output. The scripts read session state files and bundles
directly -- no AI interpretation needed for the data display layer.

## Files

| Script | Powers | Purpose |
|--------|--------|---------|
| dashboard.sh | /dashboard, /session dashboard | Show blockers, NEEDS OWNER items, next steps |
| sessions.sh | /sessions list, /sessions show | Numbered session list with age, task, repos |

## Why Scripts?

Slash commands are markdown prompt files -- Claude interprets them each time.
For data display (listing sessions, showing dashboards), deterministic bash
scripts give consistent formatting without burning tokens on interpretation.

The commands call these scripts via Bash tool, then Claude adds context and
recommendations on top of the structured output.

## Customization

The scripts use "NEEDS OWNER" as the default label for items requiring
the project owner's attention. To customize this label, edit the grep
patterns in the scripts or configure it in your owner-persona.md.
