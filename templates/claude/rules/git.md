---
paths:
  - "**/.git*"
  - "**/COMMIT_EDITMSG"
  - "**/*.{js,ts,tsx,jsx,vue,py,sh,go,rs,rb,php,md}"
---

# Git Rules

## Commit Message Format
Use Conventional Commits: `type(scope): description`
Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `ci`
Examples:
- `feat(auth): add OAuth2 login flow`
- `fix(cart): prevent negative quantity on decrement`
- `chore: update dependencies`

Keep the subject line under 72 characters.
Use the body to explain *why*, not *what* — the diff shows what changed.

## Branch Naming
Feature branches: `feat/short-description`
Bug fixes: `fix/short-description`
Spec branches: `spec/NNN-description`
Chore/tooling: `chore/short-description`

## Commit Hygiene
One logical change per commit — do not bundle unrelated changes.
Stage specific files rather than `git add -A` to avoid committing secrets or generated artifacts.
Always review `git diff --staged` before committing.
