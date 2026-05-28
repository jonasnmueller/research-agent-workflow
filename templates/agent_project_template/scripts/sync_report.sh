#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  sync_report.sh "COMMIT_MESSAGE" [--no-push]

Commits report-facing files plus agent progress notes, then pushes when an
origin remote exists. Use --no-push for local tests or offline work.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ -z "${1:-}" ]; then
  usage
  exit 1
fi

message="$1"
push_mode="${2:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a Git repository. Run git init and add a remote first." >&2
  exit 1
fi

paths=()
for path in agent notes report figures source_material/report_requirements scripts/build_report.sh .github/workflows/build-report.yml README.md .gitignore; do
  if [ -e "$path" ]; then
    paths+=("$path")
  fi
done

if [ "${#paths[@]}" -eq 0 ]; then
  echo "No report workflow paths found to stage."
  exit 0
fi

git add "${paths[@]}"

if git diff --cached --quiet; then
  echo "No staged report changes to commit."
else
  git commit -m "$message"
fi

if [ "$push_mode" = "--no-push" ]; then
  echo "Skipping push because --no-push was provided."
elif git remote get-url origin >/dev/null 2>&1; then
  git push
else
  echo "No origin remote configured; commit is local only."
fi
