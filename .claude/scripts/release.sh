#!/usr/bin/env bash
# release.sh — Version bump, CHANGELOG entry, git tag
# Usage: bash .claude/scripts/release.sh [patch|minor|major]
# Requires: bash 3.2+, git, python3 (for JSON and CHANGELOG manipulation)
set -euo pipefail

# ── Dependency checks ──────────────────────────────────────────────────────────
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found in PATH" >&2; exit 1
fi
if ! command -v python3 >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
  echo "ERROR: python3 (or node) required for package.json and CHANGELOG manipulation" >&2; exit 1
fi

# ── Dirty check ────────────────────────────────────────────────────────────────
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "ERROR: Uncommitted changes found. Commit or stash them before releasing." >&2
  git status --short >&2
  exit 1
fi

# ── Read current version from package.json ─────────────────────────────────────
if [ ! -f "package.json" ]; then
  echo "ERROR: package.json not found in current directory." >&2; exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  CURRENT_VERSION="$(python3 -c "import json; print(json.load(open('package.json'))['version'])" 2>/dev/null)"
elif command -v node >/dev/null 2>&1; then
  CURRENT_VERSION="$(node -e "process.stdout.write(require('./package.json').version)")"
else
  echo "ERROR: python3 or node required to read package.json version" >&2; exit 1
fi

if [ -z "$CURRENT_VERSION" ]; then
  echo "ERROR: Could not read version from package.json" >&2; exit 1
fi

# ── Commits since last tag ─────────────────────────────────────────────────────
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
echo "# Release"
echo ""
if [ -n "$LAST_TAG" ]; then
  echo "## Commits since ${LAST_TAG}"
  git log --oneline "${LAST_TAG}..HEAD" 2>/dev/null || echo "  (none)"
else
  echo "## Recent commits (no previous tag)"
  git log --oneline -10 2>/dev/null || echo "  (none)"
fi

echo ""
echo "Current version: **${CURRENT_VERSION}**"
echo ""

# ── Determine bump type ────────────────────────────────────────────────────────
BUMP="${1:-}"
if [ -z "$BUMP" ]; then
  echo "Bump type? [patch / minor / major]"
  read -r BUMP
fi

case "$BUMP" in
  patch|minor|major) ;;
  *) echo "ERROR: Invalid bump type '${BUMP}'. Use patch, minor, or major." >&2; exit 1 ;;
esac

# ── Calculate new version ──────────────────────────────────────────────────────
IFS='.' read -r VMAJOR VMINOR VPATCH <<< "$CURRENT_VERSION"
VMAJOR="${VMAJOR:-0}"; VMINOR="${VMINOR:-0}"; VPATCH="${VPATCH:-0}"
# Strip any pre-release suffix (e.g. "0-beta.1" -> "0") before arithmetic
VPATCH="${VPATCH%%-*}"

case "$BUMP" in
  major) VMAJOR=$((VMAJOR + 1)); VMINOR=0; VPATCH=0 ;;
  minor) VMINOR=$((VMINOR + 1)); VPATCH=0 ;;
  patch) VPATCH=$((VPATCH + 1)) ;;
esac
NEW_VERSION="${VMAJOR}.${VMINOR}.${VPATCH}"
TODAY="$(date +%Y-%m-%d)"

echo "New version:     **${NEW_VERSION}** (${BUMP} bump)"
echo ""

# ── Check CHANGELOG.md ─────────────────────────────────────────────────────────
if [ ! -f "CHANGELOG.md" ]; then
  echo "ERROR: CHANGELOG.md not found. Create one with an '## [Unreleased]' section first." >&2
  exit 1
fi
if ! grep -q "## \[Unreleased\]" CHANGELOG.md 2>/dev/null; then
  echo "ERROR: No '## [Unreleased]' section found in CHANGELOG.md." >&2
  echo "       Add one or run the CHANGELOG migration before releasing." >&2
  exit 1
fi

# ── Confirmation gate ──────────────────────────────────────────────────────────
echo "---"
echo "Ready to:"
echo "  1. Update package.json  ${CURRENT_VERSION} → ${NEW_VERSION}"
echo "  2. Update CHANGELOG.md  [Unreleased] → [v${NEW_VERSION}] — ${TODAY}"
echo "  3. git commit -m \"release: v${NEW_VERSION}\""
echo "  4. git tag v${NEW_VERSION}"
echo ""
printf "Proceed? [y/N] "
read -r CONFIRM
case "$CONFIRM" in
  [Yy]*) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# ── Update package.json ────────────────────────────────────────────────────────
if command -v python3 >/dev/null 2>&1; then
  python3 - "$NEW_VERSION" "$CURRENT_VERSION" <<'PYEOF'
import json, sys
new_version = sys.argv[1]
current_version = sys.argv[2]
with open('package.json', 'r') as f:
    data = json.load(f)
data['version'] = new_version
with open('package.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
print("  Updated package.json: {} -> {}".format(current_version, new_version))
PYEOF
elif command -v node >/dev/null 2>&1; then
  node - "$NEW_VERSION" "$CURRENT_VERSION" <<'NJEOF'
const fs = require('fs');
const newVersion = process.argv[2];
const currentVersion = process.argv[3];
const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
p.version = newVersion;
fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
console.log('  Updated package.json: ' + currentVersion + ' -> ' + newVersion);
NJEOF
fi

# ── Update CHANGELOG.md ────────────────────────────────────────────────────────
# Replace [Unreleased] with versioned heading and insert new [Unreleased] above
# python3 is required (used above for package.json), so no sed fallback needed
python3 - "$NEW_VERSION" "$TODAY" <<'PYEOF'
import sys
new_version = sys.argv[1]
today = sys.argv[2]
new_header = "## [Unreleased]\n\n\n## [v{}] — {}".format(new_version, today)
with open('CHANGELOG.md', 'r') as f:
    content = f.read()
updated = content.replace('## [Unreleased]', new_header, 1)
with open('CHANGELOG.md', 'w') as f:
    f.write(updated)
print('  Updated CHANGELOG.md: [Unreleased] -> [v{}] — {}'.format(new_version, today))
PYEOF

# ── Commit and tag ─────────────────────────────────────────────────────────────
git add package.json CHANGELOG.md
git commit -m "release: v${NEW_VERSION}"
git tag "v${NEW_VERSION}"

echo ""
echo "Done. Tagged v${NEW_VERSION}."
echo ""
echo "When ready to publish:"
echo "  git push && git push --tags"
