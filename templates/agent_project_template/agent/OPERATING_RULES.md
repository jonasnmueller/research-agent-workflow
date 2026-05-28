# Agent Operating Rules

## Start Every Session

1. Run `./scripts/agent_start.sh`.
2. Read `agent/GOAL.md`, `agent/STATUS.md`, `agent/PLAN.md`, and recent
   `notes/progress_log.md`.
3. Run `./scripts/find_report_requirements.sh` when report structure, layout,
   marking criteria, or submission format may matter.
4. Check whether the project has an Overleaf link in `agent/STATUS.md`.
5. State the local plan before editing.

## Work Style

- Work independently toward the highest-value next step.
- Make scoped edits.
- Prefer reproducible scripts and recorded commands.
- Keep the report coherent and close to final form.
- Before changing report layout or section structure, inspect any uploaded
  assignment brief, report guideline, rubric, marking criteria, template, or
  submission-format file found in the project.
- Before finalizing a report, run a rigor pass: verify reference-value
  precision against cited sources, recalculate deviations and derived
  comparisons, make physical model assumptions explicit, describe uncertainty
  limits honestly, name systematic effects early, justify fit weighting, and
  make the conclusion explain why the strongest result is strongest.
- Record uncertainty and failed ideas instead of hiding them.
- Do not commit `.venv/`, generated LaTeX files, or local secrets.

## Finish Every Session

1. Run relevant checks, tests, or `./scripts/build_report.sh` when
   `report/main.tex` exists.
2. Update `agent/STATUS.md`.
3. Update `agent/PLAN.md`.
4. Append to `notes/progress_log.md`.
5. Update `notes/failed_ideas.md` or `notes/decisions.md` when relevant.
6. Commit and push with `./scripts/agent_finish.sh "message"`.
7. Summarize changed files, checks, next steps, and the Overleaf link.

## Overleaf

Codex works locally and through GitHub. Overleaf pulls from GitHub and pushes
back to GitHub. Avoid editing the same report section in both places at once.
