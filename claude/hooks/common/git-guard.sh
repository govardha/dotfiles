#!/usr/bin/env bash
# Common git guard — blocks commits on main/master and pushes with staged changes
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

# ── Block add/commit on main/master ──────────────────────────────────────────
if echo "${cmd}" | grep -qE '^git (add|commit)'; then
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "${current_branch}" == "main" || "${current_branch}" == "master" ]]; then
    echo "BLOCKED: git add/commit on ${current_branch}. Create a feature branch first." >&2
    exit 2
  fi
fi

# ── Block push with uncommitted staged changes ───────────────────────────────
if echo "${cmd}" | grep -qE '^git push'; then
  if ! git diff --cached --quiet 2>/dev/null; then
    echo "BLOCKED: Staged changes exist but are not committed." >&2
    echo "Run 'git status' and commit your staged changes before pushing." >&2
    echo "" >&2
    git diff --cached --name-only >&2
    exit 2
  fi
fi

exit 0
