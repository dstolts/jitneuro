# JitNeuro FAQ & Troubleshooting

**Status:** Ready for launch  
**Last updated:** 2026-04-10  
**Coverage:** Installation, common issues, usage questions, enterprise  

---

## Installation FAQs

### Q: What do I need to install JitNeuro?

**A:** Very little:
- Claude Code (CLI, desktop, or web) — latest recommended
- Bash or Git Bash (for hooks; Windows auto-detects)
- Git (to clone the repo)

That's it. No external dependencies, no databases, no servers.

---

### Q: Which Claude Code versions are supported?

**A:** JitNeuro works with all current Claude Code versions. We recommend the latest version for best compatibility.

**Minimum:** Claude Code 1.0+ (slash commands support)

**Recommended:** Latest available

---

### Q: How long does installation take?

**A:** About 3-5 minutes:
- Clone repo: 1 min
- Run installer: 2 min
- Restart Claude Code: 1 min
- Verify: 1 min

---

### Q: What's the difference between user, workspace, and project modes?

**A:**

| Mode | Scope | When to use |
|------|-------|-----------|
| **user** | All repos on machine | Single developer, works everywhere |
| **workspace** | All repos under parent | Team working in shared folder |
| **project** | Single repo only | Isolated per-project (less common) |

**Recommendation:** User mode (global commands across all repos).

---

### Q: Can I switch modes after installing?

**A:** Yes, but this gets messy (multiple scopes override each other).

**Better approach:**
1. Uninstall from all scopes
2. Install in single scope (user recommended)
3. Verify with `/verify`

---

### Q: Do I need Git Bash on Windows?

**A:** Only for hooks. Installer auto-detects Git Bash.

