# Report Workflow Checklist

## Before Work

- [ ] Run `./scripts/agent_start.sh`.
- [ ] Confirm the repo is clean or understand existing changes.
- [ ] Read `agent/GOAL.md`.
- [ ] Read `agent/STATUS.md`.
- [ ] Read `agent/PLAN.md`.
- [ ] Read recent `notes/progress_log.md` entries.
- [ ] Run `./scripts/find_report_requirements.sh` before report layout or format changes.
- [ ] Check the Overleaf link in `agent/STATUS.md`.

## While Working

- [ ] Keep changes scoped to the current plan.
- [ ] Save raw outputs in `results/raw/`.
- [ ] Save processed summaries in `results/summary/`.
- [ ] Update report claims when results change.
- [ ] Keep report structure aligned with uploaded briefs, rubrics, guidelines, or templates.
- [ ] Record failed approaches if they affect future work.
- [ ] Record major decisions.

## Final Rigor Pass

- [ ] Reference values have enough precision for the quoted deviations and are
      verified against the cited source.
- [ ] Percent deviations and derived comparisons were recalculated after any
      reference-value or result change.
- [ ] Abstract, results text, conclusion, and appendix tables use the same
      numerical values and identifications.
- [ ] The physical interpretation explains the actual structure/mechanism, not
      only a convenient fitting or indexing label.
- [ ] Uncertainty wording distinguishes estimates, propagated uncertainty, fit
      uncertainty, and systematic limitations.
- [ ] Systematic effects are named near the uncertainty model as well as in the
      final comparison.
- [ ] Fitting weights are justified by the reliability of individual
      uncertainty estimates.
- [ ] The conclusion explains why the strongest result is strongest, using
      concrete evidence such as number of points, range covered, or model
      constraints.
- [ ] Units and notation are consistent in text, equations, and tables.

## Before Finishing

- [ ] Run relevant tests, checks, or LaTeX compilation.
- [ ] Update `agent/STATUS.md`.
- [ ] Update `agent/PLAN.md`.
- [ ] Append to `notes/progress_log.md`.
- [ ] Update `notes/failed_ideas.md` if needed.
- [ ] Update `notes/decisions.md` if needed.
- [ ] Commit and push with `./scripts/agent_finish.sh "..."`.
- [ ] Tell the user whether Overleaf needs to pull from GitHub.
- [ ] Include the Overleaf link if it is known.
