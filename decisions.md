# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D1 | 2026-03-24 | Commands | No commands that remove safety rails | Skip `/ship` (auto-merge) | npx-ai-setup is safety-first — adds guardrails, never removes them. Auto-merge bypasses the manual review gate. | Yes — if scoped as non-template CLI-only tool |
| D2 | 2026-03-24 | Skills | Stack-specific skills via boilerplate repos, not base setup | Design skills → boilerplate | lib/skills.sh architecture: base installs global skills, boilerplate repos install stack-specific ones. Design skills are stack-specific. | Yes — if base gains stack-conditional skill installation |
| D3 | 2026-03-24 | Hooks | Agent lifecycle hooks are dev-internal only | .claude/ not templates/ | End-users don't need agent metrics logs in their projects. Dev-tools stay in maintainer scope. | No |
