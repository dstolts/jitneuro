# JitNeuro Landing Page — Wireframe & Asset Specifications

**Status:** Ready for Lovable build  
**Target:** Single-page scrolling site  
**Mobile-first:** 80%+ responsive design  

---

## Page Layout (Desktop 1920px, Mobile 375px)

### 1. Navigation Bar (Sticky)
```
[JitNeuro Logo]  [GitHub] [Docs] [Blog] [Get Started →]
```
- Height: 60px
- Background: Semi-transparent (fade on scroll)
- CTA button: Solid brand color, right-aligned

### 2. Hero Section (Full viewport)
```
┌─────────────────────────────────────────────────────┐
│                 [Background: Neural net diagram]     │
│                                                      │
│         HEADLINE (72px):                           │
│    "Endless Auto-Recall Memory                     │
│        for Claude Code"                            │
│                                                      │
│    SUBHEADING (24px):                              │
│    "Stop re-explaining your project.               │
│     Save once, Claude learns forever."             │
│                                                      │
│              [Get Started Button]                   │
│              [Watch Demo Video]                     │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Visuals:**
- Background: Animated neural network (subtle movement)
- Logo: Top-left corner, white on transparent
- CTA buttons: 2 side-by-side (primary + secondary)

**Responsive (Mobile):**
- Stack vertically
- Reduce headline to 48px
- Center-align buttons

---

### 3. Problem Section
```
┌─────────────────────────────────────────────────────┐
│  SECTION TITLE: "The Problem"                      │
│  (48px, left-aligned)                              │
│                                                      │
│  COPY (20px, 3-line max):                          │
│  "Claude Code forgets everything after /clear.     │
│   Every context reset is amnesia. Every new        │
│   session means re-explaining your entire project" │
│                                                      │
│  [Visual: 2-col grid showing repetition]           │
│  Left column: "Session 1" → explain context        │
│  Right column: "Session 2" → explain again         │
│  (Red arrow: "Context Lost")                       │
│                                                      │
│  Pain points (bulleted):                           │
│  • Re-explain project architecture                 │
│  • Repeat stack decisions                          │
│  • Restore sprint status                           │
│  • Rebuild team context                            │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Visuals:**
- Two-column comparison (before/after)
- Animation: Context fading on /clear

**Color:** Red accent for pain, gray for lost context

---

### 4. Solution Section (4 Feature Cards)
```
┌──────────────────────────────────────────────────────┐
│  SECTION TITLE: "The Solution"                       │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │   [ICON]     │  │   [ICON]     │                 │
│  │ DO MORE,     │  │ SECURITY     │                 │
│  │ FASTER       │  │ WITHOUT      │                 │
│  │ Stop         │  │ EFFORT       │                 │
│  │ re-explain   │  │ Trust zones  │                 │
│  │ Build in     │  │ Branch       │                 │
│  │ seconds      │  │ protection   │                 │
│  └──────────────┘  └──────────────┘                 │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │   [ICON]     │  │   [ICON]     │                 │
│  │ LOW RISK     │  │ COMPOUNDS    │                 │
│  │ Markdown +   │  │ OVER TIME    │                 │
│  │ Bash only    │  │ /learn makes │                 │
│  │ Remove any   │  │ Claude       │                 │
│  │ time         │  │ smarter each │                 │
│  │              │  │ day          │                 │
│  └──────────────┘  └──────────────┘                 │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Card Specifications:**
- 300px x 300px (desktop), 100% width (mobile)
- White background with subtle shadow
- Icon: 80px x 80px, brand color
- Title: 20px bold
- Body: 16px, gray text

**Responsive:** 2x2 grid desktop, 1-column mobile

---

### 5. How It Grows Timeline
```
┌──────────────────────────────────────────────────────┐
│  SECTION TITLE: "How It Grows With You"              │
│                                                       │
│  Vertical Timeline (left-to-right on desktop):       │
│                                                       │
│  DAY 1                      DAY 3         DAY 7       │
│  ●────────────────────●─────────────●   DAY 14      │
│  │                    │              │     │    DAY 30│
│  Install              Auto-save       │     │     ●    │
│  /save                Agent           │     │    /audit│
│  /load                             Multi-   │   Stripe │
│                                     repo     │   monitor│
│                                  sync    Dashboard     │
│                                                       │
│  [Animated: each day activates in sequence]          │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Timeline Specifications:**
- Horizontal on desktop (5 points)
- Vertical on mobile (stack)
- Interactive: Click day → expand description
- Animation: Circle pulse on each milestone

