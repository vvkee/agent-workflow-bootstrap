#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-}"
[[ -n "$TARGET_DIR" ]] || { echo 'Usage: setup-test-repo.sh <target-dir>' >&2; exit 1; }

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

git init -q

git config user.name 'Workflow Fixture'
git config user.email 'workflow-fixture@example.com'

cat > note.txt <<'EOF'
hello
EOF

git add note.txt
git commit -q -m 'init fixture repo'

printf 'unstaged-change\n' >> note.txt
cat > staged.txt <<'EOF'
staged-change
EOF
git add staged.txt
cat > untracked.txt <<'EOF'
untracked-change
EOF

printf '%s\n' "$TARGET_DIR"
