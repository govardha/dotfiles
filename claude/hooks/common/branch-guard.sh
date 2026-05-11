#!/usr/bin/env bash
set -euo pipefail

# Block file writes when on main/master branch
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"

if [[ "${BRANCH}" == "main" || "${BRANCH}" == "master" ]]; then
  echo '{"decision":"block","reason":"Cannot write files on main/master. Create a feature branch first."}'
  exit 0
fi

echo '{"decision":"allow"}'