**Colors:** 
- Completed days: Solid brand color
- Future days: Faded gray

---

### 6. Architecture Section
```
┌──────────────────────────────────────────────────────┐
│  SECTION TITLE: "Under the Hood"                     │
│                                                       │
│  Two-column layout:                                  │
│                                                       │
│  LEFT: Diagram (ASCII concept)                       │
│  ┌─────────────────────────────────┐                │
│  │  User Input                     │                │
│  │       ↓                          │                │
│  │  [Routing Engine]               │                │
│  │  (MEMORY.md weights)            │                │
│  │       ↓                          │                │
│  │  [Bundle Loader]                │                │
│  │  (domain knowledge)             │                │
│  │       ↓                          │                │
│  │  [Claude] + [Engrams] + [Rules] │                │
│  │       ↓                          │                │
│  │  Better Output                  │                │
│  └─────────────────────────────────┘                │
│                                                       │
│  RIGHT: Callouts (3 boxes)                          │
│  ┌─────────────────┐                                │
│  │ Bundles         │ Domain knowledge files         │
│  │ Smart routing   │ loaded on-demand               │
│  └─────────────────┘                                │
│  ┌─────────────────┐                                │
│  │ Engrams         │ Per-project deep context       │
│  │ (50-150 lines)  │ persists learning              │
│  └─────────────────┘                                │
│  ┌─────────────────┐                                │
│  │ /learn command  │ Feedback becomes permanent     │
│  │ Permanent rules │ patterns in 24h                │
│  └─────────────────┘                                │
│                                                       │
│  CALLOUT BOX:                                       │
│  "Context Budget: 3-4% (vs 10%+ monolithic)"       │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Visuals:**
- Left: SVG architecture diagram (animated flow)
- Right: 3 stacked callout boxes
- Color: Gray diagram, brand color for highlights

**Responsive:** Stack vertically on mobile

---

### 7. Enterprise Section
```
┌──────────────────────────────────────────────────────┐
│  SECTION TITLE: "Built for Enterprise"               │
│                                                       │
│  Dark background (contrast)                          │
│                                                       │
│  3 Feature Cards:                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Holistic │  │ Ralph    │  │ Multi-   │           │
│  │ Review   │  │ Integration
   │ Repo     │           │
│  │          │  │        │  │ Sync     │           │
│  │Multi-    │  │        │  │          │           │
│  │agent     │  │Enterprise  │ Sync   │           │
│  │orch.    │  │context  │  │context  │           │
│  │          │  │isolation  │across   │           │
│  └──────────┘  └──────────┘  └──────────┘           │
│                                                       │
│  TRUST ZONES callout (right side):                   │
│  GREEN: Unrestricted work                           │
│  YELLOW: Notify on action                           │
│  RED: Block and alert                               │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Background:** Dark (navy or black)  
**Text:** White/light  
**Accent:** Green for features

---

