#!/bin/bash
# build-liquid-graph.sh — Liquid dependency graph for Shopify themes
# Usage: bash lib/build-liquid-graph.sh [project-dir]
# Output: <project-dir>/.agents/context/liquid-graph.json
#
# Single-pass awk extraction. Scans sections/, snippets/, templates/, layout/, blocks/.
# Extracts: render / include / section calls, schema block types, asset_url refs,
#           dynamic render names (variables -> target: "*").

set -e

PROJECT_DIR="${1:-$PWD}"
OUTPUT="${2:-${PROJECT_DIR}/.agents/context/liquid-graph.json}"

# Fix 2 [HIGH:92]: ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

SCAN_DIRS="sections snippets templates layout blocks"

# ---------------------------------------------------------------------------
# Collect .liquid files
# ---------------------------------------------------------------------------

_file_type() {
  case "${1#"$PROJECT_DIR/"}" in
    sections/*)  echo "section" ;;
    snippets/*)  echo "snippet" ;;
    templates/*) echo "template" ;;
    layout/*)    echo "layout" ;;
    blocks/*)    echo "block" ;;
    *)           echo "liquid" ;;
  esac
}

LIQUID_LIST=""
for d in $SCAN_DIRS; do
  dir="${PROJECT_DIR}/${d}"
  [ -d "$dir" ] || continue
  while IFS= read -r f; do
    LIQUID_LIST="${LIQUID_LIST}${f}
"
  done < <(find "$dir" -maxdepth 2 -name "*.liquid" 2>/dev/null | sort)
done

LIQUID_LIST=$(printf '%s' "$LIQUID_LIST" | grep -v '^$')
if [ -z "$LIQUID_LIST" ]; then
  echo "build-liquid-graph: no .liquid files found in ${PROJECT_DIR}" >&2
  exit 0
fi

LIQUID_ARRAY=()
while IFS= read -r line; do
  LIQUID_ARRAY+=("$line")
done <<< "$LIQUID_LIST"

# ---------------------------------------------------------------------------
# Single-pass awk extraction (all patterns in one pass, POSIX awk compatible)
# Fix 3 [HIGH:88]: skip content inside {% comment %}...{% endcomment %} blocks
# Fix 4 [HIGH:85]: extract ALL render/include/section tags per line (loop)
# Output: TSV records — source TAB relation TAB target
# ---------------------------------------------------------------------------

# Fix 5 [MEDIUM:82]: portable tmpdir
TMPDIR_GRAPH=$(mktemp -d "${TMPDIR:-/tmp}/liquid-graph-XXXXXX")
# shellcheck disable=SC2064
trap "rm -rf '$TMPDIR_GRAPH'" EXIT INT TERM

(
  for f in "${LIQUID_ARRAY[@]}"; do
    rel="${f#"$PROJECT_DIR/"}"
    printf '__FILE__\t%s\n' "$rel"
    cat "$f"
  done
) | awk -F'\t' '
/^__FILE__\t/ {
  current = $2
  in_schema = 0
  in_comment = 0
  next
}

# Schema block tracking
/\{% *-? *schema/ { in_schema = 1; next }
/\{% *-? *endschema/ { in_schema = 0; next }
in_schema {
  if (match($0, /"type"[[:space:]]*:[[:space:]]*"[^"@][^"]*"/)) {
    s = substr($0, RSTART, RLENGTH)
    sub(/.*"type"[[:space:]]*:[[:space:]]*"/, "", s)
    sub(/".*/, "", s)
    printf "%s\tschema-block\tblocks/%s\n", current, s
  }
  next
}

# Fix 3: Comment block tracking (multi-line)
# Handle same-line open+close: strip commented span first
/\{%-?[[:space:]]*comment[[:space:]]*-?%\}.*\{%-?[[:space:]]*endcomment[[:space:]]*-?%\}/ {
  # single-line comment — remove the commented span and continue processing remainder
  line = $0
  # blank out everything between comment tags (POSIX: repeated sub approach)
  while (match(line, /\{%-?[[:space:]]*comment[[:space:]]*-?%\}[^\000]*\{%-?[[:space:]]*endcomment[[:space:]]*-?%\}/)) {
    line = substr(line, 1, RSTART-1) substr(line, RSTART+RLENGTH)
  }
  $0 = line
  # fall through to extraction below with sanitized line
}

