# __PROJECT_NAME__

Agent-assisted project created from `research-agent-workflow`.

## Links

- GitHub: TODO
- Overleaf: __OVERLEAF_URL__

## Start Work

```bash
./scripts/agent_start.sh
```

Read the agent files, make scoped progress, keep the report updated, then finish:

```bash
./scripts/agent_finish.sh "Describe completed work"
```

For report-only updates:

```bash
./scripts/sync_report.sh "Update report"
```

To compile the local PDF:

```bash
./scripts/build_report.sh
```

## Structure

```text
agent/       Goal, status, plan, and operating rules
notes/       Progress log, decisions, and failed ideas
report/      Clean LaTeX report files for Overleaf/GitHub sync
src/         Code
data/        Input data
results/     Raw and processed outputs
source_material/report_requirements/
             Uploaded assignment briefs, rubrics, report guidelines, templates
scripts/     Project automation
```

Before changing report structure or formatting, run:

```bash
./scripts/find_report_requirements.sh
```

## Overleaf Rule

Codex works locally and pushes to GitHub. Overleaf pulls from GitHub. After any
Overleaf edit, push/sync from Overleaf back to GitHub before the next local
agent session.
