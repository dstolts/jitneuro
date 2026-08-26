---
type: doc
purpose: Durable repo-local agent context seeded at <repo>/.agents/context.md so runtime-specific files can stay thin adapters.
tags: [template, agents, local-context, bootstrap, repo-context]
scope: internal
last_evaluated: 2026-06-20
---

# Repo Agent Context

This file is the durable, tool-neutral home for repo-local agent context.

Use this file for context that is specific to this repo and should be available
to Codex, Claude Code, Cursor, and future agent clients. Keep runtime-specific
files such as `AGENTS.md`, `CLAUDE.md`, `.claude/`, and `.cursor/rules/` as
thin adapters that load this file and jit-knowledge.

## What Belongs Here

- Repo-specific architecture notes needed before edits
- Local workflow or verification commands
- Repo-specific service boundaries, deployment notes, and ownership notes
- Links to active Hub, backlog, questions, and local knowledge surfaces

## What Does Not Belong Here

- Secrets, credentials, tokens, PII, or machine-local private paths
- Cross-repo rules that should graduate to jit-knowledge
- Long-lived product knowledge that belongs in `.knowledge/` or domain docs

## Bootstrap Notes

- Shared rules and playbooks live in KnowledgeRoot.
- Repo active work lives in `.hub/hub.md` or `.HUB/Hub.md`, preserving the
  repo's existing hub directory case.
- Owner questions live in the active hub's `questions.md`.
- Peer-agent requests live in the active hub's `agent-inbox.md`.
