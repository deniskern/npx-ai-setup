#!/usr/bin/env bash
# skills-catalog.sh — terminal overview of installed and templated skills
# Usage: bash .claude/scripts/skills-catalog.sh
# Requires: bash 3.2+, no external dependencies
set -euo pipefail

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET="$(printf '\033[0m')"
  C_HEAD="$(printf '\033[1;36m')"
  C_SECTION="$(printf '\033[1;34m')"
  C_MODEL="$(printf '\033[1;35m')"
  C_OK="$(printf '\033[1;32m')"
  C_WARN="$(printf '\033[1;33m')"
  C_DIM="$(printf '\033[2m')"
else
  C_RESET=""
  C_HEAD=""
  C_SECTION=""
  C_MODEL=""
  C_OK=""
  C_WARN=""
  C_DIM=""
fi

repeat_char() {
  local char="$1"
  local count="$2"
  local out=""
  local i

  for ((i = 0; i < count; i++)); do
    out="${out}${char}"
  done

  printf '%s' "$out"
}

trim_description() {
  local text="$1"
  local max_len=88

  text="$(printf '%s' "$text" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  if [ "${#text}" -le "$max_len" ]; then
    printf '%s' "$text"
    return 0
  fi

  printf '%s..' "${text:0:$((max_len - 2))}"
}

parse_frontmatter_field() {
  local file="$1"
  local field="$2"

  awk -v field="$field" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    index($0, field ":") == 1 {
      value = substr($0, length(field) + 2)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "$file"
}

has_next_step() {
  local file="$1"

  if grep -q '^## Next Step' "$file"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

category_for_skill() {
  local skill="$1"

  case "$skill" in
    spec|spec-work|spec-review|spec-validate|spec-board|spec-run|spec-run-all|spec-work-all)
      printf 'Spec Workflow'
      ;;
    debug|build-fix|test|test-setup|lint|commit|pr|ci|release)
      printf 'Development'
      ;;
    review|scan|techdebt)
      printf 'Quality & Security'
      ;;
    explore|challenge|research|discover|analyze)
      printf 'Research & Planning'
      ;;
    pause|resume|reflect|doctor|update|context-refresh)
      printf 'Session & Maintenance'
      ;;
    context-load|apply-learnings|token-optimizer|orchestrate|gh-cli|agent-browser|bash-defensive-patterns)
      printf 'Utilities'
      ;;
    *)
      printf 'Other'
      ;;
  esac
}

emit_skill_record() {
  local skill="$1"
  local claude_file=".claude/skills/${skill}/SKILL.md"
  local template_file="templates/skills/${skill}/SKILL.md"
  local codex_file=".codex/skills/${skill}/SKILL.md"
  local primary_file=""
  local model="—"
  local description="—"
  local next_step="no"
  local sources=""

  if [ -f "$claude_file" ]; then
    primary_file="$claude_file"
  elif [ -f "$template_file" ]; then
    primary_file="$template_file"
  elif [ -f "$codex_file" ]; then
    primary_file="$codex_file"
  fi

  if [ -n "$primary_file" ]; then
    model="$(parse_frontmatter_field "$primary_file" "model")"
    description="$(parse_frontmatter_field "$primary_file" "description")"
    next_step="$(has_next_step "$primary_file")"
  fi

  [ -n "$model" ] || model="—"
  [ -n "$description" ] || description="—"

  if [ -f "$claude_file" ]; then
    sources="${sources}C"
  else
    sources="${sources}-"
  fi

  if [ -f "$template_file" ]; then
    sources="${sources}T"
  else
    sources="${sources}-"
  fi

  if [ -f "$codex_file" ]; then
    sources="${sources}X"
  else
    sources="${sources}-"
  fi

  printf '%s|%s|%s|%s|%s|%s\n' \
    "$(category_for_skill "$skill")" \
    "$skill" \
    "$model" \
    "$(trim_description "$description")" \
    "$sources" \
    "$next_step"
}

collect_skills() {
  {
    find .claude/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -I{} basename "{}"
    find templates/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -I{} basename "{}"
    find .codex/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -I{} basename "{}"
  } | awk 'NF' | sort -u
}

print_section() {
  local section="$1"
  shift
  local records=("$@")
  local record
  local skill model description sources next_step

  echo ""
  printf '%s%s%s\n' "$C_SECTION" "$section" "$C_RESET"
  printf '  %s%s%s\n' "$C_DIM" "$(repeat_char '─' 28)" "$C_RESET"

  for record in "${records[@]}"; do
    IFS='|' read -r _section skill model description sources next_step <<< "$record"
    printf '  %s%-18s%s %s[%s]%s %s%s%s %s%s%s\n' \
      "$C_HEAD" "$skill" "$C_RESET" \
      "$C_MODEL" "$model" "$C_RESET" \
      "$C_DIM" "$sources" "$C_RESET" \
      "$description" \
      "$( [ "$next_step" = "yes" ] && printf ' %sNS%s' "$C_OK" "$C_RESET" || printf ' %sno-NS%s' "$C_WARN" "$C_RESET" )"
  done
}

main() {
  local skills=()
  local skill
  local records=()
  local section
  local section_records=()
  local count_total=0
  local count_claude=0
  local count_templates=0
  local count_codex=0
  local count_missing_next=0
  local record
  local sources
  local next_step

  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    skills+=("$skill")
  done < <(collect_skills)

  if [ "${#skills[@]}" -eq 0 ]; then
    echo "No skills found."
    exit 0
  fi

  for skill in "${skills[@]}"; do
    record="$(emit_skill_record "$skill")"
    records+=("$record")
    count_total=$((count_total + 1))
    IFS='|' read -r _section _skill _model _description sources next_step <<< "$record"
    case "$sources" in
      C*|CT*|C-*|C-X|CTX) count_claude=$((count_claude + 1)) ;;
    esac
    case "$sources" in
      *T* ) count_templates=$((count_templates + 1)) ;;
    esac
    case "$sources" in
      *X ) count_codex=$((count_codex + 1)) ;;
    esac
    if [ "$next_step" != "yes" ]; then
      count_missing_next=$((count_missing_next + 1))
    fi
  done

  echo "${C_HEAD}# Skills Catalog${C_RESET}"
  echo ""
  printf '%sTotal:%s %d skills | %sClaude:%s %d | %sTemplates:%s %d | %sCodex:%s %d | %sMissing Next Step:%s %d\n' \
    "$C_DIM" "$C_RESET" "$count_total" \
    "$C_DIM" "$C_RESET" "$count_claude" \
    "$C_DIM" "$C_RESET" "$count_templates" \
    "$C_DIM" "$C_RESET" "$count_codex" \
    "$C_DIM" "$C_RESET" "$count_missing_next"
  printf '%sLegend:%s sources %sC%s=.claude %sT%s=templates %sX%s=.codex | %sNS%s=Next Step present\n' \
    "$C_DIM" "$C_RESET" \
    "$C_OK" "$C_RESET" \
    "$C_OK" "$C_RESET" \
    "$C_OK" "$C_RESET" \
    "$C_OK" "$C_RESET"

  for section in \
    "Spec Workflow" \
    "Development" \
    "Quality & Security" \
    "Research & Planning" \
    "Session & Maintenance" \
    "Utilities" \
    "Other"
  do
    section_records=()
    for record in "${records[@]}"; do
      IFS='|' read -r record_section _rest <<< "$record"
      if [ "$record_section" = "$section" ]; then
        section_records+=("$record")
      fi
    done
    if [ "${#section_records[@]}" -gt 0 ]; then
      print_section "$section" "${section_records[@]}"
    fi
  done
}

main "$@"
