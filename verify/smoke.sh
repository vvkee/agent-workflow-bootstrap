#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Smoke check: shell syntax\n'
bash -n "$ROOT/install.sh"
bash -n "$ROOT/bootstrap.sh"
bash -n "$ROOT/lib/common.sh"
bash -n "$ROOT/bin/ai-build"
bash -n "$ROOT/bin/ai-review"
bash -n "$ROOT/bin/ai-research"
bash -n "$ROOT/bin/ai-doctor"

printf 'Smoke check: required files\n'
for path in \
  "$ROOT/README.md" \
  "$ROOT/env/workflow.env.example" \
  "$ROOT/templates/claude/CLAUDE.md" \
  "$ROOT/templates/opencode/AGENTS.md" \
  "$ROOT/templates/codex/AGENTS.md" \
  "$ROOT/templates/codex/skills/repo-review/SKILL.md" \
  "$ROOT/templates/codex/skills/repo-brief/SKILL.md" \
  "$ROOT/templates/shared/output-contract.md" \
  "$ROOT/templates/hermes/SOUL.md"; do
  [[ -f "$path" ]] || { echo "Missing file: $path" >&2; exit 1; }
done

printf 'Smoke check: env loader precedence and shell syntax\n'
WORKFLOW_ENV="$ROOT/env/workflow.env.example" AGENT_BUILD_DRIVER=opencode bash -c '
  source "$0/lib/common.sh"
  load_workflow_env
  [[ "$AGENT_BUILD_DRIVER" == "opencode" ]]
' "$ROOT"

tmp_env="$(mktemp)"
cat > "$tmp_env" <<'EOF'
export AGENT_BUILD_DRIVER=opencode
CLAUDE_CMD="claude"
EOF
WORKFLOW_ENV="$tmp_env" bash -c '
  source "$0/lib/common.sh"
  load_workflow_env
  [[ "$AGENT_BUILD_DRIVER" == "opencode" ]]
  [[ "$CLAUDE_CMD" == "claude" ]]
' "$ROOT"
rm -f "$tmp_env"

printf 'Smoke check passed\n'
