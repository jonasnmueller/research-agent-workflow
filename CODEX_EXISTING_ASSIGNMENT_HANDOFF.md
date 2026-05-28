# Codex Handoff For An Existing Assignment Folder

Use this when you already have an assignment folder on your computer and want
Codex to install the research-agent workflow into that folder.

Open VS Code in the existing assignment folder, open Codex, then paste the
handoff below.

## Paste This Into Codex

```text
You are inside my existing assignment/project folder. Set up the research-agent
workflow in this folder without deleting, moving, or overwriting my existing
work unless you first explain exactly why it is needed.

Use this workflow repository:
https://github.com/jonasnmueller/research-agent-workflow

My Overleaf URL is: TODO
My preferred project name is: TODO

Do the following:

1. Confirm the current working directory is the assignment folder. Show me the
   folder path before making changes.
2. Inspect the folder structure and identify likely assignment briefs, rubrics,
   report guidelines, templates, data files, source code, notebooks, and any
   existing LaTeX/report files.
3. Clone or download the workflow repository into a temporary location outside
   this assignment folder.
4. Run the workflow's `scripts/adopt_project.sh` against this assignment folder.
   Use the folder name as the project name if I left the project name as TODO.
   Use TODO as the Overleaf URL if I did not provide one.
5. Preserve all existing files. If the script wants to replace an existing
   workflow script, keep the generated backup.
6. Make sure these now exist, creating them if needed:
   - `agent/`
   - `notes/`
   - `scripts/`
   - `report/`
   - `source_material/report_requirements/`
7. Put or copy obvious assignment briefs, rubrics, report guidelines, marking
   criteria, and report templates into `source_material/report_requirements/`
   when doing so will not disrupt the original folder. If unsure, leave the
   original where it is and record its path in `agent/STATUS.md`.
8. Run `./scripts/find_report_requirements.sh` and summarize the files it finds.
9. Inspect the report requirements before changing report structure.
10. If a report already exists, make sure `report/main.tex` points to the main
    report source. If no report exists, keep the template `report/main.tex`.
11. Try to build the PDF with `./scripts/build_report.sh`.
    - If a LaTeX compiler is installed, confirm whether `report/main.pdf` was
      created.
    - If no compiler is installed, tell me exactly what to install, such as
      `latexmk` or `tectonic`.
12. Initialize Git if this folder is not already a Git repository.
13. Do not push to GitHub unless I explicitly ask you to. If a GitHub remote
    already exists, show it to me.
14. Update `agent/STATUS.md`, `agent/PLAN.md`, and `notes/progress_log.md` with
    what you found, what you changed, whether the PDF builds, and what I should
    do next.
15. Finish with the exact commands I should run next inside this assignment
    folder.

Important constraints:
- Do not commit private data, generated environments, `.venv/`, `node_modules/`,
  caches, or LaTeX build junk.
- Do not delete existing assignment files.
- Do not broadly rewrite my report until you have read the rubric/guidelines.
- If anything is ambiguous, make a conservative choice and document it.
```

## Optional Values To Fill In First

Replace these two lines in the handoff if known:

```text
My Overleaf URL is: https://www.overleaf.com/project/...
My preferred project name is: comp3308-assignment-2
```

If there is no Overleaf project yet, leave the URL as `TODO`.

## Expected Result

After Codex runs the setup, the existing assignment folder should contain:

```text
agent/
notes/
report/main.tex
scripts/agent_start.sh
scripts/build_report.sh
scripts/find_report_requirements.sh
source_material/report_requirements/
```

The PDF, when a LaTeX compiler is available, is created at:

```text
report/main.pdf
```

