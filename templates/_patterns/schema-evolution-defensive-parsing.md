---
type: pattern
purpose: Any engineer writing code that consumes a field from a third-party API or upstream pipeline component must add a multi-format isinstance guard at the consumption point before applying business logic -- firing whenever a new external data source is onboarded or a production crash reveals a type mismatch -- because a single-format assumption produces silent failures when the upstream service changes its schema, which external providers do without coordinating with downstream consumers.
trigger: onboarding a new external data source; OR a production crash with a type-comparison error on an externally sourced field; OR consuming any field from a service with an independent release cycle
read_when: Before writing code that consumes any field from a third-party API or upstream pipeline component with an independent release cycle.
tags: [schema-evolution, defensive-parsing, api-integration, backwards-compatibility, pipeline-resilience]
scope: public
last_evaluated: 2026-06-03
origin: promoted from personal memory (project_jitsecure_assess_fmt.md) -- Knowledge session 2026-06-01
---

# Schema Evolution: Defensive Parsing

## Pattern

When consuming a field from any external service or upstream pipeline component, always write an isinstance/type check that handles at least the prior and current known formats before applying business logic. Do not assume a field type is stable across API versions.

## When to use

- Any field consumed from a third-party API (assessment tools, scoring services, external data providers)
- Any field passed between pipeline stages that have independent release cycles
- After discovering a type crash in production caused by a format change
- When onboarding a new data source where the schema is not under your control

## Steps or structure

1. At the point of consumption (not deep in business logic), read the raw field value.
2. Apply an isinstance check for each known format variant:
   ```python
   raw = data.get("field_name", default_value)
   if isinstance(raw, dict):
       normalized = raw.get("subkey", fallback)
   elif isinstance(raw, (int, float)):
       normalized = float(raw)
   else:
       normalized = fallback
   ```
3. Normalize to a single internal type before passing to business logic.
4. Log or surface unexpected types so format changes are visible rather than silently falling through to the fallback.
5. Document the known format variants and their origin versions in a comment at the parse site.

## Concrete example

An assessment service's JSON `score` field changed from `float` to `dict`:
```
Old: "score": 0.32
New: "score": {"pass": 12, "fail": 26, "partial": 0, "not_assessed": 19, "total": 57, "percentage": 32}
```

Defensive parse:
```python
raw = data.get("score", 0.0)
if isinstance(raw, dict):
    score = raw.get("percentage", 0) / 100.0
else:
    score = float(raw)
```

## Anti-patterns to reject

- Assuming the field type from documentation or one observed sample. APIs change.
- Handling only the current format and treating the old format as "nobody uses it." Old-format data may exist in archives, re-runs, or edge cases.
- Placing the type check deep inside business logic functions where it is harder to maintain and harder to find.

## Origin

A report generator crashed with `'>=' not supported between instances of 'dict' and 'float'` when processing assessment evidence: the upstream assessment service had changed its `score` field format from a float to a dict. Two helper functions both assumed float. Fixed with an isinstance check at the consumption point.

Related: `rules/verify-before-claiming.md`, `rules/proactive-quality.md`.
