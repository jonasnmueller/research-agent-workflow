# Overleaf Sync Workflow

Overleaf should contain only clean report-facing files. The recommended report
folder inside each project is:

```text
report/
  main.tex
  references.bib
  figures/
  tables/
```

## Preferred Flow

1. Create a GitHub repository for the project.
2. Push the project files.
3. In Overleaf, import from GitHub or connect the project to GitHub.
4. Record the Overleaf link in `agent/STATUS.md`.
5. Before local agent work, pull from GitHub.
6. After local agent work, commit and push to GitHub.
7. Before Overleaf editing, pull/sync from GitHub inside Overleaf.
8. After Overleaf editing, push/sync to GitHub from Overleaf.

## Important Constraint

Do not assume Codex can edit Overleaf directly. In this environment, Codex can
prepare and update local LaTeX files, but the Overleaf link must come from an
actual Overleaf project.

## Clean Report Copy

Use `sync_to_overleaf.sh` only when you maintain a separate local clone of the
Overleaf/GitHub report repository and want to copy the clean `report/` files
into it.
