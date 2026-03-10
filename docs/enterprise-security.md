# Enterprise Security: Hook Enforcement Model

## Trust Model

JitNeuro hooks operate as a **local convenience layer** that catches accidental
violations before they reach server-side enforcement (GitHub branch protection,
CI gates, deploy policies). They are NOT a security boundary.

**Why local hooks cannot enforce security:**
A developer with write access to hook scripts or config files can modify them
to bypass any check. The trust chain must start at a point the developer
cannot modify.

**Defense in depth:**

| Layer | Prevents | Enforced By | Bypassable? |
|-------|----------|-------------|-------------|
| JitNeuro hooks (local) | Accidental pushes, context loss | Hook scripts + config | YES -- developer can edit |
| GitHub branch protection | Direct push to protected branches | GitHub server | NO (if admin-only) |
| CI/CD gates | Bad code reaching production | CI pipeline | NO (if properly configured) |
| Deploy policies | Unauthorized deployments | Infrastructure | NO (if properly configured) |

JitNeuro hooks are Layer 1. They reduce friction and catch mistakes early.
Layers 2-4 are the actual enforcement. Always configure server-side protection
regardless of JitNeuro hooks.

---

## Securing Hooks for Teams

For teams where accidental bypass is not acceptable, move the trust root
outside the developer's write access.

### Option A: Network Share (Recommended for On-Prem)

Store hook scripts and policy config on a read-only network share.
Developers can execute but not modify.

**Setup (Windows):**

1. Create a network share for JitNeuro policy:
   ```
   \\server\jitneuro-policy\
     hooks\
       branch-protection.sh
       pre-compact-save.sh
       session-start-recovery.sh
       session-end-autosave.sh
     jitneuro-policy.json
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
           "command": "bash \"//server/jitneuro-policy/hooks/branch-protection.sh\"",
           "timeout": 5
         }]
       }]
     }
   }
   ```

5. The hooks on the share read their config from the share:
   ```bash
   # In hook script, config path is relative to script location
   CONFIG="$(dirname "$SCRIPT_DIR")/jitneuro-policy.json"
   ```

**Limitation:** Developer can still edit their local settings.local.json to
point hooks elsewhere or remove them entirely. To prevent this, use Group
Policy (see below).

**Setup (Linux/Mac):**

1. Mount a read-only NFS/SMB share:
   ```
   /mnt/jitneuro-policy/
     hooks/
     jitneuro-policy.json
   ```

2. Set mount as read-only in /etc/fstab:
   ```
   //server/jitneuro-policy /mnt/jitneuro-policy cifs ro,credentials=/etc/jitneuro-creds 0 0
   ```

3. Hook scripts owned by root, permissions 555 (read+execute, no write).

4. Configure Claude Code to use the mounted path.

### Option B: Local File System + Group Policy (Windows)

Use Windows Group Policy to lock down both the hook scripts AND the Claude
Code settings file so developers cannot modify them.

**Step 1: Lock down hook scripts**

1. Install hooks to a protected local directory:
   ```
   C:\ProgramData\JitNeuro\
     hooks\
       branch-protection.sh
       pre-compact-save.sh
       session-start-recovery.sh
       session-end-autosave.sh
     jitneuro-policy.json
   ```

2. Set NTFS permissions:
   ```powershell
   # Run as Administrator
   $path = "C:\ProgramData\JitNeuro"

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

**Step 3: Validate with Group Policy**

Create a GPO that:
1. Deploys hook scripts to C:\ProgramData\JitNeuro\ on login
2. Deploys settings.local.json to each user's ~/.claude/ on login
3. Sets correct NTFS permissions on both locations
4. Runs a validation script that checks file hashes

```powershell
# GPO startup script example
$policySource = "\\server\jitneuro-policy"
$localHooks = "C:\ProgramData\JitNeuro"
$userSettings = "$env:USERPROFILE\.claude\settings.local.json"

# Sync hooks from network to local (admin context)
robocopy "$policySource\hooks" "$localHooks\hooks" /MIR /R:3
Copy-Item "$policySource\jitneuro-policy.json" "$localHooks\jitneuro-policy.json" -Force

# Deploy user settings
Copy-Item "$policySource\settings.local.json" $userSettings -Force
Set-ItemProperty $userSettings -Name IsReadOnly -Value $true
```

### Option C: Git-Protected Policy Repo

For GitHub-native teams without on-prem infrastructure.

1. Create a `jitneuro-policy` repo (private, admin-only write access)
2. Hook scripts fetch policy from this repo at runtime:
   ```bash
   # In hook script
   POLICY=$(curl -s -H "Authorization: token $JITNEURO_TOKEN" \
     "https://raw.githubusercontent.com/org/jitneuro-policy/main/policy.json")
   ```
3. Developers have read-only access to the policy repo
4. Admins control policy via PRs to the policy repo

**Trade-offs:**
- Requires network access on every hook invocation (adds latency)
- Token management adds complexity
- Hook script itself is still local (developer could edit it)
- Best combined with Group Policy (Option B) to protect the hook scripts

---

## Security Checklist for Enterprise Deployment

| Check | Solo Dev | Small Team | Enterprise |
|-------|----------|------------|------------|
| GitHub branch protection on main | Required | Required | Required |
| JitNeuro hooks installed | Recommended | Required | Required |
| Hook scripts read-only to devs | N/A | Recommended | Required |
| Config on network share or GPO | N/A | Optional | Required |
| settings.local.json locked via GPO | N/A | N/A | Required |
| CI gates on PR merge | Optional | Required | Required |
| File hash auditing | N/A | N/A | Recommended |
| SIEM integration for bypass attempts | N/A | N/A | Optional |

---

## Limitations (Honest Assessment)

1. **Claude Code does not support org-managed settings.** There is no built-in
   way to enforce hooks that developers cannot remove. All workarounds above
   are OS-level compensating controls.

2. **Git Bash on Windows complicates permissions.** Git Bash may not respect
   NTFS ACLs the same way PowerShell does. Test hook execution under the
   exact permissions you deploy.

3. **Determined bypass is always possible.** A developer who understands the
   system can find ways around local enforcement. Server-side controls
   (GitHub, CI, deploy gates) are the real security boundary. JitNeuro hooks
   are defense-in-depth, not primary enforcement.

4. **Hook latency.** Network-based config (Option C) adds latency to every
   tool call. For PreToolUse hooks that fire on every Bash command, this
   can be noticeable. Local file or network share (Options A/B) have
   negligible latency.
