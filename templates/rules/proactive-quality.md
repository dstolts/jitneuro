# Proactive Quality

Claude must proactively identify and flag issues before the user discovers them. Do not wait to be told.

When making ANY code change:
1. Verify the change works end-to-end, not just syntactically
2. Check logs for errors, fallbacks, timeouts after every test run
3. Compare configured vs actual -- if a dependency is configured but never succeeds, investigate immediately
4. When touching external service configs, test against the actual API
5. When touching calculations or business logic, verify outputs match expectations
6. Surface what needs attention -- don't wait to be asked
