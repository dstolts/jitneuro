# JitNeuro Landing Page (jitneuro.ai) — Content Requirements

**Status:** Ready for build  
**Target Platform:** Vercel (via Lovable or custom)  
**DNS:** jitneuro.ai  

---

## Content Sections

### 1. Hero Section
**Goal:** Capture attention and communicate core value in 5 seconds

**Copy:**
- **Headline:** "Endless Auto-Recall Memory for Claude Code"
- **Subheading:** "Stop re-explaining your project. Save once, Claude learns forever."
- **CTA Button:** "Get Started" → github.com/dstolts/jitneuro

**Visuals Needed:**
- Background: Neural network diagram or memory map illustration
- Hero image: Claude Code interface with /save and /load command visible

---

### 2. Problem Section
**Goal:** Validate user pain point

**Copy (from README):**
> Claude Code forgets everything every time you clear context. Every `/clear` is amnesia. Every new terminal is a stranger. You re-explain your project, your stack, your sprint status -- every session.

**Visuals:**
- Show repetition/cycle (re-explaining same info multiple times)
- Animation: Context being lost on /clear

---

### 3. Solution Section
**Goal:** Show how JitNeuro solves the problem

**Key Points:**
- **Do more, faster** — stop re-explaining, start working in seconds
- **Security without effort** — trust zones and branch protection from install
- **Low risk** — markdown files and bash scripts, nothing to break
- **Compounds over time** — /learn makes Claude better at your work daily

**Visuals:**
- Feature cards with icons (speedometer, lock, document, growth)

---

### 4. How It Works (Day 1-30 Timeline)
**Goal:** Show progressive value realization

**Content:** Direct from README "How It Grows With You" section

| Timeline | Capability | Example |
|----------|-----------|---------|
| Day 1 | Save/Load sessions | `/save my-task` → `/load my-task` |
| Day 3 | Autosave on demand | "auto-save every 30 min" → agent created |
| Day 7 | Multi-repo orchestration | "keep Hub.md updated" → enforcer agent |
| Day 14 | Dashboard visibility | "show me all sessions" → dashboard appears |
| Day 30 | Autonomous agents | Nightly audits, Stripe monitoring, triaging |

**Visuals:**
- Animated timeline showing features activating
- Or: Screenshot carousel of each day's capability

---

### 5. Architecture/Under the Hood
**Goal:** Build credibility with technical audience

**Content:**
- **DOE (Directive Orchestration Execution)** pattern overview
- **Context Budget Comparison:**
  - JitNeuro: 3-4% of session budget (bundles + engrams + routing)
  - Monolithic context: 10%+ of budget
  - Savings: 6-7% freed for actual work

**Key Concepts:**
- **Bundles:** Domain knowledge files loaded on-demand
- **Engrams:** Per-project deep context (50-150 lines)
- **Routing Weights:** Smart trigger patterns in MEMORY.md
- **/learn:** Command that persists feedback as permanent rules

**Visuals:**
- Architecture diagram:
  ```
  User Input
     ↓
  [Routing Engine] ← MEMORY.md (weights)
     ↓
  [Bundle Loader] ← domain knowledge
     ↓
  [Claude] + [Engrams] + [Rules]
     ↓
  Output
  ```

---

### 6. Enterprise Section
**Goal:** Show value for teams/orgs

**Content:**
- **Holistic Review:** Multi-agent orchestration with governance
- **Ralph Integration:** Enterprise context isolation and scaling
- **Multi-Repo Orchestration:** Sync context across codebases
- **Trust Zones:** GREEN (unrestricted), YELLOW (notify), RED (block)

**Visuals:**
- Enterprise topology diagram (master/sub-orchestrator/worker structure)

---

### 7. Tech Stack Callout
**Goal:** Show simplicity and portability

**Content:**
- Built on: Markdown + Bash + Claude Code
- No external dependencies, no databases, no servers
- Install once, use everywhere (user/workspace/project modes)
- Fully open source (MIT license)

---

### 8. Quick Start Section
**Goal:** Lower friction for first-time users

**Content:**
```bash
git clone https://github.com/dstolts/jitneuro.git
cd jitneuro
./install.sh user
```

**Then:** `/save`, `/load`, `/learn` — that's it.

**Link:** "See QUICKSTART.md for detailed walkthrough"

---

### 9. Links Section
**Goal:** Route visitors to resources

**Navigation:**
- **GitHub:** github.com/dstolts/jitneuro
- **Docs:** github.com/dstolts/jitneuro/tree/main/docs
- **QUICKSTART:** github.com/dstolts/jitneuro/blob/main/QUICKSTART.md
- **Blog:** [link to blog post]
- **Video:** [link to YouTube walkthrough when ready]

---

### 10. About/Author Section
**Goal:** Build personal connection and credibility

**Content:**
- Author name, role/background
- Why JitNeuro was built
- How to contact/follow
- Link to personal site if applicable

**Note:** Keep generic enough for forks/adoption by others (use "author" not specific name)

---

### 11. Badge/Credibility
**Goal:** Show validation

**Badges to include:**
- #FirstMover badge (when available)
- GitHub stars count (dynamic)
- MIT License badge
- "Works with Claude Code" badge

---

## Design Notes

**Color Palette:**
- Primary: Claude brand color (indigo/purple)
- Secondary: Neutral grays for contrast
- Accent: Green for "go/ready" states, Red for "caution"

**Typography:**
- Clear hierarchy (H1 > H2 > body)
- Code blocks with syntax highlighting (Markdown, Bash, JSON examples)

**Responsive:**
- Mobile-first (80%+ traffic is mobile)
- Tablet-optimized
- Desktop-enhanced

**Performance:**
- Minimal JavaScript (avoid heavy frameworks if possible)
- Optimize images (diagrams, screenshots)
- Fast load time (<3s target)

---

## Build Path

1. **Use Lovable** to generate initial build from this spec
2. **Add custom sections** (architecture diagram, timeline animation)
3. **Test on GitHub** (readme still primary, landing page is secondary)
4. **Deploy to Vercel** with jitneuro.ai DNS
5. **Mobile responsiveness check** across devices
6. **Monitor** for accessibility (WCAG 2.1 AA target)

---

## Dependency

Landing page can be built once main branch is pushed and jitneuro.ai domain is ready. No blocking dependencies other than Lovable access/availability.
