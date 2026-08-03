---
type: template
purpose: Save the current session checkpoint with explicit machine, LLM tool, repo, working tree, and branch context; supports --reboot to finish the current safe unit, learn, push a durable branch or draft PR when needed, save, and print the exact /load resume command for reboot recovery.
read_when: When saving session state, preparing to reboot, going AFK, or creating a recovery point before context loss.
tags: [slash-command, save, session-management, checkpoint, reboot, handoff-lite]
scope: public
last_evaluated: 2026-07-11
---

# /save [name] [--reboot]

Checkpoint the current session. Canonical behavior lives in
`<KnowledgeRoot>/skills/save/SKILL.md`; read that skill before executing.

## Usage

```text
/save
/save sprint-day2
/save --reboot
/save sprint-day2 --reboot
```

## Procedure

1. Resolve `<KnowledgeRoot>` through `/knowledge` resolver rules if it is not
   already known.
2. Read `<KnowledgeRoot>/skills/save/SKILL.md`.
3. Execute the matching procedure:
   - no flag: `/session save [name]` or the mechanical equivalent, then print
     the exact `/load <name>` resume command
   - `--reboot`: finish the current logical unit, run
     `/learn` or the mechanical equivalent, reconcile durable trackers, save,
     and stop with the exact `/load <name>` resume command displayed
4. For `--reboot`, get the working tree to a clean, pushed state before the
   final stop. Run the reboot-safety gate to inspect the exact repo/worktree
   and gate the claim -- it must exit `REBOOT-SAFE` (rc 0):

   ```bash
   scripts/save-reboot-safety.sh --repo <worktree-path>
   ```

   Resolve every blocking reason it prints: commit+push in-scope
   session/checkpoint/knowledge changes (open a draft PR when not merge-ready),
   push any committed-but-unpushed commits, and convert intentionally-left
   out-of-scope changes into documented Ready DevOps tickets, then re-run with
   `--tickets <ids>`. Never leave meaningful changes only in the local working
   tree and never silently discard work. See
   `<KnowledgeRoot>/skills/save/SKILL.md` for the full procedure.

5. For `--reboot`, the checkpoint and final readback must preserve these
   resume pointers:
   - machine hostname or agent machine id
   - LLM tool/runtime (`claude-code`, `codex`, `cursor`, or other)
   - active working tree context: repo, active path, branch, base, PR,
     `continue_from`, and path rule from `WORKING TREE CONTEXT`
   - pushed branch/commit state plus PR URL and draft/ready status when
     incomplete content is preserved in a draft PR
   - active Hub path plus active task IDs, next actions, and linked plan paths
   - active `questions.md` path and open-question state
   - active `agent-inbox.md` path, `agent-goals.md` path, and repo permission
     surface
   - authorization state exactly as written (`approved` does not become
     `execute-authorized`)
   - last validation state, dirty files, blocked items, and first action after
     `/load`
6. Re-run the reboot-safety gate and re-open the saved checkpoint before
   printing the final reboot message. The gate must exit `REBOOT-SAFE` (rc 0);
   if it returns `NOT-REBOOT-SAFE` or any required pointer is missing, say the
   save is not reboot-safe and list the blocking reason / missing field instead
   of claiming success.
7. The final save output must print these fields plainly:
   - `Machine: <machine hostname or agent machine id>`
   - `Tool: <claude-code|codex|cursor|other>`
   - `Repo: <repo-name>`
   - `Working tree: <absolute path>`
   - `Branch: <current branch or detached HEAD SHA>`
   - `Upstream: <upstream branch or none>`
   - `PR: <url or none> (<draft|ready|merged|not-created>)`

For `--reboot`, incomplete content may be left in a **draft PR** when it is not
ready to merge. That is acceptable only if the branch is pushed, the draft PR
URL/status is recorded in the checkpoint, and ready follow-up tickets capture
any remaining work. Do not leave meaningful changes only in the local working
tree and call the save reboot-safe.

Do not treat `--reboot` as approval for new scope. It only changes save
timing and final output so Owner can reboot and resume cleanly.
