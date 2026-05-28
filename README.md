# Research Agent Workflow

Reusable operating base for agent-assisted university reports and research projects.

The intended bridge is:

```text
Codex / VS Code / local files
        <-> GitHub repository
        <-> Overleaf GitHub sync
```

Codex should work locally and through GitHub. Overleaf should receive only the clean
LaTeX report files. Agent notes, scratch drafts, logs, source material, virtual
environments, and failed attempts stay outside Overleaf unless they are directly
needed in the final report.

## What This Gives You

- A reusable project template in `templates/agent_project_template/`.
- A project creation script in `scripts/create_project.sh`.
- Report-generation operating rules in `workflows/report_generation/`.
- Overleaf/GitHub sync guidance in `workflows/overleaf_sync/`.
- Per-project files for autonomous agent work:
  - `agent/GOAL.md`
  - `agent/STATUS.md`
  - `agent/PLAN.md`
  - `agent/OPERATING_RULES.md`
  - `notes/progress_log.md`
  - `notes/failed_ideas.md`
  - `notes/decisions.md`
  - `report/main.tex`

## Create A Project

```bash
./scripts/create_project.sh hidden_path_assignment
```

With a known Overleaf project URL:

```bash
./scripts/create_project.sh hidden_path_assignment "" "https://www.overleaf.com/project/..."
```

The project will be created under:

```text
projects/hidden_path_assignment/
```

If you want it somewhere else:

```bash
./scripts/create_project.sh hidden_path_assignment /path/to/project "https://www.overleaf.com/project/..."
```

## Adopt An Existing Project

For an assignment repo or folder that already exists, keep it where it is and
bootstrap the reusable workflow into it:

```bash
./scripts/adopt_project.sh ~/Desktop/COMP3308/Ass2 comp3308-ass2 "https://www.overleaf.com/project/..."
```

This adds missing `agent/`, `notes/`, `scripts/`, and
`source_material/report_requirements/` files, preserves existing project files,
normalizes root or zipped LaTeX sources into `report/main.tex`, installs local
and GitHub Actions PDF builds when a report exists, initializes Git, configures
GitHub when a remote URL or authenticated `gh` is available, then commits and
pushes when push-safety checks pass. Existing workflow scripts are backed up
before being replaced.

Useful flags:

```bash
./scripts/adopt_project.sh ~/Desktop/local-only local-only TODO --no-github-create --no-push
./scripts/adopt_project.sh ~/Desktop/xray xray TODO --github-url https://github.com/me/xray.git
```

## Standard Agent Loop

Inside a project folder:

```bash
./scripts/agent_start.sh
```

Then the agent reads:

```text
agent/GOAL.md
agent/STATUS.md
agent/PLAN.md
notes/progress_log.md
```

After scoped work and checks:

```bash
./scripts/agent_finish.sh "Describe completed work"
```

For report-only updates:

```bash
./scripts/sync_report.sh "Update report interpretation"
```

Each final agent summary should include the Overleaf link from `agent/STATUS.md`
when one exists.

## Final Report Rigor Pass

The strongest graded reports came from targeted final improvements, not broad
rewrites. Before finalizing a lab or research report, agents should verify
reference-value precision against the cited source, recalculate every percent
deviation and derived comparison, make the physical model explanation explicit,
state uncertainty limits honestly, name systematic effects early, justify fit
weighting choices, make the conclusion explain why the strongest result is
strongest, and keep units/notation consistent across text and tables.

## GitHub PDF Build

Projects created from the template include:

```text
.github/workflows/build-report.yml
```

On every push or pull request that changes `report/**`, GitHub Actions compiles
`report/main.tex` and uploads the PDF as a workflow artifact. The local
equivalent is:

```bash
./scripts/build_report.sh
```

Overleaf is still useful for editing and final visual checks, but GitHub can
now independently verify that the LaTeX report builds.

## Overleaf Rule

This workflow does not assume Codex can edit Overleaf directly. The safe model is:

```text
Before agent work:     git pull
After agent work:      git commit && git push
Before Overleaf work:  pull/sync from GitHub in Overleaf
After Overleaf work:   push/sync to GitHub from Overleaf
```

Avoid editing the same report section in Overleaf and Codex at the same time.

## Important Git Hygiene

Generated environments must never be committed. This avoids Overleaf import
failures caused by symlinks in folders such as `.venv/`.

The project template ignores:

```text
.venv/
node_modules/
__pycache__/
*.aux
*.log
*.synctex.gz
```

## Current Limitation

This environment does not have an Overleaf connector. It can prepare clean LaTeX
files and GitHub-ready projects, but the actual Overleaf project link must be
created in Overleaf and recorded in `agent/STATUS.md`.
