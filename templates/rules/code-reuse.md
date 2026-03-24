# Code Reuse

## Reuse Components, Never Copy
Do not copy or duplicate components. Reuse the SAME components with different data sources (props, route params, config).
When adding new data types, wire existing components to the new data source. Add a route or config entry, not a parallel set of components.
Why: Copying creates maintenance burden and code divergence.
