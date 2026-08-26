---
type: template
purpose: Retry the SQL-first jit-knowledge routing lookup after a per-boot fallback caused by missing credentials, an unavailable Dash API, a degraded query, or a commit mismatch.
read_when: When `/load` reported that it is using local knowledge files until reboot or reconnect, and Dash API connectivity or credentials may now be available.
tags: [slash-command, reconnect, knowledge-sync, sql, session-management]
scope: public
last_evaluated: 2026-07-25
---

# /reconnect

Retry the SQL-first knowledge routing lookup without rebooting or resuming a
different session.

## Procedure

1. Resolve `<KnowledgeRoot>` through `/knowledge` resolver rules.
2. Run:

   ```bash
   bash <KnowledgeRoot>/scripts/knowledge-reboot-handoff.sh reconnect --root <KnowledgeRoot>
   ```

3. If it reports `SQL BOOTSTRAP: current routing slice recorded`, use that
   commit-matched routing slice for subsequent knowledge selection.
4. If it reports local-file fallback, keep using files. Do not retry in a loop;
   the next reboot creates a new automatic retry window.

`/reconnect` never changes a session checkpoint, consumes a reboot handoff, or
upgrades knowledge. It only retries the derived SQL routing read path. A
matching `/load` reboot handoff still performs its mandatory local sync and
receipt verification.
