# Spec 137: Security Reviewer Agent

> **Status**: in-review
> **Quelle**: specs/136-evaluate-everything-claude-code.md (Kandidat #1)
> **Ziel**: Dedizierter Security-Agent mit OWASP Top 10, Secrets Detection, stack-spezifischen Checks

## Context

ECC hat einen umfassenden Security Reviewer Agent mit OWASP-Checkliste, Pattern-Table und False-Positive-Guidance. Unser Setup hat keinen dedizierten Security-Agent — /scan prueft nur Dependencies via npm audit / bundleaudit.

## Steps

- [x] 1. Erstelle `templates/agents/security-reviewer.md` mit YAML Frontmatter (name, description, tools, model: sonnet)
- [x] 2. Implementiere OWASP Top 10 Checkliste zugeschnitten auf Stack: Liquid XSS, Vue v-html, Shell Injection, API Token Exposure
- [x] 3. Fuege Pattern-Table hinzu: kritische Code-Patterns mit Severity und Fix-Empfehlung
- [x] 4. Fuege "Common False Positives" Section hinzu um Noise zu reduzieren
- [x] 5. Fuege "When to Run" Trigger-Guide hinzu (auth changes, user input, API endpoints, dependency updates)
- [x] 6. Kopiere nach `.claude/agents/security-reviewer.md`
- [x] 7. Update `templates/claude/docs/agent-dispatch.md` Dispatch-Table mit security-reviewer Entry
- [x] 8. Verifiziere: Agent ist via Claude Code aufrufbar, Frontmatter wird korrekt geparst

## Acceptance Criteria

- Agent hat YAML Frontmatter mit model: sonnet
- OWASP Top 10 Checkliste mit stack-spezifischen Beispielen (Liquid, Vue, Shell)
- Pattern-Table mit mindestens 8 kritischen Patterns
- False Positives Section vorhanden
- Agent in Dispatch-Table registriert

## Files to Modify

- `templates/agents/security-reviewer.md` (neu)
- `.claude/agents/security-reviewer.md` (neu)
- `templates/claude/rules/agents.md`
- `.claude/rules/agents.md`
