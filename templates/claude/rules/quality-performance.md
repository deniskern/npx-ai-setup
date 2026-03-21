# Quality: Performance Principles

## Database
- No N+1 queries: do not run individual DB calls inside loops — batch or join
- Queries on large tables must use indexed columns
- Always add LIMIT to queries that could return unbounded result sets

## Caching
- Cache only deterministic, bounded data — never user-specific mutable state
- Every cache entry must have an eviction strategy (TTL, size cap, or explicit invalidation)

## I/O
- No synchronous I/O in hot paths — use async/non-blocking equivalents
- Reuse connections via pooling; never open a new connection per request

## Frontend
- No layout thrashing: do not mix reads and writes to the DOM in loops
- Lazy-load assets and components that are not needed on initial render
- Memoize expensive computations (sort, filter, map) that run on every render