If you don't have Git Bash:
- Install: https://git-scm.com/download/win
- Or use WSL for core commands (hooks won't work)

---

### Q: I got an error during installation. What do I do?

**A:** 

1. **Check prerequisites:**
   ```bash
   bash --version        # Should show version
   git --version         # Should show version
   ```

2. **If bash not found (Windows):** Install Git Bash above.

3. **If permission denied:** Re-run with appropriate permissions.

4. **If settings.json parse error:** Backup and delete `~/.claude/settings.json`, re-run installer.

5. **Still stuck?** Open a [GitHub issue](https://github.com/dstolts/jitneuro/issues) with error message and your OS.

---

## Usage FAQs

### Q: How do I save my first session?

**A:** Simple:

```
You work for a while, explaining your project...

/save my-project
```

That's it. Your context is saved. You can now safely clear.

---

### Q: How big can a saved session be?

**A:** Usually 5-20 KB per session (compressed). You can save hundreds of sessions without issues.

**Estimate:** 100 saved sessions ≈ 1-2 MB disk space.

---

### Q: Can I delete a saved session?

**A:** Not yet (it's in FEATURE-REQUESTS.md for v0.4.1).

**Workaround:** Sessions are just text files in `~/.claude/session-state/`. You can manually delete them if needed (but be careful!).

---

### Q: What if I want to clear just part of my session?

**A:** Use `/save` before clearing, then `/load` selectively:

1. `/save working-state`
2. `/clear`
3. Manually re-explain what you want to keep
4. `/save cleaner-state`
5. `/load cleaner-state` in future sessions

---

### Q: How often should I use /learn?

**A:** As often as you make corrections:

**Correction you make:** "No wait, format strings like this..."  
→ `/learn use f-strings for formatting`

**Pattern you notice:** Always use integration tests, not mocks  
→ `/learn integration tests > mocks for database`

**Preference you have:** "I prefer async/await"  
→ `/learn prefer async/await for concurrency`

Each `/learn` becomes a permanent rule Claude follows.

---

### Q: Will /learn make my context bigger?

**A:** Only slowly. /learn creates small text-based rules (50-200 chars each).

**Impact:** After 1 month of learning: +0.5-1 MB to context size.

---

### Q: Can I edit saved sessions?

**A:** Yes, but manually only (advanced users).

Sessions live in `~/.claude/session-state/` as markdown files. You can edit them, but be careful not to break the format.

---

### Q: What happens if I run /clear but forget to /save first?

**A:** Context is lost (this is what /save prevents!).

**Prevention:** Use the pre-compact hook (auto-saves before context clear).

---

## Troubleshooting

### Problem: Commands not showing up

**Symptom:** `/save` command not recognized

**Fixes:**
1. **Restart Claude Code** — Commands load at session start
2. **Verify installation:** `/verify` (check output for errors)
3. **Check scope conflict:**
   ```bash
   ls ~/.claude/commands/              # user level
   ls .claude/commands/                # project level
   ls ../.claude/commands/             # workspace level
   ```
   If multiple scopes have commands, most specific wins (project > workspace > user).

4. **Reinstall:** `./install.sh user`

---

### Problem: Hooks not firing

**Symptom:** Auto-save before /clear not working, or branch protection hook not blocking

**Fixes:**
1. **Run /verify:**
   ```bash
   /verify
   ```
   Check "Hooks" section — should show GREEN.

2. **If RED:** Reinstall hooks
   ```bash
   ./install.sh user  # re-run installer
   ```

3. **Check settings.json:**
   ```bash
   cat ~/.claude/settings.json | grep -A 20 hooks
   ```
   Should show jitneuro hooks listed.

4. **Windows only:** Verify Git Bash path
   ```bash
   which bash
   ```
   Should show `/c/Program Files/Git/bin/bash` or similar.

---

### Problem: /save or /load not working

**Symptom:** Commands run but don't save/restore context

**Possible causes:**

1. **No active session:**
   - Make sure you've had a conversation first
   - `/save` needs context to save

2. **Session name conflict:**
   ```bash
   /sessions  # see existing names
   /save my-new-name-here
   ```

3. **Disk space issue:**
   - Check if `~/.claude/session-state/` is full
   - Run: `du -sh ~/.claude/session-state/`

4. **File permissions:**
   - Check: `ls -la ~/.claude/session-state/`
   - Should show files owned by your user

---

### Problem: /learn not persisting

**Symptom:** Rule created with /learn, but Claude forgets it in next session

**Fixes:**

1. **Wait 24h:** Rules process asynchronously, taking up to 24h to embed.

2. **Check rule was created:**
   ```bash
   cat ~/.claude/cognition/anti-patterns.md  # or relevant rule file
   ```

3. **Verify rule syntax:** Rules should be one per line.

4. **Test explicitly:** In next session, do something that would violate the rule, and Claude should catch it.

---

### Problem: /verify shows RED

**Symptom:** `/verify` command shows RED status for some components

**What it means:**
- 🟢 GREEN = working fine
- 🟡 YELLOW = working but needs attention
- 🔴 RED = broken, needs action

**Fixes depend on component:**

| Component | RED means | Fix |
|-----------|-----------|-----|
| Commands | Commands not copied | Re-run installer |
| Hooks | Hooks not configured | Re-run installer |
| Config | jitneuro.json missing | Re-run installer |
| Bundles | Bundle files missing | Create bundles or re-run installer |
| Engrams | No engram found | Create engrams (optional) |

**General fix:** `./install.sh user` then restart Claude Code.

---

### Problem: Hooks not working on Windows

**Symptom:** Branch protection hook not blocking push, auto-save not firing

**Fixes:**

1. **Verify Git Bash installed:**
   ```powershell
   where bash
   ```
   Should return path to Git Bash.

2. **Verify hook scripts have execute permission:**
   ```bash
   ls -la ~/.claude/hooks/*.sh
   ```
   Should show `x` (execute) permission.

3. **Check hook paths in settings.json:**
   ```bash
   cat ~/.claude/settings.json | grep -A 1 "shell"
   ```
   Should point to Git Bash, not PowerShell.

4. **Reinstall with PowerShell script:**
   ```powershell
   .\install.ps1 -Mode user
   ```
   Installer should auto-detect and fix paths.

---

### Problem: Performance degradation

**Symptom:** Claude Code slows down over time

**Possible causes:**

1. **Too many saved sessions:**
   - `/sessions` lists all (can be hundreds)
   - Solution: Delete old sessions from `~/.claude/session-state/`

2. **Context files too large:**
   - Check: `du -sh ~/.claude/`
   - If >100 MB, consider archiving old sessions

3. **Too many rules:**
   - After 3+ months of /learn, you might have 1000+ rules
   - Solution: Review and consolidate similar rules

4. **Unrelated to JitNeuro:**
   - Could be Claude Code itself (update to latest)
   - Could be system resources (RAM, disk)

---

## Enterprise FAQs

### Q: Can I use JitNeuro in a team?

**A:** Yes! Three ways:

1. **Shared workspace:** Install in workspace mode
   ```bash
   ./install.sh workspace
   ```
   All devs under parent folder get same commands.

2. **Sync via repo:** Commit jitneuro to your team repo
   ```bash
   git clone jitneuro
   ./install.sh project  # per-repo
   ```

3. **Pre-installed:** Have team install at user level
   Each dev: `./install.sh user`

---

### Q: How does JitNeuro handle team context?

**A:** Use `/enterprise` command:

```
/enterprise set-team john, mary, alice
```

This creates team context that's shared across repos and sessions.

---

### Q: Can I use JitNeuro with CI/CD?

**A:** Hooks require Bash (not available in most CI/CD).

**Workaround:**
- Core commands (`/save`, `/load`, `/learn`) work in any environment
- CI can call `/learn` to capture test results
- Scheduled agents can dispatch CI tasks

---

### Q: Is JitNeuro compliant with security policies?

**A:** Yes, it supports trust zones:

- **GREEN:** Unrestricted (development)
- **YELLOW:** Notify on changes (staging)
- **RED:** Block and alert (production)

Configure with `/enterprise` and rules.

---

### Q: Can I export/backup sessions?

**A:** Sessions are just markdown files:

```bash
# Export all sessions
tar -czf jitneuro-sessions-backup.tar.gz ~/.claude/session-state/

# Restore
tar -xzf jitneuro-sessions-backup.tar.gz -C ~
```

---

## Common Issues Checklist

Before opening an issue, verify:

- [ ] You've run `/verify` and noted the output
- [ ] You restarted Claude Code (commands load at session start)
- [ ] You checked troubleshooting section above
- [ ] Your OS and Claude Code version
- [ ] Your error message (copy exact text)
- [ ] You've looked at existing [GitHub issues](https://github.com/dstolts/jitneuro/issues)

---

## Still Stuck?

**Resources:**
1. [QUICKSTART.md](QUICKSTART.md) — 4-step walkthrough
2. [docs/setup-guide.md](docs/setup-guide.md) — Detailed setup
3. [docs/commands-reference.md](docs/commands-reference.md) — All commands explained
4. [GitHub Issues](https://github.com/dstolts/jitneuro/issues) — Known issues
5. [GitHub Discussions](https://github.com/dstolts/jitneuro/discussions) — Ask questions

**Before opening an issue, please:**
- Search existing issues (might be already solved)
- Include your error message word-for-word
- Include your OS and Claude Code version
- Include output of `/verify`

---

**Last updated:** April 10, 2026  
**Maintainer:** [Author]  
**Contributing:** Issues and PRs welcome!
