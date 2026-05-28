#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  create_project.sh PROJECT_NAME [PROJECT_DIR] [OVERLEAF_URL]

Examples:
  ./scripts/create_project.sh hidden_path_assignment
  ./scripts/create_project.sh hidden_path_assignment "" "https://www.overleaf.com/project/..."
  ./scripts/create_project.sh hidden_path_assignment /tmp/hidden_path_assignment
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

project_name="$1"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="$root_dir/templates/agent_project_template"

if [ ! -d "$template_dir" ]; then
  echo "Template not found: $template_dir" >&2
  exit 1
fi

if [ -n "${2:-}" ]; then
  project_dir="$2"
else
  project_dir="$root_dir/projects/$project_name"
fi

overleaf_url="${3:-TODO}"
created_at="$(date '+%Y-%m-%d %H:%M %Z')"

if [ -e "$project_dir" ] && [ -n "$(find "$project_dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
  echo "Refusing to overwrite non-empty project directory: $project_dir" >&2
  exit 1
fi

mkdir -p "$project_dir"
cp -R "$template_dir/." "$project_dir/"

find "$project_dir" -type f -print0 | while IFS= read -r -d '' file; do
  PROJECT_NAME="$project_name" \
    OVERLEAF_URL="$overleaf_url" \
    CREATED_AT="$created_at" \
    perl -0pi -e 's/__PROJECT_NAME__/$ENV{PROJECT_NAME}/g; s/__OVERLEAF_URL__/$ENV{OVERLEAF_URL}/g; s/__CREATED_AT__/$ENV{CREATED_AT}/g' "$file"
done

chmod +x "$project_dir/scripts/"*.sh

echo "Created project: $project_dir"
echo "Next:"
echo "  cd \"$project_dir\""
echo "  git init"
echo "  git add ."
echo "  git commit -m \"Initial project template\""
echo "  Add a GitHub remote, push, then connect Overleaf to that repository."
