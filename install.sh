#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_ARGS=("$@")
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
PATCH_HERMES_SKILLS=0
BOOTSTRAP_REPO="${AGENT_WORKFLOW_BOOTSTRAP_REPO:-vvkee/agent-workflow-bootstrap}"
BOOTSTRAP_REF="${AGENT_WORKFLOW_BOOTSTRAP_REF:-main}"

bootstrap_from_github() {
  command -v curl >/dev/null 2>&1 || { echo 'curl is required for bootstrap' >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { echo 'tar is required for bootstrap' >&2; exit 1; }
  command -v mktemp >/dev/null 2>&1 || { echo 'mktemp is required for bootstrap' >&2; exit 1; }

  local tmpdir archive_url extracted
  tmpdir="$(mktemp -d)"
  archive_url="https://codeload.github.com/${BOOTSTRAP_REPO}/tar.gz/refs/heads/${BOOTSTRAP_REF}"

  echo "bootstrap  downloading ${BOOTSTRAP_REPO}@${BOOTSTRAP_REF}"
  curl -fsSL "$archive_url" | tar -xzf - -C "$tmpdir"
  extracted="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$extracted" ]] || { echo 'Failed to unpack bootstrap archive' >&2; exit 1; }

  exec bash "$extracted/install.sh" "${ORIGINAL_ARGS[@]}"
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

link_file "$REPO_ROOT/bin/ai-build" "$LOCAL_BIN_DIR/ai-build"
link_file "$REPO_ROOT/bin/ai-review" "$LOCAL_BIN_DIR/ai-review"

if [[ -L "$LOCAL_BIN_DIR/ai-research" ]] && [[ "$(readlink "$LOCAL_BIN_DIR/ai-research")" == "$REPO_ROOT/bin/ai-research" ]]; then
  echo "skip  $LOCAL_BIN_DIR/ai-research (already linked)"
elif [[ -e "$LOCAL_BIN_DIR/ai-research" || -L "$LOCAL_BIN_DIR/ai-research" ]]; then
  echo "note  ai-research already exists; installing workflow wrapper as ai-research-workflow"
  link_file "$REPO_ROOT/bin/ai-research" "$LOCAL_BIN_DIR/ai-research-workflow"
else
  link_file "$REPO_ROOT/bin/ai-research" "$LOCAL_BIN_DIR/ai-research"
fi

link_file "$REPO_ROOT/bin/ai-doctor" "$LOCAL_BIN_DIR/ai-doctor"

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
