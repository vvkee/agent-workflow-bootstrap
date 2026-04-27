#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_ARGS=("$@")
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
PATCH_HERMES_SKILLS=0
BOOTSTRAP_REPO="${AGENT_WORKFLOW_BOOTSTRAP_REPO:-vvkee/agent-workflow-bootstrap}"
BOOTSTRAP_REF="${AGENT_WORKFLOW_BOOTSTRAP_REF:-main}"
BOOTSTRAP_ARCHIVE_URL="${AGENT_WORKFLOW_BOOTSTRAP_ARCHIVE_URL:-}"
BOOTSTRAP_STAGE_DIR="${AGENT_WORKFLOW_BOOTSTRAP_STAGE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/agent-workflow-bootstrap}"
STAGED_REPO_DIR=""
PREVIOUS_STAGE_DIR=""

resolve_archive_url() {
  if [[ -n "$BOOTSTRAP_ARCHIVE_URL" ]]; then
    printf '%s' "$BOOTSTRAP_ARCHIVE_URL"
    return 0
  fi

  printf 'https://codeload.github.com/%s/tar.gz/refs/heads/%s' "$BOOTSTRAP_REPO" "$BOOTSTRAP_REF"
}

validate_stage_dir() {
  local expected_base="${XDG_DATA_HOME:-$HOME/.local/share}"
  local path="$1"

  [[ "$path" == /* ]] || { echo "Unsafe bootstrap stage dir (must be absolute): $path" >&2; exit 1; }
  [[ "$path" == "$expected_base/agent-workflow-bootstrap" ]] || {
    echo "Unsafe bootstrap stage dir (expected under $expected_base): $path" >&2
    exit 1
  }
}

cleanup_previous_stage() {
  if [[ -n "$PREVIOUS_STAGE_DIR" && -e "$PREVIOUS_STAGE_DIR" ]]; then
    rm -rf "$PREVIOUS_STAGE_DIR"
  fi
}

restore_previous_stage() {
  if [[ -n "$PREVIOUS_STAGE_DIR" && -e "$PREVIOUS_STAGE_DIR" ]]; then
    rm -rf "$BOOTSTRAP_STAGE_DIR"
    mv "$PREVIOUS_STAGE_DIR" "$BOOTSTRAP_STAGE_DIR"
  fi
}

stage_bootstrap_repo() {
  command -v curl >/dev/null 2>&1 || { echo 'curl is required for bootstrap' >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { echo 'tar is required for bootstrap' >&2; exit 1; }
  command -v mktemp >/dev/null 2>&1 || { echo 'mktemp is required for bootstrap' >&2; exit 1; }

  local tmpdir archive_url extracted incoming_stage backup_stage
  tmpdir="$(mktemp -d)"
  archive_url="$(resolve_archive_url)"

  echo "bootstrap  downloading ${BOOTSTRAP_REPO}@${BOOTSTRAP_REF}" >&2
  curl -fsSL "$archive_url" | tar -xzf - -C "$tmpdir"
  extracted="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$extracted" ]] || { echo 'Failed to unpack bootstrap archive' >&2; rm -rf "$tmpdir"; exit 1; }

  validate_stage_dir "$BOOTSTRAP_STAGE_DIR"
  mkdir -p "$(dirname "$BOOTSTRAP_STAGE_DIR")"

  incoming_stage="${BOOTSTRAP_STAGE_DIR}.incoming.$$"
  backup_stage="${BOOTSTRAP_STAGE_DIR}.backup.$$"
  rm -rf "$incoming_stage" "$backup_stage"
  mv "$extracted" "$incoming_stage"

  if [[ -e "$BOOTSTRAP_STAGE_DIR" ]]; then
    mv "$BOOTSTRAP_STAGE_DIR" "$backup_stage"
    PREVIOUS_STAGE_DIR="$backup_stage"
  else
    PREVIOUS_STAGE_DIR=""
  fi

  if ! mv "$incoming_stage" "$BOOTSTRAP_STAGE_DIR"; then
    rm -rf "$incoming_stage"
    restore_previous_stage
    rm -rf "$tmpdir"
    echo "Failed to stage bootstrap repo at $BOOTSTRAP_STAGE_DIR" >&2
    exit 1
  fi

  rm -rf "$tmpdir"

  STAGED_REPO_DIR="$BOOTSTRAP_STAGE_DIR"
  export STAGED_REPO_DIR
  echo "bootstrap  staged repo at $STAGED_REPO_DIR" >&2
}

bootstrap_from_github() {
  stage_bootstrap_repo
  if bash "$STAGED_REPO_DIR/install.sh" "${ORIGINAL_ARGS[@]}"; then
    cleanup_previous_stage
    exit 0
  fi

  restore_previous_stage
  exit 1
}

if [[ ! -f "$REPO_ROOT/templates/opencode/AGENTS.md" || ! -f "$REPO_ROOT/templates/claude/CLAUDE.md" ]]; then
  bootstrap_from_github
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      ;;
    --patch-hermes-skills)
      PATCH_HERMES_SKILLS=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [--force] [--patch-hermes-skills]

  --force                overwrite existing target files and links
  --patch-hermes-skills  try to append ~/.agents/skills into Hermes config.yaml
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

AGENT_STACK_HOME="${AGENT_STACK_HOME:-$HOME/.config/agent-stack}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-$HOME/.local/bin}"
AUTO_RELINK_BOOTSTRAP=0
if [[ "$REPO_ROOT" == "$BOOTSTRAP_STAGE_DIR" ]]; then
  AUTO_RELINK_BOOTSTRAP=1
fi

copy_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && "$FORCE" -ne 1 ]]; then
    echo "skip  $dst (exists)"
    return 0
  fi
  cp "$src" "$dst"
  echo "copy  $dst"
}

is_bootstrap_managed_target() {
  local target="$1"
  [[ "$target" == */agent-workflow-bootstrap*/bin/ai-* ]]
}

