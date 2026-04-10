# JitNeuro v0.4.0 Launch Verification Checklist

**Status:** Ready to execute (upon main branch push approval)  
**Duration:** 30-45 minutes  
**Executor:** Owner or authorized team member  

---

## Pre-Push Verification (5 minutes)

Before pushing to main, verify:

- [ ] **Git status is clean**
  ```bash
  git status
  # Should show: "nothing to commit, working tree clean"
  ```

- [ ] **All commits present**
  ```bash
  git log origin/main..HEAD --oneline
  # Should show 5 commits ready
  ```

- [ ] **No merge conflicts**
  ```bash
  git diff --name-only main origin/main
  # Should be empty
  ```

- [ ] **Branch is main**
  ```bash
  git branch --show-current
  # Should output: main
  ```

- [ ] **Commits match expected**
  ```
  1. Add post-launch planning documents and guides
  2. Add comprehensive post-launch guides and templates
  3. Fix: Remove duplicate 'How It Grows With You' section
  4. Add Claude Code version prerequisites to README
  5. (Any other pre-launch audit commits)
  ```

---

## Push to Main (2 minutes)

Execute the push:

```bash
# Push commits
git push origin main

# Verify push succeeded
git log origin/main..HEAD
# Should now be empty (all pushed)

# Create and push tag
git tag v0.4.0
git push --tags

# Verify tag exists on remote
git ls-remote origin | grep v0.4.0
```

---

## GitHub Verification (10 minutes)

After pushing, verify on GitHub:

### Repository Settings

- [ ] **Go to repo settings**
  - https://github.com/dstolts/jitneuro/settings

- [ ] **Update repository description**
  - Current: [check current]
  - New: "Endless Auto-Recall Memory for Claude Code"
  - Save

- [ ] **Add website**
  - Add: https://jitneuro.ai
  - Save

### Repository Topics

- [ ] **Add topics** (Settings → Topics)
  - [ ] `claude-code`
  - [ ] `ai-memory`
  - [ ] `context-management`
  - [ ] `developer-tools`
  - [ ] `ai-agents`
  - [ ] `memory-management`
  - [ ] `orchestration`
  - [ ] `dot-claude`

### README Rendering

- [ ] **Visit main repo page**
  - https://github.com/dstolts/jitneuro

- [ ] **Verify README displays correctly**
  - [ ] All sections visible
  - [ ] Code blocks have syntax highlighting
  - [ ] Images load (if any)
  - [ ] Links are clickable
  - [ ] No formatting errors
  - [ ] No duplicate sections ("How It Grows With You" appears once)

- [ ] **Verify QUICKSTART link works**
  - Click "QUICKSTART" link in README
  - Should navigate to QUICKSTART.md

- [ ] **Check navigation**
  - All links in README work
  - No 404 errors
  - External links open correctly

### Release Page

- [ ] **Create GitHub release**
  - Go to: Releases → "Create a new release"

- [ ] **Fill release details**
  - [ ] Tag: `v0.4.0` (should auto-populate)
  - [ ] Release title: "JitNeuro v0.4.0 — Framework Stability & Production Ready"
  - [ ] Release notes: Copy from RELEASE-NOTES-v0.4.0.md
  - [ ] Attach assets: Optional (pre-built files if any)
  - [ ] Publish release

---

## Documentation Verification (10 minutes)

Verify all documentation is accessible:

- [ ] **README.md**
  - [ ] Claude Code prerequisites visible
  - [ ] Installation instructions clear
  - [ ] Links work
  - [ ] No broken references

- [ ] **QUICKSTART.md**
  - [ ] Prerequisites section present
  - [ ] Installation steps clear
  - [ ] No dead links
  - [ ] Command examples make sense

- [ ] **docs/ directory**
  - [ ] All 32 docs present (run: `ls docs/ | wc -l`)
  - [ ] setup-guide.md accessible
  - [ ] commands-reference.md accessible
  - [ ] technical-overview.md accessible

- [ ] **New launch docs**
  - [ ] RELEASE-NOTES-v0.4.0.md visible
  - [ ] FAQ-AND-TROUBLESHOOTING.md visible
  - [ ] LAUNCH-*.md files present (planning docs)

---

## Framework Validation (5 minutes)

Run self-checks:

- [ ] **Verify command inventory**
  ```bash
  ls templates/commands/*.md | wc -l
  # Should output: 22
  ```

- [ ] **Verify hooks present**
  ```bash
  ls templates/hooks/*.sh | wc -l
  # Should output: 11
  ```

- [ ] **Verify install scripts**
  ```bash
  [ -f install.sh ] && [ -f install.ps1 ] && echo "OK"
  # Should output: OK
  ```

