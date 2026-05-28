#!/usr/bin/env bash
set -euo pipefail

echo "Session started: $(date '+%Y-%m-%d %H:%M %Z')"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    echo "Pulling latest changes from GitHub..."
    git pull --ff-only
  else
    echo "Git repository has no origin remote; skipping pull."
  fi

  echo
  git status --short
else
  echo "Not inside a Git repository; initialize Git before production use."
fi

echo
echo "Read next:"
echo "  agent/GOAL.md"
echo "  agent/STATUS.md"
echo "  agent/PLAN.md"
echo "  notes/progress_log.md"
