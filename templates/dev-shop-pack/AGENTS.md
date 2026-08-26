# AGENTS.md -- Dev Shop Pack Router

Select the narrowest role that owns the requested outcome and load its nearest
`AGENTS.md`. For cross-domain changes, use `tech-lead-architect` to define
boundaries, then dispatch implementation to each owning role.

Every role must:

- inspect repository instructions before changing files;
- work on a feature branch and respect repository protection rules;
- write only within its declared domain;
- report out-of-domain findings to the owning role;
- provide commands and evidence for validation performed;
- never expose, fabricate, or commit credentials or private data.

Customer-facing work follows [validation-chain.md](validation-chain.md).
