# POPULATE-HORIZON -- Interview Instructions for Claude

## Purpose

This file tells a Claude session how to interview the adopter and populate the
horizon template files. When the adopter asks you to "set up the horizon layer",
"populate my horizon files", or "run the horizon onboarding", follow this guide.

## Core Rules for the Interview

1. Ask ONE topic at a time. Do not dump all questions at once.
2. Listen and write. Do not invent answers. If the adopter is unsure, offer 2-3
   concrete example options for them to react to -- do not fill in a blank with
   a guess.
3. After each topic, confirm you understood correctly before moving on.
4. When all topics are done, summarize what was captured and ask the adopter to
   confirm or adjust before saving.
5. Write answers into the corresponding horizon/*.md file by replacing the
   [FILL IN] markers. Preserve the file structure; replace only the placeholder
   lines and the blank lines immediately below them.
6. If the adopter skips a section ("I don't know yet" or "skip this"), leave the
   [FILL IN] marker in place and note it in your summary as "skipped -- fill in
   later".

## Interview Sequence

Work through the files in this order. Complete each file before starting the next.

---

### File 1: vision.md

Ask these questions in order. Wait for an answer before asking the next one.

1. "Where do you want this venture to be in 3-5 years? What does the world look
   like once you have succeeded? Even a rough direction is useful."

2. "What are 2-4 specific signals that would tell you, without any doubt, that you
   have won? Think revenue, customers, market position, team capability -- whatever
   matters most to you."

3. "What are you explicitly NOT trying to become? List the directions you have
   already ruled out."

4. "In one or two sentences, what is the central bet this venture is making --
   the thing that must be true for your strategy to work?"

5. "What is the single number you would use to tell if the venture is on track?
   Not a vanity metric -- the one you actually care about."

After gathering answers: "Let me confirm what I heard for your vision..." then
summarize and ask for a thumbs up before writing the file.

---

### File 2: mission.md

1. "Who is your primary customer? Be specific -- not just 'small businesses' but
   what kind, what role, and what problem brings them to you."

2. "What is the core outcome or deliverable your customer gets? Describe the end
   result, not a feature list."

3. "Why does this work matter beyond the transaction? What larger purpose or
   impact keeps you doing it?"

4. "List 3-5 principles that govern HOW you do the work -- how you make decisions,
   how you treat customers, what you refuse to do even if it would make money."

5. "In 1-3 sentences, what separates your approach from the obvious alternatives
   a customer might consider?"

---

### File 3: goals.md

1. "What are the top 3 things that matter most to you right now -- the things you
   would focus on exclusively for the next 90 days if you had to drop everything
   else?"

2. "For each of those 3 priorities, what is the specific number or condition that
   tells you it is done?"

3. "Narrowing further: what specifically needs to happen in the next 8-12 weeks?"

4. "What are 2-4 things that might seem like good ideas but are explicitly NOT on
   your plate right now? Name them so I know to avoid recommending work in those
   areas."

5. "What hard constraints shape what is possible for you -- time, budget, team
   size, technical debt, regulatory, anything that is fixed for now?"

---

### File 4: operating-rhythm.md

1. "Walk me through a typical working day -- when you start, when you are in deep
   work, when you are available for review, when you stop. Even a rough sketch."

2. "When and how do you do a weekly review? What would be most useful for me to
   prepare for it, and in what format?"

3. "When you are not actively in a session, how do you want to be kept informed?
   What triggers an update vs. silence?"

4. "Give me a simple rule of thumb: when should I stop and ask you vs. proceed on
   my own? What makes something worth interrupting you for?"

5. "How do you want information presented -- short or detailed, bullets or prose,
   recommendation first or context first?"

6. "What tools are you working in daily, and where should I create artifacts?
   Are there any systems I should never touch without explicit permission?"

---

### File 5: decision-routing.md

1. "Think about the actions I might take on your behalf. What can I do completely
   on my own without telling you -- the truly low-stakes, fully reversible things?"

2. "What should I proceed with but report on at the next natural checkpoint --
   things you want to know happened but do not need to approve in advance?"

3. "What requires your explicit approval every single time, no exceptions -- the
   hard stops?"

4. "How can you signal mid-session that I should proceed on something I would
   normally stop for? And how can you signal that I should be more cautious than
   usual?"

5. "Are there any categories where the trust level changes based on environment --
   for example, staging vs. production, or internal docs vs. customer-facing?"

---

### File 6: owner-profile.md

1. "Tell me about your professional background. What should I assume you already
   know deeply? Where should I slow down and explain?"

2. "How do you prefer to work -- fast and iterative, or thorough before committing?
   How do you typically make decisions under uncertainty?"

3. "How do you want me to communicate with you -- length, format, tone, lead with
   answer or context first?"

4. "Are there focus or attention patterns I should accommodate? For example, how
   you handle context-switching, how you prefer tasks chunked."

5. "What AI behaviors frustrate you most? What do I need to avoid from the start?"

6. "What AI behaviors do you find genuinely useful and want more of?"

7. "Any other context -- schedule realities, OS or tool preferences, anything that
   does not fit the questions above?"

---

## After All Files Are Complete

Deliver a summary in this format:

```
Horizon files populated. Here is what was captured:

vision.md: [one sentence summary of what was filled in]
mission.md: [one sentence summary]
goals.md: [one sentence summary]
operating-rhythm.md: [one sentence summary]
decision-routing.md: [one sentence summary]
owner-profile.md: [one sentence summary]

Skipped (still has [FILL IN] markers): [list any skipped sections]

Does this look right? Say "confirmed" to finalize, or tell me what to adjust.
```

Do not write the files until the adopter confirms. After confirmation, write all
files, then say:

"Horizon layer is live. Your AI sessions will now load this context at startup.
To update any file, edit it directly or ask me to update it based on new direction
you describe."
