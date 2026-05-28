#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  adopt_project.sh PROJECT_DIR [PROJECT_NAME] [OVERLEAF_URL] [GITHUB_URL] [options]

Adds the reusable agent workflow to an existing project without deleting or
moving existing files. The script scaffolds missing workflow files, normalizes
local report sources into report/, configures Git/GitHub when possible, builds
report/main.pdf when a compiler is available, records progress, then commits
and pushes when safe.

Options:
  --github-url URL       GitHub remote URL to add when origin is missing.
  --no-github-create    Do not create a private GitHub repository with gh.
  --no-build            Skip local report compilation.
  --no-commit           Skip git add/commit.
  --no-push             Skip git push.
  --watch-actions       After a push, watch the newest GitHub Actions run.

Examples:
  ./scripts/adopt_project.sh ~/Desktop/COMP3308/Ass2 comp3308-ass2 "https://www.overleaf.com/project/..."
  ./scripts/adopt_project.sh ~/Desktop/xray xray TODO https://github.com/me/xray.git
  ./scripts/adopt_project.sh ~/Desktop/local-only local-only TODO --no-github-create --no-push
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

project_dir_input="$1"
shift

project_name="$(basename "$project_dir_input")"
overleaf_url="TODO"
github_url=""
create_github="auto"
build_mode="auto"
commit_mode="auto"
push_mode="auto"
watch_actions="false"

if [ "$#" -gt 0 ] && [[ "${1:-}" != --* ]]; then
  project_name="$1"
  shift
fi

if [ "$#" -gt 0 ] && [[ "${1:-}" != --* ]]; then
  if [[ "${1:-}" == git@* || "${1:-}" == https://github.com/* || "${1:-}" == http://github.com/* ]]; then
    github_url="$1"
  else
    overleaf_url="$1"
  fi
  shift
fi

remaining=("$@")

i=0
while [ "$i" -lt "${#remaining[@]}" ]; do
  arg="${remaining[$i]}"
  case "$arg" in
    --github-url)
      i=$((i + 1))
      if [ "$i" -ge "${#remaining[@]}" ]; then
        echo "--github-url requires a URL" >&2
        exit 1
      fi
      github_url="${remaining[$i]}"
      ;;
    --github-url=*)
      github_url="${arg#--github-url=}"
      ;;
    --no-github-create)
      create_github="skip"
      ;;
    --no-build)
      build_mode="skip"
      ;;
    --no-commit)
      commit_mode="skip"
      ;;
    --no-push)
      push_mode="skip"
      ;;
    --watch-actions)
      watch_actions="true"
      ;;
    http://*|https://*|git@*)
      if [ -n "$github_url" ]; then
        echo "GitHub URL supplied more than once." >&2
        exit 1
      fi
      github_url="$arg"
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage
      exit 1
      ;;
  esac
  i=$((i + 1))
done

if [ ! -d "$project_dir_input" ]; then
  echo "Project directory not found: $project_dir_input" >&2
  exit 1
fi

project_dir="$(cd "$project_dir_input" && pwd)"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="$root_dir/templates/agent_project_template"
created_at="$(date '+%Y-%m-%d %H:%M %Z')"
backup_stamp="$(date '+%Y%m%d-%H%M%S')"
unsafe_to_commit="false"
report_exists="false"
origin_url=""

actions=()
results=()
blockers=()

if [ ! -d "$template_dir" ]; then
  echo "Template directory not found: $template_dir" >&2
  exit 1
fi

log() {
  printf '%s\n' "${1:-}"
}

note_action() {
  actions+=("$1")
  log "$1"
}

note_result() {
  results+=("$1")
  log "$1"
}

note_blocker() {
  blockers+=("$1")
  log "Blocked: $1"
}

replace_placeholders() {
  local file="$1"
  PROJECT_NAME="$project_name" \
    OVERLEAF_URL="$overleaf_url" \
    CREATED_AT="$created_at" \
    perl -0pi -e 's/__PROJECT_NAME__/$ENV{PROJECT_NAME}/g; s/__OVERLEAF_URL__/$ENV{OVERLEAF_URL}/g; s/__CREATED_AT__/$ENV{CREATED_AT}/g' "$file"
}

