#!/usr/bin/env bash
# Common git guard — enforces trunk protection and safe workflows
# Rules:
#   - No commits/pushes directly to develop, master, or main
#   - develop/master/main changes only via PR
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
protected_branches="develop|master|main"

# ── Block add/commit on protected branches ───────────────────────────────────
if echo "${cmd}" | grep -qE '^git (add|commit)'; then
  if [[ "${current_branch}" =~ ${protected_branches} ]]; then
    echo "BLOCKED: Cannot commit directly to ${current_branch}" >&2
    echo "" >&2
    echo "Workflow: Create a feature branch and merge via pull request" >&2
    echo "  git checkout -b feature/my-change" >&2
    echo "  git commit -m '...'" >&2
    echo "  git push && bkt pr create --target ${current_branch}" >&2
    exit 2
  fi
fi

# ── Block push to protected branches ─────────────────────────────────────────
if echo "${cmd}" | grep -qE '^git push'; then
  # Extract target branch from push command (handles variations like push -f, push origin main, etc)
  push_target=""
  if [[ "${cmd}" =~ push[[:space:]]+((-f|--force)[[:space:]]+)?([^[:space:]]+:)?([^[:space:]]+) ]]; then
    push_target="${BASH_REMATCH[4]}"
  fi

  if [[ -z "${push_target}" ]] && [[ "${current_branch}" =~ ${protected_branches} ]]; then
    push_target="${current_branch}"
  fi

  if [[ "${push_target}" =~ ${protected_branches} ]]; then
    echo "BLOCKED: Cannot push directly to ${push_target}" >&2
    echo "" >&2
    echo "Workflow: Merge via pull request instead" >&2
    echo "  bkt pr create --title '...' --target ${push_target}" >&2
    echo "  bkt pr merge <pr-id>" >&2
    exit 2
  fi

  # ── Block push with uncommitted staged changes ───────────────────────────
  if ! git diff --cached --quiet 2>/dev/null; then
    echo "BLOCKED: Staged changes exist but are not committed." >&2
    echo "Run 'git status' and commit your staged changes before pushing." >&2
    echo "" >&2
    git diff --cached --name-only >&2
    exit 2
  fi
fi

exit 0
