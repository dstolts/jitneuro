# JitNeuro v0.4.0 Release Notes

**Release Date:** April 10, 2026  
**Stability:** Stable  
**Breaking Changes:** None  

---

## Summary

JitNeuro v0.4.0 marks the official public release of the framework. The entire system has been validated for production use, with comprehensive documentation and enterprise-ready features.

**What's new:** Prerequisite documentation clarified, duplicate content removed, framework consistency validated.

**Who should update:** All users. This is the official stable release.

---

## What's in v0.4.0

### Framework Completeness ✅

- **22 slash commands** (16 core + 5 shortcuts + test-tools + verify)
- **11 hooks** (pre-compact, session start/end, branch protection, heartbeat, agent callbacks)
- **Templates** (brainstem CLAUDE.md, bundles, engrams, rules, session state)
- **Documentation** (32 docs, setup guide, commands reference, technical overview)
- **Examples** (multi-repo sprint, solo developer, enterprise isolation)

### Key Features

1. **Memory System**
   - `/save` — checkpoint context before /clear
   - `/load` — restore context anytime
   - `/learn` — make corrections permanent
   - `/sessions` — view all saved sessions

2. **Orchestration**
   - `/orchestrate` — coordinate multi-agent work
   - `/divergent` — explore alternative approaches
   - Sub-orchestrator pattern for worker parallelism
   - Scheduled agents for autonomous execution

3. **Governance & Security**
   - Trust zones (GREEN/YELLOW/RED)
   - Branch protection hook
   - /enterprise command for team context
   - Holistic review framework

4. **Productivity**
   - `/health` — memory system diagnostics
   - `/verify` — environment validation
   - `/gitstatus` — cross-repo status
   - `/audit` — codebase analysis
   - Dashboard for unified view

5. **Integration**
   - Ralph integration (enterprise context isolation)
   - Cursor support (alternative editors)
   - Multi-repo orchestration
   - Scheduled agent dispatch

### Documentation Additions

- ✅ Claude Code version prerequisites (README + QUICKSTART)
- ✅ Framework consistency audit (all paths, commands, hooks validated)
- ✅ README clarity improvements (removed duplicate sections)
- ✅ Setup guide refinements (address common issues)

---

## Stability & Quality

### Testing

- ✅ All 22 commands verified functional
- ✅ 11 hooks tested on Windows, macOS, Linux
- ✅ Installation scripts validated (workspace/project/user modes)
- ✅ Cross-platform compatibility confirmed
- ✅ Framework self-consistency audit passed

### Compatibility

- ✅ Backward compatible with v0.3.0 deployments
- ✅ No breaking changes to command syntax
- ✅ No breaking changes to jitneuro.json schema
- ✅ Existing rules continue to work

### Known Limitations

- Hooks require Bash (Git Bash on Windows; WSL not supported for hook execution)
- Core commands work on all platforms
- Requires Claude Code (latest recommended)
- Some advanced features require specific Claude Code versions

---

## Getting Started

### Installation (30 seconds)

```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro

# Pick your scope:
./install.sh user       # global (recommended)
./install.sh workspace  # parent directory
./install.sh project    # current repo only
```

**Windows (PowerShell):**
```powershell
.\install.ps1 -Mode user
```

After installation, **restart Claude Code**. Commands load at session start only.

### First Steps

```
/verify              # Check all 9 components
/status              # See what's loaded
/help                # View all commands
/save my-session     # Save your first context
/load my-session     # Restore it (after /clear)
/learn               # Make a correction permanent
```

That's it. You now have memory that persists across context resets.

---

## Documentation

**Full docs available at:** https://github.com/dstolts/jitneuro/tree/main/docs

- [Setup Guide](docs/setup-guide.md) — Installation, configuration, scoping
- [Commands Reference](docs/commands-reference.md) — All 22 commands explained
- [QUICKSTART](QUICKSTART.md) — 4-step onboarding
- [Technical Overview](docs/technical-overview.md) — DOE framework deep dive
- [Examples](examples/) — Multi-repo sprint, solo developer workflows

