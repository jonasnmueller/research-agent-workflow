# Agent Handoff Template

Use this when starting a new Codex session for a project created from this
workflow.

```md
You are working in:

PROJECT_PATH

Goal:
- Read `agent/GOAL.md`, `agent/STATUS.md`, `agent/PLAN.md`, and the latest
  entries in `notes/progress_log.md`.
- Begin with `./scripts/agent_start.sh`.
- Run `./scripts/find_report_requirements.sh` before changing report layout,
  section structure, or submission formatting.
- Work independently toward the next highest-value task.
- Keep the report in `report/main.tex` coherent as results change.
- Before finalizing a report, run the workflow final rigor pass: verify
  reference-value precision, recalculate deviations, make physical model
  explanations explicit, state uncertainty limits honestly, surface systematic
  effects early, justify fit weighting, and make the conclusion specific to why
  the best-supported result is best.
- Update progress files before finishing.
- Commit and push automatically with `./scripts/agent_finish.sh "..."` before
  the final response whenever GitHub is connected. Do not leave completed work
  only in the local checkout unless the user explicitly asks for no push.
- Include the Overleaf link from `agent/STATUS.md` in your final summary.

Constraints:
- Do not commit generated environments such as `.venv/`.
- Do not assume direct Overleaf editing is possible.
- Avoid editing the same report section concurrently with Overleaf.
```

## Minimum User Prompt

```text
Continue this project with as little supervision as possible. Start from the
agent files, make progress, update the report, log decisions and failed ideas,
commit and push, and include the Overleaf link in the summary.
```
