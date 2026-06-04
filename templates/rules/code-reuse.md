---
type: rule
purpose: Prohibit duplicating components or UI logic and require reusing existing components with different data sources to prevent maintenance burden and code divergence.
read_when: Before building a new component, view, or UI element to verify no existing component can be reused with different props or data.
tags: [code-reuse, components, duplication, maintenance, architecture]
scope: public
last_evaluated: 2026-06-03
---
# Code Reuse

## Reuse Components, Never Copy

Do not copy or duplicate components. Reuse the SAME components with different data sources
(props, route params, config).

When adding new data types to dashboards or views, wire existing components to the new data
source. Add a route or config entry, not a parallel set of components.

## Why

Copying creates maintenance burden and code divergence. When a bug is fixed or behavior is
updated in one copy, the other copies silently stay broken. Reusing the same component means
fixing once fixes everywhere.

## How to Apply

1. Before building a new component, search the codebase for an existing one that does the same job with different data
2. If found: pass new data via props or route params -- do not duplicate the component file
3. If not found: build one component designed to accept the data shape as a parameter
4. Never justify duplication with "it's simpler" -- simplicity now = maintenance cost later