/\{%-?[[:space:]]*comment[[:space:]]*-?%\}/ { in_comment = 1; next }
/\{%-?[[:space:]]*endcomment[[:space:]]*-?%\}/ { in_comment = 0; next }
in_comment { next }

{
  line = $0

  # Fix 4: extract ALL render single-quote tags on this line
  tmp = line
  while (match(tmp, /\{%-?[[:space:]]*render[[:space:]]*'"'"'[^'"'"']+'"'"'/)) {
    frag = substr(tmp, RSTART, RLENGTH)
    sub(/.*render[[:space:]]*'"'"'/, "", frag)
    sub(/'"'"'.*/, "", frag)
    if (length(frag) > 0) printf "%s\trender\tsnippets/%s.liquid\n", current, frag
    tmp = substr(tmp, RSTART + RLENGTH)
  }

  # Fix 4: extract ALL render double-quote tags on this line
  tmp = line
  while (match(tmp, /\{%-?[[:space:]]*render[[:space:]]*"[^"]+"/)) {
    frag = substr(tmp, RSTART, RLENGTH)
    sub(/.*render[[:space:]]*"/, "", frag)
    sub(/".*/, "", frag)
    if (length(frag) > 0) printf "%s\trender\tsnippets/%s.liquid\n", current, frag
    tmp = substr(tmp, RSTART + RLENGTH)
  }

  # dynamic render (variable name, not quoted literal)
  if (match(line, /\{%-?[[:space:]]*render[[:space:]]+[^'"'"'"{[:space:]]/)) {
    printf "%s\trender-dynamic\t*\n", current
  }

  # Fix 4: extract ALL include single-quote tags on this line
  tmp = line
  while (match(tmp, /\{%-?[[:space:]]*include[[:space:]]*'"'"'[^'"'"']+'"'"'/)) {
    frag = substr(tmp, RSTART, RLENGTH)
    sub(/.*include[[:space:]]*'"'"'/, "", frag)
    sub(/'"'"'.*/, "", frag)
    if (length(frag) > 0) printf "%s\tinclude\tsnippets/%s.liquid\n", current, frag
    tmp = substr(tmp, RSTART + RLENGTH)
  }

  # Fix 4: extract ALL section single-quote tags on this line
  tmp = line
  while (match(tmp, /\{%-?[[:space:]]*section[[:space:]]*'"'"'[^'"'"']+'"'"'/)) {
    frag = substr(tmp, RSTART, RLENGTH)
    sub(/.*section[[:space:]]*'"'"'/, "", frag)
    sub(/'"'"'.*/, "", frag)
    if (length(frag) > 0) printf "%s\tsection\tsections/%s.liquid\n", current, frag
    tmp = substr(tmp, RSTART + RLENGTH)
  }

  # asset_url single-quote
  if (match(line, /'"'"'[^'"'"']+'"'"'[[:space:]]*\|[[:space:]]*asset_url/)) {
    frag = substr(line, RSTART, RLENGTH)
    sub(/^'"'"'/, "", frag); sub(/'"'"'[[:space:]]*\|.*/, "", frag)
    if (length(frag) > 0) printf "%s\tasset\tassets/%s\n", current, frag
  }
}
' > "${TMPDIR_GRAPH}/all_edges.tsv" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Stats: top rendered snippets (render+include, shape: {file, count})
# ---------------------------------------------------------------------------

awk -F'\t' '$2=="render"||$2=="include"{print $3}' "${TMPDIR_GRAPH}/all_edges.tsv" 2>/dev/null | \
  sort | uniq -c | sort -rn | head -10 | \
  awk '{cnt=$1; $1=""; sub(/^ /,""); printf "%s\t%s\n", cnt, $0}' \
  > "${TMPDIR_GRAPH}/top_rendered.tsv" || true

# ---------------------------------------------------------------------------
# Fix 1 [HIGH:95]: top_hubs — top 10 files by ALL incoming edges
# Shape: {file, imported_by} — matches JS/TS graph.json convention
# Counts all relations (render, include, section, schema-block, asset, render-dynamic)
# ---------------------------------------------------------------------------

awk -F'\t' '$3!="*" && length($3)>0 {print $3}' "${TMPDIR_GRAPH}/all_edges.tsv" 2>/dev/null | \
  sort | uniq -c | sort -rn | head -10 | \
  awk '{cnt=$1; $1=""; sub(/^ /,""); printf "%s\t%s\n", cnt, $0}' \
  > "${TMPDIR_GRAPH}/top_hubs.tsv" || true

# Referenced names for orphan detection
awk -F'\t' '$2=="render"||$2=="include"{print $3}' "${TMPDIR_GRAPH}/all_edges.tsv" 2>/dev/null | \
  sed 's|.*/||; s|\.liquid$||' | sort -u \
  > "${TMPDIR_GRAPH}/referenced_names.txt" || true

# ---------------------------------------------------------------------------
# Orphan detection
# ---------------------------------------------------------------------------

for dir_name in snippets blocks; do
  dir="${PROJECT_DIR}/${dir_name}"
  [ -d "$dir" ] || continue
  find "$dir" -maxdepth 1 -name "*.liquid" 2>/dev/null | sort | \
  while IFS= read -r snippet_f; do
    snippet_name=$(basename "$snippet_f" .liquid)
    snippet_rel="${snippet_f#"$PROJECT_DIR/"}"
    if ! grep -qxF "$snippet_name" "${TMPDIR_GRAPH}/referenced_names.txt" 2>/dev/null; then
      printf '%s\n' "$snippet_rel"
    fi
  done
done > "${TMPDIR_GRAPH}/orphans.txt" || true

# ---------------------------------------------------------------------------
# Nodes list (file TAB type)
# ---------------------------------------------------------------------------

for f in "${LIQUID_ARRAY[@]}"; do
  rel="${f#"$PROJECT_DIR/"}"
  ftype=$(_file_type "$f")
  printf '%s\t%s\n' "$rel" "$ftype"
done > "${TMPDIR_GRAPH}/nodes.tsv"

# ---------------------------------------------------------------------------
# Assemble final JSON via awk (all TSV inputs, zero subprocesses)
# Fix 1: top_hubs uses {file, imported_by} shape (ARGV[3])
#        top_rendered_snippets uses {file, count} shape (ARGV[2])
# ---------------------------------------------------------------------------

awk -F'\t' '
function jesc(s,   r) {
  r = s
  gsub(/\\/, "\\\\", r)
  gsub(/"/, "\\\"", r)
  return r
}
BEGIN {
  n_sep=""; e_sep=""; r_sep=""; h_sep=""; o_sep=""
  nj=""; ej=""; rj=""; hj=""; oj=""
}
FILENAME == ARGV[1] {
  nj = nj n_sep "{\"file\":\"" jesc($1) "\",\"type\":\"" jesc($2) "\",\"kind\":\"file\"}"
  n_sep = ","
  next
}
FILENAME == ARGV[2] {
  ej = ej e_sep "{\"source\":\"" jesc($1) "\",\"target\":\"" jesc($3) "\",\"relation\":\"" jesc($2) "\"}"
  e_sep = ","
  next
}
FILENAME == ARGV[3] {
  # TSV: count TAB file — top_rendered_snippets shape: {file, count}
  rj = rj r_sep "{\"file\":\"" jesc($2) "\",\"count\":" $1 "}"
  r_sep = ","
  next
}
FILENAME == ARGV[4] {
  # TSV: count TAB file — top_hubs shape: {file, imported_by}
  hj = hj h_sep "{\"file\":\"" jesc($2) "\",\"imported_by\":" $1 "}"
  h_sep = ","
  next
}
FILENAME == ARGV[5] {
  oj = oj o_sep "\"" jesc($1) "\""
  o_sep = ","
  next
}
END {
  printf "{\n  \"nodes\": [%s],\n  \"edges\": [%s],\n  \"stats\": {\n    \"top_rendered_snippets\": [%s],\n    \"top_hubs\": [%s],\n    \"orphans\": [%s]\n  }\n}\n",
    nj, ej, rj, hj, oj
}
' \
  "${TMPDIR_GRAPH}/nodes.tsv" \
  "${TMPDIR_GRAPH}/all_edges.tsv" \
  "${TMPDIR_GRAPH}/top_rendered.tsv" \
  "${TMPDIR_GRAPH}/top_hubs.tsv" \
  "${TMPDIR_GRAPH}/orphans.txt" \
  > "$OUTPUT"

echo "build-liquid-graph: wrote ${OUTPUT}" >&2
