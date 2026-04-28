#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_BASE="$(mktemp -d)"
trap 'rm -rf "$TMP_BASE"' EXIT

export HOME="$TMP_BASE/home"
export AGENT_STACK_HOME="$HOME/.config/agent-stack"
mkdir -p "$HOME"

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

printf 'Context smoke: init\n'
"$ROOT/bin/ai-context" init >/dev/null
assert_file "$AGENT_STACK_HOME/context/agent-rules.md"
assert_file "$AGENT_STACK_HOME/context/memory-policy.md"
assert_file "$AGENT_STACK_HOME/context/privacy-boundary.md"
assert_file "$AGENT_STACK_HOME/context/context-bundle.example.md"

printf 'Context smoke: bundle stdout\n'
"$ROOT/bin/ai-context" bundle --target codex > "$TMP_BASE/codex-context.md"
assert_contains "$TMP_BASE/codex-context.md" 'Target: codex'
assert_contains "$TMP_BASE/codex-context.md" 'Role: independent read-only reviewer.'
assert_contains "$TMP_BASE/codex-context.md" '## agent-rules.md'

printf 'Context smoke: bundle write\n'
bundle_path="$("$ROOT/bin/ai-context" bundle --target claude --write)"
assert_file "$bundle_path"
assert_contains "$bundle_path" 'Target: claude'

printf 'Context smoke: review\n'
"$ROOT/bin/ai-context" review >/dev/null

printf 'Context smoke: archive\n'
"$ROOT/bin/ai-context" archive >/dev/null

printf 'Context smoke passed\n'
