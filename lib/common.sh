#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_STACK_HOME="${AGENT_STACK_HOME:-$HOME/.config/agent-stack}"
WORKFLOW_ENV="${WORKFLOW_ENV:-$AGENT_STACK_HOME/workflow.env}"

load_workflow_env() {
  if [[ -f "$WORKFLOW_ENV" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$WORKFLOW_ENV"
    set +a
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