link_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -f "$dst"
    else
      echo "skip  $dst (exists)"
      return 0
    fi
  fi
  ln -s "$src" "$dst"
  echo "link  $dst -> $src"
}

link_command() {
  local src="$1"
  local dst="$2"
  local current_target=''
  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    current_target="$(readlink "$dst")"
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -f "$dst"
    elif [[ "$AUTO_RELINK_BOOTSTRAP" -eq 1 && -L "$dst" && "$current_target" != "$src" ]] && is_bootstrap_managed_target "$current_target"; then
      rm -f "$dst"
      ln -s "$src" "$dst"
      echo "relink $dst -> $src"
      return 0
    else
      echo "skip  $dst (exists)"
      return 0
    fi
  fi

  ln -s "$src" "$dst"
  echo "link  $dst -> $src"
}

ensure_workflow_env() {
  local dst="$AGENT_STACK_HOME/workflow.env"
  mkdir -p "$AGENT_STACK_HOME"
  if [[ -e "$dst" && "$FORCE" -ne 1 ]]; then
    echo "skip  $dst (exists)"
  else
    cp "$REPO_ROOT/env/workflow.env.example" "$dst"
    echo "copy  $dst"
  fi
}

patch_hermes_skills() {
  local config_path="$HOME/.hermes/config.yaml"
  local skills_dir="$HOME/.agents/skills"

  if [[ ! -f "$config_path" ]]; then
    echo "warn  Hermes config not found: $config_path"
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "warn  python3 not found; skip Hermes config patch"
    return 0
  fi

  python3 - "$config_path" "$skills_dir" <<'PY'
from pathlib import Path
import re
import sys

config_path = Path(sys.argv[1])
skills_dir = sys.argv[2]
text = config_path.read_text()

if skills_dir in text or '~/.agents/skills' in text:
    print(f'skip  {config_path} already references {skills_dir}')
    raise SystemExit(0)

pattern = re.compile(r'(^skills:\n(?:^[ \t].*\n)*)', re.M)
match = pattern.search(text)
if not match:
    print(f'warn  could not find skills block in {config_path}; patch manually')
    raise SystemExit(0)

block = match.group(1)
if 'external_dirs: []' in block:
    new_block = block.replace('external_dirs: []', f'external_dirs:\n  - {skills_dir}')
elif 'external_dirs:' in block:
    new_block = block.replace('external_dirs:\n', f'external_dirs:\n  - {skills_dir}\n', 1)
else:
    new_block = block + f'  external_dirs:\n  - {skills_dir}\n'

updated = text[:match.start(1)] + new_block + text[match.end(1):]
config_path.write_text(updated)
print(f'patch {config_path} -> add {skills_dir}')
PY
}

