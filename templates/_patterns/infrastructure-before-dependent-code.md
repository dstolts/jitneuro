---
type: pattern
purpose: Binding build-sequencing pattern for any multi-part system; build the testable infrastructure (runner, skill, data source, API) BEFORE the code that depends on it, so the dependent code can be exercised against real infrastructure as it is built rather than against assumptions.
read_when: Before starting implementation of any component that depends on a shared runner, API, data source, or service not yet built.
tags: [build-sequencing, infrastructure-first, testability, system-design, recursive-improvement]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---

# Infrastructure Before Dependent Code

When building a multi-part system, build the testable infrastructure first --
the runner, the skill, the data source, the API endpoint -- before the code
that consumes it. The dependent code is then exercised against real
infrastructure as it is written, not against assumptions that fail at
integration time.

## Rule

Given a system where component B depends on component A:

1. Build and verify A first, to the point where it produces real, observable
   output (a deployed endpoint, a runnable script, a populated table).
2. Only then build B. B is tested against A's real output from its first line.
3. If A cannot be built first for a hard reason, build the smallest real stub
   of A that produces observable output -- never a mock B trusts blindly.

## Why

When the dependent code is built first, it is tested against assumptions about
infrastructure that does not exist yet. The assumptions are discovered to be
wrong only at integration -- the most expensive point to find them.

Origin: the recursive-improvement loop. WS4 (the knowledge-router runner) was
never built, so WS8 (the dashboard that consumes its data) had no data to test
against, and every captured lesson defaulted to local volatile memory instead
of routing anywhere. Building WS4 first is what made WS8 testable. The data the
runner produces is exactly the data the dashboard needs.

## How to apply

- In a plan or spec, order the work so infrastructure precedes consumers.
- Treat "the consumer has nothing real to test against" as a planning defect,
  not an acceptable interim state.
- A stub that produces observable output beats a mock the consumer trusts.

## Origin

2026-05-21, recursive-improvement loop build (Knowledge-Master session).
