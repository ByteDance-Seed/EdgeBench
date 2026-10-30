#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hooks_dir="$repo_root/.githooks"

if [[ ! -d "$hooks_dir" ]]; then
  echo "Missing hooks directory: $hooks_dir" >&2
  exit 1
fi

chmod +x "$hooks_dir/pre-commit" "$hooks_dir/pre-push"
git config core.hooksPath .githooks

echo "Git hooks installed."
echo "core.hooksPath=$(git config --get core.hooksPath)"
echo "Clippy gate is now enforced on commit and push."