copy_template_file() {
  local rel_path="$1"
  local dest="$project_dir/$rel_path"
  local src="$template_dir/$rel_path"

  if [ ! -f "$src" ]; then
    echo "Template file missing: $rel_path" >&2
    exit 1
  fi

  if [ -e "$dest" ]; then
    log "Keeping existing $rel_path"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  replace_placeholders "$dest"
  note_action "Added $rel_path."
}

install_script() {
  local name="$1"
  local src="$template_dir/scripts/$name"
  local dest="$project_dir/scripts/$name"

  if [ ! -f "$src" ]; then
    echo "Template script missing: scripts/$name" >&2
    exit 1
  fi

  mkdir -p "$project_dir/scripts"

  if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
    chmod +x "$dest"
    log "Keeping current scripts/$name"
    return
  fi

  if [ -e "$dest" ]; then
    cp "$dest" "$dest.bak-$backup_stamp"
    note_action "Backed up scripts/$name to scripts/$name.bak-$backup_stamp."
  fi

  cp "$src" "$dest"
  chmod +x "$dest"
  note_action "Installed scripts/$name."
}

ensure_directories() {
  mkdir -p \
    "$project_dir/agent" \
    "$project_dir/notes" \
    "$project_dir/scripts" \
    "$project_dir/source_material/report_requirements" \
    "$project_dir/report" \
    "$project_dir/figures" \
    "$project_dir/data" \
    "$project_dir/results"

  touch "$project_dir/source_material/report_requirements/.gitkeep"
  note_action "Ensured standard workflow directories exist."
}

ensure_gitignore() {
  local gitignore="$project_dir/.gitignore"

  if [ ! -f "$gitignore" ]; then
    cp "$template_dir/.gitignore" "$gitignore"
    note_action "Added .gitignore."
    return
  fi

  local added="false"
  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    if ! grep -qxF "$pattern" "$gitignore"; then
      printf '%s\n' "$pattern" >> "$gitignore"
      added="true"
    fi
  done <<'PATTERNS'
.DS_Store
.venv/
.gh-config/
node_modules/
__pycache__/
*.pyc
*.pyo
*.swp
*.tmp
*.aux
*.bbl
*.bcf
*.blg
*.fdb_latexmk
*.fls
*.log
*.out
*.run.xml
*.synctex.gz
*.toc
.env
.env.*
PATTERNS

  if [ "$added" = "true" ]; then
    note_action "Updated .gitignore with standard local/generated patterns."
  else
    log "Keeping existing .gitignore"
  fi
}

ensure_memory_files() {
  copy_template_file "agent/GOAL.md"
  copy_template_file "agent/STATUS.md"
  copy_template_file "agent/PLAN.md"
  copy_template_file "agent/OPERATING_RULES.md"
  copy_template_file "notes/progress_log.md"
  copy_template_file "notes/failed_ideas.md"
  copy_template_file "notes/decisions.md"
}

ensure_standard_scripts() {
  install_script "agent_start.sh"
  install_script "agent_finish.sh"
  install_script "sync_report.sh"
  install_script "print_overleaf_link.sh"
  install_script "find_report_requirements.sh"
}

ensure_github_actions_build() {
  local workflow="$project_dir/.github/workflows/build-report.yml"

  mkdir -p "$project_dir/.github/workflows"
  if [ -f "$workflow" ]; then
    log "Keeping existing .github/workflows/build-report.yml"
    return
  fi

  cp "$template_dir/.github/workflows/build-report.yml" "$workflow"
  note_action "Added .github/workflows/build-report.yml."
}

ensure_graphicspath() {
  local tex_file="$1"

  if [ ! -d "$project_dir/figures" ]; then
    return
  fi

  if [ -z "$(find "$project_dir/figures" -mindepth 1 -print -quit)" ]; then
    return
  fi

  if grep -q '\\graphicspath' "$tex_file"; then
    return
  fi

  perl -0pi -e 'if (!/\\graphicspath\s*\{/) { if (s/((?:^\\usepackage[^\n]*\n)+)/$1\\graphicspath{{..\/}}\n/m) {} else { s/(\\begin\{document\})/\\graphicspath{{..\/}}\n\n$1/ } }' "$tex_file"
  note_action "Added \\graphicspath{{../}} to report/main.tex for root figures."
}

