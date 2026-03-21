#!/usr/bin/env bash
# scan-prep.sh — gather dependency audit data with zero LLM tokens
# Outputs structured severity summary to stdout; exits 0 (clean) or 2 (vulns found)
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

emit_section() {
  local label="$1"; shift
  local items=("$@")
  if [[ ${#items[@]} -gt 0 ]]; then
    echo "=== ${label} (${#items[@]}) ==="
    for item in "${items[@]}"; do
      echo "  $item"
    done
  fi
}

# ---------------------------------------------------------------------------
# Node.js — npm audit
# ---------------------------------------------------------------------------
run_npm() {
  local json
  json=$(npm audit --json 2>/dev/null || true)

  if [[ -z "$json" ]]; then
    echo "ERROR: npm audit produced no output" >&2
    exit 1
  fi

  # Extract counts per severity using python (always available on macOS/Linux)
  local summary
  summary=$(echo "$json" | python3 -c '
import json, sys

data = json.load(sys.stdin)

# npm audit v7+ uses "vulnerabilities" dict; older uses "advisories"
vulns = {}
if "vulnerabilities" in data:
    for name, info in data["vulnerabilities"].items():
        sev = info.get("severity", "unknown").upper()
        vulns.setdefault(sev, []).append(
            f"{name}@{info.get('range','?')} — fix: {info.get('fixAvailable', False)}"
        )
elif "advisories" in data:
    for adv_id, info in data["advisories"].items():
        sev = info.get("severity", "unknown").upper()
        via = info.get("module_name", "?")
        cve = info.get("cves", [])
        cve_str = ",".join(cve) if cve else "no-CVE"
        fixed = info.get("patched_versions", "?")
        vulns.setdefault(sev, []).append(f"{via} ({cve_str}) — fixed in: {fixed}")

for severity in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
    entries = vulns.get(severity, [])
    if entries:
        print(f"=== {severity} ({len(entries)}) ===")
        for e in entries:
            print(f"  {e}")

total = sum(len(v) for v in vulns.values())
if total == 0:
    print("NO_VULNERABILITIES_FOUND")
')

  echo "$summary"

  if echo "$summary" | grep -q "NO_VULNERABILITIES_FOUND"; then
    exit 0
  else
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Snyk (preferred if available, works for any project type)
# ---------------------------------------------------------------------------
run_snyk() {
  local json
  json=$(snyk test --json 2>/dev/null || true)

  local summary
  summary=$(echo "$json" | python3 -c '
import json, sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("ERROR: could not parse snyk output")
    sys.exit(1)

vulns = {}
for v in data.get("vulnerabilities", []):
    sev = v.get("severity", "unknown").upper()
    name = v.get("moduleName", "?")
    ids = ",".join(v.get("identifiers", {}).get("CVE", []) or [v.get("id","?")])
    fixed = v.get("fixedIn", ["?"])
    vulns.setdefault(sev, []).append(f"{name} ({ids}) — fixed in: {fixed}")

for severity in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
    entries = vulns.get(severity, [])
    if entries:
        print(f"=== {severity} ({len(entries)}) ===")
        for e in entries:
            print(f"  {e}")

total = sum(len(v) for v in vulns.values())
if total == 0:
    print("NO_VULNERABILITIES_FOUND")
')

  echo "$summary"

  if echo "$summary" | grep -q "NO_VULNERABILITIES_FOUND"; then
    exit 0
  else
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Python — pip-audit or safety
# ---------------------------------------------------------------------------
run_pip() {
  if has pip-audit; then
    local out
    out=$(pip-audit --format=json 2>/dev/null || true)

    local summary
    summary=$(echo "$out" | python3 -c '
import json, sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("ERROR: could not parse pip-audit output")
    sys.exit(1)

vulns = {"HIGH": [], "MEDIUM": [], "LOW": []}
for dep in data.get("dependencies", []):
    for vuln in dep.get("vulns", []):
        sev = vuln.get("fix_versions", ["?"])
        entry = f"{dep[\"name\"]}@{dep[\"version\"]} ({vuln[\"id\"]}) — fix: {sev}"
        vulns["HIGH"].append(entry)  # pip-audit does not expose CVSS natively

for severity in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
    entries = vulns.get(severity, [])
    if entries:
        print(f"=== {severity} ({len(entries)}) ===")
        for e in entries:
            print(f"  {e}")

total = sum(len(v) for v in vulns.values())
if total == 0:
    print("NO_VULNERABILITIES_FOUND")
')
    echo "$summary"

    if echo "$summary" | grep -q "NO_VULNERABILITIES_FOUND"; then
      exit 0
    else
      exit 2
    fi

  elif has safety; then
    safety check --full-report 2>/dev/null || true
  else
    echo "ERROR: No Python scanner found. Install pip-audit: pip install pip-audit" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Ruby — bundler-audit
# ---------------------------------------------------------------------------
run_bundler() {
  if ! has bundle-audit; then
    echo "ERROR: bundle-audit not found. Install: gem install bundler-audit" >&2
    exit 1
  fi

  local raw
  raw=$(bundle-audit check --update 2>/dev/null || true)

  local summary
  summary=$(echo "$raw" | awk '
    /Name:/ { pkg = $2 }
    /CVE:/ { cve = $2 }
    /Criticality:/ { sev = toupper($2); findings[sev] = findings[sev] pkg " (" cve "); " }
    END {
      found = 0
      for (s in findings) { print "=== " s " ===\n  " findings[s]; found++ }
      if (found == 0) print "NO_VULNERABILITIES_FOUND"
    }
  ')

  echo "$summary"

  if echo "$summary" | grep -q "NO_VULNERABILITIES_FOUND"; then
    exit 0
  else
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
echo "SCAN_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "PWD: $(pwd)"
echo ""

if has snyk; then
  echo "SCANNER: snyk"
  run_snyk
elif [[ -f "package.json" ]]; then
  if ! has npm; then
    echo "ERROR: package.json found but npm not available" >&2
    exit 1
  fi
  echo "SCANNER: npm-audit"
  run_npm
elif [[ -f "requirements.txt" ]] || [[ -f "Pipfile" ]] || [[ -f "pyproject.toml" ]]; then
  echo "SCANNER: pip"
  run_pip
elif [[ -f "Gemfile.lock" ]]; then
  echo "SCANNER: bundler-audit"
  run_bundler
else
  echo "ERROR: No supported project type detected." >&2
  echo "       Supported: Node.js (package.json), Python (requirements.txt/Pipfile), Ruby (Gemfile.lock), Snyk (any)" >&2
  exit 1
fi
