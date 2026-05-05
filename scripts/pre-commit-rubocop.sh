#!/usr/bin/env bash
# Pre-commit hook: run RuboCop with autofix on staged Ruby files.
set -uo pipefail

FILES=("$@")

if command -v rubocop >/dev/null 2>&1; then
  exec rubocop -A --force-exclusion "${FILES[@]}"
fi

if bundle exec rubocop -v >/dev/null 2>&1; then
  exec bundle exec rubocop -A --force-exclusion "${FILES[@]}"
fi

echo "RuboCop is not available locally; CI will enforce RuboCop."
exit 0
