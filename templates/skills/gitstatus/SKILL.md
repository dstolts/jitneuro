---
name: gitstatus
description: Resolve and run the canonical jit-knowledge gitstatus skill for current-repository status, registered cross-repo status, or git hygiene review.
---

# gitstatus

This legacy template intentionally contains no independent gitstatus behavior.
The canonical implementation lives in jit-knowledge so default scope, the
repository registry, and safety rules cannot drift between installations.

Resolve the KnowledgeRoot from `KNOWLEDGE_ROOT`, then `JIT_KNOWLEDGE_ROOT`,
then the installed workspace configuration. Read
`<KnowledgeRoot>/skills/gitstatus/SKILL.md` completely and use its scripts.
