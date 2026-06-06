#!/usr/bin/env bash
set -euo pipefail

# Block writes/shell on main/master branch (allow branch creation)
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[[ -z "${BRANCH}" ]] && exit 0

if [[ "${BRANCH}" == "main" || "${BRANCH}" == "master" ]]; then
  # Allow branch-creation commands through
  input=$(cat /dev/stdin 2>/dev/null || echo "")
  if echo "${input}" | grep -qE "git (checkout -b|switch -c|branch )"; then
    exit 0
  fi
  echo "BLOCKED: On '${BRANCH}'. Create a feature branch first: git checkout -b <name>" >&2
  exit 2
fi

exit 0