- [ ] **Verify no hardcoded paths**
  ```bash
  grep -r "C:\\Users\|/home/\|/Users/" templates/ --include="*.md" --include="*.sh" --include="*.ps1"
  # Should return: (nothing — clean)
  ```

- [ ] **Verify templates compile**
  ```bash
  [ -f templates/CLAUDE-brainstem.md ] && echo "OK"
  [ -d templates/bundles ] && echo "OK"
  [ -d templates/engrams ] && echo "OK"
  # All should output: OK
  ```

---

## Community Platform Setup (10 minutes)

If applicable, set up community channels:

### GitHub Discussions
- [ ] **Enable Discussions** (Settings → Features)
  - [ ] Check "Discussions"
  - [ ] Save

- [ ] **Create welcome post**
  - Title: "Welcome to JitNeuro"
  - Body: Brief intro, links to docs, contact info

### GitHub Issues
- [ ] **Create issue labels** (Settings → Labels)
  - [ ] `bug` (red) — bugs/defects
  - [ ] `enhancement` (blue) — feature requests
  - [ ] `documentation` (green) — docs improvements
  - [ ] `help-wanted` (orange) — need community input
  - [ ] `good-first-issue` (purple) — for new contributors
  - [ ] `question` (gray) — usage questions

- [ ] **Create initial issues** (optional)
  - [ ] "v0.4.1 Planning" (milestone)
  - [ ] "Known Limitations" (documentation)

### Community Engagement
- [ ] **Prepare Discord/Slack response template**
  - Have response ready for when community mentions JitNeuro
  - Example: "Hey! Check out [link], we're in open beta"

---

## Analytics & Monitoring Setup (5 minutes)

Prepare to track metrics:

- [ ] **GitHub Analytics**
  - [ ] Note starting stars/forks/watchers
  - [ ] Check Analytics tab (if available)
  - [ ] Set baseline metrics

- [ ] **Landing Page Analytics** (if applicable)
  - [ ] Add Google Analytics tracking code (if not already present)
  - [ ] Add Vercel analytics (if using Vercel)
  - [ ] Set up basic dashboards

- [ ] **Monitoring checklist**
  - [ ] Check GitHub issues daily for first week
  - [ ] Monitor comments/discussions
  - [ ] Track external mentions (set up alerts if possible)

---

## Post-Push Communication (5 minutes)

After verification, notify stakeholders:

- [ ] **Share push completion** (internal team)
  - "JitNeuro v0.4.0 pushed to main and tagged"
  - Link to GitHub release

- [ ] **Prepare for community announcement**
  - [ ] Finalize blog post text (if applicable)
  - [ ] Prepare Twitter/social posts
  - [ ] Prepare Discord/Slack messages

- [ ] **Start promotion sequence**
  - [ ] Per LAUNCH-PROMOTION-STRATEGY.md

---

## Quality Assurance Sign-Off

Before considering launch complete, verify:

| Component | Status | Notes |
|-----------|--------|-------|
| Framework consistency | ✅ | All 22 commands, 11 hooks present |
| Documentation | ✅ | README, QUICKSTART, 32 docs complete |
| GitHub setup | ⏳ | Pending push |
| Release notes | ✅ | v0.4.0 release notes prepared |
| FAQ/Troubleshooting | ✅ | Comprehensive guide ready |
| Landing page | ⏳ | Wireframe ready, deploy pending |
| Video script | ✅ | Script complete, recording pending |
| Promotion plan | ✅ | Strategy documented |

---

## Sign-Off

**Push date:** _______________  
**Pushed by:** _______________  
**Verification completed:** _______________  

**Sign off that everything verified:**
```
✅ All checklist items completed
✅ GitHub shows v0.4.0 tag
✅ README renders correctly
✅ Release notes published
✅ No critical issues found
✅ Ready for public announcement
```

---

## Rollback Plan (if needed)

If critical issue found after push:

1. **Stop promotion** (don't announce yet)
2. **Fix issue** on separate branch
3. **Create v0.4.0-hotfix** tag with fix
4. **Or revert** if necessary:
   ```bash
   git revert HEAD  # creates opposite commit
   git push origin main
   ```
5. **Document issue** and postmortem

---

## Next Steps (After Push)

✅ **Push complete**  
→ **Begin post-launch workstreams** (from LAUNCH-PROMOTION-STRATEGY.md):

1. **Day 1:** GitHub setup, cross-post blog
2. **Days 2-3:** Record and upload video
3. **Week 1-4:** Sustained promotion and community engagement
4. **Month 1+:** Monitor metrics, plan v0.4.1

---

**Estimated total time:** 30-45 minutes  
**Owner time required:** 20-30 minutes (rest can be automated or parallelized)  
**Success criteria:** ✅ All items checked off

---

**Status:** Checklist ready. Awaiting Owner approval to execute push.
