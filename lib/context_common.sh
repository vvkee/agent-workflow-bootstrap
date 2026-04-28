#!/usr/bin/env bash

context_dir() {
  printf '%s' "${AI_CONTEXT_DIR:-$AGENT_STACK_HOME/context}"
}

context_bundle_dir() {
  printf '%s' "${AI_CONTEXT_BUNDLE_DIR:-$(context_dir)/bundles}"
}

context_archive_dir() {
  printf '%s' "${AI_CONTEXT_ARCHIVE_DIR:-$(context_dir)/archive}"
}

context_template_dir() {
  printf '%s' "$WORKFLOW_ROOT/templates/context"
}

context_max_lines() {
  printf '%s' "${AI_CONTEXT_MAX_LINES:-300}"
}

context_max_bytes() {
  printf '%s' "${AI_CONTEXT_MAX_BYTES:-32768}"
}

context_enabled() {
  [[ "${AI_CONTEXT_ENABLED:-1}" != "0" ]]
}

context_live_files() {
  printf '%s\n' \
    agent-rules.md \
    memory-policy.md \
    privacy-boundary.md
}

context_source_dir() {
  local installed_dir template_dir
  installed_dir="$(context_dir)"
  template_dir="$(context_template_dir)"

  if [[ -d "$installed_dir" ]]; then
    printf '%s' "$installed_dir"
  else
    printf '%s' "$template_dir"
  fi
}

install_context_templates() {
  local force="${1:-0}"
  local dst template src name
  dst="$(context_dir)"
  template="$(context_template_dir)"

  [[ -d "$template" ]] || die "Context template dir not found: $template"
  mkdir -p "$dst"

  for src in "$template"/*.md; do
    [[ -f "$src" ]] || continue
    name="$(basename "$src")"
    if [[ -e "$dst/$name" && "$force" != "1" ]]; then
      echo "skip  $dst/$name (exists)"
      continue
    fi
    cp "$src" "$dst/$name"
    echo "copy  $dst/$name"
  done
}

context_target_instructions() {
  local target="$1"
  case "$target" in
    builder|claude|opencode)
      cat <<'EOF'
Role: primary code writer.
Rules: inspect the current repo first, make the smallest safe change, run verification, and report changed files / verification / remaining risk. Do not ask another agent to co-write the same files.
EOF
      ;;
    reviewer|codex)
      cat <<'EOF'
Role: independent read-only reviewer.
Rules: review only the provided diff/scope. Do not modify files. Findings are hypotheses; require concrete evidence and focus on blocker/high-risk issues.
EOF
      ;;
    researcher|hermes)
      cat <<'EOF'
Role: external research and orchestration support.
Rules: gather facts, unknowns, risks, and recommendations. Do not write code or mutate repo state from the research step.
EOF
      ;;
    *)
      cat <<EOF
Role: $target.
Rules: use only the minimum relevant context and follow the repository's actual files over stale context notes.
EOF
      ;;
  esac
}

generate_context_bundle() {
  local target="${1:-builder}"
  local source_dir file path

  if ! context_enabled; then
    cat <<'EOF'
# Agent Workflow Context Bundle
Context loading is disabled by AI_CONTEXT_ENABLED=0.
EOF
    return 0
  fi

  source_dir="$(context_source_dir)"

  cat <<EOF
# Agent Workflow Context Bundle
Target: $target
Source: $source_dir

## Target-specific instructions
$(context_target_instructions "$target")

## Context discipline
- This bundle is a small operating contract, not a personal knowledge base.
- If this bundle conflicts with the current repository, trust the repository.
- Do not request or expose secrets, credentials, financial/private records, or full personal vaults.
- Keep generated repo-local artifacts under .ai/tmp/ or .codex/tmp/ unless the user explicitly asks otherwise.

EOF

  for file in $(context_live_files); do
    path="$source_dir/$file"
    printf '## %s\n' "$file"
    if [[ -f "$path" ]]; then
      sed 's/[[:space:]]*$//' "$path"
    else
      printf '_Missing optional context file: %s_\n' "$path"
    fi
    printf '\n'
  done
}

write_context_bundle() {
  local target="${1:-builder}"
  local out_dir out_path
  out_dir="$(context_bundle_dir)"
  mkdir -p "$out_dir"
  out_path="$out_dir/context-$target-$(timestamp_now).md"
  generate_context_bundle "$target" > "$out_path"
  printf '%s' "$out_path"
}

review_context_files() {
  local dir="${1:-$(context_dir)}"
  local max_lines max_bytes warnings file path lines bytes
  max_lines="$(context_max_lines)"
  max_bytes="$(context_max_bytes)"
  warnings=0

  echo "Context review: $dir"

  if [[ ! -d "$dir" ]]; then
    echo "[warn] context dir missing: $dir (run: ai-context init)"
    return 1
  fi

  for file in $(context_live_files); do
    path="$dir/$file"
    if [[ ! -f "$path" ]]; then
      echo "[warn] missing context file: $path"
      warnings=$((warnings + 1))
      continue
    fi

    lines="$(wc -l < "$path" | tr -d ' ')"
    bytes="$(wc -c < "$path" | tr -d ' ')"

    if [[ "$lines" -gt "$max_lines" ]]; then
      echo "[warn] $file has $lines lines (limit: $max_lines)"
      warnings=$((warnings + 1))
    fi

    if [[ "$bytes" -gt "$max_bytes" ]]; then
      echo "[warn] $file has $bytes bytes (limit: $max_bytes)"
      warnings=$((warnings + 1))
    fi

    if grep -Eiq '(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$path"; then
      echo "[warn] $file contains credential-looking key/value text"
      warnings=$((warnings + 1))
    fi

    if grep -Eiq 'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY' "$path"; then
      echo "[warn] $file contains private-key-looking text"
      warnings=$((warnings + 1))
    fi

    if grep -Eq '([0-9]{4}[- ]?){3}[0-9]{4}' "$path"; then
      echo "[warn] $file contains payment-card-looking digits"
      warnings=$((warnings + 1))
    fi
  done

  if [[ "$warnings" -eq 0 ]]; then
    echo "Context review passed"
    return 0
  fi

  echo "Context review found $warnings warning(s)"
  return 1
}

archive_context_bundles() {
  local src dst count file
  src="$(context_bundle_dir)"
  dst="$(context_archive_dir)/$(timestamp_now)"
  count=0

  if [[ ! -d "$src" ]]; then
    echo "No context bundle dir found: $src"
    return 0
  fi

  mkdir -p "$dst"
  for file in "$src"/*.md "$src"/*.txt; do
    [[ -e "$file" ]] || continue
    mv "$file" "$dst/"
    count=$((count + 1))
  done

  if [[ "$count" -eq 0 ]]; then
    rmdir "$dst" 2>/dev/null || true
    echo "No context bundles to archive"
  else
    echo "Archived $count context bundle(s) to $dst"
  fi
}
