# Quality Principles

## Correctness
- Handle edge cases: empty inputs, null/undefined, boundary values
- Validate inputs before use; fail fast with clear error messages
- Check return values — never silently swallow errors
- Test actual behavior, not just the happy path

## Reliability
- No race conditions: shared state must be accessed safely
- Resources must be cleaned up (files, connections, timers, listeners)
- Operations that can run multiple times must be idempotent
- External calls must have timeouts and retry limits

## Performance
- No N+1 queries — batch or join instead of loops with DB calls
- No synchronous I/O in hot paths — use async equivalents
- Cache only deterministic, bounded data with an eviction strategy

## Code Quality
- No dead code, no magic numbers without named constants
- Logic is self-explanatory or has a comment explaining *why*
- Keep functions under ~40 lines; inject dependencies for testability

## Debugging

**Revert-First**: When something breaks, simplify — don't add more code.
3+ failed fixes = architectural problem — question the approach, not the fix.

**Investigation budget**: Max 2 diagnostic attempts per hypothesis. If no new information after 2 tries, switch strategy or ask the user.

**Shell scripts**: Run `bash -n <file>` before staging. Silent syntax errors cause hook failures.

**When challenged**: If the user disputes your conclusion, re-investigate the actual code before defending your answer.