extract_report_from_zip() {
  if ! command -v unzip >/dev/null 2>&1; then
    note_blocker "Could not inspect ZIP report sources because unzip is not installed."
    return 1
  fi

  local zip_file
  while IFS= read -r -d '' zip_file; do
    local main_path
    main_path="$(unzip -Z1 "$zip_file" 2>/dev/null | awk 'tolower($0) ~ /(^|\/)main\.tex$/ {print; exit}')"
    [ -n "$main_path" ] || continue

    unzip -p "$zip_file" "$main_path" > "$project_dir/report/main.tex"
    note_action "Extracted report/main.tex from $(basename "$zip_file")."

    local bib_path
    bib_path="$(unzip -Z1 "$zip_file" 2>/dev/null | awk 'tolower($0) ~ /(^|\/)(references|refs)\.bib$/ {print; exit}')"
    if [ -n "$bib_path" ] && [ ! -f "$project_dir/report/references.bib" ]; then
      unzip -p "$zip_file" "$bib_path" > "$project_dir/report/references.bib"
      note_action "Extracted report/references.bib from $(basename "$zip_file")."
    fi
    return 0
  done < <(find "$project_dir" -maxdepth 2 -type f -iname '*.zip' -print0)

  return 1
}

normalize_report_files() {
  if [ -f "$project_dir/report/main.tex" ]; then
    report_exists="true"
    note_result "Found existing report/main.tex."
  elif [ -f "$project_dir/main.tex" ]; then
    cp "$project_dir/main.tex" "$project_dir/report/main.tex"
    report_exists="true"
    note_action "Copied root main.tex to report/main.tex."
  elif extract_report_from_zip; then
    report_exists="true"
  fi

  if [ "$report_exists" != "true" ]; then
    note_result "No LaTeX report source found; skipped report build setup."
    return
  fi

  if [ -f "$project_dir/references.bib" ] && [ ! -f "$project_dir/report/references.bib" ]; then
    cp "$project_dir/references.bib" "$project_dir/report/references.bib"
    note_action "Copied root references.bib to report/references.bib."
  fi

  ensure_graphicspath "$project_dir/report/main.tex"
  install_script "build_report.sh"
  ensure_github_actions_build
}

update_status_link() {
  local label="$1"
  local value="$2"
  local status_file="$project_dir/agent/STATUS.md"

  [ -f "$status_file" ] || return 0
  [ -n "$value" ] || return 0

  LABEL="$label" VALUE="$value" perl -0pi -e 's/^- \Q$ENV{LABEL}\E: .*/- $ENV{LABEL}: $ENV{VALUE}/m' "$status_file"
}

ensure_status_sync_fields() {
  local status_file="$project_dir/agent/STATUS.md"

  [ -f "$status_file" ] || return 0

  if ! grep -q 'Last GitHub Actions PDF build' "$status_file"; then
    perl -0pi -e 's/(- Last Overleaf sync known: .*\n)/$1- Last GitHub Actions PDF build: Not recorded.\n/' "$status_file"
    note_action "Added GitHub Actions PDF build status field."
  fi
}

append_status_completed_line() {
  local line="$1"
  local status_file="$project_dir/agent/STATUS.md"

  [ -f "$status_file" ] || return 0
  if grep -qxF -- "- $line" "$status_file"; then
    return
  fi

  LINE="$line" perl -0pi -e 's/(## Completed\n\n)/$1- $ENV{LINE}\n/' "$status_file"
}

append_plan_done_line() {
  local line="$1"
  local plan_file="$project_dir/agent/PLAN.md"

  [ -f "$plan_file" ] || return 0
  if grep -qxF -- "- $line" "$plan_file"; then
    return
  fi

  if grep -q '^## Done' "$plan_file"; then
    printf '%s\n' "- $line" >> "$plan_file"
  else
    {
      printf '\n## Done\n\n'
      printf '%s\n' "- $line"
    } >> "$plan_file"
  fi
}

append_decision() {
  local line="$1"
  local decisions_file="$project_dir/notes/decisions.md"

  [ -f "$decisions_file" ] || return 0
  if grep -Fq "$line" "$decisions_file"; then
    return
  fi

  {
    printf '\n## %s\n\n' "$created_at"
    printf '%s\n' "$line"
  } >> "$decisions_file"
}

update_last_sync_field() {
  local field="$1"
  local value="$2"
  local status_file="$project_dir/agent/STATUS.md"

  [ -f "$status_file" ] || return 0
  FIELD="$field" VALUE="$value" perl -0pi -e 's/^- \Q$ENV{FIELD}\E: .*/- $ENV{FIELD}: $ENV{VALUE}/m' "$status_file"
}

