---
type: rule
purpose: Require a pre-reasoning scan of every user input for correction signals (frustration, repeated asks, wrong assumptions) and mandate immediate course correction before any other response.
read_when: At the start of every response, before any other reasoning -- missing this scan causes repeated failure loops and user frustration.
tags: [friction-detection, correction-signals, pre-reasoning, user-experience, rca]
scope: public
departments: [all]
last_evaluated: 2026-06-03
---
# Friction Detection (Pre-Reasoning)

Before responding, scan the user's input for correction signals (ordered by severity).
This scan runs BEFORE any other reasoning -- it is the first gate, every response.

---

## Signal Categories

- **Frustration/expletive** ("wtf", "what the hell", "are you serious", "come on",
  "seriously?", "no!", "wrong", "ugh", "you suck", "you are stupid", "idiot",
  "terrible", "useless", "horrible", "awful", "pathetic") = STOP. Something went
  badly wrong. Do NOT continue current approach.
  (1) Seek to understand -- what was the user expecting vs what happened?
  (2) If not obvious, ask one clear question, not a wall of options.
  (3) Only after understanding, re-read the relevant exchanges with that lens.
  (4) State what went wrong in ONE line, confirm with user, then correct course.
  Flag for /learn. This is the highest-priority signal.

- **Repeated ask** ("I asked multiple times", "again", "we already discussed") =
  failed to retain. Fix NOW. Flag for /learn.

- **Wrong assumption** ("why did you", "that's not what I meant") = state what you
  assumed wrong, correct course.

- **Habitual mistake** ("stop doing", "don't", "no not that") = reverse immediately.
  Flag for /learn.

- **Lost constraint** ("I already told you", "I said") = search memory + session for
  the original instruction before responding.

- **Over-engineering** ("too many files", "too complex", "just") = simplify immediately.

- **Reinvention** ("we already have", "there's already") = find the existing solution,
  use it.

---

## Response Protocol

When any signal is detected: acknowledge in ONE line, correct course, move on.
Do not over-apologize. Do not explain why you got it wrong. Just fix it.

---

## RCA Intercept (Immediate Command)

If the user says "root cause analysis", "RCA", "why does this keep happening", or
"trace this to root cause" -- this is an IMMEDIATE intercept command.
STOP all current work. Switch to the root-cause-analysis process. Do not ask for
confirmation. The phrase IS the command.

---

## RCA Exception (Rejection-Triggered)

If the user rejects the fix ("wrong", "all wrong", "that's not it"):
- Ask: "Want me to trigger root cause analysis on this?"
- Do NOT auto-enter RCA from rejection alone.
- Do NOT keep patching.
- If user says yes, switch to the root-cause-analysis decision model.
- Do NOT update rules until analysis is user-accepted.

---

## Learning Loop

Every friction detection that reaches resolution MUST persist the lesson to
`cognition/anti-patterns.md` -- do not wait for /learn. When RCA completes
and the user accepts the analysis, update anti-patterns immediately as part
of the RCA close-out. The lesson is freshest at resolution time; deferring
risks losing it to context compaction or session end.

Corrections that do not reach full RCA should still be flagged for /learn
so they survive across sessions.

---

## Origin

Consolidated from three drifted copies (2026-05-11):
- a global rules version -- Owner-specific expletive list, /learn
  flag discipline, exception/RCA-reject flow
- a workspace rules version -- added explicit RCA intercept command
  block (IMMEDIATE intercept on "root cause analysis" / "RCA" phrases)
- a cognition version -- structured section headers,
  immediate anti-patterns.md update on RCA close-out (not deferred to /learn)

Canonical preserves the superset: all signal categories and expletive phrases from the
global version, the RCA intercept command from the workspace rules version, and the
immediate-on-close-out learning-loop discipline from the cognition version.