mkdir -p "$LOCAL_BIN_DIR"

copy_file "$REPO_ROOT/templates/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
copy_file "$REPO_ROOT/templates/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
copy_file "$REPO_ROOT/templates/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
copy_file "$REPO_ROOT/templates/codex/skills/repo-review/SKILL.md" "$HOME/.agents/skills/repo-review/SKILL.md"
copy_file "$REPO_ROOT/templates/codex/skills/repo-brief/SKILL.md" "$HOME/.agents/skills/repo-brief/SKILL.md"
copy_file "$REPO_ROOT/templates/hermes/SOUL.md" "$HOME/.hermes/SOUL.md"
copy_file "$REPO_ROOT/templates/hermes/config.fragment.yaml" "$AGENT_STACK_HOME/hermes.config.fragment.yaml"
copy_file "$REPO_ROOT/templates/shared/output-contract.md" "$AGENT_STACK_HOME/output-contract.md"
ensure_workflow_env

link_command "$REPO_ROOT/bin/ai-build" "$LOCAL_BIN_DIR/ai-build"
link_command "$REPO_ROOT/bin/ai-review" "$LOCAL_BIN_DIR/ai-review"

RESEARCH_CURRENT_TARGET=''
if [[ -L "$LOCAL_BIN_DIR/ai-research" ]]; then
  RESEARCH_CURRENT_TARGET="$(readlink "$LOCAL_BIN_DIR/ai-research")"
fi

if [[ -L "$LOCAL_BIN_DIR/ai-research" ]] && [[ "$RESEARCH_CURRENT_TARGET" == "$REPO_ROOT/bin/ai-research" ]]; then
  echo "skip  $LOCAL_BIN_DIR/ai-research (already linked)"
elif [[ "$AUTO_RELINK_BOOTSTRAP" -eq 1 && -L "$LOCAL_BIN_DIR/ai-research" ]] && is_bootstrap_managed_target "$RESEARCH_CURRENT_TARGET"; then
  link_command "$REPO_ROOT/bin/ai-research" "$LOCAL_BIN_DIR/ai-research"
elif [[ -e "$LOCAL_BIN_DIR/ai-research" || -L "$LOCAL_BIN_DIR/ai-research" ]]; then
  echo "note  ai-research already exists; installing workflow wrapper as ai-research-workflow"
  link_command "$REPO_ROOT/bin/ai-research" "$LOCAL_BIN_DIR/ai-research-workflow"
else
  link_command "$REPO_ROOT/bin/ai-research" "$LOCAL_BIN_DIR/ai-research"
fi

link_command "$REPO_ROOT/bin/ai-doctor" "$LOCAL_BIN_DIR/ai-doctor"

if [[ "$PATCH_HERMES_SKILLS" -eq 1 ]]; then
  patch_hermes_skills
else
  echo "note  skipped Hermes config patch (use --patch-hermes-skills if needed)"
fi

echo
echo 'Install complete.'
echo "Repo: $REPO_ROOT"
echo "Env:  $AGENT_STACK_HOME/workflow.env"
echo "Bin:  $LOCAL_BIN_DIR"
echo
echo 'Next steps:'
echo '  1) Review ~/.config/agent-stack/workflow.env'
echo '  2) Run ai-doctor'
echo '  3) Install claude/opencode/codex if doctor warns they are missing'