inside_git_repo() {
  git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

init_git_if_needed() {
  if inside_git_repo; then
    note_result "Project is already a Git repository."
    return
  fi

  if git -C "$project_dir" init -b main >/dev/null 2>&1; then
    note_action "Initialized Git repository on main."
  else
    git -C "$project_dir" init >/dev/null
    git -C "$project_dir" branch -M main
    note_action "Initialized Git repository and renamed branch to main."
  fi
}

github_slug_from_url() {
  local url="$1"
  local slug=""

  case "$url" in
    git@github.com:*)
      slug="${url#git@github.com:}"
      ;;
    https://github.com/*)
      slug="${url#https://github.com/}"
      ;;
    http://github.com/*)
      slug="${url#http://github.com/}"
      ;;
  esac

  slug="${slug%.git}"
  printf '%s\n' "$slug"
}

safe_repo_name() {
  local name="$1"
  name="$(printf '%s' "$name" | tr '[:space:]' '-' | tr -cd 'A-Za-z0-9._-')"
  if [ -z "$name" ]; then
    name="research-project"
  fi
  printf '%s\n' "$name"
}

configure_git_remote() {
  origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"

  if [ -n "$origin_url" ]; then
    if [ -n "$github_url" ] && [ "$origin_url" != "$github_url" ]; then
      note_blocker "Existing origin points to $origin_url, not supplied URL $github_url. Remote was left unchanged."
      append_decision "- Kept existing origin remote $origin_url instead of replacing it with $github_url."
    fi
    note_result "Origin remote is $origin_url."
    update_status_link "GitHub" "$origin_url"
    return
  fi

  if [ -n "$github_url" ]; then
    git -C "$project_dir" remote add origin "$github_url"
    origin_url="$github_url"
    note_action "Added origin remote $github_url."
    update_status_link "GitHub" "$origin_url"
    return
  fi

  if [ "$create_github" = "skip" ]; then
    note_blocker "No origin remote configured and GitHub creation was disabled."
    return
  fi

  if ! command -v gh >/dev/null 2>&1; then
    note_blocker "No origin remote configured. Install/authenticate gh or rerun with --github-url URL."
    return
  fi

  if ! gh auth status >/dev/null 2>&1; then
    note_blocker "No origin remote configured. gh is installed but not authenticated."
    return
  fi

  local owner
  owner="$(gh api user --jq .login 2>/dev/null || true)"
  if [ -z "$owner" ]; then
    note_blocker "No origin remote configured. Could not determine gh account owner."
    return
  fi

  local repo_name
  repo_name="$(safe_repo_name "$project_name")"

  if (cd "$project_dir" && gh repo create "$owner/$repo_name" --private --source=. --remote=origin >/dev/null); then
    origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
    note_action "Created private GitHub repository $owner/$repo_name and added origin."
    update_status_link "GitHub" "$origin_url"
  else
    note_blocker "Could not create private GitHub repository $owner/$repo_name with gh."
  fi
}

fetch_remote_main_if_available() {
  origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
  [ -n "$origin_url" ] || return 0

  if git -C "$project_dir" fetch --depth=1 origin main >/dev/null 2>&1; then
    local branch
    branch="$(git -C "$project_dir" branch --show-current 2>/dev/null || true)"
    [ -n "$branch" ] || branch="main"
    git -C "$project_dir" branch --set-upstream-to=origin/main "$branch" >/dev/null 2>&1 || true
    note_result "Fetched origin/main shallowly."
    update_last_sync_field "Last pulled from GitHub" "$created_at shallow fetch of origin/main."
  else
    note_result "No fetchable origin/main found yet; continuing with local branch."
  fi
}

run_local_report_build() {
  if [ "$report_exists" != "true" ]; then
    return
  fi

  if [ "$build_mode" = "skip" ]; then
    note_result "Skipped local report build because --no-build was provided."
    return
  fi

  if "$project_dir/scripts/build_report.sh"; then
    note_result "Local report build produced report/main.pdf."
  else
    note_blocker "Local report build failed. See report/*.log if generated."
  fi
}

