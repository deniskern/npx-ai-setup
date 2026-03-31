#!/usr/bin/env bash
# Routing Consistency Check — run before every release
# Verifies routing rules are internally consistent across all tracked files.
# Exit 1 on any failure — safe to use as a pre-release gate.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Routing Consistency Check ==="

# ---------------------------------------------------------------------------
echo ""
echo "--- agents.md: no self-contradiction ---"

# Must not say both "Haiku is the default" AND have a table saying Sonnet is default
if grep -q 'Haiku is the default' .claude/rules/agents.md 2>/dev/null; then
  fail "agents.md still says 'Haiku is the default' (contradicts Sonnet-for-implementation rule)"
else
  pass "agents.md does not claim Haiku as default"
fi

if grep -qi 'sonnet.*default for subagents\|default for.*subagents.*sonnet\|default for implementation' .claude/rules/agents.md 2>/dev/null; then
  pass "agents.md states Sonnet as default for implementation subagents"
else
  fail "agents.md missing Sonnet-default-for-implementation statement"
fi

if grep -qi 'haiku.*never for implementation\|never.*implementation.*haiku' .claude/rules/agents.md 2>/dev/null; then
  pass "agents.md restricts Haiku to read-only / never implementation"
else
  fail "agents.md missing explicit Haiku-never-implementation restriction"
fi

# ---------------------------------------------------------------------------
echo ""
echo "--- spec-work: medium routing uses sonnet ---"

if grep -q "medium.*sonnet" .claude/skills/spec-work/SKILL.md 2>/dev/null; then
  pass ".claude/skills/spec-work/SKILL.md routes medium to sonnet"
else
  fail ".claude/skills/spec-work/SKILL.md does not route medium to sonnet"
fi

if grep -q "medium.*sonnet" templates/skills/spec-work/SKILL.md 2>/dev/null; then
  pass "templates/skills/spec-work/SKILL.md routes medium to sonnet"
else
  fail "templates/skills/spec-work/SKILL.md does not route medium to sonnet"
fi

# ---------------------------------------------------------------------------
echo ""
echo "--- spec-work template: no auto-commit per step ---"

if grep -q 'git add -u' templates/skills/spec-work/SKILL.md 2>/dev/null; then
  fail "templates/skills/spec-work/SKILL.md still has 'git add -u' auto-commit per step"
else
  pass "templates/skills/spec-work/SKILL.md does not auto-commit per step"
fi

if grep -q 'git add -u' .claude/skills/spec-work/SKILL.md 2>/dev/null; then
  fail ".claude/skills/spec-work/SKILL.md still has 'git add -u' auto-commit per step"
else
  pass ".claude/skills/spec-work/SKILL.md does not auto-commit per step"
fi

# ---------------------------------------------------------------------------
echo ""
echo "--- CLAUDE.md: haiku scoped to explore agents ---"

if grep -qi 'haiku.*explore\|haiku.*direct tool\|haiku.*read.only' CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md scopes Haiku to explore agents / direct tool use"
else
  fail "CLAUDE.md missing Haiku scope restriction (should say: explore agents or direct tool use only)"
fi

if grep -qi 'sonnet.*implementation\|sonnet.*default.*subagent\|implementation.*sonnet' CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md states Sonnet for implementation subagents"
else
  fail "CLAUDE.md missing Sonnet-for-implementation statement"
fi

# ---------------------------------------------------------------------------
echo ""
echo "--- Cross-file: medium routing line parity ---"

REPO_MEDIUM=$(grep 'medium.*sonnet\|medium.*haiku' .claude/skills/spec-work/SKILL.md 2>/dev/null | head -1 || true)
TMPL_MEDIUM=$(grep 'medium.*sonnet\|medium.*haiku' templates/skills/spec-work/SKILL.md 2>/dev/null | head -1 || true)

if [ "$REPO_MEDIUM" = "$TMPL_MEDIUM" ]; then
  pass "spec-work medium routing line is identical in repo and template"
else
  fail "spec-work medium routing line differs between repo and template"
  echo "    repo:     $REPO_MEDIUM"
  echo "    template: $TMPL_MEDIUM"
fi

# ---------------------------------------------------------------------------
echo ""
echo "--- templates/CLAUDE.md: routing table present and correct ---"

if grep -q 'Implementation, code generation, test writing' templates/CLAUDE.md 2>/dev/null; then
  fail "templates/CLAUDE.md still has broad Sonnet definition ('Implementation, code generation, test writing')"
else
  pass "templates/CLAUDE.md does not have overly broad Sonnet definition"
fi

if grep -qi 'haiku.*explore\|explore.*haiku' templates/CLAUDE.md 2>/dev/null; then
  pass "templates/CLAUDE.md scopes Haiku to explore agents"
else
  fail "templates/CLAUDE.md missing Haiku-for-explore restriction"
fi

if grep -qi 'sonnet.*code generation\|sonnet.*writing.*logic\|code generation.*sonnet' templates/CLAUDE.md 2>/dev/null; then
  pass "templates/CLAUDE.md assigns code generation to Sonnet"
else
  fail "templates/CLAUDE.md missing Sonnet-for-code-generation statement"
fi

# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Routing consistency check FAILED — fix issues before releasing."
  exit 1
fi

echo "Routing consistency check passed."
