# Testing: Critical Path, Not Happy Path

Always test the critical path -- the flow every user hits every time.
"Happy path" testing validates the easiest scenario and misses real failures.

## Principle

Identify the critical path first, then ensure e2e and integration tests cover
every step of it, including intermediate delivery mechanisms (streaming, SSE,
websockets, polling) -- not just final results.

## Why

Production failures hide in the untested middle. When e2e tests only check
trigger-to-result and skip the delivery layer that every user traverses,
bugs in that layer go undetected until production.

## How to Apply

1. Before writing tests, define the critical path for the feature.
2. Map each step in that path -- entry point, processing, delivery mechanism, result.
3. Test each step, not just the entry and exit points.
4. If a delivery mechanism (streaming, polling, websocket, SSE) is part of the critical path, it needs dedicated test coverage.
5. If an intermediate service or layer sits between trigger and result, test that layer independently.

## Anti-Pattern

```
[trigger] --> ... untested middle ... --> [result check]
```

Tests pass. Production crashes in the middle. Nobody knows until users report it.

## Correct Pattern

```
[trigger] --> [processing test] --> [delivery test] --> [result check]
```

Every segment of the critical path has coverage.