check_push_safety() {
  local rel
  local found_large="false"

  while IFS= read -r -d '' file; do
    rel="${file#$project_dir/}"
    note_blocker "File is over 95 MB and should not be pushed without Git LFS: $rel"
    found_large="true"
  done < <(find "$project_dir" -type f -size +95M -not -path "$project_dir/.git/*" -print0)

  if [ "$found_large" = "true" ]; then
    unsafe_to_commit="true"
  fi

  local tmp_matches
  tmp_matches="$(mktemp)"
  if command -v rg >/dev/null 2>&1; then
    (
      cd "$project_dir"
      rg -n --hidden \
        -g '!.git' \
        -g '!*.pdf' \
        -g '!*.png' \
        -g '!*.jpg' \
        -g '!*.jpeg' \
        -g '!*.HEIC' \
        -g '!*.xlsx' \
        -g '!*.zip' \
        '(API_KEY|SECRET|TOKEN|PASSWORD)\s*[:=]' . > "$tmp_matches" || true
    )
  else
    (
      cd "$project_dir"
      grep -RInE '(API_KEY|SECRET|TOKEN|PASSWORD)[[:space:]]*[:=]' . \
        --exclude-dir=.git \
        --exclude='*.pdf' \
        --exclude='*.png' \
        --exclude='*.jpg' \
        --exclude='*.jpeg' \
        --exclude='*.HEIC' \
        --exclude='*.xlsx' \
        --exclude='*.zip' > "$tmp_matches" 2>/dev/null || true
    )
  fi

  if [ -s "$tmp_matches" ]; then
    note_blocker "Potential secret assignment found; skipped commit/push until reviewed: $(head -n 1 "$tmp_matches")"
    unsafe_to_commit="true"
  fi

  rm -f "$tmp_matches"
}

commit_status_update_if_needed() {
  local message="$1"
  local status_file="$project_dir/agent/STATUS.md"

  [ "$commit_mode" != "skip" ] || return 0
  [ "$unsafe_to_commit" != "true" ] || return 0
  [ -f "$status_file" ] || return 0

  if git -C "$project_dir" diff --quiet -- agent/STATUS.md; then
    return 0
  fi

  git -C "$project_dir" add agent/STATUS.md
  if git -C "$project_dir" commit -m "$message"; then
    local commit_sha
    commit_sha="$(git -C "$project_dir" rev-parse --short HEAD)"
    note_result "Committed status update as $commit_sha."
  else
    note_blocker "Could not commit status update."
    return
  fi

  [ "$push_mode" != "skip" ] || return 0

  origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
  [ -n "$origin_url" ] || return 0

  local branch
  branch="$(git -C "$project_dir" branch --show-current 2>/dev/null || true)"
  [ -n "$branch" ] || branch="main"

  if git -C "$project_dir" push -u origin "$branch"; then
    note_result "Pushed status update to origin."
  else
    note_blocker "Could not push status update to origin."
  fi
}

commit_and_push() {
  if [ "$commit_mode" = "skip" ]; then
    note_result "Skipped commit because --no-commit was provided."
    return
  fi

  if [ "$unsafe_to_commit" = "true" ]; then
    note_blocker "Skipped commit/push because push-safety checks found blockers."
    return
  fi

  git -C "$project_dir" add -A

  if git -C "$project_dir" diff --cached --quiet; then
    note_result "No staged changes to commit."
  else
    if git -C "$project_dir" commit -m "Bootstrap project workflow"; then
      local commit_sha
      commit_sha="$(git -C "$project_dir" rev-parse --short HEAD)"
      note_result "Committed bootstrap changes as $commit_sha."
    else
      note_blocker "Git commit failed. Configure Git author identity or inspect the repository state."
      return
    fi
  fi

  if [ "$push_mode" = "skip" ]; then
    note_result "Skipped push because --no-push was provided."
    return
  fi

  origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
  if [ -z "$origin_url" ]; then
    note_blocker "No origin remote configured; commit is local only."
    return
  fi

  local branch
  branch="$(git -C "$project_dir" branch --show-current 2>/dev/null || true)"
  [ -n "$branch" ] || branch="main"

  if git -C "$project_dir" push -u origin "$branch"; then
    local commit_sha
    commit_sha="$(git -C "$project_dir" rev-parse --short HEAD)"
    note_result "Pushed $branch to origin at $commit_sha."
    update_last_sync_field "Last pushed to GitHub" "$created_at, bootstrap workflow pushed."
    commit_status_update_if_needed "Record bootstrap push status"
  else
    note_blocker "Git push failed. Inspect remote history and reconcile without overwriting local files."
  fi
}

