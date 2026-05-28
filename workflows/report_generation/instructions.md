# Report Generation Workflow

Use this workflow for assignment reports, lab reports, and research writeups where
the report must stay coherent while code, experiments, and analysis evolve.

## Operating Model

The agent works in the local project folder. GitHub is the source of truth.
Overleaf is the clean LaTeX editing and PDF compilation endpoint.

Do not assume direct Overleaf editing from Codex. If the project has an Overleaf
link, record it in `agent/STATUS.md` and include it in final progress summaries.

## Session Start

1. Run `./scripts/agent_start.sh`.
2. Read:
   - `agent/GOAL.md`
   - `agent/STATUS.md`
   - `agent/PLAN.md`
   - recent entries in `notes/progress_log.md`
3. Run `./scripts/find_report_requirements.sh` before report layout, section
   structure, submission format, or marking criteria decisions.
4. Check whether Overleaf or another human may have pushed changes.
5. State the local plan before editing.

## During Work

- Keep edits scoped to the current goal.
- Prefer reproducible scripts over manual calculations.
- Save raw experiment outputs in `results/raw/`.
- Save processed summaries in `results/summary/`.
- Update `report/main.tex` when results or interpretation change.
- Search for and inspect uploaded report layout, rubric, guideline, template, or
  assignment-brief files before changing the report structure.
- Record uncertainty instead of hiding it.
- Put detailed failed attempts in `notes/failed_ideas.md`, not in the report.

## Final Report Quality Pass

Before treating a scientific or lab report as final, do a targeted rigor pass
instead of a full rewrite. The XRD report that graded well improved because it
tightened the most marker-sensitive claims while preserving the existing
structure. Reuse these checks for future reports:

- Use reference values with precision appropriate to the quoted deviations or
  uncertainty. Verify the value from the cited source or add a better citation;
  do not compare to heavily rounded constants while reporting sub-percent
  deviations.
- Recalculate every derived comparison after changing a reference value:
  percent deviations, density differences, table entries, abstract statements,
  conclusion statements, and appendix summaries.
- Explain the physical model at the level a strict marker would expect. If an
  analysis uses a simplified indexing, fit, or model, state what real physical
  structure or mechanism it represents and why the simplification is valid.
- Be honest about uncertainty. Distinguish propagated estimates, two-point
  extrapolations, fit standard errors, manual peak-selection uncertainty, and
  systematic effects. Do not describe a two-point extrapolation as a complete
  statistical fit uncertainty.
- Surface systematic limitations early in the uncertainty section, not only in
  the conclusion. Common examples are zero offsets, calibration drift, alignment
  error, model inadequacy, peak selection, finite resolution, and sample
  preparation effects.
- Justify weighting choices scientifically. Use weights only when the
  individual uncertainty estimates are meaningful; otherwise prefer unweighted
  fits and explain that approximate uncertainties should not receive artificial
  statistical significance.
- Make the conclusion specific to why the best result was better. Tie improved
  agreement to the number of measurements, wider parameter or angular range,
  stronger model constraints, or reduced dependence on a single data point.
- Keep units and notation consistent across the abstract, results, conclusion,
  tables, and appendices. Use the project’s established style, and prefer
  structured unit macros where available.

## Session Finish

1. Run relevant checks or compilation.
2. Update:
   - `agent/STATUS.md`
   - `agent/PLAN.md`
   - `notes/progress_log.md`
   - `notes/failed_ideas.md` if applicable
   - `notes/decisions.md` if a major choice was made
   - `report/main.tex` if the report changed
3. Run `./scripts/agent_finish.sh "Meaningful commit message"`.
4. Tell the user:
   - what changed
   - what was checked
   - what remains
   - whether Overleaf needs to pull from GitHub
   - the Overleaf link, if recorded

## Report Quality Rule

The report is a living final document, not a dump of notes. Keep claims aligned
with the actual code, data, and results in the project.