---

## What's Changed (v0.3.0 → v0.4.0)

### Additions
- Claude Code version prerequisite documentation
- Framework consistency audit and validation
- Comprehensive post-launch planning documents
- Landing page specifications and wireframes
- Video walkthrough script and recording guide
- Promotion and community engagement strategy
- Dev.to cross-posting guidelines

### Improvements
- README clarity (removed duplicate section)
- Framework documentation completeness verified
- All command references validated
- Hardcoded path scan confirms portability
- No user-specific paths (fully portable)

### Fixes
- Removed duplicate "How It Grows With You" section in README
- Clarified prerequisite requirements

### No Breaking Changes
- ✅ All existing commands unchanged
- ✅ All existing hooks compatible
- ✅ All existing templates compatible
- ✅ Config schema backward compatible

---

## Migration Guide (for v0.3.0 users)

If you're upgrading from v0.3.0:

1. **Re-run installer** to get new guides:
   ```bash
   ./install.sh user  # or workspace/project
   ```

2. **No action needed** on existing sessions
   - All saved sessions remain compatible
   - Existing rules still apply
   - No configuration changes required

3. **Optional: Review new docs**
   - Landing page requirements
   - Video script for team training
   - Promotion strategy (if sharing with team)

---

## Contributors

**v0.4.0 contributors:**
- Core framework: [Author]
- Documentation: [Author]
- Testing & validation: [Author]
- Community feedback: [Contributors welcome!]

---

## Support & Feedback

**Having an issue?**

1. Check [QUICKSTART.md](QUICKSTART.md) troubleshooting section
2. Search [GitHub issues](https://github.com/dstolts/jitneuro/issues)
3. Open a new [GitHub issue](https://github.com/dstolts/jitneuro/issues/new) with:
   - What you were doing
   - What you expected
   - What actually happened
   - Your environment (OS, Claude Code version)

**Want to contribute?**

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a PR with description

**Have questions?**

1. Check [docs/](docs/) for comprehensive guides
2. Open a [GitHub discussion](https://github.com/dstolts/jitneuro/discussions)
3. Review [FEATURE-REQUESTS.md](FEATURE-REQUESTS.md) for planned work

---

## What's Next (v0.4.1 Roadmap)

Based on community feedback and planned enhancements:

- [ ] Advanced /learn patterns (refine rule creation)
- [ ] Expanded bundle examples (domain-specific templates)
- [ ] Ralph integration enhancements
- [ ] Multi-language support (commands in other languages)
- [ ] Custom dashboard templates
- [ ] Community-contributed rules pack

**Suggest features:** Open a [feature request](https://github.com/dstolts/jitneuro/issues/new?labels=enhancement).

---

## Acknowledgments

JitNeuro is built on the DOE (Directive Orchestration Execution) framework. Special thanks to:

- Claude Code team for the slash command platform
- Community testers and early adopters
- Contributors and issue reporters

---

## License

MIT — See [LICENSE](LICENSE) file for full text.

This means:
- ✅ Use for any purpose
- ✅ Modify and redistribute
- ✅ Use in commercial projects
- ⚠️ Include license + copyright notice
- ⚠️ No warranty or liability

---

## References

- **GitHub:** https://github.com/dstolts/jitneuro
- **Landing Page:** https://jitneuro.ai
- **Blog:** [Launch announcement]
- **Video:** [YouTube walkthrough]
- **Docs:** https://github.com/dstolts/jitneuro/tree/main/docs

---

**Download:** https://github.com/dstolts/jitneuro/archive/refs/tags/v0.4.0.zip

**Install:** See Getting Started section above.

**Report issues:** https://github.com/dstolts/jitneuro/issues

---

Thank you for trying JitNeuro. Happy building! 🚀
