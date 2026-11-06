#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/bump-release-version.sh <version>

Bumps the shared release-train crate versions:
  - cas-cli (cas)
  - cas-types
  - cas-search
  - cas-store
  - cas-core
  - cas-mcp

Example:
  scripts/bump-release-version.sh 0.5.4

Release guardrails:
  - CHANGELOG.md must contain "## [Unreleased]"
  - CHANGELOG.md must contain a dated section:
      ## [<version>] - YYYY-MM-DD
  - That section must include at least one bullet item ("- ...")
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

version="$1"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be semver (e.g. 0.5.4)" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

changelog_file="CHANGELOG.md"
if [ ! -f "$changelog_file" ]; then
  echo "error: missing $changelog_file" >&2
  exit 1
fi

if ! grep -Eq '^## \[Unreleased\]$' "$changelog_file"; then
  echo "error: $changelog_file must contain an [Unreleased] section" >&2
  exit 1
fi

if ! grep -Eq "^## \[$version\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$changelog_file"; then
  echo "error: $changelog_file is missing release heading for $version" >&2
  echo "add a section like: ## [$version] - $(date +%Y-%m-%d)" >&2
  exit 1
fi

has_bullet_in_release_section="$(
  awk -v version="$version" '
    $0 ~ "^## \\[" version "\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" { in_section=1; next }
    in_section && /^## \[/ { in_section=0 }
    in_section && /^- / { has_bullet=1 }
    END { if (has_bullet) print "yes"; else print "no" }
  ' "$changelog_file"
)"

if [ "$has_bullet_in_release_section" != "yes" ]; then
  echo "error: $changelog_file section [$version] must contain at least one bullet item" >&2
  exit 1
fi

release_crates=(
  "cas-cli/Cargo.toml"
  "crates/cas-types/Cargo.toml"
  "crates/cas-search/Cargo.toml"
  "crates/cas-store/Cargo.toml"
  "crates/cas-core/Cargo.toml"
  "crates/cas-mcp/Cargo.toml"
)

for file in "${release_crates[@]}"; do
  if [ ! -f "$file" ]; then
    echo "error: missing $file" >&2
    exit 1
  fi

  current="$(grep -m1 '^version = "' "$file" | sed -E 's/^version = "([^"]+)"/\1/')"
  if [ "$current" = "$version" ]; then
    echo "ok: $file already $version"
    continue
  fi

  perl -0777 -i -pe "s/^version = \".*\"/version = \"$version\"/m" "$file"
  echo "updated: $file ($current -> $version)"
done

tag="v$version"
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
  echo "tag: $tag exists locally"
else
  echo "tag: $tag not found locally"
fi
