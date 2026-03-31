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

## Security
- Never interpolate user input into SQL, shell commands, or HTML
- Validate and sanitize all external inputs (query params, headers, uploads)
- No secrets, tokens, or passwords in source code, logs, or error messages
- Enforce authorization checks on every request — never trust client-provided IDs

## Performance
- No N+1 queries — batch or join instead of loops with DB calls
- No synchronous I/O in hot paths — use async equivalents
- No layout thrashing: do not mix DOM reads and writes in loops
- Cache only deterministic, bounded data with an eviction strategy

## Maintainability
- Single Responsibility: each function/module does one thing
- DRY: extract repeated logic; do not copy-paste with minor variations
- Names reveal intent: `getUserByEmail` not `getUser`
- Handle errors at the layer that can act on them; don't log and re-throw

## Code Quality
- No dead code, no magic numbers without named constants
- Logic is self-explanatory or has a comment explaining *why*
- Keep functions under ~40 lines; inject dependencies for testability

## Debugging

**Revert-First**: When something breaks during implementation, simplify — don't add more code.
1. Revert the breaking change. Clean state.
2. Can the broken thing be deleted entirely?
3. One-liner minimal targeted fix only.
3+ failed fixes = architectural problem — question the approach, not the fix.

**Systematic phases**: Root Cause → Pattern Analysis → Hypothesis (specific, falsifiable) → Implement.
Treat your own code as foreign. Your mental model is a guess — the code's behavior is truth.

**Constraint Classification**: Hard (non-negotiable), Soft (negotiable if stated), Ghost (past constraints that no longer apply). Ghost constraints lock out options nobody knows are available — ask "why can't we do X?"
