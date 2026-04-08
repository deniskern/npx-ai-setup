#!/usr/bin/env bash
# build-graph.sh — Lightweight JS/TS/Vue dependency graph builder
# Extracts import/export relationships and writes .agents/context/graph.json
#
# Usage: bash scripts/build-graph.sh [project-dir]
#        project-dir defaults to current working directory
#
# Output: .agents/context/graph.json (relative to project-dir)
#         .agents/context/graph-manifest.json (mtime cache for incremental runs)
#
# Supports:
#   - Explicit imports: import ... from './x', @/, ~/, #components, #imports
#   - Nuxt auto-imports: useXxx() calls resolved against composables/ and utils/
#   - Incremental updates: mtime-based, only re-parses changed files
#   - Circular import detection
#
# Requirements: bash 3.2+, python3

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
OUTPUT_DIR="${PROJECT_DIR}/.agents/context"
GRAPH_FILE="${OUTPUT_DIR}/graph.json"
MANIFEST_FILE="${OUTPUT_DIR}/graph-manifest.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() { echo "[build-graph] $*" >&2; }

mkdir -p "$OUTPUT_DIR"

python3 - "$PROJECT_DIR" "$GRAPH_FILE" "$MANIFEST_FILE" "$TIMESTAMP" <<'PYEOF'
import sys, os, re, json

project_dir   = sys.argv[1]
graph_file    = sys.argv[2]
manifest_file = sys.argv[3]
timestamp     = sys.argv[4]

SKIP_DIRS  = {'node_modules', 'dist', 'build', '.nuxt', '.next', '.output',
              'coverage', 'vendor', '__pycache__', '.git'}
EXTENSIONS = {'.js', '.jsx', '.ts', '.tsx', '.vue', '.mjs', '.cjs'}

# ---------------------------------------------------------------------------
# Alias detection: tsconfig.json paths + nuxt.config.ts aliases
# ---------------------------------------------------------------------------
def read_aliases(project_dir):
    """Return dict of alias prefix -> resolved path relative to project_dir."""
    aliases = {
        '~/':        '',           # nuxt root alias
        '@/':        'src/',       # default webpack/vite alias
        '#imports':  None,         # nuxt virtual module — skip
        '#components': None,       # nuxt virtual module — skip
    }
    # Override @/ from tsconfig.json
    tsconfig = os.path.join(project_dir, 'tsconfig.json')
    if os.path.isfile(tsconfig):
        try:
            d = json.load(open(tsconfig))
            paths = d.get('compilerOptions', {}).get('paths', {})
            for key in ('@/*', '@/'):
                if key in paths and paths[key]:
                    target = paths[key][0].rstrip('/*').rstrip('/')
                    aliases['@/'] = target + '/'
                    break
        except Exception:
            pass
    return aliases

aliases = read_aliases(project_dir)
print(f'[build-graph] Aliases: { {k: v for k, v in aliases.items() if v is not None} }', file=sys.stderr)

# ---------------------------------------------------------------------------
# Collect source files
# ---------------------------------------------------------------------------
def collect_files(project_dir):
    result = []
    for root, dirs, files in os.walk(project_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith('.claude')]
        for f in files:
            if os.path.splitext(f)[1] in EXTENSIONS:
                result.append(os.path.join(root, f))
    return sorted(result)

all_files = collect_files(project_dir)

