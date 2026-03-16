# Spec: Skill Search Result Caching

> **Spec ID**: 097 | **Created**: 2026-03-16 | **Status**: draft | **Branch**: —

## Goal
Cache skill search results and Claude rankings to skip redundant API calls on setup re-runs.

## Context
Skill discovery runs every setup: 8+ parallel curl requests to skills.sh, install count fetches, and a Claude Haiku ranking call (~60s total). On re-runs where `package.json` hasn't changed, this is entirely redundant. Caching the result keyed by `PKG_HASH` avoids the waste while preserving freshness on dependency changes.

## Steps
- [ ] Step 1: Define cache file `.agents/.skill-cache.json` with schema: `{ "pkg_hash": "...", "cached_at": "ISO", "keywords": [...], "selected": [...] }`
- [ ] Step 2: At start of skill search in `lib/generate.sh` (~line 645), check if cache exists and `pkg_hash` matches current `package.json` cksum — if match, skip search and use cached `selected` list
- [ ] Step 3: After successful Claude ranking (~line 834), write cache file with current hash, keywords, and selected skill IDs
- [ ] Step 4: Add `--force-skills` flag to `bin/ai-setup.sh` that bypasses cache (for manual refresh)
- [ ] Step 5: Add `.agents/.skill-cache.json` to `.gitignore` template in `lib/setup.sh`
- [ ] Step 6: Test: run setup twice, verify second run skips search and prints "Using cached skill selection"

## Acceptance Criteria
- [ ] Second setup run with unchanged `package.json` skips all curl and Claude calls
- [ ] Changed `package.json` triggers fresh search (hash mismatch invalidates cache)
- [ ] `--force-skills` flag bypasses cache unconditionally
- [ ] Cache file is gitignored and machine-local

## Files to Modify
- `lib/generate.sh` — add cache read/write logic around skill search block
- `bin/ai-setup.sh` — add `--force-skills` flag parsing
- `lib/setup.sh` — add cache file to `.gitignore`

## Out of Scope
- TTL-based expiry (hash-based invalidation is sufficient)
- Caching install count metrics separately
- Sharing cache across machines
