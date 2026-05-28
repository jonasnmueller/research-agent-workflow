#!/usr/bin/env bash
set -euo pipefail

status_file="agent/STATUS.md"

if [ ! -f "$status_file" ]; then
  echo "No agent/STATUS.md file found." >&2
  exit 1
fi

link="$(awk -F'Overleaf: ' '/^- Overleaf: / {print $2; exit}' "$status_file")"

if [ -z "$link" ] || [ "$link" = "TODO" ]; then
  echo "Overleaf link not recorded."
else
  echo "$link"
fi
