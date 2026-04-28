#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_BASE="$(mktemp -d)"
trap 'rm -rf "$TMP_BASE"' EXIT

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || { echo "Missing file: $path" >&2; exit 1; }
}

assert_link_target() {
  local path="$1"
  local expected="$2"
  [[ -L "$path" ]] || { echo "Expected symlink: $path" >&2; exit 1; }
  [[ "$(readlink "$path")" == "$expected" ]] || {
    echo "Unexpected link target for $path: $(readlink "$path")" >&2
    echo "Expected: $expected" >&2
    exit 1
  }
}

assert_link_target_prefix() {
  local path="$1"
  local prefix="$2"
  [[ -L "$path" ]] || { echo "Expected symlink: $path" >&2; exit 1; }
  [[ "$(readlink "$path")" == "$prefix"* ]] || {
    echo "Unexpected link target for $path: $(readlink "$path")" >&2
    echo "Expected prefix: $prefix" >&2
    exit 1
  }
}

check_common_install_files() {
  local home_dir="$1"
  assert_file "$home_dir/.claude/CLAUDE.md"
  assert_file "$home_dir/.config/opencode/AGENTS.md"
  assert_file "$home_dir/.codex/AGENTS.md"
  assert_file "$home_dir/.agents/skills/repo-review/SKILL.md"
  assert_file "$home_dir/.agents/skills/repo-brief/SKILL.md"
  assert_file "$home_dir/.hermes/SOUL.md"
  assert_file "$home_dir/.config/agent-stack/workflow.env"
  assert_file "$home_dir/.config/agent-stack/output-contract.md"
  assert_file "$home_dir/.config/agent-stack/context/agent-rules.md"
  assert_file "$home_dir/.config/agent-stack/context/memory-policy.md"
  assert_file "$home_dir/.config/agent-stack/context/privacy-boundary.md"
  assert_file "$home_dir/.config/agent-stack/context/context-bundle.example.md"
}

printf 'Install test: local source install\n'
LOCAL_HOME="$TMP_BASE/home-local"
LOCAL_BIN_DIR="$LOCAL_HOME/.local/bin"
LOCAL_STACK_HOME="$LOCAL_HOME/.config/agent-stack"
mkdir -p "$LOCAL_HOME"

HOME="$LOCAL_HOME" \
AGENT_STACK_HOME="$LOCAL_STACK_HOME" \
LOCAL_BIN_DIR="$LOCAL_BIN_DIR" \
bash "$ROOT/install.sh"

check_common_install_files "$LOCAL_HOME"
assert_link_target "$LOCAL_BIN_DIR/ai-build" "$ROOT/bin/ai-build"
assert_link_target "$LOCAL_BIN_DIR/ai-context" "$ROOT/bin/ai-context"
assert_link_target "$LOCAL_BIN_DIR/ai-review" "$ROOT/bin/ai-review"
assert_link_target "$LOCAL_BIN_DIR/ai-research" "$ROOT/bin/ai-research"
assert_link_target "$LOCAL_BIN_DIR/ai-doctor" "$ROOT/bin/ai-doctor"

HOME="$LOCAL_HOME" \
AGENT_STACK_HOME="$LOCAL_STACK_HOME" \
LOCAL_BIN_DIR="$LOCAL_BIN_DIR" \
bash "$ROOT/install.sh"

printf 'Install test: bootstrap install stages repo to stable path\n'
ARCHIVE_PATH="$TMP_BASE/agent-workflow-bootstrap.tar.gz"
tar -czf "$ARCHIVE_PATH" \
  --exclude='.git' \
  --exclude='.ai' \
  --exclude='.codex' \
  --exclude='.hermes' \
  -C "$(dirname "$ROOT")" "$(basename "$ROOT")"

BOOT_HOME="$TMP_BASE/home-bootstrap"
BOOT_BIN_DIR="$BOOT_HOME/.local/bin"
BOOT_STACK_HOME="$BOOT_HOME/.config/agent-stack"
BOOT_STAGE_DIR="$BOOT_HOME/.local/share/agent-workflow-bootstrap"
OLD_STAGE_DIR="$BOOT_HOME/.local/share/agent-workflow-bootstrap-old"
UNRELATED_RESEARCH_TARGET="$BOOT_HOME/.local/bin/custom-ai-research"
mkdir -p "$BOOT_HOME" "$BOOT_BIN_DIR" "$OLD_STAGE_DIR/bin"

for cmd in ai-build ai-context ai-review ai-doctor; do
  printf '# old bootstrap target\n' > "$OLD_STAGE_DIR/bin/$cmd"
  ln -sf "$OLD_STAGE_DIR/bin/$cmd" "$BOOT_BIN_DIR/$cmd"
done
printf '# unrelated research command\n' > "$UNRELATED_RESEARCH_TARGET"
ln -sf "$UNRELATED_RESEARCH_TARGET" "$BOOT_BIN_DIR/ai-research"
printf '# old bootstrap alias target\n' > "$OLD_STAGE_DIR/bin/ai-research-workflow"
ln -sf "$OLD_STAGE_DIR/bin/ai-research-workflow" "$BOOT_BIN_DIR/ai-research-workflow"

HOME="$BOOT_HOME" \
AGENT_STACK_HOME="$BOOT_STACK_HOME" \
LOCAL_BIN_DIR="$BOOT_BIN_DIR" \
AGENT_WORKFLOW_BOOTSTRAP_ARCHIVE_URL="file://$ARCHIVE_PATH" \
AGENT_WORKFLOW_BOOTSTRAP_STAGE_DIR="$BOOT_STAGE_DIR" \
bash "$ROOT/bootstrap.sh"

check_common_install_files "$BOOT_HOME"
assert_file "$BOOT_STAGE_DIR/install.sh"
assert_link_target_prefix "$BOOT_BIN_DIR/ai-build" "$BOOT_STAGE_DIR/bin/ai-build"
assert_link_target_prefix "$BOOT_BIN_DIR/ai-context" "$BOOT_STAGE_DIR/bin/ai-context"
assert_link_target_prefix "$BOOT_BIN_DIR/ai-review" "$BOOT_STAGE_DIR/bin/ai-review"
assert_link_target "$BOOT_BIN_DIR/ai-research" "$UNRELATED_RESEARCH_TARGET"
assert_link_target_prefix "$BOOT_BIN_DIR/ai-research-workflow" "$BOOT_STAGE_DIR/bin/ai-research"
assert_link_target_prefix "$BOOT_BIN_DIR/ai-doctor" "$BOOT_STAGE_DIR/bin/ai-doctor"

printf 'Install test passed\n'
