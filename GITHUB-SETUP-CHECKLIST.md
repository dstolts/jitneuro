# GitHub Setup Checklist — Post-Main-Push

**Status:** Waiting for main branch push approval  
**Time to Complete:** 5-10 minutes  
**Tools:** gh CLI or GitHub web interface  

---

## Pre-Requisites
- [ ] Main branch push completed and verified
- [ ] README.md rendering correctly on GitHub (✅ confirmed 2026-04-10)

---

## Tasks

### 1. Repository Settings

**GitHub Settings → General**

- [ ] **Repository name:** `jitneuro` ✅ (already correct)
- [ ] **Description:** "Endless Auto-Recall Memory for Claude Code"
- [ ] **Website:** `https://jitneuro.ai` (add when landing page is live)
- [ ] **Visibility:** Public ✅ (already correct)

**Repository Settings → Code and automation → Branch protection**

- [ ] Main branch protection: Require PR reviews ✅ (recommended but optional)

---

### 2. Repository Topics

**GitHub Settings → Topics**

Add these topics (appear as tags below repo name):

- [ ] `claude-code`
- [ ] `ai-memory`
- [ ] `context-management`
- [ ] `developer-tools`
- [ ] `ai-agents`
- [ ] `memory-management`
- [ ] `orchestration`
- [ ] `dot-claude`

**Why:** Improves discoverability in searches (e.g., "claude-code memory")

---

### 3. About Section

**Repository Home → About (gear icon)**

- [ ] Add short description: "Endless Auto-Recall Memory for Claude Code"
- [ ] Add website link: `https://jitneuro.ai` (when live)
- [ ] Add topics (see above)

---

### 4. Release & Version Management

**Releases → Create a release**

- [ ] **Tag version:** `v0.4.0`
- [ ] **Release title:** "JitNeuro v0.4.0 — Framework Stability & Enterprise Scale"
- [ ] **Release notes:** (use template below)

**Release Notes Template:**

```markdown
# JitNeuro v0.4.0

## What's New

- ✅ Claude Code version prerequisites documented
- ✅ Framework consistency validated across all 22 commands
- ✅ README optimized (removed duplicate sections)
- ✅ Pre-launch audit completed

## Highlights

- **Framework:** 22 slash commands, 11 hooks, bundled templates
- **Scope:** Workspace/project/user installation modes
- **Platform:** Windows, macOS, Linux (Bash/Git Bash compatible)
- **License:** MIT (fully open source)

## Getting Started

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
./install.sh user    # recommended
```

Then restart Claude Code and run `/save`, `/load`, `/learn`.

See [QUICKSTART.md](QUICKSTART.md) for a detailed walkthrough.

## Documentation

- [Setup Guide](docs/setup-guide.md) — Complete installation & configuration
- [Commands Reference](docs/commands-reference.md) — All 22 commands explained
- [Technical Overview](docs/technical-overview.md) — DOE framework deep dive
- [QUICKSTART.md](QUICKSTART.md) — 4-step onboarding

## Known Limitations

- Hooks require Bash (Git Bash on Windows; WSL not supported for hooks)
- Core commands work on all platforms
- Tested on Claude Code v1.x+ (latest recommended)

## Contributors

- Owner: [Your Name]
- Community: Open to PRs and issues

## Next Steps

- Report issues: [GitHub Issues](https://github.com/dstolts/jitneuro/issues)
- Discuss: [GitHub Discussions](https://github.com/dstolts/jitneuro/discussions)
- Blog post: [Read the launch announcement](blog-url-here)

## License

MIT — See LICENSE file for full text.
```

---

### 5. Verify Rendering

After push, check:

- [ ] README displays correctly (headers, code blocks, links)
- [ ] QUICKSTART.md links work
- [ ] All documentation links in README are functional
- [ ] GitHub displays repo topics correctly
- [ ] Release notes render properly

**Test by visiting:** https://github.com/dstolts/jitneuro

---

## CLI Commands (Alternative to Web UI)

If using `gh` CLI:

```bash
# Set repository description and website
gh repo edit dstolts/jitneuro \
  --description "Endless Auto-Recall Memory for Claude Code" \
  --homepage "https://jitneuro.ai"

# Add topics
gh api repos/dstolts/jitneuro --input - <<'EOF'
{
  "topics": [
    "claude-code",
    "ai-memory",
    "context-management",
    "developer-tools",
    "ai-agents",
    "memory-management",
    "orchestration",
    "dot-claude"
  ]
}
EOF

# Create release (manual in web UI recommended for detailed notes)
gh release create v0.4.0 \
  --title "JitNeuro v0.4.0 — Framework Stability" \
  --notes-file RELEASE-NOTES-v0.4.0.md
```

---

## Post-Setup

After GitHub setup is complete:

1. **Link landing page:** Add jitneuro.ai website URL to repo
2. **Promote:** Share GitHub repo URL in blog, Dev.to, social
3. **Monitor:** Watch for issues/stars/forks
4. **Engage:** Respond to issues and PRs promptly

---

## Rollback Plan

If something needs fixing before going public:

- Edit release notes (doesn't require new tag)
- Update README and commit to main (visible immediately)
- Fix topics/description via GitHub settings (no commit needed)
- Create v0.4.1 patch if critical fix needed

---

**Estimated Time:** 5-10 minutes for web UI, 2 minutes for CLI  
**Difficulty:** Low — mostly copying values and clicking buttons  
**Risk:** None — all changes are reversible
