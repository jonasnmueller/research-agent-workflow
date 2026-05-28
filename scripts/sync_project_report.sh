#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  sync_project_report.sh PROJECT_NAME OVERLEAF_REPORT_DIR

Copies projects/PROJECT_NAME/report into a separate Overleaf/GitHub checkout.
This does not commit or push the destination checkout.
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

project_name="$1"
dest="$2"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root_dir/projects/$project_name/report"

"$root_dir/workflows/overleaf_sync/sync_to_overleaf.sh" "$src" "$dest"
