#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_REPO="${AGENT_WORKFLOW_BOOTSTRAP_REPO:-vvkee/agent-workflow-bootstrap}"
BOOTSTRAP_REF="${AGENT_WORKFLOW_BOOTSTRAP_REF:-main}"
BOOTSTRAP_ARCHIVE_URL="${AGENT_WORKFLOW_BOOTSTRAP_ARCHIVE_URL:-}"
BOOTSTRAP_STAGE_DIR="${AGENT_WORKFLOW_BOOTSTRAP_STAGE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/agent-workflow-bootstrap}"

command -v curl >/dev/null 2>&1 || { echo 'curl is required for bootstrap' >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo 'tar is required for bootstrap' >&2; exit 1; }
command -v mktemp >/dev/null 2>&1 || { echo 'mktemp is required for bootstrap' >&2; exit 1; }

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
  if [[ -n "${PREVIOUS_STAGE_DIR:-}" && -e "$PREVIOUS_STAGE_DIR" ]]; then
    rm -rf "$PREVIOUS_STAGE_DIR"
  fi
}

restore_previous_stage() {
  if [[ -n "${PREVIOUS_STAGE_DIR:-}" && -e "$PREVIOUS_STAGE_DIR" ]]; then
    rm -rf "$BOOTSTRAP_STAGE_DIR"
    mv "$PREVIOUS_STAGE_DIR" "$BOOTSTRAP_STAGE_DIR"
  fi
}

tmpdir="$(mktemp -d)"
archive_url="$(resolve_archive_url)"
incoming_stage="${BOOTSTRAP_STAGE_DIR}.incoming.$$"
backup_stage="${BOOTSTRAP_STAGE_DIR}.backup.$$"
PREVIOUS_STAGE_DIR=""

echo "bootstrap  downloading ${BOOTSTRAP_REPO}@${BOOTSTRAP_REF}"
curl -fsSL "$archive_url" | tar -xzf - -C "$tmpdir"
repo_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -n "$repo_dir" ]] || { echo 'Failed to unpack bootstrap archive' >&2; rm -rf "$tmpdir"; exit 1; }

validate_stage_dir "$BOOTSTRAP_STAGE_DIR"
mkdir -p "$(dirname "$BOOTSTRAP_STAGE_DIR")"
rm -rf "$incoming_stage" "$backup_stage"
mv "$repo_dir" "$incoming_stage"
if [[ -e "$BOOTSTRAP_STAGE_DIR" ]]; then
  mv "$BOOTSTRAP_STAGE_DIR" "$backup_stage"
  PREVIOUS_STAGE_DIR="$backup_stage"
fi
if ! mv "$incoming_stage" "$BOOTSTRAP_STAGE_DIR"; then
  rm -rf "$incoming_stage"
  restore_previous_stage
  rm -rf "$tmpdir"
  echo "Failed to stage bootstrap repo at $BOOTSTRAP_STAGE_DIR" >&2
  exit 1
fi
rm -rf "$tmpdir"

echo "bootstrap  staged repo at $BOOTSTRAP_STAGE_DIR"
if bash "$BOOTSTRAP_STAGE_DIR/install.sh" "$@"; then
  cleanup_previous_stage
  exit 0
fi
restore_previous_stage
exit 1
