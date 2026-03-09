# JitNeuro Quickstart -- Testing the System

This is your practice guide. Run through these scenarios to validate
the system works before publishing.

## What's Deployed

Your workspace (D:\Code\) already has JitNeuro installed:

```
D:\Code\.claude\
  bundles\           5 bundles (active-work, aibm, blog, infrastructure, integrations)
  skills\            5 skills (save, resume, orchestrate, sessions, conversation-log)
  context-manifest.md   routing weights + bundle index
  session-state\        empty, ready for saves
```

MEMORY.md is 90 lines (was 224). All detail lives in bundles.

---

## Test 1: Routing Weights (Does Claude load the right bundle?)

Start a new session from D:\Code\. Try these prompts and watch what Claude reads:

```
"What's the AIBM pricing?"
```
Expected: Claude reads .claude/bundles/aibm.md, answers from the bundle.

```
"Where were we on the blog comments sprint?"
```
Expected: Claude reads .claude/bundles/active-work.md, reports sprint status.

```
"What port does AIFieldSupport-App run on?"
```
Expected: Claude reads .claude/bundles/infrastructure.md, answers 3002.

**Pass criteria:** Claude loads the right bundle without being told which one.
If it doesn't, the routing weights in MEMORY.md need tuning.

---

## Test 2: Save / Clear / Resume

### Step 1: Do some work
Start working on anything (or just have a conversation with context).

### Step 2: Save
```
/save jitneuro-test
```
Expected:
- Claude asks to confirm the name (or uses yours)
- Writes to .claude/session-state/jitneuro-test.md
- Reports: task, repos, bundles, "Safe to /clear"
- File is 30-60 lines

### Step 3: Verify the file
```powershell
cat D:\Code\.claude\session-state\jitneuro-test.md
```
Check: Does it capture what you were doing? Modified files? Next steps?

### Step 4: Clear
```
/clear
```
Context is gone. Claude knows nothing about what you were doing.

### Step 5: Resume
```
/resume jitneuro-test
```
Expected:
- Claude reads session-state/jitneuro-test.md
- Loads the bundles listed in the save
- Reports: task, repos, loaded bundles, next steps
- Picks up where you left off

**Pass criteria:** After resume, Claude knows what you were doing and can continue.

---

## Test 3: Sessions List

After creating a couple saves (even fake ones), try:

```
/sessions
```
Expected: Table showing all session files with age, task, repos.

---

## Test 4: Multiple Sessions (Simulates 6 terminals)

Create saves for different tasks:

```
/save aibm-pricing-review
```
(do some AIBM work, then save)

```
/save blog-post-draft
```
(switch to blog work, then save)

```
/sessions
```
Expected: Both sessions listed, no collision, each has its own state.

Then resume one:
```
/resume aibm-pricing-review
```
Expected: Loads AIBM context, not blog context.

---

## Test 5: Conversation Logging (Optional)

```
convlog on jitneuro-test
```
Expected: Creates .logs/YYYYMMDD-HHMMSS-jitneuro-test.md

Ask a few questions. Then:
```
convlog status
```
Expected: Shows logging on, file path, prompt count.

```
convlog off
```

Check the log file -- should have your prompts + response summaries.

---

## Test 6: Cross-Repo Session

Start work that touches two repos (e.g., discuss an API change that affects frontend):

```
/save api-frontend-auth-fix
```
Expected: Session file lists BOTH repos under "Repos Involved."

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Claude doesn't load a bundle | Check routing weights in MEMORY.md -- does the trigger word match? |
| Save too short (<20 lines) | Claude may not have enough context yet -- work more before saveing |
| Save too long (>80 lines) | Skill says 30-60 lines target -- Claude should summarize, not replay |
| /resume loads wrong bundles | Check the session file -- are the right bundles listed? |
| /sessions shows nothing | No saves created yet -- run /save first |
| Skills not recognized | Verify .claude/skills/ directory has the .md files |

---

## After Testing

Once you're confident:
1. Clean up test sessions: `/sessions clean` or delete .claude/session-state/*.md
2. Push to GitHub (ask Claude -- RED zone)
3. Record the video using these same test scenarios as the demo script
