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
OUTPUT_DIR="${PROJECT_DIR}/.agents/context"
OUTPUT_FILE="${OUTPUT_DIR}/liquid-graph.json"

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
# Output: TSV records — source TAB relation TAB target
# ---------------------------------------------------------------------------

TMPDIR_GRAPH=$(mktemp -d /tmp/liquid-graph-XXXXXX)
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
  next
}
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
{
  line = $0
  # render single-quote
  if (match(line, /\{%-?[[:space:]]*render[[:space:]]*'"'"'[^'"'"']+'"'"'/)) {
    frag = substr(line, RSTART, RLENGTH)
    sub(/.*render[[:space:]]*'"'"'/, "", frag); sub(/'"'"'.*/, "", frag)
    if (length(frag) > 0) printf "%s\trender\tsnippets/%s.liquid\n", current, frag
  }
  # render double-quote
  if (match(line, /\{%-?[[:space:]]*render[[:space:]]*"[^"]+"/)) {
    frag = substr(line, RSTART, RLENGTH)
    sub(/.*render[[:space:]]*"/, "", frag); sub(/".*/, "", frag)
    if (length(frag) > 0) printf "%s\trender\tsnippets/%s.liquid\n", current, frag
  }
  # dynamic render
  if (match(line, /\{%-?[[:space:]]*render[[:space:]]+[^'"'"'"{[:space:]]/)) {
    printf "%s\trender-dynamic\t*\n", current
  }
  # include single-quote
  if (match(line, /\{%-?[[:space:]]*include[[:space:]]*'"'"'[^'"'"']+'"'"'/)) {
    frag = substr(line, RSTART, RLENGTH)
    sub(/.*include[[:space:]]*'"'"'/, "", frag); sub(/'"'"'.*/, "", frag)
    if (length(frag) > 0) printf "%s\tinclude\tsnippets/%s.liquid\n", current, frag
  }
  # section single-quote
  if (match(line, /\{%-?[[:space:]]*section[[:space:]]*'"'"'[^'"'"']+'"'"'/)) {
    frag = substr(line, RSTART, RLENGTH)
    sub(/.*section[[:space:]]*'"'"'/, "", frag); sub(/'"'"'.*/, "", frag)
    if (length(frag) > 0) printf "%s\tsection\tsections/%s.liquid\n", current, frag
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
# Stats: top rendered snippets (TSV: count TAB target)
# ---------------------------------------------------------------------------

awk -F'\t' '$2=="render"||$2=="include"{print $3}' "${TMPDIR_GRAPH}/all_edges.tsv" 2>/dev/null | \
  sort | uniq -c | sort -rn | head -20 | \
  awk '{cnt=$1; $1=""; sub(/^ /,""); printf "%s\t%s\n", cnt, $0}' \
  > "${TMPDIR_GRAPH}/top_rendered.tsv" || true

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
# ---------------------------------------------------------------------------

awk -F'\t' '
function jesc(s,   r) {
  r = s
  gsub(/\\/, "\\\\", r)
  gsub(/"/, "\\\"", r)
  return r
}
BEGIN {
  n_sep=""; e_sep=""; t_sep=""; o_sep=""
  nj=""; ej=""; tj=""; oj=""
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
  # TSV: count TAB target
  tj = tj t_sep "{\"file\":\"" jesc($2) "\",\"count\":" $1 "}"
  t_sep = ","
  next
}
FILENAME == ARGV[4] {
  oj = oj o_sep "\"" jesc($1) "\""
  o_sep = ","
  next
}
END {
  printf "{\n  \"nodes\": [%s],\n  \"edges\": [%s],\n  \"stats\": {\n    \"top_hubs\": [%s],\n    \"orphans\": [%s],\n    \"top_rendered_snippets\": [%s]\n  }\n}\n",
    nj, ej, tj, oj, tj
}
' \
  "${TMPDIR_GRAPH}/nodes.tsv" \
  "${TMPDIR_GRAPH}/all_edges.tsv" \
  "${TMPDIR_GRAPH}/top_rendered.tsv" \
  "${TMPDIR_GRAPH}/orphans.txt" \
  > "$OUTPUT_FILE"

echo "build-liquid-graph: wrote ${OUTPUT_FILE}" >&2
