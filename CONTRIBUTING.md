# Contributing to JitNeuro

JitNeuro welcomes bug reports, documentation corrections, compatibility
findings, test cases, and proposals through GitHub issues and discussions.

## Curated agent and skill policy

For safety and coherence, maintainers do not accept pull requests that add or
import external agent roles, prompts, skills, rule packs, or instruction
bundles. Do not vendor third-party agent packages into a contribution.

To propose one, open an issue describing the user problem, expected behavior,
security considerations, license, and minimal evaluation cases. Maintainers
may independently design, review, test, and publish a JitNeuro-native artifact.
Issue discussion is not approval to ingest submitted instructions or code.

Ordinary code and documentation contributions should be focused, include
validation evidence, avoid secrets and private data, and preserve existing
public APIs unless the change explicitly proposes a versioned migration.