### 8. Tech Stack Section
```
┌──────────────────────────────────────────────────────┐
│  SECTION TITLE: "Simple & Portable"                  │
│                                                       │
│  Built on:                                           │
│  ┌─────────────────────────────────────────┐        │
│  │ Markdown  +  Bash  +  Claude Code       │        │
│  │                                          │        │
│  │ No external dependencies                │        │
│  │ No databases. No servers.               │        │
│  │ Install once. Use everywhere.           │        │
│  │                                          │        │
│  │ 📦 Fully open source (MIT License)      │        │
│  └─────────────────────────────────────────┘        │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Style:** Large, bold typography on white  
**Color:** Gray text, brand color for emoji/accents

---

### 9. Quick Start Section
```
┌──────────────────────────────────────────────────────┐
│  SECTION TITLE: "Get Started in 3 Steps"             │
│                                                       │
│  Code block (dark background):                       │
│  $ git clone https://github.com/dstolts/jitneuro   │
│  $ cd jitneuro                                      │
│  $ ./install.sh user                                │
│                                                       │
│  Then:  /save   /load   /learn                      │
│                                                       │
│  [Link button: "See detailed QUICKSTART →"]          │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Code block:** Monospace, syntax highlighting, copy button

---

### 10. Resources / Links Section
```
┌──────────────────────────────────────────────────────┐
│  "Learn More"                                         │
│                                                       │
│  [GitHub] [Docs] [Blog] [QUICKSTART] [Email]        │
│                                                       │
│  Grid of link buttons (icon + text)                  │
│                                                       │
└──────────────────────────────────────────────────────┘
```

---

### 11. Footer
```
┌──────────────────────────────────────────────────────┐
│  JitNeuro — Endless Auto-Recall Memory               │
│  MIT License | Built for Claude Code                │
│                                                       │
│  © 2026 [Author]. Not affiliated with Anthropic.   │
│                                                       │
│  [GitHub] [Twitter] [LinkedIn] [Contact]            │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Background:** Dark  
**Text:** Gray  
**Links:** Underlined on hover

---

## Asset Checklist

### Images Needed
- [ ] Neural network background (SVG or subtle animation)
- [ ] Claude Code interface screenshot (showing /save command)
- [ ] Architecture diagram (SVG)
- [ ] Problem scenario visual (repetition cycle)
- [ ] Enterprise topology diagram
- [ ] Feature card icons (4x: speedometer, lock, document, growth)
- [ ] OG image for social sharing (1200x630px)

### Animations (Optional but Recommended)
- [ ] Neural network background: subtle pulse/flow
- [ ] Hero CTA buttons: hover glow
- [ ] Timeline: day-by-day activation sequence
- [ ] Architecture diagram: data flow animation
- [ ] Feature cards: stagger in on scroll

### Color Palette

| Role | Color | Usage |
|------|-------|-------|
| Primary (Brand) | #6366F1 | Buttons, accents, headlines |
| Secondary | #EC4899 | Emphasis, highlights |
| Background | #FFFFFF | Main body |
| Dark BG | #1F2937 | Enterprise section, footer |
| Text Primary | #111827 | Headlines, body text |
| Text Secondary | #6B7280 | Meta, descriptions |
| Success | #10B981 | Trust zones (GREEN) |
| Warning | #F59E0B | Trust zones (YELLOW) |
| Error | #EF4444 | Trust zones (RED) |

### Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| H1 (Hero) | Inter/System | 72px | 700 |
| H2 (Section) | Inter/System | 48px | 700 |
| H3 (Card) | Inter/System | 20px | 600 |
| Body | Inter/System | 16px | 400 |
| Code | Courier/Mono | 14px | 400 |

---

## Mobile Responsiveness Breakpoints

| Breakpoint | Width | Adjustments |
|-----------|-------|-------------|
| Mobile | 375-568px | Stack sections, 1-col cards, smaller fonts |
| Tablet | 768-1024px | 2-col cards, medium fonts |
| Desktop | 1024px+ | Full layout as designed |

---

## Build Tools Recommendation

**For Lovable:**
- Drag-drop sections from this wireframe
- Use color palette above
- Import SVG diagrams from templates/
- Add animations via Lovable motion editor

**For Custom Build:**
- Use Next.js or Astro for performance
- Tailwind CSS for styling
- Framer Motion for animations
- Vercel for hosting

---

**Status:** Ready for designer/Lovable. All sections defined, assets listed, responsive breakpoints specified.