watch_github_actions_if_requested() {
  [ "$watch_actions" = "true" ] || return 0
  [ "$report_exists" = "true" ] || return 0

  if ! command -v gh >/dev/null 2>&1; then
    note_blocker "Could not watch GitHub Actions because gh is not installed."
    return
  fi

  origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
  local repo_slug
  repo_slug="$(github_slug_from_url "$origin_url")"
  if [ -z "$repo_slug" ]; then
    note_blocker "Could not infer GitHub repo slug from origin: $origin_url"
    return
  fi

  local run_id
  run_id="$(gh run list --repo "$repo_slug" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
  if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
    note_blocker "No GitHub Actions run found to watch for $repo_slug."
    return
  fi

  if gh run watch "$run_id" --repo "$repo_slug" --exit-status; then
    note_result "GitHub Actions passed on run $run_id."
    update_last_sync_field "Last GitHub Actions PDF build" "Passed on run $run_id."
    commit_status_update_if_needed "Record GitHub Actions build status"
  else
    note_blocker "GitHub Actions failed on run $run_id."
    update_last_sync_field "Last GitHub Actions PDF build" "Failed on run $run_id."
    commit_status_update_if_needed "Record GitHub Actions build status"
  fi
}

append_progress_entry() {
  local progress_file="$project_dir/notes/progress_log.md"

  [ -f "$progress_file" ] || return 0

  {
    printf '\n## %s\n\n' "$created_at"
    printf '### Goal\n\n'
    printf 'Bootstrap the project for the reusable research-agent workflow.\n\n'
    printf '### Actions\n\n'
    if [ "${#actions[@]}" -eq 0 ]; then
      printf -- '- No file or setup changes were needed.\n'
    else
      for item in "${actions[@]}"; do
        printf -- '- %s\n' "$item"
      done
    fi
    printf '\n### Results\n\n'
    if [ "${#results[@]}" -eq 0 ]; then
      printf -- '- No results recorded.\n'
    else
      for item in "${results[@]}"; do
        printf -- '- %s\n' "$item"
      done
    fi
    printf '\n### Failed Ideas\n\n'
    if [ "${#blockers[@]}" -eq 0 ]; then
      printf -- '- None.\n'
    else
      for item in "${blockers[@]}"; do
        printf -- '- %s\n' "$item"
      done
    fi
    printf '\n### Next\n\n'
    if [ "${#blockers[@]}" -eq 0 ]; then
      printf -- '- Continue normal agent work from `./scripts/agent_start.sh`.\n'
    else
      printf -- '- Resolve the blockers above, then rerun bootstrap or finish with `./scripts/agent_finish.sh`.\n'
    fi
  } >> "$progress_file"
}

final_status() {
  local status
  status="$(git -C "$project_dir" status -sb 2>/dev/null || true)"

  log
  log "Bootstrap summary"
  log "Project: $project_dir"
  origin_url="$(git -C "$project_dir" remote get-url origin 2>/dev/null || true)"
  if [ -n "$origin_url" ]; then
    log "GitHub: $origin_url"
  else
    log "GitHub: not configured"
  fi
  if inside_git_repo; then
    log "Current commit: $(git -C "$project_dir" rev-parse --short HEAD 2>/dev/null || printf 'none')"
    log "Git status:"
    printf '%s\n' "$status"
  fi
  if [ "${#blockers[@]}" -gt 0 ]; then
    log "Blockers:"
    for item in "${blockers[@]}"; do
      log "  - $item"
    done
  fi
}

log "Bootstrapping project: $project_dir"

ensure_directories
ensure_gitignore
ensure_memory_files
ensure_status_sync_fields
ensure_standard_scripts
normalize_report_files
if [ "$overleaf_url" != "TODO" ]; then
  update_status_link "Overleaf" "$overleaf_url"
fi
append_status_completed_line "Bootstrapped reusable project workflow at $created_at."
append_plan_done_line "Bootstrapped reusable project workflow at $created_at."

init_git_if_needed
configure_git_remote
fetch_remote_main_if_available
run_local_report_build
check_push_safety
append_progress_entry
commit_and_push
watch_github_actions_if_requested

final_status
