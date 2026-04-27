#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_BASE="$(mktemp -d)"
trap 'rm -rf "$TMP_BASE"' EXIT

LOG_DIR="$TMP_BASE/logs"
mkdir -p "$LOG_DIR"
export WORKFLOW_FAKE_LOG_DIR="$LOG_DIR"
export PATH="$ROOT/verify/fixtures/bin:$PATH"

WORKFLOW_ENV_FILE="$TMP_BASE/workflow.env"
cat > "$WORKFLOW_ENV_FILE" <<'EOF'
AGENT_BUILD_DRIVER=claude
CLAUDE_CMD=claude
OPENCODE_CMD=opencode
CODEX_CMD=codex
HERMES_CMD=hermes
CODEX_REVIEW_MODE=working-tree
HERMES_RESEARCH_TOOLSETS=web,browser
EOF
export WORKFLOW_ENV="$WORKFLOW_ENV_FILE"

REPO_DIR="$TMP_BASE/repo"
"$ROOT/verify/fixtures/setup-test-repo.sh" "$REPO_DIR" >/dev/null
cd "$REPO_DIR"

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || { echo "Missing file: $path" >&2; exit 1; }
}

assert_contains() {
  local path="$1"
  local text="$2"
  grep -F -- "$text" "$path" >/dev/null 2>&1 || {
    echo "Expected to find [$text] in $path" >&2
    exit 1
  }
}

assert_not_contains() {
  local path="$1"
  local text="$2"
  if grep -F -- "$text" "$path" >/dev/null 2>&1; then
    echo "Did not expect to find [$text] in $path" >&2
    exit 1
  fi
}

printf 'E2E: ai-build with Claude driver\n'
"$ROOT/bin/ai-build" --dump-prompt "fix fixture bug" > "$TMP_BASE/ai-build-claude.out"
assert_file "$LOG_DIR/claude-1.args"
assert_contains "$LOG_DIR/claude-1.args" 'ARG[0]=-p'
assert_contains "$LOG_DIR/claude-1.args" '--dangerously-skip-permissions'
BUILD_PROMPT_PATH="$(find "$REPO_DIR/.ai/tmp" -maxdepth 1 -name 'build-prompt-*.txt' | head -n 1)"
assert_file "$BUILD_PROMPT_PATH"
assert_contains "$BUILD_PROMPT_PATH" '任务：'

printf 'E2E: ai-build with OpenCode driver override\n'
"$ROOT/bin/ai-build" --driver opencode --model test-model --no-auto-approve --dump-prompt "implement fixture feature" > "$TMP_BASE/ai-build-opencode.out"
assert_file "$LOG_DIR/opencode-1.args"
assert_contains "$LOG_DIR/opencode-1.args" 'ARG[0]=run'
assert_contains "$LOG_DIR/opencode-1.args" 'ARG[1]=--agent'
assert_contains "$LOG_DIR/opencode-1.args" 'ARG[3]=--model'
assert_contains "$LOG_DIR/opencode-1.args" 'ARG[4]=test-model'
assert_not_contains "$LOG_DIR/opencode-1.args" '--dangerously-skip-permissions'

printf 'E2E: ai-review working-tree diff with explicit untracked file\n'
"$ROOT/bin/ai-review" --mode working-tree --model review-model --include-untracked untracked.txt --dump-prompt > "$TMP_BASE/ai-review.out"
assert_file "$LOG_DIR/codex-1.args"
assert_contains "$LOG_DIR/codex-1.args" 'ARG[0]=exec'
assert_contains "$LOG_DIR/codex-1.args" 'review-model'
REVIEW_DIFF_PATH="$(find "$REPO_DIR/.codex/tmp" -maxdepth 1 -name 'review-*.diff' | head -n 1)"
REVIEW_PROMPT_PATH="$(find "$REPO_DIR/.codex/tmp" -maxdepth 1 -name 'review-prompt-*.txt' | head -n 1)"
assert_file "$REVIEW_DIFF_PATH"
assert_file "$REVIEW_PROMPT_PATH"
assert_contains "$REVIEW_DIFF_PATH" '## git status --short'
assert_contains "$REVIEW_DIFF_PATH" '## git diff'
assert_contains "$REVIEW_DIFF_PATH" '## git diff --no-index (explicit untracked files)'
assert_contains "$REVIEW_DIFF_PATH" 'untracked.txt'
assert_contains "$REVIEW_PROMPT_PATH" 'Review only this diff file:'

printf 'E2E: ai-research with profile/toolset override\n'
"$ROOT/bin/ai-research" --profile thin --toolsets web --dump-prompt "research fixture topic" > "$TMP_BASE/ai-research.out"
assert_file "$LOG_DIR/hermes-1.args"
assert_contains "$LOG_DIR/hermes-1.args" 'ARG[0]=-p'
assert_contains "$LOG_DIR/hermes-1.args" 'ARG[1]=thin'
assert_contains "$LOG_DIR/hermes-1.args" 'ARG[2]=chat'
assert_contains "$LOG_DIR/hermes-1.args" 'ARG[5]=-t'
assert_contains "$LOG_DIR/hermes-1.args" 'ARG[6]=web'
RESEARCH_PROMPT_PATH="$(find "$REPO_DIR/.ai/tmp" -maxdepth 1 -name 'research-prompt-*.txt' | head -n 1)"
assert_file "$RESEARCH_PROMPT_PATH"
assert_contains "$RESEARCH_PROMPT_PATH" '研究问题：'

printf 'E2E check passed\n'
