# Quality: General Principles

## Correctness
- Handle all edge cases: empty inputs, null/undefined, boundary values
- Validate inputs before use; fail fast with clear error messages
- Check return values and error codes — never silently swallow errors
- Test the actual behavior, not just the happy path

## Reliability
- No race conditions: shared state must be accessed safely
- Resources must be cleaned up (files, connections, timers, listeners)
- Operations that can run multiple times must be idempotent
- External calls must have timeouts and retry limits

## Code Quality
- No dead code (unreachable branches, unused variables, commented-out blocks)
- No hardcoded magic values without named constants
- Logic is self-explanatory or has a comment explaining *why*
