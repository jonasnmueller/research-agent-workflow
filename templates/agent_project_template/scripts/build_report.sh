#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../report"

if command -v latexmk >/dev/null 2>&1; then
  latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error main.tex
elif command -v tectonic >/dev/null 2>&1; then
  tectonic -X compile main.tex
else
  echo "No LaTeX compiler found. Install latexmk or tectonic." >&2
  exit 1
fi
