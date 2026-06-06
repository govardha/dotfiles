#!/usr/bin/env bash
set -euo pipefail

# Block writes/shell on main/master branch (no-op outside git repos)
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[[ -z "${BRANCH}" ]] && exit 0

if [[ "${BRANCH}" == "main" || "${BRANCH}" == "master" ]]; then
  echo "BLOCKED: On '${BRANCH}'. Create a feature branch first: git checkout -b <name>" >&2
  exit 2
fi

exit 0
