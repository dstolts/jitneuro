# Changelog

Notable changes to JitNeuro's licensing and repository-wide governance are
recorded here. Feature-level release notes live in the versioned
`RELEASE-NOTES-vX.Y.Z.md` files at the repo root.

## Unreleased

### Changed -- Relicensing (decision LIC-001)

- **License changed from MIT to a split Apache-2.0 (code) + CC BY 4.0
  (docs/content) license.** Both licenses remain fully open-source
  (OSI-approved / Creative Commons) and add an explicit, legally
  enforceable attribution requirement that MIT did not provide.
  - `LICENSE` -- full, verbatim Apache License, Version 2.0 text
    (https://www.apache.org/licenses/LICENSE-2.0.txt), applying to all
    code (scripts, hooks, installers).
  - `NOTICE` -- Apache-2.0 Section 4(d) attribution notice for JitNeuro,
    copyright Just In Time AI INC.
  - `LICENSE-docs` -- Creative Commons Attribution 4.0 International
    (CC BY 4.0), applying to documentation and content (`*.md` files,
    `docs/`, `templates/*.md`, and other non-executable content).
  - SPDX-License-Identifier + copyright headers added to source files
    (shell, PowerShell, and JavaScript scripts).
- Relicensing is possible without contributor consent because the sole
  copyright holder of this repository's history is Just In Time AI INC;
  no third-party contributions with independent copyright exist as of
  this change.
- No runtime dependencies (no `package.json` or equivalent manifest) --
  dependency-compatibility check found nothing to reconcile against
  Apache-2.0.

## 2026-08-26
- Relicensed: code and docs unified under the MIT License (was Apache-2.0 + CC BY 4.0). Simpler adoption, one license for everything.
- Completed the MIT relicense mechanically: executable SPDX headers now identify MIT, and the obsolete split-license `LICENSE-docs` and Apache/CC attribution `NOTICE` files were removed.