# ---------------------------------------------------------------------------
# Build auto-import index: composable/util name -> file path
# Scans composables/, utils/, plugins/ for exported use* functions
# ---------------------------------------------------------------------------
def build_auto_import_index(all_files, project_dir):
    """Map function name -> relative file path for auto-importable symbols."""
    index = {}
    AUTO_IMPORT_DIRS = {'composables', 'utils', 'plugins', 'stores', 'server/utils'}
    EXPORT_PATTERN = re.compile(
        r'^export\s+(?:default\s+)?(?:const|function\*?|async\s+function)\s+(\w+)',
        re.MULTILINE
    )
    for fp in all_files:
        rel = os.path.relpath(fp, project_dir)
        # Only scan auto-import candidate directories
        parts = rel.replace('\\', '/').split('/')
        # Check if any path segment matches auto-import dirs (supports app/composables/ etc)
        if not any(p in AUTO_IMPORT_DIRS for p in parts[:-1]):
            continue
        try:
            content = open(fp, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue
        if fp.endswith('.vue'):
            scripts = re.findall(r'<script(?:[^>]*)>(.*?)</script>', content, re.DOTALL)
            content = '\n'.join(scripts)
        for m in EXPORT_PATTERN.finditer(content):
            name = m.group(1)
            if name not in index:
                index[name] = rel
    return index

auto_import_index = build_auto_import_index(all_files, project_dir)
print(f'[build-graph] Auto-import index: {len(auto_import_index)} symbols', file=sys.stderr)

# ---------------------------------------------------------------------------
# Load manifest for incremental mode
# ---------------------------------------------------------------------------
manifest = {}
if os.path.isfile(manifest_file):
    try:
        manifest = json.load(open(manifest_file))
    except Exception:
        pass

new_manifest = {}
changed_files = []
for f in all_files:
    rel = os.path.relpath(f, project_dir)
    mtime = str(int(os.path.getmtime(f)))
    new_manifest[rel] = mtime
    if manifest.get(rel) != mtime:
        changed_files.append(f)

total   = len(all_files)
changed = len(changed_files)
incremental = os.path.isfile(graph_file) and changed < total

if incremental:
    print(f'[build-graph] Incremental mode: {changed}/{total} files changed', file=sys.stderr)
else:
    print(f'[build-graph] Full build: processing all {total} files', file=sys.stderr)
    changed_files = all_files

# ---------------------------------------------------------------------------
# Load existing graph (incremental merge)
# ---------------------------------------------------------------------------
existing_nodes = []
existing_edges = []
if incremental:
    try:
        g = json.load(open(graph_file))
        changed_rels = {os.path.relpath(f, project_dir) for f in changed_files}
        existing_nodes = [n for n in g.get('nodes', []) if n['id'] not in changed_rels]
        existing_edges = [e for e in g.get('edges', []) if e['source'] not in changed_rels]
    except Exception:
        pass

# ---------------------------------------------------------------------------
# Resolve explicit import path to project-relative path
# ---------------------------------------------------------------------------
def resolve_path(source_rel, import_path):
    # Apply alias substitution
    for prefix, replacement in aliases.items():
        if import_path.startswith(prefix):
            if replacement is None:
                return None  # virtual module, skip
            import_path = replacement + import_path[len(prefix):]
            # Absolute from project root
            resolved = os.path.normpath(os.path.join(project_dir, import_path))
            break
    else:
        if not import_path.startswith(('./', '../')):
            return None  # bare node_modules specifier
        source_dir = os.path.dirname(os.path.join(project_dir, source_rel))
        resolved   = os.path.normpath(os.path.join(source_dir, import_path))

    for ext in ('', '.ts', '.tsx', '.js', '.jsx', '.vue',
                '/index.ts', '/index.js', '/index.vue'):
        candidate = resolved + ext
        if os.path.isfile(candidate):
            return os.path.relpath(candidate, project_dir)
    return os.path.relpath(resolved, project_dir)

# ---------------------------------------------------------------------------
# Extract script content (Vue SFCs)
# ---------------------------------------------------------------------------
def script_content(content, ext):
    if ext == '.vue':
        blocks = re.findall(r'<script(?:[^>]*)>(.*?)</script>', content, re.DOTALL)
        return '\n'.join(blocks)
    return content

# ---------------------------------------------------------------------------
# Patterns
# ---------------------------------------------------------------------------
P_FROM      = re.compile(r'''import\s+(?:type\s+)?(?:\{[^}]*\}|\*\s+as\s+\w+|\w+(?:\s*,\s*(?:\{[^}]*\}|\w+))*)\s+from\s+['"]([^'"]+)['"]''', re.MULTILINE)
P_SIDE      = re.compile(r'''import\s+['"]([^'"]+)['"]''', re.MULTILINE)
P_REEXPORT  = re.compile(r'''export\s+(?:type\s+)?(?:\*|\{[^}]*\})\s+from\s+['"]([^'"]+)['"]''', re.MULTILINE)
P_REQUIRE   = re.compile(r'''require\s*\(\s*['"]([^'"]+)['"]\s*\)''', re.MULTILINE)
P_AUTO_CALL = re.compile(r'\b(use[A-Z]\w*)\s*\(', re.MULTILINE)  # useFoo(

P_EXPORT_DECL    = re.compile(r'^export\s+(?:default\s+)?(?:const|let|var|function\*?|async\s+function|class|type|interface|enum|abstract\s+class)\s+(\w+)', re.MULTILINE)
P_EXPORT_BRACE   = re.compile(r'export\s+\{([^}]+)\}(?:\s+from\s+[\'\"]\S+[\'\"])?', re.MULTILINE)
P_EXPORT_DEFAULT = re.compile(r'^export\s+default\b', re.MULTILINE)
P_DEFINE_EXPOSE  = re.compile(r'defineExpose\s*\(\s*\{([^}]+)\}', re.MULTILINE)

def extract_explicit_imports(content):
    seen, results = set(), []
    for pat in (P_FROM, P_SIDE, P_REEXPORT, P_REQUIRE):
        for m in pat.finditer(content):
            p = m.group(1)
            if p not in seen:
                seen.add(p); results.append(p)
    return results

def extract_auto_import_calls(content):
    """Return set of use* function names called in this file."""
    return set(P_AUTO_CALL.findall(content))

def extract_exports(content):
    seen, exports = set(), []
    for m in P_EXPORT_DECL.finditer(content):
        n = m.group(1)
        if n not in seen: seen.add(n); exports.append(n)
    for m in P_EXPORT_BRACE.finditer(content):
        for n in m.group(1).split(','):
            n = n.strip().split(' as ')[-1].strip()
            if n and n != 'default' and n not in seen:
                seen.add(n); exports.append(n)
    if P_EXPORT_DEFAULT.search(content) and 'default' not in seen:
        seen.add('default'); exports.append('default')
    for m in P_DEFINE_EXPOSE.finditer(content):
        for n in m.group(1).split(','):
            n = n.strip().split(':')[0].strip()
            if n and n not in seen: seen.add(n); exports.append(n)
    return exports

# ---------------------------------------------------------------------------
# Process changed files
# ---------------------------------------------------------------------------
new_nodes = []
new_edges = []

for filepath in changed_files:
    rel = os.path.relpath(filepath, project_dir)
    ext = os.path.splitext(filepath)[1]
    try:
        raw = open(filepath, encoding='utf-8', errors='ignore').read()
    except Exception:
        continue

    content = script_content(raw, ext)
    exports = extract_exports(content)
    new_nodes.append({'id': rel, 'type': 'file', 'exports': exports})

    seen_targets = set()

    # 1. Explicit imports
    for imp_path in extract_explicit_imports(content):
        target = resolve_path(rel, imp_path)
        if target and target not in seen_targets:
            seen_targets.add(target)
            new_edges.append({'source': rel, 'target': target, 'kind': 'explicit'})

    # 2. Auto-import calls (Nuxt composables / utils)
    for fn_name in extract_auto_import_calls(content):
        target = auto_import_index.get(fn_name)
        if target and target != rel and target not in seen_targets:
            seen_targets.add(target)
            new_edges.append({'source': rel, 'target': target, 'kind': 'auto-import'})

# ---------------------------------------------------------------------------
# Merge + circular detection
# ---------------------------------------------------------------------------
all_nodes = existing_nodes + new_nodes
all_edges = existing_edges + new_edges

edge_map = {}
for e in all_edges:
    edge_map.setdefault(e['source'], []).append(e['target'])

# Build a separate map containing only explicit imports for cycle traversal.
# Auto-imports are framework-injected (e.g. Nuxt) and must not contribute to
# cycle detection — otherwise A->B explicit + B->A auto-import looks circular.
explicit_edge_map = {}
for e in all_edges:
    if e.get('kind') == 'explicit':
        explicit_edge_map.setdefault(e['source'], []).append(e['target'])

def has_path(src, target, visited=None):
    """Check if there is a directed path from src to target via explicit imports only."""
    if visited is None: visited = set()
    for neighbor in explicit_edge_map.get(src, []):
        if neighbor == target: return True
        if neighbor not in visited:
            visited.add(neighbor)
            if has_path(neighbor, target, visited): return True
    return False

explicit_edges = [e for e in all_edges if e.get('kind') == 'explicit']
circular = list({
    f"{e['source']} <-> {e['target']}"
    for e in explicit_edges
    if has_path(e['target'], e['source'])
})

# Hub stats
hub_counts = {}
for e in all_edges:
    hub_counts[e['target']] = hub_counts.get(e['target'], 0) + 1
top_hubs = sorted(hub_counts.items(), key=lambda x: -x[1])[:5]

output = {
    'version': 2,
    'generated': timestamp,
    'root': project_dir,
    'stats': {
        'files':          len(all_nodes),
        'edges':          len(all_edges),
        'explicit_edges': sum(1 for e in all_edges if e.get('kind') == 'explicit'),
        'auto_edges':     sum(1 for e in all_edges if e.get('kind') == 'auto-import'),
        'circular_count': len(circular),
        'top_hubs': [{'file': f, 'imported_by': c} for f, c in top_hubs],
    },
    'nodes': all_nodes,
    'edges': all_edges,
    'circular_imports': circular,
}

json.dump(output, open(graph_file, 'w'), indent=2)
json.dump(new_manifest, open(manifest_file, 'w'), indent=2)

if circular:
    print(f'[build-graph] WARNING: {len(circular)} circular import(s):', file=sys.stderr)
    for c in circular: print(f'  {c}', file=sys.stderr)

s = output['stats']
hubs_str = ', '.join(f"{h['file']} (x{h['imported_by']})" for h in s['top_hubs'][:3])
print(f"[build-graph] Done: {s['files']} files | {s['explicit_edges']} explicit + {s['auto_edges']} auto-import edges | {s['circular_count']} circular", file=sys.stderr)
if hubs_str:
    print(f'[build-graph] Top hubs: {hubs_str}', file=sys.stderr)
print(f'[build-graph] Output: {graph_file}', file=sys.stderr)
PYEOF
