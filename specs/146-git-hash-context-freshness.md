# Spec 146: Git-Hash Context-Freshness

> **Status**: in-progress
> **Source**: specs/145-evaluate-understand-anything.md (Kandidat #3)
> **Goal**: context-freshness.sh um Git-Commit-Hash-Vergleich erweitern statt nur Datei-Alter zu pruefen

## Context

Aktuell prueft `context-freshness.sh` nur das Alter der Context-Dateien in Tagen. Der Hook laeuft bei jedem UserPromptSubmit und muss unter ~10ms bleiben. Understand-Anything nutzt Git-Hash-Vergleich fuer inkrementelle Stale-Detection — wir adaptieren das Pattern mit minimalem Overhead.

**Wichtig**: Der Hook nutzt bereits `.agents/context/.state` fuer PKG_HASH und TSCONFIG_HASH. Git-Hash wird dort integriert, kein separates File.

## Steps

- [x] 1. Read `hooks/context-freshness.sh` (both .claude/ and templates/) to understand current `.state` format and performance constraints
- [x] 2. Add `GIT_HASH=<hash>` line to existing `.agents/context/.state` file format (neben PKG_HASH, TSCONFIG_HASH)
- [x] 3. In Hook: read stored GIT_HASH, compare with `git rev-parse HEAD` (single fast command, ~5ms). If different → stale. Skip `git diff` — zu teuer fuer Hook-Budget
- [x] 4. In context-refresher agent: write updated GIT_HASH to `.state` after successful refresh (context-refresher.md muss angepasst werden)
- [x] 5. Keep existing age-based and checksum checks as additional signals (hash mismatch OR age > threshold = stale)
- [x] 6. Mirror changes to both template versions
- [ ] 7. Test: verify hash is written to `.state` after context-refresher runs, verify stale detection triggers on commit

## Acceptance Criteria

- GIT_HASH stored in existing `.state` file (no new state files)
- `git rev-parse HEAD` adds <10ms to hook runtime
- Stale detection triggers on new commits, not just time
- Age-based fallback still works when GIT_HASH missing from `.state`
- No breaking changes to existing hook behavior

## Files to Modify

- `.claude/hooks/context-freshness.sh`
- `templates/hooks/context-freshness.sh`
- `.claude/agents/context-refresher.md` (write GIT_HASH after refresh)
- `templates/agents/context-refresher.md`
