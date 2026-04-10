# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| 1 | 2024 | Distribution | Runtime language | Bash (POSIX sh) | Zero install dependencies — runs anywhere git does without Node/Python | No |
| 2 | 2024 | Distribution | Package manager | npm tarball | Widest dev-tool distribution reach; `npx` install UX is frictionless | No |
| 3 | 2025 | Architecture | Quality gates | Hook-first, shell scripts for green path | LLM only activates on failure — zero tokens on passing checks | No |
| 4 | 2025 | Tooling | Token optimization | RTK mandatory via tool-redirect.sh | 60–90% token reduction across git/test/build ops; enforced by PreToolUse hook | No |
| 5 | 2025 | Context | Context injection | L0 YAML frontmatter abstracts in .agents/context/ | SessionStart injects ~400 tokens of structured summaries; full files on demand | No |
| 6 | 2025 | Memory | Session learning | transcript-ingest.sh via Haiku on Stop | Automatic cross-session learning extraction costs ~500 tokens per session end | Soft |
