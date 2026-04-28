#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Smoke check: shell syntax\n'
bash -n "$ROOT/install.sh"
bash -n "$ROOT/bootstrap.sh"
bash -n "$ROOT/lib/common.sh"
bash -n "$ROOT/lib/context_common.sh"
bash -n "$ROOT/lib/prompts.sh"
bash -n "$ROOT/bin/ai-build"
bash -n "$ROOT/bin/ai-context"
bash -n "$ROOT/bin/ai-review"
bash -n "$ROOT/bin/ai-research"
bash -n "$ROOT/bin/ai-doctor"
bash -n "$ROOT/verify/test-install.sh"
bash -n "$ROOT/verify/context-smoke.sh"
bash -n "$ROOT/verify/e2e.sh"
bash -n "$ROOT/verify/fixtures/setup-test-repo.sh"
bash -n "$ROOT/verify/fixtures/bin/claude"
bash -n "$ROOT/verify/fixtures/bin/opencode"
bash -n "$ROOT/verify/fixtures/bin/codex"
bash -n "$ROOT/verify/fixtures/bin/hermes"

printf 'Smoke check: required files\n'
for path in \
  "$ROOT/README.md" \
  "$ROOT/docs/roadmap.md" \
  "$ROOT/env/workflow.env.example" \
  "$ROOT/lib/prompts.sh" \
  "$ROOT/templates/claude/CLAUDE.md" \
  "$ROOT/templates/opencode/AGENTS.md" \
  "$ROOT/templates/codex/AGENTS.md" \
  "$ROOT/templates/codex/skills/repo-review/SKILL.md" \
  "$ROOT/templates/codex/skills/repo-brief/SKILL.md" \
  "$ROOT/templates/context/agent-rules.md" \
  "$ROOT/templates/context/memory-policy.md" \
  "$ROOT/templates/context/privacy-boundary.md" \
  "$ROOT/templates/context/context-bundle.example.md" \
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

printf 'Smoke check: install flow\n'
bash "$ROOT/verify/test-install.sh"

printf 'Smoke check: context flow\n'
bash "$ROOT/verify/context-smoke.sh"

printf 'Smoke check: wrapper e2e\n'
bash "$ROOT/verify/e2e.sh"

printf 'Smoke check passed\n'
