#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  agent_finish.sh "COMMIT_MESSAGE" [--no-push]

Commits project work and pushes when an origin remote exists. Use --no-push for
local tests or offline work.
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

git add -A

if git diff --cached --quiet; then
  echo "No staged changes to commit."
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

echo
echo "Finish summary reminder:"
echo "  - Summarize changed files and checks."
echo "  - Tell the user whether Overleaf needs to pull from GitHub."
echo "  - Include the Overleaf link from agent/STATUS.md if known."
