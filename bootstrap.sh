#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_REPO="${AGENT_WORKFLOW_BOOTSTRAP_REPO:-vvkee/agent-workflow-bootstrap}"
BOOTSTRAP_REF="${AGENT_WORKFLOW_BOOTSTRAP_REF:-main}"

command -v curl >/dev/null 2>&1 || { echo 'curl is required for bootstrap' >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo 'tar is required for bootstrap' >&2; exit 1; }
command -v mktemp >/dev/null 2>&1 || { echo 'mktemp is required for bootstrap' >&2; exit 1; }

tmpdir="$(mktemp -d)"
archive_url="https://codeload.github.com/${BOOTSTRAP_REPO}/tar.gz/refs/heads/${BOOTSTRAP_REF}"

echo "bootstrap  downloading ${BOOTSTRAP_REPO}@${BOOTSTRAP_REF}"
curl -fsSL "$archive_url" | tar -xzf - -C "$tmpdir"
repo_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -n "$repo_dir" ]] || { echo 'Failed to unpack bootstrap archive' >&2; exit 1; }

exec bash "$repo_dir/install.sh" "$@"
