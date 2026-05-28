#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  find_report_requirements.sh [SEARCH_TERM...]

Find likely uploaded files that define the required report layout, rubric,
marking criteria, submission format, or assignment instructions.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

terms=("$@")
if [ "${#terms[@]}" -eq 0 ]; then
  terms=(
    guideline guidelines rubric marking criteria instruction instructions
    assignment brief layout format template specification spec canvas submission requirements
  )
fi

pattern="$(IFS='|'; echo "${terms[*]}")"

echo "Likely report requirement/layout files by filename:"
find . \
  \( -path './.git' -o -path './.venv' -o -path './node_modules' -o -path './__pycache__' -o -path './results' -o -path './outputs' -o -path './Evaluating_Classifiers/output' -o -path './Weka_Results' \) -prune -o \
  -type f \
  \( -iname '*.pdf' -o -iname '*.docx' -o -iname '*.doc' -o -iname '*.md' -o -iname '*.txt' -o -iname '*.tex' -o -iname '*.rtf' \) \
  -print \
  | grep -Eai "$pattern" \
  | sort || true

echo
echo "Text matches in readable requirement/memory files:"
text_files=()
while IFS= read -r -d '' file; do
  text_files+=("$file")
done < <(
  {
    find . -maxdepth 1 -type f \( -iname '*.md' -o -iname '*.txt' -o -iname '*.tex' \) -print0
    for dir in agent notes source_material; do
      if [ -d "$dir" ]; then
        find "$dir" -type f \( -iname '*.md' -o -iname '*.txt' -o -iname '*.tex' \) -print0
      fi
    done
  } 2>/dev/null
)

if [ "${#text_files[@]}" -eq 0 ]; then
  echo "No readable requirement/memory text files found."
elif command -v rg >/dev/null 2>&1; then
  rg -n -i "$pattern" "${text_files[@]}" || true
else
  grep -HnEi "$pattern" "${text_files[@]}" 2>/dev/null || true
fi

echo
echo "If a relevant PDF or DOCX is found, inspect it before changing report structure."
