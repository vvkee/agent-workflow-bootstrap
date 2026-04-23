#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_STACK_HOME="${AGENT_STACK_HOME:-$HOME/.config/agent-stack}"
WORKFLOW_ENV="${WORKFLOW_ENV:-$AGENT_STACK_HOME/workflow.env}"

load_workflow_env() {
  if [[ ! -f "$WORKFLOW_ENV" ]]; then
    return 0
  fi

  local workflow_keys=(
    AGENT_BUILD_DRIVER
    CLAUDE_CMD
    CLAUDE_BUILD_MODEL
    CLAUDE_AUTO_APPROVE
    OPENCODE_CMD
    OPENCODE_BUILD_AGENT
    OPENCODE_BUILD_MODEL
    OPENCODE_AUTO_APPROVE
    CODEX_CMD
    CODEX_REVIEW_MODEL
    CODEX_REVIEW_MODE
    HERMES_CMD
    HERMES_RESEARCH_PROFILE
    HERMES_RESEARCH_TOOLSETS
    AI_BUILD_TITLE
    AI_REVIEW_TITLE
    AI_RESEARCH_TITLE
  )
  local preset_keys=()
  local key preset_var

  for key in "${workflow_keys[@]}"; do
    if [[ -n "${!key+x}" ]]; then
      preset_keys+=("$key")
      printf -v "preset_$key" '%s' "${!key}"
    fi
  done

  set -a
  # shellcheck disable=SC1090
  source "$WORKFLOW_ENV"
  set +a

  if ((${#preset_keys[@]} > 0)); then
    for key in "${preset_keys[@]}"; do
      preset_var="preset_$key"
      printf -v "$key" '%s' "${!preset_var}"
      export "$key"
    done
  fi
}

log() {
  printf '[agent-workflow] %s\n' "$*"
}

warn() {
  printf '[agent-workflow][warn] %s\n' "$*" >&2
}

die() {
  printf '[agent-workflow][error] %s\n' "$*" >&2
  exit 1
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

ensure_git_repo() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || die 'Current directory is not inside a git repository'
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  export REPO_ROOT
  cd "$REPO_ROOT"
}

ensure_repo_tmp_dirs() {
  [[ -n "${REPO_ROOT:-}" ]] || die 'REPO_ROOT is not set'
  mkdir -p "$REPO_ROOT/.ai/tmp" "$REPO_ROOT/.codex/tmp"
}

collect_input() {
  if [[ $# -gt 0 ]]; then
    printf '%s' "$*"
    return 0
  fi

  if [[ ! -t 0 ]]; then
    cat
    return 0
  fi

  die 'Please provide task text as arguments or via stdin'
}

resolve_codex_cmd() {
  if [[ -n "${CODEX_CMD:-}" ]] && command -v "$CODEX_CMD" >/dev/null 2>&1; then
    printf '%s' "$CODEX_CMD"
    return 0
  fi

  if command -v codex >/dev/null 2>&1; then
    printf '%s' "codex"
    return 0
  fi

  if command -v npx >/dev/null 2>&1; then
    printf '%s' "npx -y @openai/codex"
    return 0
  fi

  return 1
}

has_working_tree_diff() {
  ! git diff --quiet -- . || ! git diff --cached --quiet -- .
}

has_head_parent() {
  git rev-parse --verify HEAD^ >/dev/null 2>&1
}
