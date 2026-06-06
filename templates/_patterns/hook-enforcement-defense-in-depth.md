---
type: pattern
purpose: Defines the defense-in-depth model for AI-assistant hooks -- a local hook is a convenience layer that catches accidental violations, NOT a security boundary; real enforcement lives server-side (branch protection, CI gates, access controls). MUST be consulted by anyone configuring agent guardrails or relying on a hook to BLOCK an action, because treating a bypassable local hook as the only control ships unenforced policy -- a misconfigured or determined agent simply skips it and the prohibited change reaches production.
read_when: Before configuring agent guardrails or any hook intended to block a prohibited action in an AI-assisted workflow.
tags: [security, hooks, enforcement, trust-model, claude-code, ai-guardrails]
scope: public
departments: [all]
status: canonical
community_reviewed: 2026-06-02
last_evaluated: 2026-06-03
---

# Enterprise Security: Hook Enforcement Model

## Trust Model

Claude Code hooks operate as a **local convenience layer** that catches accidental
violations before they reach server-side enforcement (GitHub branch protection,
CI gates, deploy policies). They are NOT a security boundary.

**Why local hooks cannot enforce security:**
A developer with write access to hook scripts or config files can modify them
to bypass any check. The trust chain must start at a point the developer
cannot modify.

**The full trust chain (all must be protected):**

| File | What It Controls | Risk If Modified |
|------|-----------------|------------------|
| `settings.local.json` | Which hooks Claude Code loads and where scripts live | Remove hooks = no enforcement |
| `settings.json` | Can override settings.local.json | Same as above |
| Hook scripts (`.sh`) | Enforcement logic (what gets blocked) | Weaken or disable checks |
| `agent-policy.json` | Config hooks read (protectedBranches, behavior) | Change protected branches to empty list |
| `CLAUDE.md` (all levels) | Prose guardrails (trust zones, approval rules) | Add "push to main freely" = Claude obeys |
| `.claude/rules/` | Scoped rules Claude follows per file type | Remove or weaken rules |

**CLAUDE.md is the subtlest risk.** It is not code -- it is natural language
instructions that Claude follows. A developer adding "ignore branch protection"
or "push to main is always allowed" to any CLAUDE.md will override prose
guardrails. Hooks still block (if intact), but Claude will stop asking for
permission and may find other ways to accomplish the goal.

**Defense in depth:**

| Layer | Prevents | Enforced By | Bypassable? |
|-------|----------|-------------|-------------|
| CLAUDE.md guardrails | Claude following unsafe patterns | Prose instructions | YES -- developer can edit |
| Claude Code hooks (local) | Accidental pushes, context loss | Hook scripts + config | YES -- developer can edit |
| GitHub branch protection | Direct push to protected branches | GitHub server | NO (if admin-only) |
| CI/CD gates | Bad code reaching production | CI pipeline | NO (if properly configured) |
| Deploy policies | Unauthorized deployments | Infrastructure | NO (if properly configured) |

Claude Code hooks are Layer 1. They reduce friction and catch mistakes early.
Layers 2-4 are the actual enforcement. Always configure server-side protection
regardless of local hooks.

---

## Securing Hooks for Teams

For teams where accidental bypass is not acceptable, move the trust root
outside the developer's write access.

### Option A: Network Share (Recommended for On-Prem)

Store hook scripts and policy config on a read-only network share.
Developers can execute but not modify.

**Setup (Windows):**

1. Create a network share for agent policy:
   ```
   \\server\agent-policy\
     hooks\
       branch-protection.sh
       pre-compact-save.sh
       session-start-recovery.sh
       session-end-autosave.sh
     agent-policy.json
   ```

2. Set share permissions:
   - IT/Admins: Full Control
   - Developers: Read + Execute only

3. Set NTFS permissions on the folder:
   - IT/Admins: Full Control
   - Developers group: Read & Execute, List folder contents, Read
   - Remove: Write, Modify, Full Control for developers

4. Configure Claude Code settings.local.json to point to the share:
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": "Bash",
         "hooks": [{
           "type": "command",
           "command": "//server/agent-policy/hooks/branch-protection.sh",
           "timeout": 5
         }]
       }]
     }
   }
   ```

5. The hooks on the share read their config from the share:
   ```bash
   # In hook script, config path is relative to script location
   CONFIG="$(dirname "$SCRIPT_DIR")/agent-policy.json"
   ```

**Limitation:** Developer can still edit their local settings.local.json to
point hooks elsewhere or remove them entirely. To prevent this, use Group
Policy (see below).

**Setup (Linux/Mac):**

1. Mount a read-only NFS/SMB share:
   ```
   /mnt/agent-policy/
     hooks/
     agent-policy.json
   ```

2. Set mount as read-only in /etc/fstab:
   ```
   //server/agent-policy /mnt/agent-policy cifs ro,credentials=/etc/agent-policy-creds 0 0
   ```

3. Hook scripts owned by root, permissions 555 (read+execute, no write).

4. Configure Claude Code to use the mounted path.

### Option B: Local File System + Group Policy (Windows)

Use Windows Group Policy to lock down both the hook scripts AND the Claude
Code settings file so developers cannot modify them.

**Step 1: Lock down hook scripts**

1. Install hooks to a protected local directory:
   ```
   %ProgramData%\AgentPolicy\
     hooks\
       branch-protection.sh
       pre-compact-save.sh
       session-start-recovery.sh
       session-end-autosave.sh
     agent-policy.json
   ```

2. Set NTFS permissions:
   ```powershell
   # Run as Administrator
   $path = "%ProgramData%\AgentPolicy"

   # Remove inherited permissions
   $acl = Get-Acl $path
   $acl.SetAccessRuleProtection($true, $false)

   # Admins: Full Control
   $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
     "BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
   $acl.AddAccessRule($adminRule)

   # Developers: Read + Execute only
   $devRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
     "DOMAIN\Developers", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
   $acl.AddAccessRule($devRule)

   Set-Acl $path $acl
   ```

3. Apply recursively to all files:
   ```powershell
   Get-ChildItem $path -Recurse | ForEach-Object {
     Set-Acl $_.FullName $acl
   }
   ```

**Step 2: Lock down settings.local.json (prevents hook removal)**

This is the critical step. Without this, developers can remove hook entries
from their settings.local.json.

Option 2a -- Group Policy registry preference:
   - Use GPO to deploy a standard settings.local.json
   - Set the GPO preference to "Replace" mode (re-applies on each login)
   - Developer edits are overwritten on next policy refresh

Option 2b -- File system audit + scheduled task:
   - Set NTFS auditing on settings.local.json for write events
   - Scheduled task checks file hash every N minutes, restores from template
   - Alerts IT when tampered

Option 2c -- Read-only settings.local.json:
   - Deploy settings.local.json with read-only NTFS permissions for developers
   - Developer cannot edit the file at all
   - Limitation: blocks ALL settings changes, not just hooks

**Step 3: Lock down CLAUDE.md guardrails (prevents prose bypass)**

CLAUDE.md files contain the trust zones, approval workflows, and critical rules
that Claude follows. If a developer modifies these, Claude will follow the
modified instructions -- even if hooks are intact.

Files to protect:
- Workspace-level: `<workspace>/.claude/CLAUDE.md` (shared guardrails)
- Workspace-level: `<workspace>/CLAUDE.md` (if used for project-level instructions)
- User-level: the user-global CLAUDE.md loaded by Claude Code on startup (global rules)
