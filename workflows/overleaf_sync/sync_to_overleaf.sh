#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  sync_to_overleaf.sh PROJECT_REPORT_DIR OVERLEAF_REPORT_DIR

Copies clean LaTeX report files from a project report directory into a separate
Overleaf/GitHub report checkout. This script does not push by itself.

Example:
  ./workflows/overleaf_sync/sync_to_overleaf.sh \
    projects/hidden_path_assignment/report \
    ~/Overleaf/hidden-path-assignment
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

src="$1"
dest="$2"

if [ ! -d "$src" ]; then
  echo "Source report directory not found: $src" >&2
  exit 1
fi

mkdir -p "$dest"

rsync -av --delete \
  --exclude '*.aux' \
  --exclude '*.bbl' \
  --exclude '*.bcf' \
  --exclude '*.blg' \
  --exclude '*.fdb_latexmk' \
  --exclude '*.fls' \
  --exclude '*.log' \
  --exclude '*.out' \
  --exclude '*.run.xml' \
  --exclude '*.synctex.gz' \
  --exclude '*.toc' \
  "$src/" "$dest/"

echo "Copied clean report files to: $dest"
echo "Review, commit, and push from the Overleaf/GitHub checkout when ready."
